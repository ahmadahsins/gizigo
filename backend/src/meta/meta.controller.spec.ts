import { Test, TestingModule } from '@nestjs/testing';
import { MetaController } from './meta.controller';

describe('MetaController', () => {
  let controller: MetaController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [MetaController],
    }).compile();

    controller = module.get<MetaController>(MetaController);
  });

  it('food-categories returns five entries', () => {
    const res = controller.getFoodCategories();
    expect(res.items.length).toBe(5);
    expect(res.items[0]).toHaveProperty('key');
  });

  it('nutrition-grades returns three tiers', () => {
    const res = controller.getNutritionGrades();
    expect(res.items.length).toBe(3);
  });

  it('locations search placeholder returns empty items', () => {
    const res = controller.searchLocations('ugm');
    expect(res.query).toBe('ugm');
    expect(res.items).toEqual([]);
  });
});
