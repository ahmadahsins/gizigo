import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags, ApiOperation } from '@nestjs/swagger';
import { FoodsService } from './foods.service';
import { GetFoodsQueryDto } from './dto/get-foods-query.dto';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';

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
  async searchFoods(@Query() query: GetFoodsQueryDto) {
    return this.foodsService.getFoods(query);
  }

  @Get(':id')
  @ApiOperation({
    summary: 'Food detail + simulated multi-platform prices',
    description:
      'Includes `price_comparisons` array for Flutter list UI and optional per-platform `icon_url`.',
  })
  async getFoodDetails(@Param('id') id: string) {
    return this.foodsService.getFoodDetails(id);
  }
}
