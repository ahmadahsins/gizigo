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
  @ApiOperation({ summary: 'Get list of foods with filters' })
  async getFoods(@Query() query: GetFoodsQueryDto) {
    return this.foodsService.getFoods(query);
  }

  @Get('search')
  @ApiOperation({ summary: 'Search foods by name or description' })
  async searchFoods(@Query('q') q: string) {
    return this.foodsService.getFoods({ q });
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get food details with price comparison' })
  async getFoodDetails(@Param('id') id: string) {
    return this.foodsService.getFoodDetails(id);
  }
}
