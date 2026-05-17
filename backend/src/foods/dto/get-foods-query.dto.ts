import {
  IsOptional,
  IsNumber,
  IsString,
  IsEnum,
  IsIn,
  Min,
  Max,
  IsBoolean,
} from 'class-validator';
import { Type, Transform } from 'class-transformer';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { NutritionGrade } from '../../common/enums/nutrition-grade.enum';
import { FOOD_CATEGORY_KEYS } from '../../common/constants/food-categories';

export type FoodsSortMode = 'distance' | 'price_asc' | 'recommended';

export class GetFoodsQueryDto {
  @ApiPropertyOptional({
    description: 'Full-text filter on name/description (client-side substring)',
  })
  @IsOptional()
  @IsString()
  q?: string;

  @ApiPropertyOptional({ enum: NutritionGrade, description: 'Health tier badge' })
  @IsOptional()
  @IsEnum(NutritionGrade)
  nutrition_grade?: NutritionGrade;

  @ApiPropertyOptional({
    enum: FOOD_CATEGORY_KEYS,
    description: 'Menu category (Main Course, Snacks, …)',
  })
  @IsOptional()
  @IsString()
  @IsIn([...FOOD_CATEGORY_KEYS])
  food_category?: string;

  @ApiPropertyOptional({ description: 'Minimum base_price (IDR)' })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  min_price?: number;

  @ApiPropertyOptional({ description: 'Maximum base_price (IDR)' })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  max_price?: number;

  @ApiPropertyOptional({
    description: 'User latitude (required for distance sort / max_distance_km)',
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  lat?: number;

  @ApiPropertyOptional({
    description: 'User longitude (required for distance sort / max_distance_km)',
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  lng?: number;

  @ApiPropertyOptional({
    description: 'Drop foods farther than this (km); requires lat & lng',
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  max_distance_km?: number;

  @ApiPropertyOptional({
    enum: ['distance', 'price_asc', 'recommended'],
    description:
      'distance needs lat/lng; recommended uses recommendation_score then price',
  })
  @IsOptional()
  @IsIn(['distance', 'price_asc', 'recommended'])
  sort?: FoodsSortMode;

  @ApiPropertyOptional({ default: 1, minimum: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  page?: number;

  @ApiPropertyOptional({ default: 50, minimum: 1, maximum: 100 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  @Max(100)
  limit?: number;

  @ApiPropertyOptional({
    description: 'Only items flagged for the home hero card',
  })
  @IsOptional()
  @Transform(({ value }) => {
    if (value === undefined || value === '' || value === null) {
      return undefined;
    }
    return value === true || value === 'true' || value === '1';
  })
  @IsBoolean()
  featured_only?: boolean;
}
