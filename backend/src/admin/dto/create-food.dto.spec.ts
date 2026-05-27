import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { CreateFoodDto } from './create-food.dto';

describe('CreateFoodDto recipe validation', () => {
  const validBody = {
    name: 'Sup sehat',
    description: 'Menu hangat',
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

  it('accepts a supported measured recipe without a photo url', async () => {
    const errors = await validate(plainToInstance(CreateFoodDto, validBody));

    expect(errors).toHaveLength(0);
  });

  it('accepts provider deeplinks without client-supplied platform prices', async () => {
    const dto = plainToInstance(CreateFoodDto, {
      ...validBody,
      comparison_data: {
        gofood: { url: 'https://gofood.co.id/menu/example' },
        grabfood: { url: 'https://food.grab.com/menu/example' },
      },
    });

    await expect(validate(dto)).resolves.toHaveLength(0);
  });

  it('rejects legacy client-supplied platform prices', async () => {
    const dto = plainToInstance(CreateFoodDto, {
      ...validBody,
      comparison_data: {
        gofood: {
          price: 18000,
          url: 'https://gofood.co.id/menu/example',
        },
      },
    });

    const errors = await validate(dto, {
      whitelist: true,
      forbidNonWhitelisted: true,
    });

    expect(errors.some((error) => error.property === 'comparison_data')).toBe(
      true,
    );
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
