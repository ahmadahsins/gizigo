import { NutritionGrade } from '../enums/nutrition-grade.enum';

export const NUTRITION_GRADES_META: ReadonlyArray<{
  key: NutritionGrade;
  label_en: string;
  label_id: string;
}> = [
  {
    key: NutritionGrade.EXCELLENT,
    label_en: 'Excellent',
    label_id: 'Sangat baik',
  },
  {
    key: NutritionGrade.VERY_GOOD,
    label_en: 'Very good',
    label_id: 'Baik sekali',
  },
  { key: NutritionGrade.GOOD, label_en: 'Good', label_id: 'Baik' },
];
