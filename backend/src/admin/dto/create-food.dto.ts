import {
  IsString,
  IsNumber,
  IsBoolean,
  IsArray,
  ValidateNested,
  IsOptional,
  IsUrl,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

class ProviderComparisonDto {
  @ApiProperty({ description: 'Base price on this provider' })
  @IsNumber()
  price: number;

  @ApiProperty({
    description: 'Deep link URL to the food/merchant on this provider',
  })
  @IsUrl()
  url: string;
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

  @ApiPropertyOptional({ type: ComparisonDataDto })
  @IsOptional()
  @ValidateNested()
  @Type(() => ComparisonDataDto)
  comparison_data?: ComparisonDataDto;
}
