/** Static seed records for local / hackathon Firestore. */

export const SEED_MERCHANTS = [
  {
    id: 'merchant_warteg_sendowo',
    merchant_id: 'merchant_warteg_sendowo',
    name: 'Warteg Sendowo',
    address: 'Jl. Margonda Raya No. 12, Depok',
    coordinates: { latitude: -6.3729, longitude: 106.8346 },
    is_verified: true,
  },
  {
    id: 'merchant_warung_sehat',
    merchant_id: 'merchant_warung_sehat',
    name: 'Warung Sehat',
    address: 'Jl. Prof. Dr. Soepomo No. 45, Jakarta Selatan',
    coordinates: { latitude: -6.2435, longitude: 106.8444 },
    is_verified: true,
  },
  {
    id: 'merchant_warteg_makmur',
    merchant_id: 'merchant_warteg_makmur',
    name: 'Warteg Makmur',
    address: 'Jl. Cikini Raya No. 8, Jakarta Pusat',
    coordinates: { latitude: -6.1944, longitude: 106.8381 },
    is_verified: false,
  },
] as const;

export const SEED_FOODS = [
  {
    id: 'seed_food_ayam_goreng',
    name: 'Ayam goreng',
    description: 'Ayam goreng renyah tanpa MSG, porsi mahasiswa.',
    photo_url:
      'https://images.unsplash.com/photo-1627662168223-7df99068099a?auto=format&fit=crop&w=800&q=80',
    nutrition_grade: 'EXCELLENT',
    food_category: 'main_course',
    health_labels: ['High Protein', 'Low Calorie'],
    base_price: 17000,
    merchant_id: 'merchant_warteg_sendowo',
    is_available: true,
    is_featured: true,
    recommendation_score: 92,
    nutritional_info: { calories: 420, protein_g: 32, fat_g: 20, carb_g: 28 },
    comparison_data: {
      gofood: {
        price: 18000,
        url: 'https://gofood.co.id/jakarta/restaurant/warteg-sendowo',
      },
      grabfood: {
        price: 17500,
        url: 'https://food.grab.com/id/id/restaurant/warteg-sendowo',
      },
      shopeefood: {
        price: 17000,
        url: 'https://shopeefood.co.id/jakarta/warteg-sendowo',
      },
    },
  },
  {
    id: 'seed_food_tumis_kangkung',
    name: 'Tumis kangkung',
    description: 'Kangkung tumis bawang putih, rendah kalori dan tinggi serat.',
    photo_url:
      'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=800&q=80',
    nutrition_grade: 'VERY_GOOD',
    food_category: 'main_course',
    health_labels: ['High Fiber', 'Vegetarian'],
    base_price: 12000,
    merchant_id: 'merchant_warung_sehat',
    is_available: true,
    is_featured: false,
    recommendation_score: 78,
    nutritional_info: { calories: 180, protein_g: 6, fat_g: 8, carb_g: 22 },
    comparison_data: {
      gofood: {
        price: 13000,
        url: 'https://gofood.co.id/jakarta/restaurant/warung-sehat',
      },
      grabfood: {
        price: 12500,
        url: 'https://food.grab.com/id/id/restaurant/warung-sehat',
      },
    },
  },
  {
    id: 'seed_food_nasi_goreng_telur',
    name: 'Nasi goreng telur',
    description: 'Nasi goreng telur dengan sayuran, porsi pas untuk makan siang.',
    photo_url:
      'https://images.unsplash.com/photo-1603133872878-684f208fb274?auto=format&fit=crop&w=800&q=80',
    nutrition_grade: 'GOOD',
    food_category: 'main_course',
    health_labels: ['Balanced Meal'],
    base_price: 15000,
    merchant_id: 'merchant_warteg_makmur',
    is_available: true,
    is_featured: false,
    recommendation_score: 65,
    nutritional_info: { calories: 510, protein_g: 14, fat_g: 18, carb_g: 72 },
    comparison_data: {
      gofood: {
        price: 16000,
        url: 'https://gofood.co.id/jakarta/restaurant/warteg-makmur',
      },
      shopeefood: {
        price: 15500,
        url: 'https://shopeefood.co.id/jakarta/warteg-makmur',
      },
    },
  },
] as const;
