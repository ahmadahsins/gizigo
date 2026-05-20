import { NestFactory } from '@nestjs/core';
import { ExpressAdapter } from '@nestjs/platform-express';
import express from 'express';
import { AppModule } from './app.module';
import { configureApp } from './bootstrap';
import type { Request, Response } from 'express';

let expressApp: express.Express | undefined;

async function bootstrap(): Promise<express.Express> {
  if (!expressApp) {
    expressApp = express();
    const app = await NestFactory.create(AppModule, new ExpressAdapter(expressApp));
    await configureApp(app);
    await app.init();
  }
  return expressApp;
}

export default async function handler(req: Request, res: Response) {
  const app = await bootstrap();
  app(req, res);
}
