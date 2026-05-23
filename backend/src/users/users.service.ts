import { Injectable, NotFoundException } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { FirebaseService } from '../firebase/firebase.service';
import { RecordRecentlyViewedDto } from './dto/record-recently-viewed.dto';
import { RecordRecentLocationDto } from './dto/record-recent-location.dto';
import { RecentlyViewedQueryDto } from './dto/recently-viewed-query.dto';
import { UpdateUserProfileDto } from './dto/update-user-profile.dto';
import { CloudinaryService } from '../cloudinary/cloudinary.service';
import type { UploadedImageFile } from '../common/types/uploaded-image-file';

type StoredRecord = Record<string, unknown>;

@Injectable()
export class UsersService {
  constructor(
    private readonly firebaseService: FirebaseService,
    private readonly cloudinaryService: CloudinaryService,
  ) {}

  private db() {
    return this.firebaseService.getFirestore();
  }

  async getProfile(uid: string) {
    const doc = await this.db().collection('users').doc(uid).get();
    const data = this.toRecord(doc.data());
    return this.normalizeProfile(uid, data);
  }

  async updateProfile(uid: string, dto: UpdateUserProfileDto) {
    const ref = this.db().collection('users').doc(uid);
    const snap = await ref.get();
    if (!snap.exists) {
      throw new NotFoundException(
        'User not found — call POST /auth/sync (or /auth/signup) first',
      );
    }

    const patch: Record<string, unknown> = {};
    for (const [key, value] of Object.entries(dto)) {
      if (value !== undefined) {
        patch[key] = value;
      }
    }
    patch['updated_at'] = admin.firestore.FieldValue.serverTimestamp();

    await ref.set(patch, { merge: true });
    return this.getProfile(uid);
  }

  async uploadProfilePhoto(uid: string, file: UploadedImageFile) {
    const ref = this.db().collection('users').doc(uid);
    const snap = await ref.get();
    if (!snap.exists) {
      throw new NotFoundException(
        'User not found - call POST /auth/sync (or /auth/signup) first',
      );
    }

    const profilePhotoUrl = await this.cloudinaryService.uploadProfilePhoto(
      uid,
      file.buffer,
    );
    await ref.set(
      {
        profile_photo_url: profilePhotoUrl,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    return this.getProfile(uid);
  }

  async recordRecentlyViewed(uid: string, dto: RecordRecentlyViewedDto) {
    const foodRef = this.db().collection('foods').doc(dto.food_id);
    const foodSnap = await foodRef.get();
    if (!foodSnap.exists) {
      throw new NotFoundException('Food not found');
    }

    const rvRef = this.db()
      .collection('users')
      .doc(uid)
      .collection('recently_viewed')
      .doc(dto.food_id);

    await rvRef.set({
      food_id: dto.food_id,
      viewed_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { ok: true };
  }

  async getRecentlyViewed(uid: string, query: RecentlyViewedQueryDto) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const fetchSize = Math.min(Math.max(page * limit, limit), 100);

    const snap = await this.db()
      .collection('users')
      .doc(uid)
      .collection('recently_viewed')
      .orderBy('viewed_at', 'desc')
      .limit(fetchSize)
      .get();

    const rows = snap.docs
      .map((d) => {
        const data = this.toRecord(d.data());
        const foodId = data['food_id'];
        if (typeof foodId !== 'string') return null;
        return {
          food_id: foodId,
          viewed_at: this.serializeTs(data['viewed_at']),
        };
      })
      .filter((row): row is { food_id: string; viewed_at: string | null } =>
        Boolean(row),
      );

    const foodIds = [...new Set(rows.map((r) => r.food_id).filter(Boolean))];
    const foodMap = await this.batchFoodMap(foodIds);

    let items = rows
      .map((r) => {
        const food = foodMap[r.food_id];
        if (!food) return null;
        return {
          viewed_at: r.viewed_at,
          food: this.publicFoodCard(r.food_id, food),
        };
      })
      .filter(Boolean) as Array<{
      viewed_at: string | null;
      food: Record<string, unknown>;
    }>;

    if (query.q) {
      const term = query.q.toLowerCase();
      items = items.filter(
        (row) =>
          this.matchesText(row.food['name'], term) ||
          this.matchesText(row.food['description'], term),
      );
    }

    const total = items.length;
    const start = (page - 1) * limit;
    const pageItems = items.slice(start, start + limit);

    return {
      items: pageItems,
      total,
      page,
      limit,
      total_pages: Math.ceil(total / limit) || 1,
    };
  }

  async recordRecentLocation(uid: string, dto: RecordRecentLocationDto) {
    const locId = `${Math.round(dto.lat * 1e5)}_${Math.round(dto.lng * 1e5)}`;
    const ref = this.db()
      .collection('users')
      .doc(uid)
      .collection('recent_locations')
      .doc(locId);

    await ref.set(
      {
        label: dto.label,
        address: dto.address,
        lat: dto.lat,
        lng: dto.lng,
        distance_km: dto.distance_km ?? null,
        last_used_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    return { ok: true, id: locId };
  }

  async getRecentLocations(uid: string) {
    const snap = await this.db()
      .collection('users')
      .doc(uid)
      .collection('recent_locations')
      .orderBy('last_used_at', 'desc')
      .limit(50)
      .get();

    return snap.docs.map((d) => {
      const data = this.toRecord(d.data());
      return {
        id: d.id,
        ...data,
        last_used_at: this.serializeTs(data['last_used_at']),
      };
    });
  }

  private normalizeProfile(uid: string, data: StoredRecord) {
    return {
      uid,
      name: data['name'] ?? null,
      email: data['email'] ?? null,
      username: data['username'] ?? data['name'] ?? null,
      role: data['role'] ?? 'customer',
      merchant_id: data['merchant_id'] ?? null,
      profile_photo_url: data['profile_photo_url'] ?? null,
      gender: data['gender'] ?? null,
      age: data['age'] ?? null,
      weight_kg: data['weight_kg'] ?? null,
      height_cm: data['height_cm'] ?? null,
      nutrition_goal: data['nutrition_goal'] ?? null,
      food_preferences: Array.isArray(data['food_preferences'])
        ? data['food_preferences']
        : [],
      dietary_restrictions: Array.isArray(data['dietary_restrictions'])
        ? data['dietary_restrictions']
        : [],
      taste_profile: Array.isArray(data['taste_profile'])
        ? data['taste_profile']
        : [],
      onboarding_completed: Boolean(data['onboarding_completed']),
      preferred_language: data['preferred_language'] ?? null,
      dark_mode: data['dark_mode'] ?? null,
    };
  }

  private serializeTs(ts: unknown): string | null {
    if (!ts) return null;
    if (typeof (ts as { toDate?: () => Date }).toDate === 'function') {
      return (ts as FirebaseFirestore.Timestamp).toDate().toISOString();
    }
    return null;
  }

  private async batchFoodMap(
    ids: string[],
  ): Promise<Record<string, StoredRecord>> {
    const map: Record<string, StoredRecord> = {};
    if (ids.length === 0) return map;

    const refs = ids.map((id) => this.db().collection('foods').doc(id));
    const chunks: FirebaseFirestore.DocumentReference[][] = [];
    for (let i = 0; i < refs.length; i += 10) {
      chunks.push(refs.slice(i, i + 10));
    }

    for (const chunk of chunks) {
      const docs = await this.db().getAll(...chunk);
      docs.forEach((d) => {
        if (d.exists) map[d.id] = this.toRecord(d.data());
      });
    }
    return map;
  }

  private publicFoodCard(id: string, food: StoredRecord) {
    return {
      id,
      name: food['name'] ?? null,
      description: food['description'] ?? null,
      photo_url: food['photo_url'] ?? null,
      image_url: food['photo_url'] ?? null,
      base_price: food['base_price'] ?? null,
      nutrition_grade: food['nutrition_grade'] ?? null,
      food_category: food['food_category'] ?? null,
      merchant_id: food['merchant_id'] ?? null,
      is_available: food['is_available'] ?? null,
    };
  }

  private toRecord(value: unknown): StoredRecord {
    return value !== null && typeof value === 'object'
      ? (value as StoredRecord)
      : {};
  }

  private matchesText(value: unknown, term: string): boolean {
    return typeof value === 'string' && value.toLowerCase().includes(term);
  }
}
