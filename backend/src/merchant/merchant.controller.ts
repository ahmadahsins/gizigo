import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Put,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiBody,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
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
  @ApiOperation({ summary: 'Create a food for the logged-in merchant' })
  @ApiBody({
    type: CreateMerchantFoodDto,
    examples: { default: { value: MERCHANT_CREATE_FOOD_BODY_EXAMPLE } },
  })
  async createFood(
    @Req() req: { merchantId: string; userRole: UserRole },
    @Body() dto: CreateMerchantFoodDto,
  ) {
    return this.foodsManagementService.createFood(
      dto,
      { role: req.userRole, merchantId: req.merchantId },
    );
  }

  @Put('foods/:id')
  @ApiOperation({ summary: 'Update a food owned by the logged-in merchant' })
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

  @Delete('foods/:id')
  @ApiOperation({ summary: 'Soft-delete a food owned by the logged-in merchant' })
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
