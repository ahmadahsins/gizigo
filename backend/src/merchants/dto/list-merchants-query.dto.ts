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

export class ListMerchantsQueryDto {
  @ApiPropertyOptional({
    description: 'Case-insensitive search by name, address, or business email',
  })
  @IsOptional()
  @IsString()
  q?: string;

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

  @ApiPropertyOptional({
    description: 'When true, only active merchants; when false, only inactive',
  })
  @IsOptional()
  @Transform(({ value }) => {
    if (value === undefined || value === '' || value === null) {
      return undefined;
    }
    return value === true || value === 'true' || value === '1';
  })
  @IsBoolean()
  is_active?: boolean;
}
