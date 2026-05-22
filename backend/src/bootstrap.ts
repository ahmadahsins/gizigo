import 'reflect-metadata';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';

export async function configureApp(app: INestApplication): Promise<void> {
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
        '- After Firebase email/Google signup on the client, call `POST /auth/sync` or `POST /auth/signup` (same handler). Pass `account_type: merchant` plus `merchant` profile on first signup for merchant accounts.',
        '- Merchants manage their store via `/merchant/me` and menus via `/merchant/foods`.',
        '- Admins manage all merchants via `/admin/merchants` and all foods via `/admin/foods`.',
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
}
