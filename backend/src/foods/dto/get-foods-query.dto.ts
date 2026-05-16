import { IsOptional, IsNumber, IsString } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class GetFoodsQueryDto {
  @ApiPropertyOptional({ description: 'Category label (e.g. Vegan)' })
  @IsOptional()
  @IsString()
  category?: string;

  @ApiPropertyOptional({ description: 'Search term for name/description' })
  @IsOptional()
  @IsString()
  q?: string;

  @ApiPropertyOptional({
    description: 'User Latitude for distance calculation',
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  lat?: number;

  @ApiPropertyOptional({
    description: 'User Longitude for distance calculation',
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  lng?: number;
}
