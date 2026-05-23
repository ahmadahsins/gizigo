import {
  Body,
  Controller,
  Delete,
  Get,
  HttpStatus,
  Param,
  Patch,
  ParseFilePipeBuilder,
  Post,
  Put,
  Query,
  Req,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiBody,
  ApiConsumes,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import type { UploadedImageFile } from '../common/types/uploaded-image-file';
import { MerchantsService } from '../merchants/merchants.service';
import { FoodsManagementService } from '../foods/foods-management.service';
import { UpdateMerchantProfileDto } from '../merchants/dto/update-merchant-profile.dto';
import { CreateMerchantFoodDto } from './dto/create-merchant-food.dto';
import { UpdateMerchantFoodDto } from './dto/update-merchant-food.dto';
import { ListMerchantFoodsQueryDto } from './dto/list-merchant-foods-query.dto';
import {
  MERCHANT_CREATE_FOOD_BODY_EXAMPLE,
  MERCHANT_PROFILE_EXAMPLE,
} from '../swagger/api-examples';

@ApiTags('merchant')
@Controller('merchant')
@UseGuards(FirebaseAuthGuard, RolesGuard)
@Roles(UserRole.MERCHANT)
@ApiBearerAuth()
export class MerchantController {
  constructor(
    private readonly merchantsService: MerchantsService,
    private readonly foodsManagementService: FoodsManagementService,
  ) {}

  @Get('me')
  @ApiOperation({ summary: 'Get logged-in merchant store profile' })
  @ApiOkResponse({ schema: { example: MERCHANT_PROFILE_EXAMPLE } })
  async getMe(@Req() req: { merchantId: string }) {
    return this.merchantsService.getMerchant(req.merchantId);
  }

  @Patch('me')
  @ApiOperation({ summary: 'Update logged-in merchant store profile' })
  @ApiOkResponse({ schema: { example: MERCHANT_PROFILE_EXAMPLE } })
  async patchMe(
    @Req() req: { merchantId: string },
    @Body() dto: UpdateMerchantProfileDto,
  ) {
    return this.merchantsService.updateMerchant(req.merchantId, dto);
  }

  @Get('foods')
  @ApiOperation({ summary: 'List foods owned by the logged-in merchant' })
  async listFoods(
    @Req() req: { merchantId: string; userRole: UserRole },
    @Query() query: ListMerchantFoodsQueryDto,
  ) {
    return this.foodsManagementService.listFoodsForMerchant(
      req.merchantId,
      query.page,
      query.limit,
    );
  }

  @Post('foods')
  @ApiOperation({
    summary: 'Create a food for the logged-in merchant',
    description:
      'Requires request-only `recipe`; generated nutrition is saved only when its grade is at least GOOD. The recipe is never saved.',
  })
  @ApiBody({
    type: CreateMerchantFoodDto,
    examples: { default: { value: MERCHANT_CREATE_FOOD_BODY_EXAMPLE } },
  })
  async createFood(
    @Req() req: { merchantId: string; userRole: UserRole },
    @Body() dto: CreateMerchantFoodDto,
  ) {
    return this.foodsManagementService.createFood(dto, {
      role: req.userRole,
      merchantId: req.merchantId,
    });
  }

  @Put('foods/:id')
  @ApiOperation({
    summary: 'Update a food owned by the logged-in merchant',
    description:
      'Send `recipe` only to refresh generated nutrition. Recipe ingredients are not persisted.',
  })
  async updateFood(
    @Req() req: { merchantId: string; userRole: UserRole },
    @Param('id') id: string,
    @Body() dto: UpdateMerchantFoodDto,
  ) {
    return this.foodsManagementService.updateFood(id, dto, {
      role: req.userRole,
      merchantId: req.merchantId,
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
    summary: 'Upload or replace a photo for a food owned by this merchant',
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
    @Req() req: { merchantId: string; userRole: UserRole },
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
      role: req.userRole,
      merchantId: req.merchantId,
    });
  }

  @Delete('foods/:id')
  @ApiOperation({
    summary: 'Soft-delete a food owned by the logged-in merchant',
  })
  async deleteFood(
    @Req() req: { merchantId: string; userRole: UserRole },
    @Param('id') id: string,
  ) {
    return this.foodsManagementService.deleteFood(id, {
      role: req.userRole,
      merchantId: req.merchantId,
    });
  }
}
