import { Injectable, NotFoundException } from '@nestjs/common';
import { FirebaseService } from '../firebase/firebase.service';
import { GetFoodsQueryDto } from './dto/get-foods-query.dto';
import * as geofire from 'geofire-common';

@Injectable()
export class FoodsService {
  constructor(private firebaseService: FirebaseService) {}

  async getFoods(query: GetFoodsQueryDto) {
    const db = this.firebaseService.getFirestore();
    let foodsRef: FirebaseFirestore.Query = db
      .collection('foods')
      .where('is_available', '==', true);

    if (query.category) {
      foodsRef = foodsRef.where(
        'health_labels',
        'array-contains',
        query.category,
      );
    }

    const snapshot = await foodsRef.get();
    let foods = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));

    // Simple text search filter
    if (query.q) {
      const searchTerm = query.q.toLowerCase();
      foods = foods.filter(
        (f) =>
          (f['name'] && f['name'].toLowerCase().includes(searchTerm)) ||
          (f['description'] &&
            f['description'].toLowerCase().includes(searchTerm)),
      );
    }

    // Location sorting
    if (query.lat !== undefined && query.lng !== undefined) {
      const center: [number, number] = [query.lat, query.lng];

      const merchantIds = [
        ...new Set(foods.map((f) => f['merchant_id']).filter((id) => id)),
      ];
      if (merchantIds.length > 0) {
        // Chunk requests since Firestore 'in' query has a limit of 10
        const merchantsMap = {};
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

        foods = foods.map((food) => {
          const merchant = merchantsMap[food['merchant_id'] as string];
          if (merchant && merchant.coordinates) {
            const mLoc: [number, number] = [
              merchant.coordinates.latitude,
              merchant.coordinates.longitude,
            ];
            const distanceInKm = geofire.distanceBetween(center, mLoc);
            return { ...food, distanceInKm, merchant };
          }
          return { ...food, distanceInKm: Infinity, merchant };
        });

        // Sort by distance
        foods.sort(
          (a, b) =>
            (a['distanceInKm'] as number) - (b['distanceInKm'] as number),
        );
      }
    }

    return foods;
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

    // Price comparison simulation logic (+- 5%)
    let comparisonData = foodData.comparison_data;
    if (comparisonData) {
      comparisonData = JSON.parse(JSON.stringify(comparisonData));

      ['gofood', 'grabfood', 'shopeefood'].forEach((provider) => {
        if (comparisonData[provider] && comparisonData[provider].price) {
          const fluctuation = Math.random() * 0.1 - 0.05; // -5% to +5%
          const simulatedPrice =
            comparisonData[provider].price * (1 + fluctuation);
          // Round to nearest 100
          comparisonData[provider].simulated_price =
            Math.round(simulatedPrice / 100) * 100;
        }
      });

      foodData.comparison_data = comparisonData;
    }

    return { id: doc.id, ...foodData };
  }
}
