/** Stable keys for `food_category` on foods + `/meta/food-categories` */
export const FOOD_CATEGORY_KEYS = [
  'main_course',
  'appetizers',
  'snacks',
  'desserts',
  'beverages',
  'breakfast',
  'lunch',
  'dinner',
  'salads',
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
  { key: 'breakfast', label_en: 'Breakfast', label_id: 'Sarapan' },
  { key: 'lunch', label_en: 'Lunch', label_id: 'Makan Siang' },
  { key: 'dinner', label_en: 'Dinner', label_id: 'Makan Malam' },
  { key: 'salads', label_en: 'Salads', label_id: 'Salad' },
];
