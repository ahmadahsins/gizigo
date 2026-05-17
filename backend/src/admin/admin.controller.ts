import {
  Controller,
  Post,
  Put,
  Delete,
  Body,
  Param,
  UseGuards,
  NotFoundException,
  InternalServerErrorException,
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
import { FirebaseService } from '../firebase/firebase.service';
import { CreateFoodDto } from './dto/create-food.dto';
import { UpdateFoodDto } from './dto/update-food.dto';
import * as admin from 'firebase-admin';

@ApiTags('admin')
@Controller('admin')
@UseGuards(FirebaseAuthGuard, RolesGuard)
@Roles('admin')
@ApiBearerAuth()
export class AdminController {
  constructor(private firebaseService: FirebaseService) {}

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
    try {
      const db = this.firebaseService.getFirestore();

      // Auto-generate ID or use provided? For MVP, let's let Firestore auto-generate ID,
      // but schema says `food_id` as primary key. We can store the auto-generated doc ID as `food_id`.
      const foodRef = db.collection('foods').doc();
      const foodData = {
        food_id: foodRef.id,
        ...createFoodDto,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      };

      await foodRef.set(foodData);

      return { message: 'Food created successfully', id: foodRef.id };
    } catch (error) {
      throw new InternalServerErrorException('Failed to create food');
    }
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
    const db = this.firebaseService.getFirestore();
    const foodRef = db.collection('foods').doc(id);
    const doc = await foodRef.get();

    if (!doc.exists) {
      throw new NotFoundException('Food not found');
    }

    try {
      await foodRef.update({
        ...updateFoodDto,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { message: 'Food updated successfully' };
    } catch (error) {
      throw new InternalServerErrorException('Failed to update food');
    }
  }

  @Delete('foods/:id')
  @ApiOperation({ summary: 'Soft delete food entry' })
  @ApiOkResponse({
    schema: { example: { message: 'Food soft-deleted successfully' } },
  })
  async deleteFood(@Param('id') id: string) {
    const db = this.firebaseService.getFirestore();
    const foodRef = db.collection('foods').doc(id);
    const doc = await foodRef.get();

    if (!doc.exists) {
      throw new NotFoundException('Food not found');
    }

    try {
      // Soft delete
      await foodRef.update({
        is_available: false,
        deleted_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { message: 'Food soft-deleted successfully' };
    } catch (error) {
      throw new InternalServerErrorException('Failed to delete food');
    }
  }
}
