import {
  Controller,
  Post,
  Put,
  Delete,
  Body,
  Param,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiTags,
  ApiOperation,
  ApiBody,
  ApiOkResponse,
} from '@nestjs/swagger';
import { ADMIN_CREATE_FOOD_BODY_EXAMPLE } from '../swagger/api-examples';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { UserRole } from '../common/enums/user-role.enum';
import { FoodsManagementService } from '../foods/foods-management.service';
import { CreateFoodDto } from './dto/create-food.dto';
import { UpdateFoodDto } from './dto/update-food.dto';

@ApiTags('admin')
@Controller('admin')
@UseGuards(FirebaseAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
@ApiBearerAuth()
export class AdminController {
  constructor(private readonly foodsManagementService: FoodsManagementService) {}

  @Post('foods')
  @ApiOperation({
    summary: 'Create new food entry',
    description:
      'Persist `nutrition_grade`, `food_category`, optional `nutritional_info` for recommendations.',
  })
  @ApiBody({
    type: CreateFoodDto,
    examples: { default: { value: ADMIN_CREATE_FOOD_BODY_EXAMPLE } },
  })
  @ApiOkResponse({
    schema: {
      example: { message: 'Food created successfully', id: 'autoFirestoreDocId' },
    },
  })
  async createFood(@Body() createFoodDto: CreateFoodDto) {
    return this.foodsManagementService.createFood(createFoodDto, {
      role: UserRole.ADMIN,
    });
  }

  @Put('foods/:id')
  @ApiOperation({
    summary: 'Update food entry',
    description: 'Partial body allowed — same shape as create.',
  })
  @ApiBody({
    type: UpdateFoodDto,
    examples: {
      patchPrice: {
        summary: 'Update price only',
        value: { base_price: 18500 },
      },
    },
  })
  @ApiOkResponse({
    schema: { example: { message: 'Food updated successfully' } },
  })
  async updateFood(
    @Param('id') id: string,
    @Body() updateFoodDto: UpdateFoodDto,
  ) {
    return this.foodsManagementService.updateFood(id, updateFoodDto, {
      role: UserRole.ADMIN,
    });
  }

  @Delete('foods/:id')
  @ApiOperation({ summary: 'Soft delete food entry' })
  @ApiOkResponse({
    schema: { example: { message: 'Food soft-deleted successfully' } },
  })
  async deleteFood(@Param('id') id: string) {
    return this.foodsManagementService.deleteFood(id, {
      role: UserRole.ADMIN,
    });
  }
}
