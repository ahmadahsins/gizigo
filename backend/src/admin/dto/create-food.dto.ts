import {
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsEnum,
  IsIn,
  IsInt,
  IsNumber,
  IsOptional,
  IsPositive,
  IsString,
  IsUrl,
  Min,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { FOOD_CATEGORY_KEYS } from '../../common/constants/food-categories';
import { RecipeUnit } from '../../common/enums/recipe-unit.enum';

class ProviderComparisonDto {
  @ApiProperty({ description: 'Base price on this provider' })
  @IsNumber()
  price!: number;

  @ApiProperty({
    description: 'Deep link URL to the food/merchant on this provider',
  })
  @IsUrl()
  url!: string;

  @ApiPropertyOptional({
    description: 'Logo/icon URL for this delivery platform (Flutter list UI)',
  })
  @IsOptional()
  @IsUrl()
  icon_url?: string;
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

export class RecipeIngredientDto {
  @ApiProperty({ example: 'chicken breast' })
  @IsString()
  name!: string;

  @ApiProperty({ example: 150, description: 'Quantity in the supplied unit' })
  @Type(() => Number)
  @IsNumber()
  @IsPositive()
  amount!: number;

  @ApiProperty({ enum: RecipeUnit })
  @IsEnum(RecipeUnit)
  unit!: RecipeUnit;
}

export class RecipeDto {
  @ApiProperty({
    example: 1,
    description: 'Number of portions; nutrition is calculated per serving',
  })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  servings!: number;

  @ApiProperty({ type: [RecipeIngredientDto] })
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => RecipeIngredientDto)
  ingredients!: RecipeIngredientDto[];
}

export class CreateFoodDto {
  @ApiProperty()
  @IsString()
  name!: string;

  @ApiProperty()
  @IsString()
  description!: string;

  @ApiProperty({
    enum: FOOD_CATEGORY_KEYS,
    description: 'Menu category (horizontal chips on home)',
  })
  @IsString()
  @IsIn([...FOOD_CATEGORY_KEYS])
  food_category!: string;

  @ApiProperty({ type: [String] })
  @IsArray()
  @IsString({ each: true })
  health_labels!: string[];

  @ApiProperty()
  @IsNumber()
  base_price!: number;

  @ApiProperty({
    type: RecipeDto,
    description:
      'Request-only recipe used for Gemini nutrition analysis. Never persisted.',
  })
  @ValidateNested()
  @Type(() => RecipeDto)
  recipe!: RecipeDto;

  @ApiProperty()
  @IsString()
  merchant_id!: string;

  @ApiProperty()
  @IsBoolean()
  is_available!: boolean;

  @ApiPropertyOptional({
    description: 'Featured hero card on home',
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

  @ApiPropertyOptional({ type: ComparisonDataDto })
  @IsOptional()
  @ValidateNested()
  @Type(() => ComparisonDataDto)
  comparison_data?: ComparisonDataDto;
}
