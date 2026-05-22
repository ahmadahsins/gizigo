import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';
import { MerchantLocationDto } from './merchant-location.dto';

export class CreateMerchantDto extends MerchantLocationDto {
  @ApiPropertyOptional({
    description: 'Firebase Auth UID of the merchant owner (admin create only)',
  })
  @IsOptional()
  @IsString()
  owner_uid?: string;
}
