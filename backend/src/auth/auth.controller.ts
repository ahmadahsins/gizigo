import { Controller, Post, Body, Req, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiBody,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { FirebaseAuthGuard } from './firebase-auth.guard';
import {
  AUTH_MERCHANT_SIGNUP_BODY_EXAMPLE,
  AUTH_SYNC_RESPONSE_EXAMPLE,
} from '../swagger/api-examples';
import { AuthService } from './auth.service';
import { AuthSyncDto } from './dto/auth-sync.dto';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post(['sync', 'signup'])
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Sync Firestore user after Firebase Auth (signup alias available)',
    description:
      'Call with the Firebase ID token after signup. First call may include `account_type` and `merchant` profile for merchant registration. `POST /auth/signup` uses the same handler as `POST /auth/sync`.',
  })
  @ApiBody({
    type: AuthSyncDto,
    examples: {
      customer: { summary: 'Customer signup', value: {} },
      merchant: {
        summary: 'Merchant signup',
        value: AUTH_MERCHANT_SIGNUP_BODY_EXAMPLE,
      },
    },
  })
  @ApiOkResponse({
    description: 'Sync OK',
    schema: { example: AUTH_SYNC_RESPONSE_EXAMPLE },
  })
  async sync(
    @Req() req: { user: { uid: string; name?: string; email?: string } },
    @Body() dto: AuthSyncDto,
  ) {
    return this.authService.sync(req.user, dto);
  }
}
