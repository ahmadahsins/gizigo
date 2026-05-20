import serverlessExpress from '@vendia/serverless-express';
import { NestFactory } from '@nestjs/core';
import { ExpressAdapter } from '@nestjs/platform-express';
import express from 'express';
import { AppModule } from './app.module';
import { configureApp } from './bootstrap';

let cachedHandler: ReturnType<typeof serverlessExpress> | undefined;

export default async function handler(
  req: Parameters<ReturnType<typeof serverlessExpress>>[0],
  res: Parameters<ReturnType<typeof serverlessExpress>>[1],
  context: Parameters<ReturnType<typeof serverlessExpress>>[2],
) {
  if (!cachedHandler) {
    const expressApp = express();
    const app = await NestFactory.create(AppModule, new ExpressAdapter(expressApp));
    await configureApp(app);
    await app.init();
    cachedHandler = serverlessExpress({ app: expressApp });
  }

  return cachedHandler(req, res, context);
}
