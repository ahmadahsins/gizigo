import { IsString, IsNumber, IsOptional, Min } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';

export class RecordRecentLocationDto {
  @ApiProperty({ example: 'UGM, Yogyakarta' })
  @IsString()
  label: string;

  @ApiProperty()
  @IsString()
  address: string;

  @ApiProperty({ description: 'Latitude (WGS84)' })
  @Type(() => Number)
  @IsNumber()
  lat: number;

  @ApiProperty({ description: 'Longitude (WGS84)' })
  @Type(() => Number)
  @IsNumber()
  lng: number;

  @ApiPropertyOptional({
    description: 'Distance from current pin in km (client-calculated)',
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  distance_km?: number;
}
