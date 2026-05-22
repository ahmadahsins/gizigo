import {
  Injectable,
  InternalServerErrorException,
  NotFoundException,
} from '@nestjs/common';
import * as admin from 'firebase-admin';
import { geohashForLocation } from 'geofire-common';
import { FirebaseService } from '../firebase/firebase.service';
import { CreateMerchantDto } from './dto/create-merchant.dto';
import { UpdateMerchantDto } from './dto/update-merchant.dto';
import { ListMerchantsQueryDto } from './dto/list-merchants-query.dto';
import { MerchantLocationDto } from './dto/merchant-location.dto';

export interface CreateMerchantOptions {
  merchantId?: string;
  ownerUid?: string;
  isVerified?: boolean;
}

@Injectable()
export class MerchantsService {
  constructor(private readonly firebaseService: FirebaseService) {}

  private db() {
    return this.firebaseService.getFirestore();
  }

  async createMerchant(
    dto: CreateMerchantDto | MerchantLocationDto,
    options: CreateMerchantOptions = {},
  ) {
    const db = this.db();
    const merchantRef = options.merchantId
      ? db.collection('merchants').doc(options.merchantId)
      : db.collection('merchants').doc();

    const merchantId = merchantRef.id;
    const ownerUid = options.ownerUid ?? ('owner_uid' in dto ? dto.owner_uid : undefined);

    const payload = this.buildMerchantPayload(merchantId, dto, {
      ownerUid,
      isVerified: options.isVerified ?? true,
    });

    try {
      await merchantRef.set(payload);
    } catch {
      throw new InternalServerErrorException('Failed to create merchant');
    }

    return { id: merchantId, ...this.serializeMerchant(payload) };
  }

  async getMerchant(merchantId: string) {
    const doc = await this.db().collection('merchants').doc(merchantId).get();
    if (!doc.exists) {
      throw new NotFoundException('Merchant not found');
    }
    return { id: doc.id, ...this.serializeMerchant(doc.data()!) };
  }

  async updateMerchant(merchantId: string, dto: UpdateMerchantDto) {
    const ref = this.db().collection('merchants').doc(merchantId);
    const snap = await ref.get();
    if (!snap.exists) {
      throw new NotFoundException('Merchant not found');
    }

    const patch: Record<string, unknown> = {
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (dto.name !== undefined) patch.name = dto.name;
    if (dto.address !== undefined) patch.address = dto.address;
    if (dto.owner_uid !== undefined) patch.owner_uid = dto.owner_uid;
    if (dto.is_verified !== undefined) patch.is_verified = dto.is_verified;
    if (dto.is_active !== undefined) patch.is_active = dto.is_active;

    if (dto.lat !== undefined && dto.lng !== undefined) {
      patch.coordinates = new admin.firestore.GeoPoint(dto.lat, dto.lng);
      patch.geohash = geohashForLocation([dto.lat, dto.lng]);
    }

    try {
      await ref.update(patch);
    } catch {
      throw new InternalServerErrorException('Failed to update merchant');
    }

    return this.getMerchant(merchantId);
  }

  async deleteMerchant(merchantId: string) {
    const ref = this.db().collection('merchants').doc(merchantId);
    const snap = await ref.get();
    if (!snap.exists) {
      throw new NotFoundException('Merchant not found');
    }

    try {
      await ref.update({
        is_active: false,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch {
      throw new InternalServerErrorException('Failed to delete merchant');
    }

    return { message: 'Merchant soft-deleted successfully' };
  }

  async listMerchants(query: ListMerchantsQueryDto = {}) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;

    const snap = await this.db().collection('merchants').get();
    let items = snap.docs.map((doc) => ({
      id: doc.id,
      ...this.serializeMerchant(doc.data()),
    }));

    if (query.is_active !== undefined) {
      items = items.filter((item) => item.is_active === query.is_active);
    }

    items.sort((a, b) => String(a.name).localeCompare(String(b.name)));

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

  private buildMerchantPayload(
    merchantId: string,
    dto: CreateMerchantDto | MerchantLocationDto,
    options: { ownerUid?: string; isVerified: boolean },
  ) {
    const now = admin.firestore.FieldValue.serverTimestamp();
    return {
      merchant_id: merchantId,
      name: dto.name,
      address: dto.address,
      coordinates: new admin.firestore.GeoPoint(dto.lat, dto.lng),
      geohash: geohashForLocation([dto.lat, dto.lng]),
      owner_uid: options.ownerUid ?? null,
      is_verified: options.isVerified,
      is_active: true,
      created_at: now,
      updated_at: now,
    };
  }

  private serializeMerchant(data: FirebaseFirestore.DocumentData) {
    const coords = data.coordinates as FirebaseFirestore.GeoPoint | undefined;
    return {
      merchant_id: data.merchant_id ?? null,
      name: data.name ?? null,
      address: data.address ?? null,
      lat: coords?.latitude ?? null,
      lng: coords?.longitude ?? null,
      owner_uid: data.owner_uid ?? null,
      is_verified: data.is_verified ?? true,
      is_active: data.is_active ?? true,
      created_at: this.serializeTs(data.created_at),
      updated_at: this.serializeTs(data.updated_at),
    };
  }

  private serializeTs(ts: unknown): string | null {
    if (!ts) return null;
    if (typeof (ts as { toDate?: () => Date }).toDate === 'function') {
      return (ts as FirebaseFirestore.Timestamp).toDate().toISOString();
    }
    return null;
  }
}
