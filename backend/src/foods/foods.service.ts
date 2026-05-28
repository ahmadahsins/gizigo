import { Injectable, NotFoundException } from '@nestjs/common';
import { FirebaseService } from '../firebase/firebase.service';
import { GetFoodsQueryDto } from './dto/get-foods-query.dto';
import { RecommendationsQueryDto } from './dto/recommendations-query.dto';
import { NutritionGrade } from '../common/enums/nutrition-grade.enum';
import { NutritionGoal } from '../common/enums/nutrition-goal.enum';
import * as geofire from 'geofire-common';
import { AiService } from '../ai/ai.service';
import * as admin from 'firebase-admin';

const PLATFORM_KEYS = ['gofood', 'grabfood', 'shopeefood'] as const;
type PlatformKey = (typeof PLATFORM_KEYS)[number];
type ScoredFood = Record<string, unknown> & { personalization_score: number };
type StoredRecord = Record<string, unknown>;
type DeliveryLinksData = Partial<Record<PlatformKey, DeliveryLink>>;
type DeliveryLink = {
  url: string;
  icon_url?: string;
};

const PLATFORM_LABEL: Record<PlatformKey, string> = {
  gofood: 'GoFood',
  grabfood: 'GrabFood',
  shopeefood: 'ShopeeFood',
};

const PLATFORM_MARKUP_RANGE: Record<
  PlatformKey,
  { minimum: number; maximum: number }
> = {
  gofood: { minimum: 0.12, maximum: 0.18 },
  grabfood: { minimum: 0.08, maximum: 0.15 },
  shopeefood: { minimum: 0.05, maximum: 0.12 },
};
const PRICE_COMPARISON_BUCKET_HOURS = 6;
const PRICE_COMPARISON_BUCKET_MS =
  PRICE_COMPARISON_BUCKET_HOURS * 60 * 60 * 1000;
type PriceComparisonWindow = {
  bucketStartMs: number;
  updatedAt: string;
  validUntil: string;
};

@Injectable()
export class FoodsService {
  constructor(
    private firebaseService: FirebaseService,
    private readonly aiService: AiService,
  ) {}

  async getFoods(query: GetFoodsQueryDto) {
    const db = this.firebaseService.getFirestore();
    const page = query.page ?? 1;
    const limit = query.limit ?? 50;

    const snapshot = await db
      .collection('foods')
      .where('is_available', '==', true)
      .get();

    let foods: Record<string, unknown>[] = snapshot.docs.map((doc) =>
      this.publicStoredFood(doc.id, doc.data()),
    );

    if (query.featured_only === true) {
      foods = foods.filter((f) => f['is_featured'] === true);
    }

    const merchantsMap = await this.loadMerchantsMap(db, foods);

    foods = foods.filter((food) =>
      this.isFoodFromVisibleMerchant(food, merchantsMap),
    );

    foods = foods.map((food) => {
      const mid = food['merchant_id'] as string | undefined;
      const merchantDoc = mid ? merchantsMap[mid] : undefined;
      return {
        ...food,
        vendor_name: this.stringOrNull(merchantDoc?.['name']),
        image_url: food['photo_url'] ?? null,
        merchant_coordinates: this.readGeoPoint(merchantDoc?.['coordinates']),
      };
    });

    if (query.q) {
      const term = query.q.toLowerCase();
      foods = foods.filter(
        (f) =>
          this.matchesText(f['name'], term) ||
          this.matchesText(f['description'], term),
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
      foods = foods.filter((f) => Number(f['base_price']) >= query.min_price!);
    }
    if (query.max_price !== undefined) {
      foods = foods.filter((f) => Number(f['base_price']) <= query.max_price!);
    }

    const center: [number, number] | null =
      query.lat !== undefined &&
      query.lng !== undefined &&
      !Number.isNaN(query.lat) &&
      !Number.isNaN(query.lng)
        ? [query.lat, query.lng]
        : null;
    const hasUserLoc = center !== null;

    if (center) {
      foods = foods.map((food) => {
        const coords = this.readGeoPoint(food['merchant_coordinates']);
        let distance_in_km = Number.POSITIVE_INFINITY;
        if (coords) {
          const mLoc: [number, number] = [coords.latitude, coords.longitude];
          distance_in_km = geofire.distanceBetween(center, mLoc);
        }
        const rest = { ...food };
        delete rest['merchant_coordinates'];
        return { ...rest, distance_in_km };
      });

      if (query.max_distance_km !== undefined) {
        foods = foods.filter(
          (f) => (f['distance_in_km'] as number) <= query.max_distance_km!,
        );
      }
    } else {
      foods = foods.map((food) => {
        const rest = { ...food };
        delete rest['merchant_coordinates'];
        return rest;
      });
    }

    const sort = query.sort ?? (hasUserLoc ? 'distance' : 'recommended');

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

    const safeFoodData = this.toRecord(foodData);
    const deliveryLinks = this.readDeliveryLinks(
      safeFoodData['comparison_data'],
    );

    const merchantsMap = await this.loadMerchantsMap(db, [
      { merchant_id: safeFoodData['merchant_id'] },
    ]);
    const mid = this.optionalString(safeFoodData['merchant_id']);
    const merchantDoc = mid ? merchantsMap[mid] : undefined;
    if (merchantDoc?.['is_active'] === false) {
      throw new NotFoundException('Food not found');
    }
    const vendor_name = this.stringOrNull(merchantDoc?.['name']);
    const priceComparisonWindow = this.priceComparisonWindow();
    const priceComparisons = this.buildPriceComparisons(
      doc.id,
      Number(safeFoodData['base_price']),
      deliveryLinks,
      priceComparisonWindow.bucketStartMs,
    );

    delete safeFoodData['recipe'];
    return {
      id: doc.id,
      ...safeFoodData,
      vendor_name,
      image_url: safeFoodData['photo_url'] ?? null,
      comparison_data: deliveryLinks ?? null,
      price_comparisons: priceComparisons,
      price_comparison_updated_at:
        priceComparisons.length > 0 ? priceComparisonWindow.updatedAt : null,
      price_comparison_valid_until:
        priceComparisons.length > 0 ? priceComparisonWindow.validUntil : null,
    };
  }

  /**
   * Home hero + rail: Gemini ranks available foods when profile context exists,
   * while the local score remains a resilient fallback.
   */
  async getRecommendations(uid: string, query: RecommendationsQueryDto) {
    const db = this.firebaseService.getFirestore();
    const userSnap = await db.collection('users').doc(uid).get();
    const user = this.toRecord(userSnap.data());

    const snapshot = await db
      .collection('foods')
      .where('is_available', '==', true)
      .get();

    let foods: Record<string, unknown>[] = snapshot.docs.map((doc) =>
      this.publicStoredFood(doc.id, doc.data()),
    );

    const merchantsMap = await this.loadMerchantsMap(db, foods);

    foods = foods.filter((food) =>
      this.isFoodFromVisibleMerchant(food, merchantsMap),
    );

    const center: [number, number] | null =
      query.lat !== undefined &&
      query.lng !== undefined &&
      !Number.isNaN(query.lat) &&
      !Number.isNaN(query.lng)
        ? [query.lat, query.lng]
        : null;

    foods = foods.map((food) => {
      const mid = food['merchant_id'] as string | undefined;
      const merchantDoc = mid ? merchantsMap[mid] : undefined;
      let distance_in_km: number | undefined;
      const coordinates = this.readGeoPoint(merchantDoc?.['coordinates']);
      if (center && coordinates) {
        distance_in_km = geofire.distanceBetween(center, [
          coordinates.latitude,
          coordinates.longitude,
        ]);
      }
      return {
        ...food,
        vendor_name: this.stringOrNull(merchantDoc?.['name']),
        image_url: food['photo_url'] ?? null,
        distance_in_km,
      };
    });

    const usePersonalization = this.hasPersonalizationProfile(user);
    const preferenceFilter = usePersonalization
      ? this.applyFoodPreferenceHardFilter(foods, user)
      : { foods, applied: [] };
    const recommendationPool = preferenceFilter.foods;

    const scored = recommendationPool.map((food) => {
      const dist = food['distance_in_km'] as number | undefined;
      const raw = usePersonalization
        ? this.personalizationScore(food, user, dist)
        : this.genericFoodScore(food, dist);

      return {
        ...food,
        personalization_score: Math.round(raw * 100) / 100,
      };
    });

    const locallySorted = [...scored].sort(
      (a, b) => b.personalization_score - a.personalization_score,
    );
    let sortedByScore = locallySorted;
    let recommendationSource: 'gemini' | 'fallback' = 'fallback';

    if (usePersonalization && recommendationPool.length > 0) {
      try {
        const aiOrder = await this.aiService.rankFoodsForUser(
          this.recommendationUserProfile(user),
          recommendationPool.map((food) => ({
            id: food['id'] as string,
            name: food['name'],
            description: food['description'],
            nutrition_grade: food['nutrition_grade'],
            food_category: food['food_category'],
            health_labels: food['health_labels'],
            nutritional_info: food['nutritional_info'],
          })),
        );
        const aiSorted = this.mergeAiRanking(aiOrder, locallySorted);
        if (aiSorted) {
          sortedByScore = aiSorted;
          recommendationSource = 'gemini';
        }
      } catch {
        recommendationSource = 'fallback';
      }
    }

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
        recommendation_source: recommendationSource,
        hard_filters: preferenceFilter.applied,
      },
    };
  }

  private hasPersonalizationProfile(user: StoredRecord): boolean {
    const scalarFields = [
      'gender',
      'age',
      'weight_kg',
      'height_cm',
      'nutrition_goal',
    ];
    const arrayFields = [
      'food_preferences',
      'dietary_restrictions',
      'taste_profile',
    ];
    return (
      scalarFields.some((field) => user[field] != null) ||
      arrayFields.some(
        (field) => Array.isArray(user[field]) && user[field].length > 0,
      )
    );
  }

  private recommendationUserProfile(user: StoredRecord) {
    return {
      gender: user['gender'] ?? null,
      age: user['age'] ?? null,
      weight_kg: user['weight_kg'] ?? null,
      height_cm: user['height_cm'] ?? null,
      nutrition_goal: user['nutrition_goal'] ?? null,
      food_preferences: user['food_preferences'] ?? [],
      dietary_restrictions: user['dietary_restrictions'] ?? [],
      taste_profile: user['taste_profile'] ?? [],
    };
  }

  private mergeAiRanking(
    orderedIds: string[],
    locallySorted: ScoredFood[],
  ): ScoredFood[] | null {
    const byId = new Map(
      locallySorted.map((food) => [food['id'] as string, food]),
    );
    const used = new Set<string>();
    const ranked: ScoredFood[] = [];

    for (const id of orderedIds) {
      const food = byId.get(id);
      if (food && !used.has(id)) {
        ranked.push(food);
        used.add(id);
      }
    }
    if (ranked.length === 0) return null;

    for (const food of locallySorted) {
      const id = food['id'] as string;
      if (!used.has(id)) ranked.push(food);
    }
    return ranked;
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

  private publicStoredFood(
    id: string,
    value: unknown,
  ): Record<string, unknown> {
    const safeFood = this.toRecord(value);
    delete safeFood['recipe'];
    return { id, ...safeFood };
  }

  private personalizationScore(
    food: Record<string, unknown>,
    user: StoredRecord,
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

  private applyFoodPreferenceHardFilter(
    foods: Record<string, unknown>[],
    user: StoredRecord,
  ): { foods: Record<string, unknown>[]; applied: string[] } {
    const hardFilters = this.foodPreferenceHardFilters(user);
    if (hardFilters.length === 0) return { foods, applied: [] };

    const filtered = foods.filter((food) =>
      hardFilters.every((filter) => this.matchesHardPreference(food, filter)),
    );

    if (filtered.length === 0) {
      return { foods, applied: [] };
    }

    return { foods: filtered, applied: hardFilters };
  }

  private foodPreferenceHardFilters(user: StoredRecord): string[] {
    const preferences = this.stringArray(user['food_preferences']);
    const filters = new Set<string>();

    for (const preference of preferences) {
      const normalized = this.normalizedPreferenceKey(preference);
      if (
        normalized.includes('vegetarian') ||
        normalized.includes('vegan') ||
        normalized.includes('plantbased')
      ) {
        filters.add('vegetarian');
      }
      if (normalized.includes('glutenfree')) {
        filters.add('gluten_free');
      }
    }

    return [...filters];
  }

  private matchesHardPreference(
    food: Record<string, unknown>,
    filter: string,
  ): boolean {
    const searchable = [
      ...this.stringArray(food['health_labels']),
      this.stringOrNull(food['food_category']),
      this.stringOrNull(food['name']),
      this.stringOrNull(food['description']),
    ]
      .filter((value): value is string => Boolean(value))
      .map((value) => this.normalizedPreferenceKey(value));

    if (filter === 'vegetarian') {
      return searchable.some(
        (value) =>
          value.includes('vegetarian') ||
          value.includes('vegan') ||
          value.includes('plantbased'),
      );
    }

    if (filter === 'gluten_free') {
      return searchable.some((value) => value.includes('glutenfree'));
    }

    return true;
  }

  private tierBonus(grade?: string): number {
    if (grade === NutritionGrade.EXCELLENT) return 34;
    if (grade === NutritionGrade.VERY_GOOD) return 22;
    if (grade === NutritionGrade.GOOD) return 12;
    return 0;
  }

  private buildPriceComparisons(
    foodId: string,
    basePrice: number,
    deliveryLinks: DeliveryLinksData | null,
    bucketStartMs: number,
  ) {
    if (!deliveryLinks || !Number.isFinite(basePrice) || basePrice < 0) {
      return [];
    }
    const rows: Array<{
      platform_key: PlatformKey;
      platform: string;
      price: number;
      base_price: number;
      order_url: string;
      icon_url: string | null;
    }> = [];

    for (const key of PLATFORM_KEYS) {
      const link = deliveryLinks[key];
      if (link) {
        rows.push({
          platform_key: key,
          platform: PLATFORM_LABEL[key],
          price: this.simulatedPlatformPrice(
            foodId,
            key,
            basePrice,
            bucketStartMs,
          ),
          base_price: basePrice,
          order_url: link.url,
          icon_url: link.icon_url ?? null,
        });
      }
    }
    return rows;
  }

  private async loadMerchantsMap(
    db: FirebaseFirestore.Firestore,
    foods: Record<string, unknown>[],
  ): Promise<Record<string, StoredRecord>> {
    const merchantIds = [
      ...new Set(
        foods.map((f) => f['merchant_id']).filter(Boolean) as string[],
      ),
    ];
    const merchantsMap: Record<string, StoredRecord> = {};
    if (merchantIds.length === 0) return merchantsMap;

    for (let i = 0; i < merchantIds.length; i += 10) {
      const chunk = merchantIds.slice(i, i + 10);
      const merchantsSnapshot = await db
        .collection('merchants')
        .where('merchant_id', 'in', chunk)
        .get();
      merchantsSnapshot.forEach((doc) => {
        const merchant = this.toRecord(doc.data());
        const merchantId = this.optionalString(merchant['merchant_id']);
        if (merchantId) merchantsMap[merchantId] = merchant;
      });
    }
    return merchantsMap;
  }

  private toRecord(value: unknown): StoredRecord {
    return value !== null && typeof value === 'object'
      ? { ...(value as StoredRecord) }
      : {};
  }

  private optionalString(value: unknown): string | undefined {
    return typeof value === 'string' ? value : undefined;
  }

  private stringOrNull(value: unknown): string | null {
    return this.optionalString(value) ?? null;
  }

  private stringArray(value: unknown): string[] {
    return Array.isArray(value)
      ? value.filter((item): item is string => typeof item === 'string')
      : [];
  }

  private normalizedPreferenceKey(value: string): string {
    return value.toLowerCase().replace(/[^a-z0-9]+/g, '');
  }

  private matchesText(value: unknown, term: string): boolean {
    return typeof value === 'string' && value.toLowerCase().includes(term);
  }

  private isFoodFromVisibleMerchant(
    food: Record<string, unknown>,
    merchantsMap: Record<string, StoredRecord>,
  ): boolean {
    const merchantId = this.optionalString(food['merchant_id']);
    return !merchantId || merchantsMap[merchantId]?.['is_active'] !== false;
  }

  private readGeoPoint(value: unknown): FirebaseFirestore.GeoPoint | undefined {
    return value instanceof admin.firestore.GeoPoint ? value : undefined;
  }

  private readDeliveryLinks(value: unknown): DeliveryLinksData | null {
    const raw = this.toRecord(value);
    const data: DeliveryLinksData = {};
    for (const key of PLATFORM_KEYS) {
      const row = this.toRecord(raw[key]);
      const url = row['url'];
      if (typeof url === 'string') {
        data[key] = {
          url,
          icon_url: this.optionalString(row['icon_url']),
        };
      }
    }
    return Object.keys(data).length ? data : null;
  }

  private simulatedPlatformPrice(
    foodId: string,
    platform: PlatformKey,
    basePrice: number,
    bucketStartMs: number,
  ): number {
    const range = PLATFORM_MARKUP_RANGE[platform];
    const fraction = this.stableFraction(
      `${foodId}:${platform}:${bucketStartMs}`,
    );
    const markup = range.minimum + fraction * (range.maximum - range.minimum);
    return Math.round((basePrice * (1 + markup)) / 100) * 100;
  }

  private priceComparisonWindow(now = new Date()): PriceComparisonWindow {
    const bucketStartMs =
      Math.floor(now.getTime() / PRICE_COMPARISON_BUCKET_MS) *
      PRICE_COMPARISON_BUCKET_MS;
    return {
      bucketStartMs,
      updatedAt: new Date(bucketStartMs).toISOString(),
      validUntil: new Date(
        bucketStartMs + PRICE_COMPARISON_BUCKET_MS,
      ).toISOString(),
    };
  }

  private stableFraction(value: string): number {
    let hash = 2166136261;
    for (let index = 0; index < value.length; index += 1) {
      hash ^= value.charCodeAt(index);
      hash = Math.imul(hash, 16777619);
    }
    return (hash >>> 0) / 4294967295;
  }
}
