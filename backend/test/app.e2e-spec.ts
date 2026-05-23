import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module';

describe('AppController (e2e)', () => {
  let app: INestApplication<App>;

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
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

  afterEach(async () => {
    await app.close();
  });
});
