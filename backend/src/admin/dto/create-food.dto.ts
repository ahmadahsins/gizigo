import {
  IsString,
  IsNumber,
  IsBoolean,
  IsArray,
  ValidateNested,
  IsOptional,
  IsUrl,
  IsEnum,
  IsIn,
  Min,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { NutritionGrade } from '../../common/enums/nutrition-grade.enum';
import { FOOD_CATEGORY_KEYS } from '../../common/constants/food-categories';

class ProviderComparisonDto {
  @ApiProperty({ description: 'Base price on this provider' })
  @IsNumber()
  price: number;

  @ApiProperty({
    description: 'Deep link URL to the food/merchant on this provider',
  })
  @IsUrl()
  url: string;

  @ApiPropertyOptional({
    description: 'Logo/icon URL for this delivery platform (Flutter list UI)',
  })
  @IsOptional()
  @IsUrl()
  icon_url?: string;
}

class NutritionalInfoDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(0)
  calories?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(0)
  protein_g?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(0)
  fat_g?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(0)
  carb_g?: number;
}

class ComparisonDataDto {
  @ApiPropertyOptional()
  @IsOptional()
  @ValidateNested()
  @Type(() => ProviderComparisonDto)
  gofood?: ProviderComparisonDto;

  @ApiPropertyOptional()
  @IsOptional()
  @ValidateNested()
  @Type(() => ProviderComparisonDto)
  grabfood?: ProviderComparisonDto;

  @ApiPropertyOptional()
  @IsOptional()
  @ValidateNested()
  @Type(() => ProviderComparisonDto)
  shopeefood?: ProviderComparisonDto;
}

export class CreateFoodDto {
  @ApiProperty()
  @IsString()
  name: string;

  @ApiProperty()
  @IsString()
  description: string;

  @ApiProperty()
  @IsUrl()
  photo_url: string;

  @ApiProperty({
    enum: NutritionGrade,
    description: 'Badge tier for healthy menu (filter “Label” in app)',
  })
  @IsEnum(NutritionGrade)
  nutrition_grade: NutritionGrade;

  @ApiProperty({
    enum: FOOD_CATEGORY_KEYS,
    description: 'Menu category (horizontal chips on home)',
  })
  @IsString()
  @IsIn([...FOOD_CATEGORY_KEYS])
  food_category: string;

  @ApiProperty({ type: [String] })
  @IsArray()
  @IsString({ each: true })
  health_labels: string[];

  @ApiProperty()
  @IsNumber()
  base_price: number;

  @ApiProperty()
  @IsString()
  merchant_id: string;

  @ApiProperty()
  @IsBoolean()
  is_available: boolean;

  @ApiPropertyOptional({
    description: 'Featured hero card on home (“You Might Like This”)',
  })
  @IsOptional()
  @IsBoolean()
  is_featured?: boolean;

  @ApiPropertyOptional({
    description: 'Higher sorts first when sort=recommended',
  })
  @IsOptional()
  @IsNumber()
  recommendation_score?: number;

  @ApiPropertyOptional({ type: NutritionalInfoDto })
  @IsOptional()
  @ValidateNested()
  @Type(() => NutritionalInfoDto)
  nutritional_info?: NutritionalInfoDto;

  @ApiPropertyOptional({ type: ComparisonDataDto })
  @IsOptional()
  @ValidateNested()
  @Type(() => ComparisonDataDto)
  comparison_data?: ComparisonDataDto;
}
