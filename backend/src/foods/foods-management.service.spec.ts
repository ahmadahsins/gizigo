import {
  ForbiddenException,
  NotFoundException,
  ServiceUnavailableException,
  UnprocessableEntityException,
} from '@nestjs/common';
import { FoodsManagementService } from './foods-management.service';
import { UserRole } from '../common/enums/user-role.enum';
import { NutritionGrade } from '../common/enums/nutrition-grade.enum';
import { RecipeUnit } from '../common/enums/recipe-unit.enum';

describe('FoodsManagementService', () => {
  const baseFoodDto = {
    name: 'Ayam goreng',
    description: 'Crispy chicken',
    food_category: 'main_course',
    health_labels: ['High Protein'],
    base_price: 17000,
    is_available: true,
    recipe: {
      servings: 1,
      ingredients: [{ name: 'chicken', amount: 150, unit: RecipeUnit.G }],
    },
  };
  const acceptedAssessment = {
    nutritional_info: {
      calories: 420,
      protein_g: 32,
      fat_g: 20,
      carb_g: 28,
    },
    grade: NutritionGrade.EXCELLENT,
    accepted: true,
    reason: 'Balanced protein-rich serving',
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
  let analyzeRecipe: jest.Mock;
  let uploadFoodPhoto: jest.Mock;
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
    analyzeRecipe = jest.fn().mockResolvedValue(acceptedAssessment);
    uploadFoodPhoto = jest
      .fn()
      .mockResolvedValue('https://res.cloudinary.com/demo/foods/food1.jpg');

    service = new FoodsManagementService(
      firebaseService as never,
      {
        analyzeRecipe,
      } as never,
      {
        uploadFoodPhoto,
      } as never,
    );
  });

  it('creates food for merchant with generated nutrition and never stores recipe', async () => {
    const result = await service.createFood(baseFoodDto, {
      role: UserRole.MERCHANT,
      merchantId: 'merchant_a',
    });

    expect(analyzeRecipe).toHaveBeenCalledWith(baseFoodDto.recipe);
    expect(result).toEqual(
      expect.objectContaining({
        id: 'food1',
        nutrition_grade: NutritionGrade.EXCELLENT,
      }),
    );
    expect(foodRef.set).toHaveBeenCalledWith(
      expect.objectContaining({
        merchant_id: 'merchant_a',
        food_id: 'food1',
        nutrition_grade: NutritionGrade.EXCELLENT,
        nutritional_info: acceptedAssessment.nutritional_info,
      }),
    );
    expect(foodRef.set).toHaveBeenCalledWith(
      expect.not.objectContaining({ recipe: expect.anything() }),
    );
    expect(foodRef.set).toHaveBeenCalledWith(
      expect.not.objectContaining({ photo_url: expect.anything() }),
    );
  });

  it('creates food for admin with explicit merchant id', async () => {
    await service.createFood(
      { ...baseFoodDto, merchant_id: 'merchant_b' },
      { role: UserRole.ADMIN },
    );

    expect(foodRef.set).toHaveBeenCalledWith(
      expect.objectContaining({ merchant_id: 'merchant_b' }),
    );
  });

  it('rejects food below GOOD without writing it', async () => {
    analyzeRecipe.mockResolvedValue({
      ...acceptedAssessment,
      grade: 'BELOW_GOOD',
      accepted: false,
    });

    await expect(
      service.createFood(baseFoodDto, {
        role: UserRole.MERCHANT,
        merchantId: 'merchant_a',
      }),
    ).rejects.toBeInstanceOf(UnprocessableEntityException);
    expect(foodRef.set).not.toHaveBeenCalled();
  });

  it('does not write when Gemini analysis is unavailable', async () => {
    analyzeRecipe.mockRejectedValue(
      new ServiceUnavailableException('Nutrition analysis unavailable'),
    );

    await expect(
      service.createFood(baseFoodDto, {
        role: UserRole.MERCHANT,
        merchantId: 'merchant_a',
      }),
    ).rejects.toBeInstanceOf(ServiceUnavailableException);
    expect(foodRef.set).not.toHaveBeenCalled();
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

  it('updates metadata without reanalyzing nutrition', async () => {
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
    expect(analyzeRecipe).not.toHaveBeenCalled();
    expect(foodRef.update).toHaveBeenCalledWith(
      expect.objectContaining({ base_price: 18000, is_featured: true }),
    );
  });

  it('blocks a scoped admin update for food owned by another merchant', async () => {
    foodRef.get.mockResolvedValue({
      exists: true,
      data: () => ({ merchant_id: 'merchant_b' }),
    });

    await expect(
      service.updateFood(
        'food1',
        { base_price: 18000 },
        { role: UserRole.ADMIN, merchantScopeId: 'merchant_a' },
      ),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(foodRef.update).not.toHaveBeenCalled();
  });

  it('reanalyzes an updated recipe but does not persist it', async () => {
    foodRef.get.mockResolvedValue({
      exists: true,
      data: () => ({ merchant_id: 'merchant_a' }),
    });

    await service.updateFood(
      'food1',
      { recipe: baseFoodDto.recipe },
      { role: UserRole.MERCHANT, merchantId: 'merchant_a' },
    );

    expect(analyzeRecipe).toHaveBeenCalledWith(baseFoodDto.recipe);
    expect(foodRef.update).toHaveBeenCalledWith(
      expect.objectContaining({
        nutrition_grade: NutritionGrade.EXCELLENT,
        nutritional_info: acceptedAssessment.nutritional_info,
      }),
    );
    expect(foodRef.update).toHaveBeenCalledWith(
      expect.not.objectContaining({ recipe: expect.anything() }),
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
      expect.objectContaining({ base_price: 18000 }),
    );
    expect(foodRef.update).toHaveBeenCalledWith(
      expect.not.objectContaining({
        is_featured: true,
        recommendation_score: 99,
        merchant_id: 'merchant_b',
      }),
    );
  });

  it('uploads a photo for a food owned by the merchant', async () => {
    foodRef.get.mockResolvedValue({
      exists: true,
      data: () => ({ merchant_id: 'merchant_a' }),
    });

    const result = await service.uploadFoodPhoto(
      'food1',
      { buffer: Buffer.from('image') },
      { role: UserRole.MERCHANT, merchantId: 'merchant_a' },
    );

    expect(uploadFoodPhoto).toHaveBeenCalledWith('food1', Buffer.from('image'));
    expect(foodRef.update).toHaveBeenCalledWith(
      expect.objectContaining({
        photo_url: 'https://res.cloudinary.com/demo/foods/food1.jpg',
      }),
    );
    expect(result).toEqual(
      expect.objectContaining({
        food_id: 'food1',
        photo_url: 'https://res.cloudinary.com/demo/foods/food1.jpg',
      }),
    );
  });

  it('does not upload a photo for another merchants food', async () => {
    foodRef.get.mockResolvedValue({
      exists: true,
      data: () => ({ merchant_id: 'merchant_b' }),
    });

    await expect(
      service.uploadFoodPhoto(
        'food1',
        { buffer: Buffer.from('image') },
        { role: UserRole.MERCHANT, merchantId: 'merchant_a' },
      ),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(uploadFoodPhoto).not.toHaveBeenCalled();
    expect(foodRef.update).not.toHaveBeenCalled();
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

  it('filters merchant foods for admin search and active tabs', async () => {
    foodsCollection.where.mockReturnValue({
      get: jest.fn().mockResolvedValue({
        docs: [
          {
            id: 'food1',
            data: () => ({
              name: 'Ayam sehat',
              description: 'Protein',
              merchant_id: 'merchant_a',
              is_available: true,
            }),
          },
          {
            id: 'food2',
            data: () => ({
              name: 'Sup',
              description: 'Warm',
              merchant_id: 'merchant_a',
              is_available: false,
            }),
          },
        ],
      }),
    });

    const result = await service.listFoodsForMerchant('merchant_a', {
      q: 'ayam',
      is_available: true,
    });

    expect(result.items.map((item) => item.id)).toEqual(['food1']);
  });
});
