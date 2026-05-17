import { PartialType } from '@nestjs/swagger';
import { CreateFoodDto } from './create-food.dto';

/** Partial update — semua field dari CreateFoodDto opsional */
export class UpdateFoodDto extends PartialType(CreateFoodDto) {}
