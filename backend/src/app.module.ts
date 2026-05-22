import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import firebaseConfig from './config/firebase.config';
import { FirebaseModule } from './firebase/firebase.module';
import { AuthModule } from './auth/auth.module';
import { FoodsModule } from './foods/foods.module';
import { AdminModule } from './admin/admin.module';
import { UsersModule } from './users/users.module';
import { MetaModule } from './meta/meta.module';
import { MerchantModule } from './merchant/merchant.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [firebaseConfig],
    }),
    FirebaseModule,
    AuthModule,
    FoodsModule,
    AdminModule,
    MerchantModule,
    UsersModule,
    MetaModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
