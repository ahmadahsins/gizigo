import { Module } from '@nestjs/common';
import { MerchantController } from './merchant.controller';
import { AuthModule } from '../auth/auth.module';
import { MerchantsModule } from '../merchants/merchants.module';
import { FoodsManagementModule } from '../foods/foods-management.module';

@Module({
  imports: [AuthModule, MerchantsModule, FoodsManagementModule],
  controllers: [MerchantController],
})
export class MerchantModule {}
