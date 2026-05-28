import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsNumber, IsOptional } from 'class-validator';

export class FoodDetailQueryDto {
  @ApiPropertyOptional({
    description:
      'User latitude (optional; used for Universal Mock delivery ETA)',
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  lat?: number;

  @ApiPropertyOptional({
    description:
      'User longitude (optional; used for Universal Mock delivery ETA)',
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  lng?: number;
}
