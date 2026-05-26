import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { CreateMerchantScopedFoodDto } from '../../admin/dto/create-merchant-scoped-food.dto';
import { ListMerchantFoodsQueryDto } from '../../merchant/dto/list-merchant-foods-query.dto';
import { CreateMerchantDto } from './create-merchant.dto';
import { ListMerchantsQueryDto } from './list-merchants-query.dto';

describe('Admin merchant DTOs', () => {
  it('requires a valid business email and Firebase-compatible password', async () => {
    const errors = await validate(
      plainToInstance(CreateMerchantDto, {
        name: 'Store',
        business_email: 'not-an-email',
        password: '123',
        address: 'Address',
        lat: -6.2,
        lng: 106.8,
      }),
    );

    expect(errors.map((error) => error.property)).toEqual(
      expect.arrayContaining(['business_email', 'password']),
    );
  });

  it('validates merchant search and active filter query values', async () => {
    const dto = plainToInstance(ListMerchantsQueryDto, {
      q: 'mie',
      is_active: 'false',
      page: 1,
      limit: 20,
    });

    await expect(validate(dto)).resolves.toHaveLength(0);
    expect(dto.is_active).toBe(false);
  });

  it('parses inactive menu tab query from an HTTP string', async () => {
    const dto = plainToInstance(ListMerchantFoodsQueryDto, {
      is_available: 'false',
    });

    await expect(validate(dto)).resolves.toHaveLength(0);
    expect(dto.is_available).toBe(false);
  });

  it('does not accept merchant_id in nested admin create menu input', async () => {
    const dto = plainToInstance(CreateMerchantScopedFoodDto, {
      name: 'Soup',
      description: 'Warm',
      food_category: 'main_course',
      health_labels: [],
      base_price: 12000,
      merchant_id: 'must-not-be-supplied',
      is_available: true,
      recipe: {
        servings: 1,
        ingredients: [{ name: 'water', amount: 1, unit: 'cup' }],
      },
    });
    const errors = await validate(dto, {
      whitelist: true,
      forbidNonWhitelisted: true,
    });

    expect(errors.some((error) => error.property === 'merchant_id')).toBe(true);
  });
});
