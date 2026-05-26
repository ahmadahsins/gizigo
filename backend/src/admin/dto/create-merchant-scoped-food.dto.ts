import { OmitType } from '@nestjs/swagger';
import { CreateFoodDto } from './create-food.dto';

export class CreateMerchantScopedFoodDto extends OmitType(CreateFoodDto, [
  'merchant_id',
] as const) {}
