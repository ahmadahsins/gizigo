import { Injectable, NotFoundException } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { FirebaseService } from '../firebase/firebase.service';
import { RecordRecentlyViewedDto } from './dto/record-recently-viewed.dto';
import { RecordRecentLocationDto } from './dto/record-recent-location.dto';
import { RecentlyViewedQueryDto } from './dto/recently-viewed-query.dto';
import { UpdateUserProfileDto } from './dto/update-user-profile.dto';

@Injectable()
export class UsersService {
  constructor(private firebaseService: FirebaseService) {}

  private db() {
    return this.firebaseService.getFirestore();
  }

  async getProfile(uid: string) {
    const doc = await this.db().collection('users').doc(uid).get();
    const data = doc.data() ?? {};
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

    let rows = snap.docs.map((d) => ({
      food_id: d.data().food_id as string,
      viewed_at: this.serializeTs(d.data().viewed_at),
    }));

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
          String(row.food.name ?? '')
            .toLowerCase()
            .includes(term) ||
          String(row.food.description ?? '')
            .toLowerCase()
            .includes(term),
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

    return snap.docs.map((d) => ({
      id: d.id,
      ...d.data(),
      last_used_at: this.serializeTs(d.data().last_used_at),
    }));
  }

  private normalizeProfile(uid: string, data: FirebaseFirestore.DocumentData) {
    return {
      uid,
      name: data.name ?? null,
      email: data.email ?? null,
      username: data.username ?? data.name ?? null,
      role: data.role ?? 'customer',
      gender: data.gender ?? null,
      age: data.age ?? null,
      weight_kg: data.weight_kg ?? null,
      height_cm: data.height_cm ?? null,
      nutrition_goal: data.nutrition_goal ?? null,
      food_preferences: Array.isArray(data.food_preferences)
        ? data.food_preferences
        : [],
      onboarding_completed: Boolean(data.onboarding_completed),
      preferred_language: data.preferred_language ?? null,
      dark_mode: data.dark_mode ?? null,
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
  ): Promise<Record<string, FirebaseFirestore.DocumentData>> {
    const map: Record<string, FirebaseFirestore.DocumentData> = {};
    if (ids.length === 0) return map;

    const refs = ids.map((id) => this.db().collection('foods').doc(id));
    const chunks: FirebaseFirestore.DocumentReference[][] = [];
    for (let i = 0; i < refs.length; i += 10) {
      chunks.push(refs.slice(i, i + 10));
    }

    for (const chunk of chunks) {
      const docs = await this.db().getAll(...chunk);
      docs.forEach((d) => {
        if (d.exists) map[d.id] = d.data() as FirebaseFirestore.DocumentData;
      });
    }
    return map;
  }

  private publicFoodCard(id: string, food: FirebaseFirestore.DocumentData) {
    return {
      id,
      name: food.name ?? null,
      description: food.description ?? null,
      photo_url: food.photo_url ?? null,
      image_url: food.photo_url ?? null,
      base_price: food.base_price ?? null,
      nutrition_grade: food.nutrition_grade ?? null,
      food_category: food.food_category ?? null,
      merchant_id: food.merchant_id ?? null,
      is_available: food.is_available ?? null,
    };
  }
}
