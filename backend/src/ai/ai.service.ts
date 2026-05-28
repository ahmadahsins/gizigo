import {
  Injectable,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleGenAI } from '@google/genai';
import { NutritionGrade } from '../common/enums/nutrition-grade.enum';
import { RecipeUnit } from '../common/enums/recipe-unit.enum';

export interface RecipeInput {
  servings: number;
  ingredients: Array<{
    name: string;
    amount: number;
    unit: RecipeUnit;
  }>;
}

export interface NutritionalInfo {
  calories: number;
  protein_g: number;
  fat_g: number;
  carb_g: number;
}

export type AiNutritionGrade = NutritionGrade | 'BELOW_GOOD';

export interface NutritionAssessment {
  nutritional_info: NutritionalInfo;
  grade: AiNutritionGrade;
  accepted: boolean;
  reason: string;
}

export interface RecommendationFoodCandidate {
  id: string;
  name?: unknown;
  description?: unknown;
  nutrition_grade?: unknown;
  food_category?: unknown;
  health_labels?: unknown;
  nutritional_info?: unknown;
}

const NUTRITION_ASSESSMENT_SCHEMA = {
  type: 'object',
  properties: {
    nutritional_info: {
      type: 'object',
      properties: {
        calories: { type: 'number' },
        protein_g: { type: 'number' },
        fat_g: { type: 'number' },
        carb_g: { type: 'number' },
      },
      required: ['calories', 'protein_g', 'fat_g', 'carb_g'],
    },
    grade: {
      type: 'string',
      enum: ['EXCELLENT', 'VERY_GOOD', 'GOOD', 'BELOW_GOOD'],
    },
    accepted: { type: 'boolean' },
    reason: { type: 'string' },
  },
  required: ['nutritional_info', 'grade', 'accepted', 'reason'],
};

const RECOMMENDATIONS_SCHEMA = {
  type: 'object',
  properties: {
    ordered_food_ids: {
      type: 'array',
      items: { type: 'string' },
    },
  },
  required: ['ordered_food_ids'],
};

@Injectable()
export class AiService {
  private readonly logger = new Logger(AiService.name);
  private readonly model: string;
  private readonly timeoutMs: number;
  private readonly client: GoogleGenAI | null;

  constructor(private readonly configService: ConfigService) {
    const apiKey = this.configService.get<string>('GEMINI_API_KEY');
    this.model =
      this.configService.get<string>('GEMINI_MODEL') ?? 'gemini-2.5-flash';
    const configuredTimeout = Number(
      this.configService.get<string>('GEMINI_TIMEOUT_MS') ?? 20000,
    );
    this.timeoutMs =
      Number.isFinite(configuredTimeout) && configuredTimeout > 0
        ? configuredTimeout
        : 20000;
    this.client = apiKey ? new GoogleGenAI({ apiKey }) : null;
  }

  async analyzeRecipe(recipe: RecipeInput): Promise<NutritionAssessment> {
    const client = this.requireClient();

    try {
      const response = await this.withTimeout(
        client.models.generateContent({
          model: this.model,
          contents: [
            'Analyze the nutrition of this menu recipe per serving.',
            'Return estimated calories, protein, fat, and carbohydrates in grams.',
            'Assign EXCELLENT, VERY_GOOD, GOOD, or BELOW_GOOD based on whether it is a healthy menu option.',
            'accepted must be true only for EXCELLENT, VERY_GOOD, or GOOD.',
            'Keep reason brief and general; do not mention individual ingredients or quantities.',
            `Recipe input: ${JSON.stringify(recipe)}`,
          ].join('\n'),
          config: {
            temperature: 0.1,
            responseMimeType: 'application/json',
            responseJsonSchema: NUTRITION_ASSESSMENT_SCHEMA,
          },
        }),
      );

      const parsed = this.parseJson(response.text);
      return this.validateNutritionAssessment(parsed, recipe);
    } catch (error) {
      if (error instanceof ServiceUnavailableException) throw error;
      this.logAiFailure('Nutrition analysis', error);
      throw new ServiceUnavailableException(
        'Nutrition analysis is temporarily unavailable',
      );
    }
  }

  async rankFoodsForUser(
    user: Record<string, unknown>,
    foods: RecommendationFoodCandidate[],
  ): Promise<string[]> {
    const client = this.requireClient();

    try {
      const response = await this.withTimeout(
        client.models.generateContent({
          model: this.model,
          contents: [
            'Rank the available food IDs for this user from best match to least match.',
            'Use health suitability first: dietary restrictions, nutrition goal, body profile, taste profile, and preferences.',
            'Use only food IDs supplied in candidates and include every suitable candidate once.',
            `User profile: ${JSON.stringify(user)}`,
            `Food candidates: ${JSON.stringify(foods)}`,
          ].join('\n'),
          config: {
            temperature: 0.1,
            responseMimeType: 'application/json',
            responseJsonSchema: RECOMMENDATIONS_SCHEMA,
          },
        }),
      );

      const parsed = this.parseJson(response.text) as {
        ordered_food_ids?: unknown;
      };
      if (
        !Array.isArray(parsed.ordered_food_ids) ||
        !parsed.ordered_food_ids.every((id) => typeof id === 'string')
      ) {
        throw new Error('Invalid recommendation output');
      }
      return parsed.ordered_food_ids;
    } catch (error) {
      if (error instanceof ServiceUnavailableException) throw error;
      this.logAiFailure('AI recommendations', error);
      throw new ServiceUnavailableException(
        'AI recommendations are temporarily unavailable',
      );
    }
  }

  private requireClient(): GoogleGenAI {
    if (!this.client) {
      throw new ServiceUnavailableException('Gemini API is not configured');
    }
    return this.client;
  }

  private async withTimeout<T>(request: Promise<T>): Promise<T> {
    let timer: ReturnType<typeof setTimeout> | undefined;
    const timeout = new Promise<never>((_, reject) => {
      timer = setTimeout(
        () => reject(new Error('Gemini request timed out')),
        this.timeoutMs,
      );
    });
    try {
      return await Promise.race([request, timeout]);
    } finally {
      if (timer) clearTimeout(timer);
    }
  }

  private parseJson(text: string | undefined): unknown {
    if (!text) throw new Error('AI response was empty');
    return JSON.parse(text) as unknown;
  }

  private logAiFailure(scope: string, error: unknown): void {
    const details = this.describeError(error);
    this.logger.warn(
      `${scope} failed via Gemini model ${this.model} after ${this.timeoutMs}ms timeout window: ${details}`,
    );
  }

  private describeError(error: unknown): string {
    if (!(error instanceof Error)) return String(error);

    const extra = error as Error & {
      code?: unknown;
      status?: unknown;
      statusCode?: unknown;
    };
    const metadata = [
      extra.code ? `code=${String(extra.code)}` : undefined,
      extra.status ? `status=${String(extra.status)}` : undefined,
      extra.statusCode ? `statusCode=${String(extra.statusCode)}` : undefined,
    ]
      .filter(Boolean)
      .join(', ');

    return [error.name, error.message, metadata].filter(Boolean).join(' | ');
  }

  private validateNutritionAssessment(
    value: unknown,
    recipe: RecipeInput,
  ): NutritionAssessment {
    const result = value as Partial<NutritionAssessment> | null;
    const validGrades: AiNutritionGrade[] = [
      NutritionGrade.EXCELLENT,
      NutritionGrade.VERY_GOOD,
      NutritionGrade.GOOD,
      'BELOW_GOOD',
    ];
    const nutrition = result?.nutritional_info;
    const validNumber = (number: unknown) =>
      typeof number === 'number' && Number.isFinite(number) && number >= 0;

    if (
      !result ||
      !nutrition ||
      !validNumber(nutrition.calories) ||
      !validNumber(nutrition.protein_g) ||
      !validNumber(nutrition.fat_g) ||
      !validNumber(nutrition.carb_g) ||
      !validGrades.includes(result.grade as AiNutritionGrade) ||
      typeof result.accepted !== 'boolean' ||
      typeof result.reason !== 'string' ||
      result.reason.trim().length === 0
    ) {
      throw new Error('Invalid nutrition assessment');
    }

    const accepted = result.grade !== 'BELOW_GOOD';
    if (result.accepted !== accepted) {
      throw new Error('Inconsistent nutrition assessment');
    }

    return {
      nutritional_info: nutrition,
      grade: result.grade as AiNutritionGrade,
      accepted,
      reason: this.redactIngredientNames(result.reason.trim(), recipe),
    };
  }

  private redactIngredientNames(reason: string, recipe: RecipeInput): string {
    return recipe.ingredients.reduce((safeReason, ingredient) => {
      const escaped = ingredient.name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      if (!escaped.trim()) return safeReason;
      return safeReason.replace(
        new RegExp(escaped, 'gi'),
        'selected ingredient',
      );
    }, reason);
  }
}
