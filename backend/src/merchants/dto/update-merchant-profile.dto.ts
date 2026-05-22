import { PartialType } from '@nestjs/swagger';
import { MerchantLocationDto } from './merchant-location.dto';

export class UpdateMerchantProfileDto extends PartialType(MerchantLocationDto) {}
