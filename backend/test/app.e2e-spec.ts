import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module';
import { configureApp } from './../src/bootstrap';

describe('AppController (e2e)', () => {
  let app: INestApplication<App>;

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    configureApp(app);
    await app.init();
  });

  it('/ (GET)', () => {
    return request(app.getHttpServer())
      .get('/')
      .expect(200)
      .expect('Hello World!');
  });

  it('/meta/food-categories (GET)', () => {
    return request(app.getHttpServer())
      .get('/meta/food-categories')
      .expect(200)
      .expect((res) => {
        expect(Array.isArray(res.body.items)).toBe(true);
        expect(res.body.items.length).toBeGreaterThanOrEqual(5);
      });
  });

  it('/meta/nutrition-grades (GET)', () => {
    return request(app.getHttpServer())
      .get('/meta/nutrition-grades')
      .expect(200)
      .expect((res) => {
        expect(
          res.body.items.map((x: { key: string }) => x.key).sort(),
        ).toEqual(['EXCELLENT', 'GOOD', 'VERY_GOOD']);
      });
  });

  it('/meta/nutrition-goals (GET)', () => {
    return request(app.getHttpServer())
      .get('/meta/nutrition-goals')
      .expect(200)
      .expect((res) => {
        expect(
          res.body.items.map((x: { key: string }) => x.key).sort(),
        ).toEqual(['BULKING', 'DIET', 'MAINTAIN']);
      });
  });

  it('/meta/locations/search (GET)', () => {
    return request(app.getHttpServer())
      .get('/meta/locations/search')
      .query({ q: 'test' })
      .expect(200)
      .expect((res) => {
        expect(res.body.items).toEqual([]);
        expect(res.body.query).toBe('test');
      });
  });

  it('/api (GET) serves Swagger UI', () => {
    return request(app.getHttpServer())
      .get('/api')
      .expect(200)
      .expect('Content-Type', /html/)
      .expect((res) => {
        expect(res.text).toContain('swagger-ui-bundle.js');
        expect(res.text).toContain('cdn.jsdelivr.net/npm/swagger-ui-dist');
        expect(res.headers['content-security-policy']).toContain(
          'https://cdn.jsdelivr.net',
        );
      });
  });

  it('/api-json (GET) serves the OpenAPI document', () => {
    return request(app.getHttpServer())
      .get('/api-json')
      .expect(200)
      .expect((res) => {
        expect(res.body.info.title).toBe('GiziGo API');
      });
  });

  it('/api Swagger static assets are available', async () => {
    await request(app.getHttpServer())
      .get('/api/swagger-ui.css')
      .expect(200)
      .expect('Content-Type', /css/);

    await request(app.getHttpServer())
      .get('/api/swagger-ui-bundle.js')
      .expect(200)
      .expect('Content-Type', /javascript/);
  });

  afterEach(async () => {
    await app.close();
  });
});
