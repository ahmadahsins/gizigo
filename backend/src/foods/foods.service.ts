import { Injectable, NotFoundException } from '@nestjs/common';
import { FirebaseService } from '../firebase/firebase.service';
import { GetFoodsQueryDto } from './dto/get-foods-query.dto';
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
