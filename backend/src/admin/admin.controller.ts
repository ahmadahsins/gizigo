import {
  Controller,
  Post,
  Put,
  Delete,
  Body,
  HttpStatus,
  Param,
  ParseFilePipeBuilder,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiTags,
  ApiOperation,
  ApiBody,
  ApiConsumes,
  ApiOkResponse,
} from '@nestjs/swagger';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { ADMIN_CREATE_FOOD_BODY_EXAMPLE } from '../swagger/api-examples';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { UserRole } from '../common/enums/user-role.enum';
import type { UploadedImageFile } from '../common/types/uploaded-image-file';
import { FoodsManagementService } from '../foods/foods-management.service';
import { CreateFoodDto } from './dto/create-food.dto';
import { UpdateFoodDto } from './dto/update-food.dto';

@ApiTags('admin')
@Controller('admin')
@UseGuards(FirebaseAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
@ApiBearerAuth()
export class AdminController {
  constructor(
    private readonly foodsManagementService: FoodsManagementService,
  ) {}

  @Post('foods')
  @ApiOperation({
    summary: 'Create new food entry',
    description:
      'Requires a request-only `recipe`. Gemini generates nutrition fields and rejects menus below GOOD; recipe ingredients are never persisted.',
  })
  @ApiBody({
    type: CreateFoodDto,
    examples: { default: { value: ADMIN_CREATE_FOOD_BODY_EXAMPLE } },
  })
  @ApiOkResponse({
    schema: {
      example: {
        message: 'Food created successfully',
        id: 'autoFirestoreDocId',
      },
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

  @Post('foods/:id/photo')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(),
      limits: { fileSize: 5 * 1024 * 1024 },
    }),
  )
  @ApiOperation({
    summary: 'Upload or replace a food photo',
    description:
      'Accepts one JPEG, PNG, or WebP image (max 5 MB), uploads it to Cloudinary, and persists `photo_url`.',
  })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      required: ['file'],
      properties: { file: { type: 'string', format: 'binary' } },
    },
  })
  @ApiOkResponse({
    schema: {
      example: {
        message: 'Food photo uploaded successfully',
        food_id: 'foodDocId1',
        photo_url:
          'https://res.cloudinary.com/demo/image/upload/gizigo/foods/foodDocId1.jpg',
      },
    },
  })
  async uploadFoodPhoto(
    @Param('id') id: string,
    @UploadedFile(
      new ParseFilePipeBuilder()
        .addFileTypeValidator({ fileType: /(jpeg|jpg|png|webp)$/ })
        .addMaxSizeValidator({ maxSize: 5 * 1024 * 1024 })
        .build({ errorHttpStatusCode: HttpStatus.UNPROCESSABLE_ENTITY }),
    )
    file: UploadedImageFile,
  ) {
    return this.foodsManagementService.uploadFoodPhoto(id, file, {
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
