import { ServiceUnavailableException } from '@nestjs/common';
import { AiService } from './ai.service';
import { NutritionGrade } from '../common/enums/nutrition-grade.enum';
import { RecipeUnit } from '../common/enums/recipe-unit.enum';

describe('AiService', () => {
  const recipe = {
    servings: 1,
    ingredients: [{ name: 'chicken', amount: 120, unit: RecipeUnit.G }],
  };
  let generateContent: jest.Mock;
  let service: AiService;

  beforeEach(() => {
    service = new AiService({
      get: jest.fn((key: string) =>
        key === 'GEMINI_API_KEY' ? 'test-key' : undefined,
      ),
    } as never);
    generateContent = jest.fn();
    Object.defineProperty(service, 'client', {
      value: { models: { generateContent } },
    });
  });

  it('parses and redacts a valid accepted nutrition assessment', async () => {
    generateContent.mockResolvedValue({
      text: JSON.stringify({
        nutritional_info: {
          calories: 360,
          protein_g: 30,
          fat_g: 12,
          carb_g: 18,
        },
        grade: NutritionGrade.VERY_GOOD,
        accepted: true,
        reason: 'Chicken provides a protein-forward serving',
      }),
    });

    const result = await service.analyzeRecipe(recipe);

    expect(result.grade).toBe(NutritionGrade.VERY_GOOD);
    expect(result.reason).toBe(
      'selected ingredient provides a protein-forward serving',
    );
  });

  it('returns a valid below-good assessment for the caller to reject', async () => {
    generateContent.mockResolvedValue({
      text: JSON.stringify({
        nutritional_info: {
          calories: 920,
          protein_g: 8,
          fat_g: 55,
          carb_g: 92,
        },
        grade: 'BELOW_GOOD',
        accepted: false,
        reason: 'The macro balance is not suitable',
      }),
    });

    const result = await service.analyzeRecipe(recipe);

    expect(result.accepted).toBe(false);
    expect(result.grade).toBe('BELOW_GOOD');
  });

  it('fails closed for malformed or invalid nutrition values', async () => {
    generateContent.mockResolvedValue({
      text: JSON.stringify({
        nutritional_info: {
          calories: -1,
          protein_g: 30,
          fat_g: 12,
          carb_g: 18,
        },
        grade: NutritionGrade.GOOD,
        accepted: true,
        reason: 'Looks good',
      }),
    });

    await expect(service.analyzeRecipe(recipe)).rejects.toBeInstanceOf(
      ServiceUnavailableException,
    );
  });

  it('maps provider failures to a safe service-unavailable error', async () => {
    generateContent.mockRejectedValue(new Error('provider details'));

    await expect(service.analyzeRecipe(recipe)).rejects.toThrow(
      'Nutrition analysis is temporarily unavailable',
    );
  });

  it('times out a stalled provider request without exposing recipe input', async () => {
    const timeoutService = new AiService({
      get: jest.fn((key: string) => {
        if (key === 'GEMINI_API_KEY') return 'test-key';
        if (key === 'GEMINI_TIMEOUT_MS') return '1';
        return undefined;
      }),
    } as never);
    Object.defineProperty(timeoutService, 'client', {
      value: {
        models: {
          generateContent: jest.fn(() => new Promise(() => undefined)),
        },
      },
    });

    await expect(timeoutService.analyzeRecipe(recipe)).rejects.toThrow(
      'Nutrition analysis is temporarily unavailable',
    );
  });
});
