import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import {
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';

export class ListMerchantFoodsQueryDto {
  @ApiPropertyOptional({
    description: 'Case-insensitive search by food name or description',
  })
  @IsOptional()
  @IsString()
  q?: string;

  @ApiPropertyOptional({
    description: 'Filter the active or inactive menu tab',
  })
  @IsOptional()
  @Transform(({ value }) => {
    if (value === undefined || value === '' || value === null) {
      return undefined;
    }
    return value === true || value === 'true' || value === '1';
  })
  @IsBoolean()
  is_available?: boolean;

  @ApiPropertyOptional({ default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional({ default: 20, maximum: 100 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number = 20;
}
