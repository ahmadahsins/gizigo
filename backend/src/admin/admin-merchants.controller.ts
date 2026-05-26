import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  Query,
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
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { UserRole } from '../common/enums/user-role.enum';
import {
  buildImageUploadPipe,
  IMAGE_UPLOAD_MAX_SIZE_BYTES,
} from '../common/pipes/image-upload.pipe';
import type { UploadedImageFile } from '../common/types/uploaded-image-file';
import { FoodsManagementService } from '../foods/foods-management.service';
import { CreateMerchantDto } from '../merchants/dto/create-merchant.dto';
import { UpdateMerchantDto } from '../merchants/dto/update-merchant.dto';
import { ListMerchantsQueryDto } from '../merchants/dto/list-merchants-query.dto';
import { ListMerchantFoodsQueryDto } from '../merchant/dto/list-merchant-foods-query.dto';
import {
  ADMIN_CREATE_MERCHANT_BODY_EXAMPLE,
  MERCHANT_PROFILE_EXAMPLE,
} from '../swagger/api-examples';
import { AdminMerchantsService } from './admin-merchants.service';
import { CreateMerchantScopedFoodDto } from './dto/create-merchant-scoped-food.dto';
import { UpdateMerchantScopedFoodDto } from './dto/update-merchant-scoped-food.dto';

@ApiTags('admin')
@Controller('admin/merchants')
@UseGuards(FirebaseAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
@ApiBearerAuth()
export class AdminMerchantsController {
  constructor(
    private readonly adminMerchantsService: AdminMerchantsService,
    private readonly foodsManagementService: FoodsManagementService,
  ) {}

  @Get()
  @ApiOperation({ summary: 'List all merchants' })
  async listMerchants(@Query() query: ListMerchantsQueryDto) {
    return this.adminMerchantsService.listMerchants(query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get merchant by id' })
  @ApiOkResponse({ schema: { example: MERCHANT_PROFILE_EXAMPLE } })
  async getMerchant(@Param('id') id: string) {
    return this.adminMerchantsService.getMerchant(id);
  }

  @Post()
  @ApiOperation({ summary: 'Create a merchant' })
  @ApiBody({
    type: CreateMerchantDto,
    examples: { default: { value: ADMIN_CREATE_MERCHANT_BODY_EXAMPLE } },
  })
  async createMerchant(@Body() dto: CreateMerchantDto) {
    return this.adminMerchantsService.createMerchant(dto);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Update a merchant' })
  async updateMerchant(
    @Param('id') id: string,
    @Body() dto: UpdateMerchantDto,
  ) {
    return this.adminMerchantsService.updateMerchant(id, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Soft-delete a merchant' })
  async deleteMerchant(@Param('id') id: string) {
    return this.adminMerchantsService.deleteMerchant(id);
  }

  @Get(':merchantId/foods')
  @ApiOperation({ summary: 'List foods for one merchant (canonical admin UI)' })
  async listMerchantFoods(
    @Param('merchantId') merchantId: string,
    @Query() query: ListMerchantFoodsQueryDto,
  ) {
    await this.adminMerchantsService.assertMerchantExists(merchantId);
    return this.foodsManagementService.listFoodsForMerchant(merchantId, query);
  }

  @Post(':merchantId/foods')
  @ApiOperation({
    summary: 'Create a food for one merchant (canonical admin UI)',
    description:
      'Recipe is analyzed in memory only and is never stored. Upload its photo with the /photo request after create succeeds.',
  })
  async createMerchantFood(
    @Param('merchantId') merchantId: string,
    @Body() dto: CreateMerchantScopedFoodDto,
  ) {
    await this.adminMerchantsService.assertMerchantExists(merchantId);
    return this.foodsManagementService.createFood(
      dto,
      { role: UserRole.ADMIN },
      merchantId,
    );
  }

  @Put(':merchantId/foods/:foodId')
  @ApiOperation({ summary: 'Update a food scoped to one merchant' })
  async updateMerchantFood(
    @Param('merchantId') merchantId: string,
    @Param('foodId') foodId: string,
    @Body() dto: UpdateMerchantScopedFoodDto,
  ) {
    await this.adminMerchantsService.assertMerchantExists(merchantId);
    return this.foodsManagementService.updateFood(foodId, dto, {
      role: UserRole.ADMIN,
      merchantScopeId: merchantId,
    });
  }

  @Post(':merchantId/foods/:foodId/photo')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(),
      limits: { fileSize: IMAGE_UPLOAD_MAX_SIZE_BYTES },
    }),
  )
  @ApiOperation({ summary: 'Upload a photo for a food scoped to one merchant' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      required: ['file'],
      properties: { file: { type: 'string', format: 'binary' } },
    },
  })
  async uploadMerchantFoodPhoto(
    @Param('merchantId') merchantId: string,
    @Param('foodId') foodId: string,
    @UploadedFile(buildImageUploadPipe()) file: UploadedImageFile,
  ) {
    await this.adminMerchantsService.assertMerchantExists(merchantId);
    return this.foodsManagementService.uploadFoodPhoto(foodId, file, {
      role: UserRole.ADMIN,
      merchantScopeId: merchantId,
    });
  }

  @Delete(':merchantId/foods/:foodId')
  @ApiOperation({ summary: 'Soft-delete a food scoped to one merchant' })
  async deleteMerchantFood(
    @Param('merchantId') merchantId: string,
    @Param('foodId') foodId: string,
  ) {
    await this.adminMerchantsService.assertMerchantExists(merchantId);
    return this.foodsManagementService.deleteFood(foodId, {
      role: UserRole.ADMIN,
      merchantScopeId: merchantId,
    });
  }
}
