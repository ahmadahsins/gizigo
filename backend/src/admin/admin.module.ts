import { Module } from '@nestjs/common';
import { AdminController } from './admin.controller';
import { AdminMerchantsController } from './admin-merchants.controller';
import { AuthModule } from '../auth/auth.module';
import { FoodsManagementModule } from '../foods/foods-management.module';
import { MerchantsModule } from '../merchants/merchants.module';
import { AdminMerchantsService } from './admin-merchants.service';

@Module({
  imports: [AuthModule, FoodsManagementModule, MerchantsModule],
  controllers: [AdminController, AdminMerchantsController],
  providers: [AdminMerchantsService],
})
export class AdminModule {}
