import {
  ForbiddenException,
  Injectable,
  InternalServerErrorException,
  NotFoundException,
} from '@nestjs/common';
import * as admin from 'firebase-admin';
import { FirebaseService } from '../firebase/firebase.service';
import { UserRole } from '../common/enums/user-role.enum';
import { CreateFoodDto } from '../admin/dto/create-food.dto';
import { UpdateFoodDto } from '../admin/dto/update-food.dto';
import { CreateMerchantFoodDto } from '../merchant/dto/create-merchant-food.dto';

export interface FoodActorContext {
  role: UserRole;
  merchantId?: string;
}

@Injectable()
export class FoodsManagementService {
  constructor(private readonly firebaseService: FirebaseService) {}

  private db() {
    return this.firebaseService.getFirestore();
  }

  async createFood(
    dto: CreateFoodDto | CreateMerchantFoodDto,
    actor: FoodActorContext,
    merchantIdOverride?: string,
  ) {
    const merchantId = this.resolveMerchantId(actor, dto, merchantIdOverride);
    const foodData = this.buildFoodPayload(dto, merchantId, actor);

    try {
      const db = this.db();
      const foodRef = db.collection('foods').doc();
      await foodRef.set({
        food_id: foodRef.id,
        ...foodData,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      return { message: 'Food created successfully', id: foodRef.id };
    } catch {
      throw new InternalServerErrorException('Failed to create food');
    }
  }

  async updateFood(id: string, dto: UpdateFoodDto, actor: FoodActorContext) {
    const foodRef = this.db().collection('foods').doc(id);
    const doc = await foodRef.get();

    if (!doc.exists) {
      throw new NotFoundException('Food not found');
    }

    this.assertFoodOwnership(doc.data()!, actor);

    const patch = this.buildUpdatePatch(dto, actor);

    try {
      await foodRef.update({
        ...patch,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      return { message: 'Food updated successfully' };
    } catch {
      throw new InternalServerErrorException('Failed to update food');
    }
  }

  async deleteFood(id: string, actor: FoodActorContext) {
    const foodRef = this.db().collection('foods').doc(id);
    const doc = await foodRef.get();

    if (!doc.exists) {
      throw new NotFoundException('Food not found');
    }

    this.assertFoodOwnership(doc.data()!, actor);

    try {
      await foodRef.update({
        is_available: false,
        deleted_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      return { message: 'Food soft-deleted successfully' };
    } catch {
      throw new InternalServerErrorException('Failed to delete food');
    }
  }

  async listFoodsForMerchant(
    merchantId: string,
    page = 1,
    limit = 20,
    includeUnavailable = true,
  ) {
    const snap = await this.db()
      .collection('foods')
      .where('merchant_id', '==', merchantId)
      .get();

    let items: Array<{ id: string } & Record<string, unknown>> = snap.docs.map(
      (doc) => ({
        id: doc.id,
        ...(doc.data() as Record<string, unknown>),
      }),
    );

    if (!includeUnavailable) {
      items = items.filter((item) => item.is_available !== false);
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

  private resolveMerchantId(
    actor: FoodActorContext,
    dto: CreateFoodDto | CreateMerchantFoodDto,
    merchantIdOverride?: string,
  ): string {
    if (actor.role === UserRole.MERCHANT) {
      if (!actor.merchantId) {
        throw new ForbiddenException('Merchant account is missing merchant_id');
      }
      return actor.merchantId;
    }

    if (actor.role === UserRole.ADMIN) {
      const merchantId =
        merchantIdOverride ?? ('merchant_id' in dto ? dto.merchant_id : undefined);
      if (!merchantId) {
        throw new ForbiddenException('merchant_id is required for admin food create');
      }
      return merchantId;
    }

    throw new ForbiddenException('Insufficient permissions');
  }

  private buildFoodPayload(
    dto: CreateFoodDto | CreateMerchantFoodDto,
    merchantId: string,
    actor: FoodActorContext,
  ) {
    const payload: Record<string, unknown> = {
      name: dto.name,
      description: dto.description,
      photo_url: dto.photo_url,
      nutrition_grade: dto.nutrition_grade,
      food_category: dto.food_category,
      health_labels: dto.health_labels,
      base_price: dto.base_price,
      merchant_id: merchantId,
      is_available: dto.is_available,
      nutritional_info: dto.nutritional_info ?? null,
      comparison_data: dto.comparison_data ?? null,
    };

    if (actor.role === UserRole.ADMIN) {
      const adminDto = dto as CreateFoodDto;
      if (adminDto.is_featured !== undefined) {
        payload.is_featured = adminDto.is_featured;
      }
      if (adminDto.recommendation_score !== undefined) {
        payload.recommendation_score = adminDto.recommendation_score;
      }
    }

    return payload;
  }

  private buildUpdatePatch(dto: UpdateFoodDto, actor: FoodActorContext) {
    const patch: Record<string, unknown> = {};

    for (const [key, value] of Object.entries(dto)) {
      if (value === undefined) continue;
      if (actor.role === UserRole.MERCHANT && this.isAdminOnlyFoodField(key)) {
        continue;
      }
      patch[key] = value;
    }

    if (actor.role === UserRole.MERCHANT) {
      delete patch.merchant_id;
    }

    return patch;
  }

  private isAdminOnlyFoodField(key: string): boolean {
    return ['merchant_id', 'is_featured', 'recommendation_score'].includes(key);
  }

  private assertFoodOwnership(
    food: FirebaseFirestore.DocumentData,
    actor: FoodActorContext,
  ) {
    if (actor.role === UserRole.ADMIN) {
      return;
    }

    if (actor.role === UserRole.MERCHANT) {
      if (food.merchant_id !== actor.merchantId) {
        throw new ForbiddenException('You can only manage your own foods');
      }
      return;
    }

    throw new ForbiddenException('Insufficient permissions');
  }
}
