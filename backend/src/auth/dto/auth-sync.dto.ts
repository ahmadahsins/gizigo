import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsIn, IsOptional, ValidateIf, ValidateNested } from 'class-validator';
import { UserRole } from '../../common/enums/user-role.enum';
import { MerchantLocationDto } from '../../merchants/dto/merchant-location.dto';

export class AuthSyncDto {
  @ApiPropertyOptional({
    enum: [UserRole.CUSTOMER, UserRole.MERCHANT],
    default: UserRole.CUSTOMER,
    description: 'Account type on first signup only',
  })
  @IsOptional()
  @IsIn([UserRole.CUSTOMER, UserRole.MERCHANT])
  account_type?: UserRole.CUSTOMER | UserRole.MERCHANT;

  @ApiPropertyOptional({
    type: MerchantLocationDto,
    description: 'Required when account_type is merchant',
  })
  @ValidateIf((o: AuthSyncDto) => o.account_type === UserRole.MERCHANT)
  @ValidateNested()
  @Type(() => MerchantLocationDto)
  merchant?: MerchantLocationDto;
}
