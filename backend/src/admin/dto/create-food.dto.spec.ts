import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { CreateFoodDto } from './create-food.dto';

describe('CreateFoodDto recipe validation', () => {
  const validBody = {
    name: 'Sup sehat',
    description: 'Menu hangat',
    photo_url: 'https://example.com/soup.jpg',
    food_category: 'main_course',
    health_labels: ['Low Fat'],
    base_price: 15000,
    merchant_id: 'merchant_a',
    is_available: true,
    recipe: {
      servings: 2,
      ingredients: [{ name: 'broth', amount: 1, unit: 'cup' }],
    },
  };

  it('accepts a supported measured recipe', async () => {
    const errors = await validate(plainToInstance(CreateFoodDto, validBody));

    expect(errors).toHaveLength(0);
  });

  it('rejects invalid serving counts and ingredient units', async () => {
    const dto = plainToInstance(CreateFoodDto, {
      ...validBody,
      recipe: {
        servings: 0,
        ingredients: [{ name: 'broth', amount: 1, unit: 'bowl' }],
      },
    });

    const errors = await validate(dto);

    expect(errors.some((error) => error.property === 'recipe')).toBe(true);
  });
});
