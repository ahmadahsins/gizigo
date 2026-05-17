import { IsOptional, IsNumber, Min, Max } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class RecommendationsQueryDto {
  @ApiPropertyOptional({
    description: 'User latitude — adds distance_in_km & boosts nearby items slightly',
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  lat?: number;

  @ApiPropertyOptional({
    description: 'User longitude — pairs with lat',
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  lng?: number;

  @ApiPropertyOptional({
    default: 1,
    description: 'Hero strip “You Might Like This” — top picks after personalization',
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  @Max(5)
  featured_limit?: number;

  @ApiPropertyOptional({
    default: 15,
    description: 'List length for “Recommendations for You” (excluding featured)',
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  @Max(50)
  limit?: number;
}
