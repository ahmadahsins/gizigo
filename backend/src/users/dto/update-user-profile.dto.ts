import {
  IsOptional,
  IsString,
  IsEnum,
  IsNumber,
  IsBoolean,
  IsArray,
  Min,
  Max,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { Gender } from '../../common/enums/gender.enum';
import { NutritionGoal } from '../../common/enums/nutrition-goal.enum';

export class UpdateUserProfileDto {
  @ApiPropertyOptional({ description: 'Display name (from signup full name)' })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  username?: string;

  @ApiPropertyOptional({ enum: Gender })
  @IsOptional()
  @IsEnum(Gender)
  gender?: Gender;

  @ApiPropertyOptional({
    description: 'Age in full years',
    minimum: 13,
    maximum: 120,
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(13)
  @Max(120)
  age?: number;

  @ApiPropertyOptional({
    description: 'Weight kilograms',
    minimum: 20,
    maximum: 400,
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(20)
  @Max(400)
  weight_kg?: number;

  @ApiPropertyOptional({
    description: 'Height centimeters',
    minimum: 50,
    maximum: 260,
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(50)
  @Max(260)
  height_cm?: number;

  @ApiPropertyOptional({
    enum: NutritionGoal,
    description: 'Drives /foods/recommendations ranking',
  })
  @IsOptional()
  @IsEnum(NutritionGoal)
  nutrition_goal?: NutritionGoal;

  @ApiPropertyOptional({
    type: [String],
    example: ['High Protein', 'Low Calorie'],
    description: 'Matched loosely against foods.health_labels',
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  food_preferences?: string[];

  @ApiPropertyOptional({
    type: [String],
    example: ['Vegetarian', 'Peanut allergy'],
    description: 'Dietary constraints used for AI food ranking',
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  dietary_restrictions?: string[];

  @ApiPropertyOptional({
    type: [String],
    example: ['Spicy', 'Savory'],
    description: 'Taste preferences used for AI food ranking',
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  taste_profile?: string[];

  @ApiPropertyOptional({
    description: 'True after onboarding wizard completed',
  })
  @IsOptional()
  @IsBoolean()
  onboarding_completed?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  preferred_language?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  dark_mode?: boolean;
}
