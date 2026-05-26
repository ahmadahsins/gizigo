import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsString, MinLength } from 'class-validator';
import { MerchantLocationDto } from './merchant-location.dto';

export class CreateMerchantDto extends MerchantLocationDto {
  @ApiProperty({ example: 'owner@warungsehat.id' })
  @IsEmail()
  business_email!: string;

  @ApiProperty({
    minLength: 6,
    description: 'Credential for Firebase Auth. Never persisted or returned.',
  })
  @IsString()
  @MinLength(6)
  password!: string;
}
