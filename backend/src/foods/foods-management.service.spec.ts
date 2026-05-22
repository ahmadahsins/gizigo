import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { FoodsManagementService } from './foods-management.service';
import { UserRole } from '../common/enums/user-role.enum';
import { NutritionGrade } from '../common/enums/nutrition-grade.enum';

describe('FoodsManagementService', () => {
  const baseFoodDto = {
    name: 'Ayam goreng',
    description: 'Crispy chicken',
    photo_url: 'https://example.com/food.jpg',
    nutrition_grade: NutritionGrade.EXCELLENT,
    food_category: 'main_course',
    health_labels: ['High Protein'],
    base_price: 17000,
    is_available: true,
  };

  let foodRef: {
    get: jest.Mock;
    set: jest.Mock;
    update: jest.Mock;
    id: string;
  };
  let foodsCollection: {
    doc: jest.Mock;
    where: jest.Mock;
  };
  let service: FoodsManagementService;

  beforeEach(() => {
    foodRef = {
      id: 'food1',
      get: jest.fn(),
      set: jest.fn(),
      update: jest.fn(),
    };

    foodsCollection = {
      doc: jest.fn().mockReturnValue(foodRef),
      where: jest.fn().mockReturnValue({
        get: jest.fn().mockResolvedValue({
          docs: [
            {
              id: 'food1',
              data: () => ({ name: 'Ayam goreng', merchant_id: 'merchant_a' }),
            },
          ],
        }),
      }),
    };

    const firebaseService = {
      getFirestore: jest.fn().mockReturnValue({
        collection: jest.fn((name: string) => {
          if (name === 'foods') return foodsCollection;
          throw new Error(`Unexpected collection ${name}`);
        }),
      }),
    };

    service = new FoodsManagementService(firebaseService as never);
  });

  it('creates food for merchant using logged-in merchant id', async () => {
    const result = await service.createFood(baseFoodDto, {
      role: UserRole.MERCHANT,
      merchantId: 'merchant_a',
    });

    expect(result.id).toBe('food1');
    expect(foodRef.set).toHaveBeenCalledWith(
      expect.objectContaining({
        merchant_id: 'merchant_a',
        food_id: 'food1',
      }),
    );
  });

  it('creates food for admin with explicit merchant_id', async () => {
    await service.createFood(
      { ...baseFoodDto, merchant_id: 'merchant_b' },
      { role: UserRole.ADMIN },
    );

    expect(foodRef.set).toHaveBeenCalledWith(
      expect.objectContaining({ merchant_id: 'merchant_b' }),
    );
  });

  it('blocks merchant from updating another merchants food', async () => {
    foodRef.get.mockResolvedValue({
      exists: true,
      data: () => ({ merchant_id: 'merchant_b' }),
    });

    await expect(
      service.updateFood(
        'food1',
        { base_price: 18000 },
        { role: UserRole.MERCHANT, merchantId: 'merchant_a' },
      ),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('allows admin to update any food', async () => {
    foodRef.get.mockResolvedValue({
      exists: true,
      data: () => ({ merchant_id: 'merchant_b' }),
    });

    const result = await service.updateFood(
      'food1',
      { base_price: 18000, is_featured: true },
      { role: UserRole.ADMIN },
    );

    expect(result.message).toBe('Food updated successfully');
    expect(foodRef.update).toHaveBeenCalledWith(
      expect.objectContaining({ base_price: 18000, is_featured: true }),
    );
  });

  it('strips admin-only fields when merchant updates food', async () => {
    foodRef.get.mockResolvedValue({
      exists: true,
      data: () => ({ merchant_id: 'merchant_a' }),
    });

    await service.updateFood(
      'food1',
      {
        base_price: 18000,
        is_featured: true,
        recommendation_score: 99,
        merchant_id: 'merchant_b',
      },
      { role: UserRole.MERCHANT, merchantId: 'merchant_a' },
    );

    expect(foodRef.update).toHaveBeenCalledWith(
      expect.objectContaining({
        base_price: 18000,
      }),
    );
    expect(foodRef.update).toHaveBeenCalledWith(
      expect.not.objectContaining({
        is_featured: true,
        recommendation_score: 99,
        merchant_id: 'merchant_b',
      }),
    );
  });

  it('throws when deleting missing food', async () => {
    foodRef.get.mockResolvedValue({ exists: false });

    await expect(
      service.deleteFood('missing', {
        role: UserRole.ADMIN,
      }),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('lists foods for a merchant', async () => {
    const result = await service.listFoodsForMerchant('merchant_a');

    expect(result.items).toHaveLength(1);
    expect(result.items[0].merchant_id).toBe('merchant_a');
  });
});
