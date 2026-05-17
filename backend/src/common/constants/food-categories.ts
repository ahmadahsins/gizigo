/** Stable keys for `food_category` on foods + `/meta/food-categories` */
export const FOOD_CATEGORY_KEYS = [
  'main_course',
  'appetizers',
  'snacks',
  'desserts',
  'beverages',
] as const;

export type FoodCategoryKey = (typeof FOOD_CATEGORY_KEYS)[number];

export const FOOD_CATEGORIES_META: ReadonlyArray<{
  key: FoodCategoryKey;
  label_en: string;
  label_id: string;
}> = [
  { key: 'main_course', label_en: 'Main Course', label_id: 'Hidangan Utama' },
  { key: 'appetizers', label_en: 'Appetizers', label_id: 'Pembuka' },
  { key: 'snacks', label_en: 'Snacks', label_id: 'Camilan' },
  { key: 'desserts', label_en: 'Desserts', label_id: 'Penutup' },
  { key: 'beverages', label_en: 'Beverages', label_id: 'Minuman' },
];
