import { Module } from '@nestjs/common';
import { FoodsManagementService } from './foods-management.service';
import { AiModule } from '../ai/ai.module';
import { CloudinaryModule } from '../cloudinary/cloudinary.module';

@Module({
  imports: [AiModule, CloudinaryModule],
  providers: [FoodsManagementService],
  exports: [FoodsManagementService],
})
export class FoodsManagementModule {}
