import { Module } from '@nestjs/common';
import { FirebaseAuthGuard } from './firebase-auth.guard';
import { RolesGuard } from './roles.guard';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { MerchantsModule } from '../merchants/merchants.module';

@Module({
  imports: [MerchantsModule],
  controllers: [AuthController],
  providers: [FirebaseAuthGuard, RolesGuard, AuthService],
  exports: [FirebaseAuthGuard, RolesGuard, AuthService],
})
export class AuthModule {}
