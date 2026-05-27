import { NotFoundException } from '@nestjs/common';
import { FoodsService } from './foods.service';

describe('FoodsService recommendations', () => {
  const foodDocs = [
    {
      id: 'food1',
      data: () => ({
        name: 'Salad',
        nutrition_grade: 'EXCELLENT',
        is_available: true,
      }),
    },
    {
      id: 'food2',
      data: () => ({
        name: 'Soup',
        nutrition_grade: 'GOOD',
        is_available: true,
      }),
    },
  ];

  function setup(
    user: Record<string, unknown>,
    foods = foodDocs,
    merchants: Array<{ id: string; data: () => Record<string, unknown> }> = [],
  ) {
    const rankFoodsForUser = jest.fn().mockResolvedValue(['food2', 'food1']);
    const firebaseService = {
      getFirestore: jest.fn().mockReturnValue({
        collection: jest.fn((name: string) => {
          if (name === 'users') {
            return {
              doc: jest.fn().mockReturnValue({
                get: jest.fn().mockResolvedValue({ data: () => user }),
              }),
            };
          }
          if (name === 'foods') {
            return {
              where: jest.fn().mockReturnValue({
                get: jest.fn().mockResolvedValue({ docs: foods }),
              }),
            };
          }
          if (name === 'merchants') {
            return {
              where: jest.fn().mockReturnValue({
                get: jest.fn().mockResolvedValue({
                  forEach: (
                    callback: (doc: {
                      data: () => Record<string, unknown>;
                    }) => void,
                  ) => merchants.forEach(callback),
                }),
              }),
            };
          }
          throw new Error(`Unexpected collection ${name}`);
        }),
      }),
    };
    return {
      rankFoodsForUser,
      service: new FoodsService(
        firebaseService as never,
        {
          rankFoodsForUser,
        } as never,
      ),
    };
  }

  it('uses Gemini order for a personalized profile', async () => {
    const { service, rankFoodsForUser } = setup({
      gender: 'FEMALE',
      nutrition_goal: 'DIET',
      dietary_restrictions: ['Vegetarian'],
    });

    const response = await service.getRecommendations('user1', {
      featured_limit: 0,
      limit: 2,
    });

    expect(rankFoodsForUser).toHaveBeenCalled();
    expect(response.recommendations.map((food) => food.id)).toEqual([
      'food2',
      'food1',
    ]);
    expect(response.context.recommendation_source).toBe('gemini');
  });

  it('falls back locally when Gemini cannot rank foods', async () => {
    const { service, rankFoodsForUser } = setup({ nutrition_goal: 'DIET' });
    rankFoodsForUser.mockRejectedValue(new Error('unavailable'));

    const response = await service.getRecommendations('user1', {
      featured_limit: 0,
      limit: 2,
    });

    expect(response.context.recommendation_source).toBe('fallback');
    expect(response.recommendations[0].id).toBe('food1');
  });

  it('does not call Gemini when no personalization input exists', async () => {
    const { service, rankFoodsForUser } = setup({});

    const response = await service.getRecommendations('user1', {
      featured_limit: 0,
      limit: 2,
    });

    expect(rankFoodsForUser).not.toHaveBeenCalled();
    expect(response.context.recommendation_source).toBe('fallback');
  });

  it('does not recommend foods from inactive merchants', async () => {
    const { service } = setup(
      {},
      [
        {
          id: 'food1',
          data: () => ({
            name: 'Visible',
            merchant_id: 'active',
            is_available: true,
            nutrition_grade: 'GOOD',
          }),
        },
        {
          id: 'food2',
          data: () => ({
            name: 'Hidden',
            merchant_id: 'closed',
            is_available: true,
            nutrition_grade: 'EXCELLENT',
          }),
        },
      ],
      [
        {
          id: 'active',
          data: () => ({ merchant_id: 'active', is_active: true }),
        },
        {
          id: 'closed',
          data: () => ({ merchant_id: 'closed', is_active: false }),
        },
      ],
    );

    const response = await service.getRecommendations('user1', {
      featured_limit: 0,
      limit: 2,
    });

    expect(response.recommendations.map((food) => food.id)).toEqual(['food1']);
  });

  it('returns not found for customer detail owned by an inactive merchant', async () => {
    const service = new FoodsService(
      {
        getFirestore: jest.fn().mockReturnValue({
          collection: jest.fn((name: string) => {
            if (name === 'foods') {
              return {
                doc: jest.fn().mockReturnValue({
                  get: jest.fn().mockResolvedValue({
                    exists: true,
                    id: 'food1',
                    data: () => ({ merchant_id: 'closed', name: 'Hidden' }),
                  }),
                }),
              };
            }
            return {
              where: jest.fn().mockReturnValue({
                get: jest.fn().mockResolvedValue({
                  forEach: (
                    callback: (doc: {
                      data: () => Record<string, unknown>;
                    }) => void,
                  ) =>
                    callback({
                      data: () => ({ merchant_id: 'closed', is_active: false }),
                    }),
                }),
              }),
            };
          }),
        }),
      } as never,
      {} as never,
    );

    await expect(service.getFoodDetails('food1')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('keeps platform prices stable within a six-hour window', async () => {
    const service = new FoodsService(
      {
        getFirestore: jest.fn().mockReturnValue({
          collection: jest.fn((name: string) => {
            if (name !== 'foods') {
              throw new Error(`Unexpected collection ${name}`);
            }
            return {
              doc: jest.fn().mockReturnValue({
                get: jest.fn().mockResolvedValue({
                  exists: true,
                  id: 'salad-123',
                  data: () => ({
                    name: 'Salad Buah',
                    base_price: 30000,
                    comparison_data: {
                      gofood: { url: 'https://gofood.co.id/salad' },
                      grabfood: { url: 'https://food.grab.com/salad' },
                      shopeefood: { url: 'https://shopeefood.co.id/salad' },
                    },
                  }),
                }),
              }),
            };
          }),
        }),
      } as never,
      {} as never,
    );

    jest.useFakeTimers().setSystemTime(new Date('2026-05-27T00:10:00.000Z'));

    try {
      const first = await service.getFoodDetails('salad-123');
      jest.setSystemTime(new Date('2026-05-27T05:59:59.000Z'));
      const second = await service.getFoodDetails('salad-123');

      expect(first.price_comparisons).toEqual(second.price_comparisons);
      expect(first.price_comparison_updated_at).toBe(
        '2026-05-27T00:00:00.000Z',
      );
      expect(first.price_comparison_valid_until).toBe(
        '2026-05-27T06:00:00.000Z',
      );
      expect(first.price_comparisons).toHaveLength(3);
      expect(first.price_comparisons).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            platform_key: 'gofood',
            base_price: 30000,
            order_url: 'https://gofood.co.id/salad',
          }),
        ]),
      );
      expect(
        first.price_comparisons.every((item) => item.price > item.base_price),
      ).toBe(true);

      jest.setSystemTime(new Date('2026-05-27T06:00:00.000Z'));
      const nextWindow = await service.getFoodDetails('salad-123');
      expect(nextWindow.price_comparison_updated_at).toBe(
        '2026-05-27T06:00:00.000Z',
      );
      expect(nextWindow.price_comparison_valid_until).toBe(
        '2026-05-27T12:00:00.000Z',
      );
      expect(nextWindow.price_comparisons).not.toEqual(first.price_comparisons);
    } finally {
      jest.useRealTimers();
    }
  });
});
