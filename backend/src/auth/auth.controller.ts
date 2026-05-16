import { Controller, Post, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags, ApiOperation } from '@nestjs/swagger';
import { FirebaseAuthGuard } from './firebase-auth.guard';
import { FirebaseService } from '../firebase/firebase.service';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private firebaseService: FirebaseService) {}

  @Post('login')
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Login / Sync user profile after Firebase Auth' })
  async login(@Req() req) {
    const user = req.user;

    // Sync to Firestore
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
        created_at: new Date(),
      });
    }

    return { message: 'Logged in successfully', uid: user.uid };
  }
}
