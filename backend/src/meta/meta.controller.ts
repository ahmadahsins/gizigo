import { Controller, Get, Query } from '@nestjs/common';
import { ApiOperation, ApiQuery, ApiTags } from '@nestjs/swagger';
import { FOOD_CATEGORIES_META } from '../common/constants/food-categories';
import { NUTRITION_GRADES_META } from '../common/constants/nutrition-grades-meta';

@ApiTags('meta')
@Controller('meta')
export class MetaController {
  @Get('food-categories')
  @ApiOperation({ summary: 'Constants for home category chips + admin validation keys' })
  getFoodCategories() {
    return { items: FOOD_CATEGORIES_META };
  }

  @Get('nutrition-grades')
  @ApiOperation({
    summary: 'Nutrition tier labels (maps to `foods.nutrition_grade` + Label filter)',
  })
  getNutritionGrades() {
    return { items: NUTRITION_GRADES_META };
  }

  @Get('locations/search')
  @ApiOperation({
    summary:
      'Placeholder for map/search (returns empty until Google Places / Mapbox is wired)',
  })
  @ApiQuery({ name: 'q', required: false })
  searchLocations(@Query('q') q?: string) {
    return {
      query: q ?? '',
      items: [] as unknown[],
      note: 'Integrate a Places provider on the client or server later.',
    };
  }
}
