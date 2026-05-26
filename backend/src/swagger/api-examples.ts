/** Plain examples for @ApiOkResponse / @ApiCreatedResponse — keep in sync with handlers */

export const AUTH_SYNC_RESPONSE_EXAMPLE = {
  message: 'Synced successfully',
  uid: 'firebaseUidExample123',
  role: 'customer',
  merchant_id: null,
  profile_photo_url:
    'https://res.cloudinary.com/demo/image/upload/gizigo/profile-photos/firebaseUidExample123.jpg',
};

export const AUTH_MERCHANT_SIGNUP_BODY_EXAMPLE = {
  account_type: 'merchant',
  merchant: {
    name: 'Warteg Sendowo',
    address: 'Jl. Margonda Raya No. 12, Depok',
    lat: -6.3729,
    lng: 106.8346,
  },
};

export const MERCHANT_PROFILE_EXAMPLE = {
  id: 'firebaseUidExample123',
  merchant_id: 'firebaseUidExample123',
  name: 'Warteg Sendowo',
  business_email: 'owner@warteg-sendowo.id',
  address: 'Jl. Margonda Raya No. 12, Depok',
  lat: -6.3729,
  lng: 106.8346,
  owner_uid: 'firebaseUidExample123',
  is_verified: true,
  is_active: true,
  created_at: '2026-05-17T10:00:00.000Z',
  updated_at: '2026-05-17T10:00:00.000Z',
};

export const ADMIN_CREATE_MERCHANT_BODY_EXAMPLE = {
  name: 'Warung Sehat',
  business_email: 'owner@warungsehat.id',
  password: 'SecureLogin123',
  address: 'Jl. Prof. Dr. Soepomo No. 45, Jakarta Selatan',
  lat: -6.2435,
  lng: 106.8444,
};

export const MERCHANT_CREATE_FOOD_BODY_EXAMPLE = {
  name: 'Ayam goreng',
  description: 'Ayam goreng renyah',
  food_category: 'main_course',
  health_labels: ['High Protein'],
  base_price: 17000,
  is_available: true,
  recipe: {
    servings: 1,
    ingredients: [
      { name: 'dada ayam', amount: 150, unit: 'g' },
      { name: 'minyak', amount: 1, unit: 'tsp' },
    ],
  },
  comparison_data: {
    gofood: {
      price: 18000,
      url: 'https://gofood.co.id/merchant/example',
    },
  },
};

export const USER_PROFILE_EXAMPLE = {
  uid: 'firebaseUidExample123',
  name: 'GiziGang',
  email: 'user@example.com',
  username: 'gizigang',
  role: 'customer',
  merchant_id: null,
  gender: 'MALE',
  age: 21,
  weight_kg: 65,
  height_cm: 170,
  nutrition_goal: 'DIET',
  food_preferences: ['High Protein', 'Low Calorie'],
  dietary_restrictions: ['Halal'],
  taste_profile: ['Savory', 'Spicy'],
  onboarding_completed: true,
  preferred_language: 'id_ID',
  dark_mode: false,
};

export const PATCH_USER_BODY_EXAMPLE = {
  name: 'GiziGang',
  gender: 'FEMALE',
  age: 22,
  weight_kg: 60,
  height_cm: 165,
  nutrition_goal: 'BULKING',
  food_preferences: ['High Protein'],
  dietary_restrictions: [],
  taste_profile: ['Savory'],
  onboarding_completed: true,
};

export const FOODS_PAGINATED_EXAMPLE = {
  items: [
    {
      id: 'foodDocId1',
      name: 'Ayam goreng',
      description: 'Crispy fried chicken',
      base_price: 17000,
      nutrition_grade: 'EXCELLENT',
      food_category: 'main_course',
      vendor_name: 'Warteg Sendowo',
      image_url: 'https://res.cloudinary.com/demo/image/upload/sample.jpg',
      distance_in_km: 1.2,
    },
  ],
  total: 42,
  page: 1,
  limit: 20,
  total_pages: 3,
};

export const FOOD_DETAIL_EXAMPLE = {
  id: 'foodDocId1',
  name: 'Ayam goreng',
  description: 'Deskripsi lengkap untuk layar detail.',
  photo_url: 'https://res.cloudinary.com/demo/image/upload/sample.jpg',
  base_price: 17000,
  nutrition_grade: 'EXCELLENT',
  food_category: 'main_course',
  merchant_id: 'merchant_1',
  vendor_name: 'Warteg Sendowo',
  image_url: 'https://res.cloudinary.com/demo/image/upload/sample.jpg',
  nutritional_info: { calories: 450, protein_g: 35, fat_g: 18, carb_g: 30 },
  price_comparisons: [
    {
      platform_key: 'gofood',
      platform: 'GoFood',
      price: 18000,
      base_price: 17500,
      order_url: 'https://gofood.link/example',
      icon_url: 'https://example.com/gofood.png',
    },
  ],
};

export const RECOMMENDATIONS_RESPONSE_EXAMPLE = {
  featured: [
    {
      id: 'foodFeatured1',
      name: 'Ayam goreng',
      base_price: 17000,
      nutrition_grade: 'EXCELLENT',
      vendor_name: 'Warteg Sendowo',
      image_url: 'https://res.cloudinary.com/demo/image/upload/sample.jpg',
      personalization_score: 128.5,
    },
  ],
  recommendations: [
    {
      id: 'foodRec2',
      name: 'Tumis kangkung',
      base_price: 12000,
      nutrition_grade: 'VERY_GOOD',
      vendor_name: 'Warung Sehat',
      image_url: 'https://res.cloudinary.com/demo/image/upload/sample2.jpg',
      personalization_score: 95,
    },
  ],
  context: {
    nutrition_goal: 'DIET',
    onboarding_completed: true,
    personalized: true,
    recommendation_source: 'gemini',
  },
};

export const ADMIN_CREATE_FOOD_BODY_EXAMPLE = {
  name: 'Ayam goreng',
  description: 'Ayam goreng renyah',
  food_category: 'main_course',
  health_labels: ['High Protein'],
  base_price: 17000,
  merchant_id: 'merchant_1',
  is_available: true,
  is_featured: true,
  recommendation_score: 85,
  recipe: {
    servings: 1,
    ingredients: [
      { name: 'dada ayam', amount: 150, unit: 'g' },
      { name: 'minyak', amount: 1, unit: 'tsp' },
    ],
  },
  comparison_data: {
    gofood: {
      price: 18000,
      url: 'https://gofood.co.id/merchant/example',
      icon_url: 'https://example.com/gofood.png',
    },
    grabfood: { price: 17500, url: 'https://food.grab.com/example' },
    shopeefood: { price: 17000, url: 'https://shopeefood.co.id/example' },
  },
};

export const META_CATEGORIES_EXAMPLE = {
  items: [
    {
      key: 'main_course',
      label_en: 'Main Course',
      label_id: 'Hidangan Utama',
    },
  ],
};

export const RECENTLY_VIEWED_RESPONSE_EXAMPLE = {
  items: [
    {
      viewed_at: '2026-05-17T10:00:00.000Z',
      food: {
        id: 'food1',
        name: 'Nasi goreng',
        nutrition_grade: 'GOOD',
        base_price: 15000,
      },
    },
  ],
  total: 5,
  page: 1,
  limit: 20,
  total_pages: 1,
};
