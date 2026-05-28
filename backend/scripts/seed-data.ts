/** Static seed records for local / hackathon Firestore. */

export const SEED_MERCHANTS = [
  {
    id: 'merchant_warteg_sendowo',
    merchant_id: 'merchant_warteg_sendowo',
    name: 'Warteg Sendowo',
    address: 'Jl. Kaliurang KM 5, Caturtunggal, Depok, Sleman, Yogyakarta',
    coordinates: { latitude: -7.7561, longitude: 110.3805 },
    is_verified: true,
    is_active: true,
    owner_uid: null,
  },
  {
    id: 'merchant_warung_sehat',
    merchant_id: 'merchant_warung_sehat',
    name: 'Warung Sehat',
    address: 'Jl. Affandi No. 32, Caturtunggal, Depok, Sleman, Yogyakarta',
    coordinates: { latitude: -7.7766, longitude: 110.3881 },
    is_verified: true,
    is_active: true,
    owner_uid: null,
  },
  {
    id: 'merchant_warteg_makmur',
    merchant_id: 'merchant_warteg_makmur',
    name: 'Warteg Makmur',
    address: 'Jl. Colombo No. 1, Caturtunggal, Depok, Sleman, Yogyakarta',
    coordinates: { latitude: -7.7737, longitude: 110.3869 },
    is_verified: false,
    is_active: true,
    owner_uid: null,
  },
] as const;

export const SEED_FOODS = [
  {
    id: 'seed_food_ayam_goreng',
    name: 'Ayam Panggang Sayur Komplit',
    description:
      'Dada ayam panggang rendah minyak dengan nasi, brokoli, wortel, dan buncis. Porsi seimbang untuk makan siang mahasiswa.',
    photo_url:
      'https://images.unsplash.com/photo-1627662168223-7df99068099a?auto=format&fit=crop&w=800&q=80',
    nutrition_grade: 'VERY_GOOD',
    food_category: 'lunch',
    health_labels: ['High Protein', 'Low Calories'],
    base_price: 23000,
    merchant_id: 'merchant_warteg_sendowo',
    is_available: true,
    is_featured: true,
    recommendation_score: 90,
    nutritional_info: { calories: 510, protein_g: 38, fat_g: 14, carb_g: 58 },
    nutrition_assessment_reason:
      'Menu seimbang dengan protein tinggi dari ayam panggang, karbohidrat cukup, dan sayuran tinggi serat.',
    comparison_data: {
      gofood: {
        url: 'https://gofood.co.id/jakarta/restaurant/warteg-sendowo/ayam-panggang-sayur',
      },
      grabfood: {
        url: 'https://food.grab.com/id/id/restaurant/warteg-sendowo/ayam-panggang-sayur',
      },
      shopeefood: {
        url: 'https://shopeefood.co.id/jakarta/warteg-sendowo/ayam-panggang-sayur',
      },
    },
  },
  {
    id: 'seed_food_tumis_kangkung',
    name: 'Tumis Kangkung Tahu Tempe',
    description:
      'Kangkung tumis bawang putih dengan tahu dan tempe kukus. Rendah minyak, tinggi serat, dan cocok untuk menu vegetarian.',
    photo_url:
      'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=800&q=80',
    nutrition_grade: 'EXCELLENT',
    food_category: 'salads',
    health_labels: ['Vegetarian', 'High Protein'],
    base_price: 16000,
    merchant_id: 'merchant_warung_sehat',
    is_available: true,
    is_featured: false,
    recommendation_score: 86,
    nutritional_info: { calories: 310, protein_g: 18, fat_g: 12, carb_g: 32 },
    nutrition_assessment_reason:
      'Menu tinggi serat dan protein nabati, dengan proses masak rendah minyak sehingga cocok untuk pilihan sehat.',
    comparison_data: {
      gofood: {
        url: 'https://gofood.co.id/jakarta/restaurant/warung-sehat/tumis-kangkung-tahu-tempe',
      },
      grabfood: {
        url: 'https://food.grab.com/id/id/restaurant/warung-sehat/tumis-kangkung-tahu-tempe',
      },
      shopeefood: {
        url: 'https://shopeefood.co.id/jakarta/warung-sehat/tumis-kangkung-tahu-tempe',
      },
    },
  },
  {
    id: 'seed_food_nasi_goreng_telur',
    name: 'Nasi Merah Telur Sayur',
    description:
      'Nasi merah dengan telur dadar rendah minyak, edamame, wortel, dan pakcoy. Alternatif makan malam ringan dan bergizi.',
    photo_url:
      'https://images.unsplash.com/photo-1603133872878-684f208fb274?auto=format&fit=crop&w=800&q=80',
    nutrition_grade: 'VERY_GOOD',
    food_category: 'dinner',
    health_labels: ['High Protein', 'Low Calories'],
    base_price: 20000,
    merchant_id: 'merchant_warteg_makmur',
    is_available: true,
    is_featured: false,
    recommendation_score: 82,
    nutritional_info: { calories: 440, protein_g: 20, fat_g: 13, carb_g: 58 },
    nutrition_assessment_reason:
      'Menggunakan nasi merah dan sayuran untuk meningkatkan serat, dengan protein dari telur dan porsi lemak yang terkontrol.',
    comparison_data: {
      gofood: {
        url: 'https://gofood.co.id/jakarta/restaurant/warteg-makmur/nasi-merah-telur-sayur',
      },
      grabfood: {
        url: 'https://food.grab.com/id/id/restaurant/warteg-makmur/nasi-merah-telur-sayur',
      },
      shopeefood: {
        url: 'https://shopeefood.co.id/jakarta/warteg-makmur/nasi-merah-telur-sayur',
      },
    },
  },
] as const;
