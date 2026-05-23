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

  function setup(user: Record<string, unknown>) {
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
                get: jest.fn().mockResolvedValue({ docs: foodDocs }),
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
});
