import { Controller, Get, Param, Query, Req, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiTags,
  ApiOperation,
  ApiOkResponse,
} from '@nestjs/swagger';
import { FoodsService } from './foods.service';
import { GetFoodsQueryDto } from './dto/get-foods-query.dto';
import { RecommendationsQueryDto } from './dto/recommendations-query.dto';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import {
  FOODS_PAGINATED_EXAMPLE,
  FOOD_DETAIL_EXAMPLE,
  RECOMMENDATIONS_RESPONSE_EXAMPLE,
} from '../swagger/api-examples';

@ApiTags('foods')
@Controller('foods')
@UseGuards(FirebaseAuthGuard)
@ApiBearerAuth()
export class FoodsController {
  constructor(private readonly foodsService: FoodsService) {}

  @Get()
  @ApiOperation({
    summary: 'Paginated food list with nutrition, category, price, distance filters',
    description:
      'Returns `{ items, total, page, limit, total_pages }`. Each item includes `vendor_name` and `image_url`. Pass `lat`/`lng` for `distance_in_km` and distance sort.',
  })
  @ApiOkResponse({
    schema: { example: FOODS_PAGINATED_EXAMPLE },
  })
  async getFoods(@Query() query: GetFoodsQueryDto) {
    return this.foodsService.getFoods(query);
  }

  @Get('search')
  @ApiOperation({
    summary:
      'Search foods — identical query params to GET /foods (includes q + filters)',
    description:
      'Use on the dedicated search screen so Label / Price / Range filters combine with text search.',
  })
  @ApiOkResponse({
    schema: { example: FOODS_PAGINATED_EXAMPLE },
  })
  async searchFoods(@Query() query: GetFoodsQueryDto) {
    return this.foodsService.getFoods(query);
  }

  @Get('recommendations')
  @ApiOperation({
    summary:
      'Personalized home sections — “You Might Like This” + recommendations rail',
    description:
      '`featured`: prefers `is_featured` then highest score. Scoring uses `PATCH /users/me` fields (`nutrition_goal`, `food_preferences`) and `foods.nutritional_info` when available. Without onboarding data, falls back to `recommendation_score` + nutrition tier.',
  })
  @ApiOkResponse({
    schema: { example: RECOMMENDATIONS_RESPONSE_EXAMPLE },
  })
  async getRecommendations(
    @Req() req: { user: { uid: string } },
    @Query() query: RecommendationsQueryDto,
  ) {
    return this.foodsService.getRecommendations(req.user.uid, query);
  }

  @Get(':id')
  @ApiOperation({
    summary: 'Food detail + simulated multi-platform prices',
    description:
      'Includes `price_comparisons` array for Flutter list UI and optional per-platform `icon_url`.',
  })
  @ApiOkResponse({
    schema: { example: FOOD_DETAIL_EXAMPLE },
  })
  async getFoodDetails(@Param('id') id: string) {
    return this.foodsService.getFoodDetails(id);
  }
}
