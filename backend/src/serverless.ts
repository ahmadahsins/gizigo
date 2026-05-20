import serverlessExpress from '@vendia/serverless-express';
import { createApp } from './bootstrap';

let cachedHandler: ReturnType<typeof serverlessExpress> | undefined;

export default async function handler(
  req: Parameters<ReturnType<typeof serverlessExpress>>[0],
  res: Parameters<ReturnType<typeof serverlessExpress>>[1],
  context: Parameters<ReturnType<typeof serverlessExpress>>[2],
) {
  if (!cachedHandler) {
    const app = await createApp();
    const expressApp = app.getHttpAdapter().getInstance();
    cachedHandler = serverlessExpress({ app: expressApp });
  }

  return cachedHandler(req, res, context);
}
