import { Controller, Get, Query } from '@nestjs/common';
import {
  ApiOkResponse,
  ApiOperation,
  ApiQuery,
  ApiTags,
} from '@nestjs/swagger';
import { FOOD_CATEGORIES_META } from '../common/constants/food-categories';
import { NUTRITION_GRADES_META } from '../common/constants/nutrition-grades-meta';
import { NUTRITION_GOALS_META } from '../common/constants/nutrition-goals-meta';
import { META_CATEGORIES_EXAMPLE } from '../swagger/api-examples';

@ApiTags('meta')
@Controller('meta')
export class MetaController {
  @Get('food-categories')
  @ApiOperation({
    summary: 'Constants for home category chips + admin validation keys',
  })
  @ApiOkResponse({
    schema: { example: META_CATEGORIES_EXAMPLE },
  })
  getFoodCategories() {
    return { items: FOOD_CATEGORIES_META };
  }

  @Get('nutrition-grades')
  @ApiOperation({
    summary:
      'Nutrition tier labels (maps to `foods.nutrition_grade` + Label filter)',
  })
  @ApiOkResponse({
    schema: {
      example: {
        items: [
          {
            key: 'EXCELLENT',
            label_en: 'Excellent',
            label_id: 'Sangat baik',
          },
        ],
      },
    },
  })
  getNutritionGrades() {
    return { items: NUTRITION_GRADES_META };
  }

  @Get('nutrition-goals')
  @ApiOperation({
    summary: 'Onboarding goals for `PATCH /users/me` (`nutrition_goal`)',
    description:
      'Shown on signup wizard; drives `/foods/recommendations` scoring.',
  })
  @ApiOkResponse({
    schema: {
      example: {
        items: [
          {
            key: 'DIET',
            label_en: 'Diet / cut',
            label_id: 'Diet / defisit kalori',
            hint: 'Prioritizes lower calories…',
          },
        ],
      },
    },
  })
  getNutritionGoals() {
    return { items: NUTRITION_GOALS_META };
  }

  @Get('locations/search')
  @ApiOperation({
    summary:
      'Placeholder for map/search (returns empty until Google Places / Mapbox is wired)',
  })
  @ApiQuery({ name: 'q', required: false })
  @ApiOkResponse({
    schema: {
      example: {
        query: 'UGM',
        items: [],
        note: 'Integrate a Places provider on the client or server later.',
      },
    },
  })
  searchLocations(@Query('q') q?: string) {
    return {
      query: q ?? '',
      items: [] as unknown[],
      note: 'Integrate a Places provider on the client or server later.',
    };
  }
}
