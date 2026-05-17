import { Controller, Post, Req, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiTags,
  ApiOperation,
  ApiOkResponse,
} from '@nestjs/swagger';
import { FirebaseAuthGuard } from './firebase-auth.guard';
import { FirebaseService } from '../firebase/firebase.service';
import { AUTH_SYNC_RESPONSE_EXAMPLE } from '../swagger/api-examples';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private firebaseService: FirebaseService) {}

  @Post(['sync', 'signup'])
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Sync Firestore user after Firebase Auth (signup alias available)',
    description:
      'Call with the Firebase ID token after `createUserWithEmailAndPassword` / Google sign-in. Creates `users/{uid}` on first success. `POST /auth/signup` uses the same handler as `POST /auth/sync`.',
  })
  @ApiOkResponse({
    description: 'Sync OK',
    schema: { example: AUTH_SYNC_RESPONSE_EXAMPLE },
  })
  async sync(@Req() req) {
    const user = req.user;

    const userRef = this.firebaseService
      .getFirestore()
      .collection('users')
      .doc(user.uid);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      await userRef.set({
        uid: user.uid,
        name: user.name || 'Unknown',
        email: user.email,
        role: 'customer',
        onboarding_completed: false,
        food_preferences: [],
        created_at: new Date(),
      });
    }

    return { message: 'Synced successfully', uid: user.uid };
  }
}
