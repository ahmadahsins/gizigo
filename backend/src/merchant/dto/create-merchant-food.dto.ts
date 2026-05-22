import { OmitType } from '@nestjs/swagger';
import { CreateFoodDto } from '../../admin/dto/create-food.dto';

export class CreateMerchantFoodDto extends OmitType(CreateFoodDto, [
  'merchant_id',
  'is_featured',
  'recommendation_score',
] as const) {}
