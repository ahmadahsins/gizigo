import { Injectable, NotFoundException } from '@nestjs/common';
import { FirebaseService } from '../firebase/firebase.service';
import { GetFoodsQueryDto } from './dto/get-foods-query.dto';
import { RecommendationsQueryDto } from './dto/recommendations-query.dto';
import { NutritionGrade } from '../common/enums/nutrition-grade.enum';
import { NutritionGoal } from '../common/enums/nutrition-goal.enum';
import * as geofire from 'geofire-common';

const PLATFORM_KEYS = ['gofood', 'grabfood', 'shopeefood'] as const;
type PlatformKey = (typeof PLATFORM_KEYS)[number];

const PLATFORM_LABEL: Record<PlatformKey, string> = {
  gofood: 'GoFood',
  grabfood: 'GrabFood',
  shopeefood: 'ShopeeFood',
};

@Injectable()
export class FoodsService {
  constructor(private firebaseService: FirebaseService) {}

  async getFoods(query: GetFoodsQueryDto) {
    const db = this.firebaseService.getFirestore();
    const page = query.page ?? 1;
    const limit = query.limit ?? 50;

    const snapshot = await db
      .collection('foods')
      .where('is_available', '==', true)
      .get();

    let foods: Record<string, unknown>[] = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    if (query.featured_only === true) {
      foods = foods.filter((f) => f['is_featured'] === true);
    }

    const merchantsMap = await this.loadMerchantsMap(db, foods);

    foods = foods.map((food) => {
      const mid = food['merchant_id'] as string | undefined;
      const merchantDoc = mid ? merchantsMap[mid] : undefined;
      return {
        ...food,
        vendor_name: (merchantDoc?.name as string | undefined) ?? null,
        image_url: food['photo_url'] ?? null,
        merchant_coordinates: merchantDoc?.coordinates ?? null,
      };
    });

    if (query.q) {
      const term = query.q.toLowerCase();
      foods = foods.filter(
        (f) =>
          (f['name'] && String(f['name']).toLowerCase().includes(term)) ||
          (f['description'] &&
            String(f['description']).toLowerCase().includes(term)),
      );
    }

    if (query.nutrition_grade) {
      foods = foods.filter(
        (f) => f['nutrition_grade'] === query.nutrition_grade,
      );
    }

    if (query.food_category) {
      foods = foods.filter((f) => f['food_category'] === query.food_category);
    }

    if (query.min_price !== undefined) {
      foods = foods.filter(
        (f) => Number(f['base_price']) >= query.min_price!,
      );
    }
    if (query.max_price !== undefined) {
      foods = foods.filter(
        (f) => Number(f['base_price']) <= query.max_price!,
      );
    }

    const hasUserLoc =
      query.lat !== undefined &&
      query.lng !== undefined &&
      !Number.isNaN(query.lat) &&
      !Number.isNaN(query.lng);

    if (hasUserLoc) {
      const center: [number, number] = [query.lat!, query.lng!];
      foods = foods.map((food) => {
        const coords = food['merchant_coordinates'] as
          | FirebaseFirestore.GeoPoint
          | undefined;
        let distance_in_km = Number.POSITIVE_INFINITY;
        if (coords) {
          const mLoc: [number, number] = [coords.latitude, coords.longitude];
          distance_in_km = geofire.distanceBetween(center, mLoc);
        }
        const { merchant_coordinates: _, ...rest } = food as Record<
          string,
          unknown
        >;
        return { ...rest, distance_in_km };
      });

      if (query.max_distance_km !== undefined) {
        foods = foods.filter(
          (f) => (f['distance_in_km'] as number) <= query.max_distance_km!,
        );
      }
    } else {
      foods = foods.map((food) => {
        const { merchant_coordinates: _, ...rest } = food as Record<
          string,
          unknown
        >;
        return rest;
      });
    }

    const sort =
      query.sort ?? (hasUserLoc ? 'distance' : 'recommended');

    if (sort === 'distance' && hasUserLoc) {
      foods.sort(
        (a, b) =>
          (a['distance_in_km'] as number) - (b['distance_in_km'] as number),
      );
    } else if (sort === 'price_asc') {
      foods.sort((a, b) => Number(a['base_price']) - Number(b['base_price']));
    } else {
      foods.sort((a, b) => {
        const scoreDiff =
          Number(b['recommendation_score'] ?? 0) -
          Number(a['recommendation_score'] ?? 0);
        if (scoreDiff !== 0) return scoreDiff;
        return Number(a['base_price']) - Number(b['base_price']);
      });
    }

    const total = foods.length;
    const start = (page - 1) * limit;
    const items = foods.slice(start, start + limit);

    return {
      items,
      total,
      page,
      limit,
      total_pages: Math.ceil(total / limit) || 1,
    };
  }

  async getFoodDetails(id: string) {
    const db = this.firebaseService.getFirestore();
    const doc = await db.collection('foods').doc(id).get();

    if (!doc.exists) {
      throw new NotFoundException('Food not found');
    }

    const foodData = doc.data();
    if (!foodData) {
      throw new NotFoundException('Food data is empty');
    }

    let comparisonData = foodData.comparison_data;
    if (comparisonData) {
      comparisonData = JSON.parse(JSON.stringify(comparisonData));

      PLATFORM_KEYS.forEach((provider) => {
        if (comparisonData[provider]?.price != null) {
          const fluctuation = Math.random() * 0.1 - 0.05;
          const simulatedPrice =
            comparisonData[provider].price * (1 + fluctuation);
          comparisonData[provider].simulated_price =
            Math.round(simulatedPrice / 100) * 100;
        }
      });
    }

    const merchantsMap = await this.loadMerchantsMap(db, [
      { merchant_id: foodData.merchant_id },
    ]);
    const mid = foodData.merchant_id as string | undefined;
    const merchantDoc = mid ? merchantsMap[mid] : undefined;
    const vendor_name = (merchantDoc?.name as string | undefined) ?? null;

    return {
      id: doc.id,
      ...foodData,
      vendor_name,
      image_url: foodData.photo_url ?? null,
      comparison_data: comparisonData ?? null,
      price_comparisons: this.buildPriceComparisons(comparisonData),
    };
  }

  /**
   * Home hero + rail: uses `nutrition_goal`, `food_preferences`, optional GPS,
   * and `nutritional_info` on foods when present.
   */
  async getRecommendations(uid: string, query: RecommendationsQueryDto) {
    const db = this.firebaseService.getFirestore();
    const userSnap = await db.collection('users').doc(uid).get();
    const user = userSnap.data() ?? {};

    const snapshot = await db
      .collection('foods')
      .where('is_available', '==', true)
      .get();

    let foods: Record<string, unknown>[] = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    const merchantsMap = await this.loadMerchantsMap(db, foods);

    const hasUserLoc =
      query.lat !== undefined &&
      query.lng !== undefined &&
      !Number.isNaN(query.lat) &&
      !Number.isNaN(query.lng);

    const center: [number, number] | null = hasUserLoc
      ? [query.lat!, query.lng!]
      : null;

    foods = foods.map((food) => {
      const mid = food['merchant_id'] as string | undefined;
      const merchantDoc = mid ? merchantsMap[mid] : undefined;
      let distance_in_km: number | undefined;
      if (center && merchantDoc?.coordinates) {
        const c = merchantDoc.coordinates as FirebaseFirestore.GeoPoint;
        distance_in_km = geofire.distanceBetween(center, [
          c.latitude,
          c.longitude,
        ]);
      }
      return {
        ...food,
        vendor_name: (merchantDoc?.name as string | undefined) ?? null,
        image_url: food['photo_url'] ?? null,
        distance_in_km,
      };
    });

    const usePersonalization =
      user['nutrition_goal'] != null ||
      (Array.isArray(user['food_preferences']) &&
        (user['food_preferences'] as unknown[]).length > 0);

    const scored = foods.map((food) => {
      const dist = food['distance_in_km'] as number | undefined;
      const raw = usePersonalization
        ? this.personalizationScore(food, user, dist)
        : this.genericFoodScore(food, dist);

      return {
        ...food,
        personalization_score: Math.round(raw * 100) / 100,
      };
    });

    const sortedByScore = [...scored].sort(
      (a, b) =>
        (b['personalization_score'] as number) -
        (a['personalization_score'] as number),
    );

    const featuredLimit = query.featured_limit ?? 1;
    const recLimit = query.limit ?? 15;

    const featured: Record<string, unknown>[] = [];
    const used = new Set<string>();

    if (featuredLimit > 0) {
      for (const f of sortedByScore) {
        if (featured.length >= featuredLimit) break;
        if (f['is_featured'] !== true) continue;
        const id = f['id'] as string;
        if (!used.has(id)) {
          featured.push(f);
          used.add(id);
        }
      }
      for (const f of sortedByScore) {
        if (featured.length >= featuredLimit) break;
        const id = f['id'] as string;
        if (!used.has(id)) {
          featured.push(f);
          used.add(id);
        }
      }
    }

    const recommendations: Record<string, unknown>[] = [];
    for (const f of sortedByScore) {
      if (recommendations.length >= recLimit) break;
      const id = f['id'] as string;
      if (!used.has(id)) {
        recommendations.push(f);
        used.add(id);
      }
    }

    return {
      featured,
      recommendations,
      context: {
        nutrition_goal: user['nutrition_goal'] ?? null,
        onboarding_completed: Boolean(user['onboarding_completed']),
        personalized: usePersonalization,
      },
    };
  }

  private genericFoodScore(
    food: Record<string, unknown>,
    distanceKm?: number,
  ): number {
    let score = Number(food['recommendation_score'] ?? 0);
    score += this.tierBonus(food['nutrition_grade'] as string | undefined);
    if (distanceKm != null && Number.isFinite(distanceKm)) {
      score += Math.max(0, 12 - distanceKm) * 0.6;
    }
    return score;
  }

  private personalizationScore(
    food: Record<string, unknown>,
    user: FirebaseFirestore.DocumentData,
    distanceKm?: number,
  ): number {
    const goal = user['nutrition_goal'] as string | undefined;
    let score = Number(food['recommendation_score'] ?? 0);
    score += this.tierBonus(food['nutrition_grade'] as string | undefined);

    const ni = (food['nutritional_info'] as Record<string, number>) ?? {};

    if (goal === NutritionGoal.DIET) {
      if (ni.calories != null) {
        score += Math.max(0, 650 - ni.calories) * 0.12;
      }
      if (ni.fat_g != null) {
        score -= ni.fat_g * 0.9;
      }
      if (ni.protein_g != null) {
        score += ni.protein_g * 0.35;
      }
    } else if (goal === NutritionGoal.BULKING) {
      score += Number(ni.protein_g ?? 0) * 2.4;
      if (ni.calories != null) {
        score += ni.calories * 0.015;
      }
    } else {
      score += Number(ni.protein_g ?? 0) * 0.55;
      if (ni.calories != null) {
        score -= Math.min(40, Math.abs(520 - ni.calories) * 0.04);
      }
    }

    const prefs = user['food_preferences'] as string[] | undefined;
    const labels = (food['health_labels'] as string[]) ?? [];
    if (prefs?.length && labels.length) {
      const lower = labels.map((l) => l.toLowerCase());
      for (const p of prefs) {
        const pl = p.toLowerCase().trim();
        if (!pl) continue;
        if (lower.some((l) => l.includes(pl) || pl.includes(l))) {
          score += 20;
        }
      }
    }

    if (distanceKm != null && Number.isFinite(distanceKm)) {
      score += Math.max(0, 12 - distanceKm) * 0.65;
    }

    return score;
  }

  private tierBonus(grade?: string): number {
    if (grade === NutritionGrade.EXCELLENT) return 34;
    if (grade === NutritionGrade.VERY_GOOD) return 22;
    if (grade === NutritionGrade.GOOD) return 12;
    return 0;
  }

  private buildPriceComparisons(comparisonData: Record<string, unknown> | null) {
    if (!comparisonData) return [];
    const rows: Array<{
      platform_key: PlatformKey;
      platform: string;
      price: number;
      base_price: number;
      order_url: string;
      icon_url: string | null;
    }> = [];

    for (const key of PLATFORM_KEYS) {
      const row = comparisonData[key] as
        | {
            price: number;
            simulated_price?: number;
            url: string;
            icon_url?: string;
          }
        | undefined;
      if (row?.price != null) {
        rows.push({
          platform_key: key,
          platform: PLATFORM_LABEL[key],
          price: row.simulated_price ?? row.price,
          base_price: row.price,
          order_url: row.url,
          icon_url: row.icon_url ?? null,
        });
      }
    }
    return rows;
  }

  private async loadMerchantsMap(
    db: FirebaseFirestore.Firestore,
    foods: Record<string, unknown>[],
  ): Promise<Record<string, FirebaseFirestore.DocumentData>> {
    const merchantIds = [
      ...new Set(
        foods.map((f) => f['merchant_id']).filter(Boolean) as string[],
      ),
    ];
    const merchantsMap: Record<string, FirebaseFirestore.DocumentData> = {};
    if (merchantIds.length === 0) return merchantsMap;

    for (let i = 0; i < merchantIds.length; i += 10) {
      const chunk = merchantIds.slice(i, i + 10);
      const merchantsSnapshot = await db
        .collection('merchants')
        .where('merchant_id', 'in', chunk)
        .get();
      merchantsSnapshot.forEach((doc) => {
        merchantsMap[doc.data().merchant_id] = doc.data();
      });
    }
    return merchantsMap;
  }
}
