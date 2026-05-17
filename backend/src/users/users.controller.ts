import {
  Body,
  Controller,
  Get,
  Patch,
  Post,
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
import { UsersService } from './users.service';
import { RecordRecentlyViewedDto } from './dto/record-recently-viewed.dto';
import { RecordRecentLocationDto } from './dto/record-recent-location.dto';
import { RecentlyViewedQueryDto } from './dto/recently-viewed-query.dto';
import { UpdateUserProfileDto } from './dto/update-user-profile.dto';
import {
  PATCH_USER_BODY_EXAMPLE,
  RECENTLY_VIEWED_RESPONSE_EXAMPLE,
  USER_PROFILE_EXAMPLE,
} from '../swagger/api-examples';

@ApiTags('users')
@Controller('users')
@UseGuards(FirebaseAuthGuard)
@ApiBearerAuth()
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  @ApiOperation({
    summary: 'Current user profile (includes onboarding fields when set)',
  })
  @ApiOkResponse({
    description: 'Profile document',
    schema: { example: USER_PROFILE_EXAMPLE },
  })
  async getMe(@Req() req: { user: { uid: string } }) {
    return this.usersService.getProfile(req.user.uid);
  }

  @Patch('me')
  @ApiOperation({
    summary: 'Update profile / onboarding (partial)',
    description:
      'Send after signup wizard: gender, age, anthropometrics, nutrition_goal, food_preferences, onboarding_completed.',
  })
  @ApiBody({
    type: UpdateUserProfileDto,
    examples: {
      onboarding: { value: PATCH_USER_BODY_EXAMPLE },
    },
  })
  @ApiOkResponse({
    description: 'Updated profile',
    schema: { example: USER_PROFILE_EXAMPLE },
  })
  async patchMe(
    @Req() req: { user: { uid: string } },
    @Body() dto: UpdateUserProfileDto,
  ) {
    return this.usersService.updateProfile(req.user.uid, dto);
  }

  @Post('me/recently-viewed')
  @ApiOperation({ summary: 'Upsert a food into Recently viewed (call from detail screen)' })
  async postRecentlyViewed(
    @Req() req: { user: { uid: string } },
    @Body() dto: RecordRecentlyViewedDto,
  ) {
    return this.usersService.recordRecentlyViewed(req.user.uid, dto);
  }

  @Get('me/recently-viewed')
  @ApiOperation({ summary: 'Paginated recently viewed foods with optional search' })
  @ApiOkResponse({
    schema: { example: RECENTLY_VIEWED_RESPONSE_EXAMPLE },
  })
  async getRecentlyViewed(
    @Req() req: { user: { uid: string } },
    @Query() query: RecentlyViewedQueryDto,
  ) {
    return this.usersService.getRecentlyViewed(req.user.uid, query);
  }

  @Post('me/recent-locations')
  @ApiOperation({ summary: 'Save or refresh a recent delivery/map location' })
  async postRecentLocation(
    @Req() req: { user: { uid: string } },
    @Body() dto: RecordRecentLocationDto,
  ) {
    return this.usersService.recordRecentLocation(req.user.uid, dto);
  }

  @Get('me/recent-locations')
  @ApiOperation({ summary: 'List recent locations (newest first)' })
  async getRecentLocations(@Req() req: { user: { uid: string } }) {
    return this.usersService.getRecentLocations(req.user.uid);
  }
}
