import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import helmet from 'helmet';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';

export async function createApp(): Promise<INestApplication> {
  const app = await NestFactory.create(AppModule);

  app.use(helmet());
  app.enableCors();

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );

  const config = new DocumentBuilder()
    .setTitle('GiziGo API')
    .setDescription(
      [
        'REST API for the GiziGo student food-discovery app.',
        '',
        '- Auth: Firebase ID token → `Authorization: Bearer <token>`.',
        '- After Firebase email/Google signup on the client, call `POST /auth/sync` or `POST /auth/signup` (same handler).',
        '- Complete onboarding with `PATCH /users/me`, then load home picks via `GET /foods/recommendations`.',
        '',
        'Interactive schemas include **example** payloads on major operations.',
      ].join('\n'),
    )
    .setVersion('1.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api', app, document);

  await app.init();
  return app;
}
