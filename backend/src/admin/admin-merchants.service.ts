import {
  BadRequestException,
  ConflictException,
  Injectable,
  InternalServerErrorException,
  NotFoundException,
} from '@nestjs/common';
import * as admin from 'firebase-admin';
import { geohashForLocation } from 'geofire-common';
import { FirebaseService } from '../firebase/firebase.service';
import { CreateMerchantDto } from '../merchants/dto/create-merchant.dto';
import { ListMerchantsQueryDto } from '../merchants/dto/list-merchants-query.dto';
import { UpdateMerchantDto } from '../merchants/dto/update-merchant.dto';

type StoredRecord = Record<string, unknown>;

@Injectable()
export class AdminMerchantsService {
  constructor(private readonly firebaseService: FirebaseService) {}

  private db() {
    return this.firebaseService.getFirestore();
  }

  private auth() {
    return this.firebaseService.getAuth();
  }

  async createMerchant(dto: CreateMerchantDto) {
    const account = await this.createAuthUser({
      email: dto.business_email,
      password: dto.password,
      displayName: dto.name,
      disabled: false,
    });

    try {
      const now = admin.firestore.FieldValue.serverTimestamp();
      const db = this.db();
      const batch = db.batch();
      batch.set(db.collection('users').doc(account.uid), {
        uid: account.uid,
        name: dto.name,
        email: dto.business_email,
        role: 'merchant',
        merchant_id: account.uid,
        onboarding_completed: true,
        food_preferences: [],
        created_at: now,
        updated_at: now,
      });
      batch.set(db.collection('merchants').doc(account.uid), {
        merchant_id: account.uid,
        owner_uid: account.uid,
        name: dto.name,
        business_email: dto.business_email,
        address: dto.address,
        coordinates: new admin.firestore.GeoPoint(dto.lat, dto.lng),
        geohash: geohashForLocation([dto.lat, dto.lng]),
        is_verified: true,
        is_active: true,
        created_at: now,
        updated_at: now,
      });
      await batch.commit();
    } catch {
      try {
        await this.auth().deleteUser(account.uid);
      } catch {
        // Best effort rollback after a failed Firestore transaction.
      }
      throw new InternalServerErrorException('Failed to create merchant');
    }

    return this.getMerchant(account.uid);
  }

  async listMerchants(query: ListMerchantsQueryDto = {}) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const snap = await this.db().collection('merchants').get();
    let items = await Promise.all(
      snap.docs.map((doc) => this.serializeMerchant(doc.id, doc.data())),
    );

    if (query.is_active !== undefined) {
      items = items.filter((item) => item.is_active === query.is_active);
    }

    if (query.q?.trim()) {
      const term = query.q.trim().toLowerCase();
      items = items.filter(
        (item) =>
          this.includesTerm(item.name, term) ||
          this.includesTerm(item.address, term) ||
          this.includesTerm(item.business_email, term),
      );
    }

    items.sort((a, b) => (a.name ?? '').localeCompare(b.name ?? ''));
    const total = items.length;
    const start = (page - 1) * limit;

    return {
      items: items.slice(start, start + limit),
      total,
      page,
      limit,
      total_pages: Math.ceil(total / limit) || 1,
    };
  }

  async getMerchant(merchantId: string) {
    const doc = await this.db().collection('merchants').doc(merchantId).get();
    if (!doc.exists) {
      throw new NotFoundException('Merchant not found');
    }
    return this.serializeMerchant(doc.id, doc.data());
  }

  async assertMerchantExists(merchantId: string) {
    await this.getMerchant(merchantId);
  }

  async updateMerchant(merchantId: string, dto: UpdateMerchantDto) {
    const db = this.db();
    const merchantRef = db.collection('merchants').doc(merchantId);
    const snap = await merchantRef.get();
    if (!snap.exists) {
      throw new NotFoundException('Merchant not found');
    }

    const stored = this.toRecord(snap.data());
    let ownerUid = this.optionalString(stored['owner_uid']);
    let newlyProvisionedUid: string | undefined;

    if (!ownerUid && (dto.business_email || dto.password)) {
      if (!dto.business_email || !dto.password) {
        throw new BadRequestException(
          'business_email and password are required to provision a login',
        );
      }
      const account = await this.createAuthUser({
        email: dto.business_email,
        password: dto.password,
        displayName: dto.name ?? this.optionalString(stored['name']),
        disabled: dto.is_active === false,
      });
      ownerUid = account.uid;
      newlyProvisionedUid = account.uid;
    }

    try {
      if (ownerUid && !newlyProvisionedUid) {
        const authPatch: admin.auth.UpdateRequest = {};
        if (dto.business_email !== undefined) {
          authPatch.email = dto.business_email;
        }
        if (dto.password !== undefined) {
          authPatch.password = dto.password;
        }
        if (dto.name !== undefined) {
          authPatch.displayName = dto.name;
        }
        if (dto.is_active !== undefined) {
          authPatch.disabled = !dto.is_active;
        }
        if (Object.keys(authPatch).length > 0) {
          await this.updateAuthUser(ownerUid, authPatch);
        }
      }

      const currentEmail =
        dto.business_email ??
        this.optionalString(stored['business_email']) ??
        (ownerUid ? await this.readAuthEmail(ownerUid) : null);
      const now = admin.firestore.FieldValue.serverTimestamp();
      const patch: StoredRecord = { updated_at: now };
      if (dto.name !== undefined) patch['name'] = dto.name;
      if (dto.address !== undefined) patch['address'] = dto.address;
      if (dto.is_verified !== undefined) {
        patch['is_verified'] = dto.is_verified;
      }
      if (dto.is_active !== undefined) patch['is_active'] = dto.is_active;
      if (currentEmail !== null) patch['business_email'] = currentEmail;
      if (ownerUid && !this.optionalString(stored['owner_uid'])) {
        patch['owner_uid'] = ownerUid;
      }
      if (dto.lat !== undefined && dto.lng !== undefined) {
        patch['coordinates'] = new admin.firestore.GeoPoint(dto.lat, dto.lng);
        patch['geohash'] = geohashForLocation([dto.lat, dto.lng]);
      }

      const batch = db.batch();
      batch.update(merchantRef, patch);
      if (ownerUid) {
        const userPatch: StoredRecord = {
          uid: ownerUid,
          role: 'merchant',
          merchant_id: merchantId,
          onboarding_completed: true,
          updated_at: now,
        };
        if (dto.name !== undefined) userPatch['name'] = dto.name;
        if (currentEmail !== null) userPatch['email'] = currentEmail;
        if (newlyProvisionedUid) {
          userPatch['name'] =
            dto.name ?? this.optionalString(stored['name']) ?? '';
          userPatch['food_preferences'] = [];
          userPatch['created_at'] = now;
        }
        batch.set(db.collection('users').doc(ownerUid), userPatch, {
          merge: true,
        });
      }
      await batch.commit();
    } catch (error: unknown) {
      if (newlyProvisionedUid) {
        try {
          await this.auth().deleteUser(newlyProvisionedUid);
        } catch {
          // Best effort rollback for provisioning during a legacy update.
        }
      }
      if (error instanceof ConflictException) throw error;
      throw new InternalServerErrorException('Failed to update merchant');
    }

    return this.getMerchant(merchantId);
  }

  async deleteMerchant(merchantId: string) {
    const merchantRef = this.db().collection('merchants').doc(merchantId);
    const snap = await merchantRef.get();
    if (!snap.exists) {
      throw new NotFoundException('Merchant not found');
    }

    const ownerUid = this.optionalString(
      this.toRecord(snap.data())['owner_uid'],
    );
    try {
      if (ownerUid) {
        await this.updateAuthUser(ownerUid, { disabled: true });
      }
      await merchantRef.update({
        is_active: false,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (error: unknown) {
      if (error instanceof ConflictException) throw error;
      throw new InternalServerErrorException('Failed to delete merchant');
    }
    return { message: 'Merchant soft-deleted successfully' };
  }

  async getDashboard() {
    const db = this.db();
    const [merchantSnap, foodSnap] = await Promise.all([
      db.collection('merchants').get(),
      db.collection('foods').get(),
    ]);
    const merchantActivity = new Map<string, boolean>();
    merchantSnap.docs.forEach((doc) => {
      const data = this.toRecord(doc.data());
      const id = this.optionalString(data['merchant_id']) ?? doc.id;
      merchantActivity.set(id, data['is_active'] !== false);
    });

    let totalActiveItems = 0;
    let totalInactiveItems = 0;
    foodSnap.docs.forEach((doc) => {
      const food = this.toRecord(doc.data());
      const merchantId = this.optionalString(food['merchant_id']);
      const merchantActive =
        merchantId === undefined || merchantActivity.get(merchantId) !== false;
      if (food['is_available'] === true && merchantActive) {
        totalActiveItems += 1;
      } else {
        totalInactiveItems += 1;
      }
    });

    return {
      total_merchants: merchantSnap.docs.length,
      total_active_items: totalActiveItems,
      total_inactive_items: totalInactiveItems,
    };
  }

  private async createAuthUser(request: admin.auth.CreateRequest) {
    try {
      return await this.auth().createUser(request);
    } catch (error: unknown) {
      if (this.firebaseErrorCode(error) === 'auth/email-already-exists') {
        throw new ConflictException('Business email is already in use');
      }
      throw new InternalServerErrorException(
        'Failed to create merchant account',
      );
    }
  }

  private async updateAuthUser(uid: string, request: admin.auth.UpdateRequest) {
    try {
      await this.auth().updateUser(uid, request);
    } catch (error: unknown) {
      if (this.firebaseErrorCode(error) === 'auth/email-already-exists') {
        throw new ConflictException('Business email is already in use');
      }
      throw new InternalServerErrorException(
        'Failed to update merchant account',
      );
    }
  }

  private async serializeMerchant(id: string, value: unknown) {
    const data = this.toRecord(value);
    const ownerUid = this.optionalString(data['owner_uid']);
    const email =
      this.optionalString(data['business_email']) ??
      (ownerUid ? await this.readAuthEmail(ownerUid) : null);
    const coords =
      data['coordinates'] instanceof admin.firestore.GeoPoint
        ? data['coordinates']
        : undefined;
    return {
      id,
      merchant_id: this.optionalString(data['merchant_id']) ?? id,
      name: this.optionalString(data['name']) ?? null,
      business_email: email,
      address: this.optionalString(data['address']) ?? null,
      lat: coords?.latitude ?? null,
      lng: coords?.longitude ?? null,
      owner_uid: ownerUid ?? null,
      is_verified: data['is_verified'] !== false,
      is_active: data['is_active'] !== false,
      created_at: this.serializeTs(data['created_at']),
      updated_at: this.serializeTs(data['updated_at']),
    };
  }

  private async readAuthEmail(uid: string): Promise<string | null> {
    try {
      const account = await this.auth().getUser(uid);
      return account.email ?? null;
    } catch {
      return null;
    }
  }

  private includesTerm(value: string | null, term: string): boolean {
    return value !== null && value.toLowerCase().includes(term);
  }

  private firebaseErrorCode(value: unknown): string | null {
    if (typeof value !== 'object' || value === null || !('code' in value)) {
      return null;
    }
    return typeof value.code === 'string' ? value.code : null;
  }

  private optionalString(value: unknown): string | undefined {
    return typeof value === 'string' ? value : undefined;
  }

  private toRecord(value: unknown): StoredRecord {
    return value !== null && typeof value === 'object'
      ? { ...(value as StoredRecord) }
      : {};
  }

  private serializeTs(value: unknown): string | null {
    const timestamp = value as { toDate?: () => Date } | null;
    if (typeof timestamp?.toDate === 'function') {
      return timestamp.toDate().toISOString();
    }
    return null;
  }
}
