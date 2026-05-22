import { Module } from '@nestjs/common';
import { FoodsManagementService } from './foods-management.service';

@Module({
  providers: [FoodsManagementService],
  exports: [FoodsManagementService],
})
export class FoodsManagementModule {}
