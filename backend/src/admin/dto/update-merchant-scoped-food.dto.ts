import { PartialType } from '@nestjs/swagger';
import { CreateMerchantScopedFoodDto } from './create-merchant-scoped-food.dto';

export class UpdateMerchantScopedFoodDto extends PartialType(
  CreateMerchantScopedFoodDto,
) {}
