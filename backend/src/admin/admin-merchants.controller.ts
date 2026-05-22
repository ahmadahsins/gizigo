import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiBody,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { UserRole } from '../common/enums/user-role.enum';
import { MerchantsService } from '../merchants/merchants.service';
import { FoodsManagementService } from '../foods/foods-management.service';
import { CreateMerchantDto } from '../merchants/dto/create-merchant.dto';
import { UpdateMerchantDto } from '../merchants/dto/update-merchant.dto';
import { ListMerchantsQueryDto } from '../merchants/dto/list-merchants-query.dto';
import { ListMerchantFoodsQueryDto } from '../merchant/dto/list-merchant-foods-query.dto';
import {
  ADMIN_CREATE_MERCHANT_BODY_EXAMPLE,
  MERCHANT_PROFILE_EXAMPLE,
} from '../swagger/api-examples';

@ApiTags('admin')
@Controller('admin/merchants')
@UseGuards(FirebaseAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
@ApiBearerAuth()
export class AdminMerchantsController {
  constructor(
    private readonly merchantsService: MerchantsService,
    private readonly foodsManagementService: FoodsManagementService,
  ) {}

  @Get()
  @ApiOperation({ summary: 'List all merchants' })
  async listMerchants(@Query() query: ListMerchantsQueryDto) {
    return this.merchantsService.listMerchants(query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get merchant by id' })
  @ApiOkResponse({ schema: { example: MERCHANT_PROFILE_EXAMPLE } })
  async getMerchant(@Param('id') id: string) {
    return this.merchantsService.getMerchant(id);
  }

  @Post()
  @ApiOperation({ summary: 'Create a merchant' })
  @ApiBody({
    type: CreateMerchantDto,
    examples: { default: { value: ADMIN_CREATE_MERCHANT_BODY_EXAMPLE } },
  })
  async createMerchant(@Body() dto: CreateMerchantDto) {
    return this.merchantsService.createMerchant(dto);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Update a merchant' })
  async updateMerchant(
    @Param('id') id: string,
    @Body() dto: UpdateMerchantDto,
  ) {
    return this.merchantsService.updateMerchant(id, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Soft-delete a merchant' })
  async deleteMerchant(@Param('id') id: string) {
    return this.merchantsService.deleteMerchant(id);
  }

  @Get(':id/foods')
  @ApiOperation({ summary: 'List foods for a merchant' })
  async listMerchantFoods(
    @Param('id') id: string,
    @Query() query: ListMerchantFoodsQueryDto,
  ) {
    return this.foodsManagementService.listFoodsForMerchant(
      id,
      query.page,
      query.limit,
    );
  }
}
