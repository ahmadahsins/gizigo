import { Module } from '@nestjs/common';
import { FoodsManagementService } from './foods-management.service';
import { AiModule } from '../ai/ai.module';

@Module({
  imports: [AiModule],
  providers: [FoodsManagementService],
  exports: [FoodsManagementService],
})
export class FoodsManagementModule {}
