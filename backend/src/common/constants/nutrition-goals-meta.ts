import { NutritionGoal } from '../enums/nutrition-goal.enum';

export const NUTRITION_GOALS_META = [
  {
    key: NutritionGoal.DIET,
    label_en: 'Diet / cut',
    label_id: 'Diet / defisit kalori',
    hint: 'Prioritizes lower calories & healthier tiers when data exists',
  },
  {
    key: NutritionGoal.BULKING,
    label_en: 'Bulking',
    label_id: 'Bulking',
    hint: 'Prioritizes higher protein when nutritional_info is present',
  },
  {
    key: NutritionGoal.MAINTAIN,
    label_en: 'Maintain',
    label_id: 'Menjaga berat',
    hint: 'Balances recommendation_score and nutrition tier',
  },
] as const;
