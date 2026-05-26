import {
  ForbiddenException,
  Injectable,
  InternalServerErrorException,
  NotFoundException,
  UnprocessableEntityException,
} from '@nestjs/common';
import * as admin from 'firebase-admin';
import { FirebaseService } from '../firebase/firebase.service';
import { UserRole } from '../common/enums/user-role.enum';
import { CreateFoodDto } from '../admin/dto/create-food.dto';
import { UpdateFoodDto } from '../admin/dto/update-food.dto';
import { CreateMerchantScopedFoodDto } from '../admin/dto/create-merchant-scoped-food.dto';
import { UpdateMerchantScopedFoodDto } from '../admin/dto/update-merchant-scoped-food.dto';
import { CreateMerchantFoodDto } from '../merchant/dto/create-merchant-food.dto';
import { UpdateMerchantFoodDto } from '../merchant/dto/update-merchant-food.dto';
import { ListMerchantFoodsQueryDto } from '../merchant/dto/list-merchant-foods-query.dto';
import { AiService, NutritionAssessment } from '../ai/ai.service';
import { CloudinaryService } from '../cloudinary/cloudinary.service';
import type { UploadedImageFile } from '../common/types/uploaded-image-file';

export interface FoodActorContext {
  role: UserRole;
  merchantId?: string;
  merchantScopeId?: string;
}

@Injectable()
export class FoodsManagementService {
  constructor(
    private readonly firebaseService: FirebaseService,
    private readonly aiService: AiService,
    private readonly cloudinaryService: CloudinaryService,
  ) {}

  private db() {
    return this.firebaseService.getFirestore();
  }

  async createFood(
    dto: CreateFoodDto | CreateMerchantFoodDto | CreateMerchantScopedFoodDto,
    actor: FoodActorContext,
    merchantIdOverride?: string,
  ) {
    const merchantId = this.resolveMerchantId(actor, dto, merchantIdOverride);
    const assessment = await this.analyzeAcceptedRecipe(dto.recipe);
    const foodData = this.buildFoodPayload(dto, merchantId, actor, assessment);

    try {
      const db = this.db();
      const foodRef = db.collection('foods').doc();
      await foodRef.set({
        food_id: foodRef.id,
        ...foodData,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      return {
        message: 'Food created successfully',
        id: foodRef.id,
        nutrition_grade: assessment.grade,
        nutritional_info: assessment.nutritional_info,
        nutrition_assessment_reason: assessment.reason,
      };
    } catch {
      throw new InternalServerErrorException('Failed to create food');
    }
  }

  async updateFood(
    id: string,
    dto: UpdateFoodDto | UpdateMerchantFoodDto | UpdateMerchantScopedFoodDto,
    actor: FoodActorContext,
  ) {
    const foodRef = this.db().collection('foods').doc(id);
    const doc = await foodRef.get();

    if (!doc.exists) {
      throw new NotFoundException('Food not found');
    }

    this.assertFoodOwnership(doc.data()!, actor);

    const assessment = dto.recipe
      ? await this.analyzeAcceptedRecipe(dto.recipe)
      : undefined;
    const patch = this.buildUpdatePatch(dto, actor, assessment);

    try {
      await foodRef.update({
        ...patch,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      return {
        message: 'Food updated successfully',
        ...(assessment
          ? {
              nutrition_grade: assessment.grade,
              nutritional_info: assessment.nutritional_info,
              nutrition_assessment_reason: assessment.reason,
            }
          : {}),
      };
    } catch {
      throw new InternalServerErrorException('Failed to update food');
    }
  }

  async uploadFoodPhoto(
    id: string,
    file: UploadedImageFile,
    actor: FoodActorContext,
  ) {
    const foodRef = this.db().collection('foods').doc(id);
    const doc = await foodRef.get();

    if (!doc.exists) {
      throw new NotFoundException('Food not found');
    }

    this.assertFoodOwnership(doc.data()!, actor);

    const photoUrl = await this.cloudinaryService.uploadFoodPhoto(
      id,
      file.buffer,
    );

    try {
      await foodRef.update({
        photo_url: photoUrl,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      return {
        message: 'Food photo uploaded successfully',
        food_id: id,
        photo_url: photoUrl,
      };
    } catch {
      throw new InternalServerErrorException('Failed to update food photo');
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
    query: ListMerchantFoodsQueryDto = {},
  ) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const snap = await this.db()
      .collection('foods')
      .where('merchant_id', '==', merchantId)
      .get();

    let items: Array<{ id: string } & Record<string, unknown>> = snap.docs.map(
      (doc) => {
        const food = {
          ...(doc.data() as unknown as Record<string, unknown>),
        };
        delete food['recipe'];
        return { id: doc.id, ...food };
      },
    );

    if (query.is_available !== undefined) {
      items = items.filter((item) => item.is_available === query.is_available);
    }

    if (query.q?.trim()) {
      const term = query.q.trim().toLowerCase();
      items = items.filter(
        (item) =>
          this.matchesText(item.name, term) ||
          this.matchesText(item.description, term),
      );
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
    dto: CreateFoodDto | CreateMerchantFoodDto | CreateMerchantScopedFoodDto,
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
        merchantIdOverride ??
        ('merchant_id' in dto ? dto.merchant_id : undefined);
      if (!merchantId) {
        throw new ForbiddenException(
          'merchant_id is required for admin food create',
        );
      }
      return merchantId;
    }

    throw new ForbiddenException('Insufficient permissions');
  }

  private buildFoodPayload(
    dto: CreateFoodDto | CreateMerchantFoodDto | CreateMerchantScopedFoodDto,
    merchantId: string,
    actor: FoodActorContext,
    assessment: NutritionAssessment,
  ) {
    const payload: Record<string, unknown> = {
      name: dto.name,
      description: dto.description,
      nutrition_grade: assessment.grade,
      food_category: dto.food_category,
      health_labels: dto.health_labels,
      base_price: dto.base_price,
      merchant_id: merchantId,
      is_available: dto.is_available,
      nutritional_info: assessment.nutritional_info,
      nutrition_assessment_reason: assessment.reason,
      nutrition_analyzed_at: admin.firestore.FieldValue.serverTimestamp(),
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

  private buildUpdatePatch(
    dto: UpdateFoodDto | UpdateMerchantFoodDto | UpdateMerchantScopedFoodDto,
    actor: FoodActorContext,
    assessment?: NutritionAssessment,
  ) {
    const patch: Record<string, unknown> = {};

    for (const [key, value] of Object.entries(dto)) {
      if (value === undefined) continue;
      if (key === 'recipe') continue;
      if (actor.role === UserRole.MERCHANT && this.isAdminOnlyFoodField(key)) {
        continue;
      }
      patch[key] = value;
    }

    if (actor.role === UserRole.MERCHANT) {
      delete patch.merchant_id;
    }

    if (assessment) {
      patch.nutrition_grade = assessment.grade;
      patch.nutritional_info = assessment.nutritional_info;
      patch.nutrition_assessment_reason = assessment.reason;
      patch.nutrition_analyzed_at =
        admin.firestore.FieldValue.serverTimestamp();
    }

    return patch;
  }

  private async analyzeAcceptedRecipe(recipe: CreateFoodDto['recipe']) {
    const assessment = await this.aiService.analyzeRecipe(recipe);
    if (!assessment.accepted || assessment.grade === 'BELOW_GOOD') {
      throw new UnprocessableEntityException({
        message: 'Food rejected because its nutrition grade is below GOOD',
        nutrition_grade: assessment.grade,
        nutritional_info: assessment.nutritional_info,
        nutrition_assessment_reason: assessment.reason,
      });
    }
    return assessment;
  }

  private isAdminOnlyFoodField(key: string): boolean {
    return ['merchant_id', 'is_featured', 'recommendation_score'].includes(key);
  }

  private assertFoodOwnership(
    food: FirebaseFirestore.DocumentData,
    actor: FoodActorContext,
  ) {
    if (actor.role === UserRole.ADMIN) {
      if (actor.merchantScopeId && food.merchant_id !== actor.merchantScopeId) {
        throw new ForbiddenException('Food does not belong to this merchant');
      }
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

  private matchesText(value: unknown, term: string): boolean {
    return typeof value === 'string' && value.toLowerCase().includes(term);
  }
}
