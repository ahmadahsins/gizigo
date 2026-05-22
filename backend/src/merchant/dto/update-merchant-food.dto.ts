import { PartialType } from '@nestjs/swagger';
import { CreateMerchantFoodDto } from './create-merchant-food.dto';

export class UpdateMerchantFoodDto extends PartialType(CreateMerchantFoodDto) {}
