import {
  Body,
  Controller,
  Get,
  HttpStatus,
  Patch,
  ParseFilePipeBuilder,
  Post,
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
import type { UploadedImageFile } from '../common/types/uploaded-image-file';
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

  @Post('me/photo')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(),
      limits: { fileSize: 5 * 1024 * 1024 },
    }),
  )
  @ApiOperation({
    summary: 'Upload or replace current user profile photo',
    description:
      'Accepts one JPEG, PNG, or WebP image (max 5 MB), uploads it to Cloudinary, and persists `profile_photo_url`.',
  })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      required: ['file'],
      properties: {
        file: { type: 'string', format: 'binary' },
      },
    },
  })
  @ApiOkResponse({
    description: 'Updated profile containing profile_photo_url',
    schema: { example: USER_PROFILE_EXAMPLE },
  })
  async uploadProfilePhoto(
    @Req() req: { user: { uid: string } },
    @UploadedFile(
      new ParseFilePipeBuilder()
        .addFileTypeValidator({ fileType: /(jpeg|jpg|png|webp)$/ })
        .addMaxSizeValidator({ maxSize: 5 * 1024 * 1024 })
        .build({ errorHttpStatusCode: HttpStatus.UNPROCESSABLE_ENTITY }),
    )
    file: UploadedImageFile,
  ) {
    return this.usersService.uploadProfilePhoto(req.user.uid, file);
  }

  @Post('me/recently-viewed')
  @ApiOperation({
    summary: 'Upsert a food into Recently viewed (call from detail screen)',
  })
  async postRecentlyViewed(
    @Req() req: { user: { uid: string } },
    @Body() dto: RecordRecentlyViewedDto,
  ) {
    return this.usersService.recordRecentlyViewed(req.user.uid, dto);
  }

  @Get('me/recently-viewed')
  @ApiOperation({
    summary: 'Paginated recently viewed foods with optional search',
  })
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
