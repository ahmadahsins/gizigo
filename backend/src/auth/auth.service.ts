import {
  ConflictException,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import * as admin from 'firebase-admin';
import { FirebaseService } from '../firebase/firebase.service';
import { MerchantsService } from '../merchants/merchants.service';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthSyncDto } from './dto/auth-sync.dto';

export interface AuthUserPayload {
  uid: string;
  name?: string;
  email?: string;
}

type StoredUser = Record<string, unknown>;

@Injectable()
export class AuthService {
  constructor(
    private readonly firebaseService: FirebaseService,
    private readonly merchantsService: MerchantsService,
  ) {}

  private db() {
    return this.firebaseService.getFirestore();
  }

  async sync(user: AuthUserPayload, dto: AuthSyncDto = {}) {
    const rawAccountType = (dto as { account_type?: string }).account_type;
    if (rawAccountType === UserRole.ADMIN) {
      throw new ForbiddenException(
        'Admin accounts cannot be created via signup',
      );
    }

    const accountType = dto.account_type ?? UserRole.CUSTOMER;

    const userRef = this.db().collection('users').doc(user.uid);
    const userDoc = await userRef.get();

    if (userDoc.exists) {
      const storedUser = this.toRecord(userDoc.data());
      const existingRole = this.readRole(storedUser['role']);
      if (dto.account_type && dto.account_type !== existingRole) {
        throw new ConflictException(
          'Account type cannot be changed after signup',
        );
      }

      return {
        message: 'Synced successfully',
        uid: user.uid,
        role: existingRole,
        merchant_id: this.readString(storedUser['merchant_id']),
      };
    }

    if (accountType === UserRole.MERCHANT) {
      if (!dto.merchant) {
        throw new ConflictException(
          'Merchant profile is required when account_type is merchant',
        );
      }

      return this.createMerchantAccount(user, dto);
    }

    await userRef.set({
      uid: user.uid,
      name: user.name || 'Unknown',
      email: user.email,
      role: UserRole.CUSTOMER,
      onboarding_completed: false,
      food_preferences: [],
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      message: 'Synced successfully',
      uid: user.uid,
      role: UserRole.CUSTOMER,
      merchant_id: null,
    };
  }

  private async createMerchantAccount(user: AuthUserPayload, dto: AuthSyncDto) {
    const db = this.db();
    const userRef = db.collection('users').doc(user.uid);

    await db.runTransaction(async (transaction) => {
      const existing = await transaction.get(userRef);
      if (existing.exists) {
        throw new ConflictException('User already exists');
      }

      transaction.set(userRef, {
        uid: user.uid,
        name: user.name || dto.merchant!.name,
        email: user.email,
        role: UserRole.MERCHANT,
        merchant_id: user.uid,
        onboarding_completed: true,
        food_preferences: [],
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    await this.merchantsService.createMerchant(dto.merchant!, {
      merchantId: user.uid,
      ownerUid: user.uid,
      isVerified: true,
    });

    return {
      message: 'Synced successfully',
      uid: user.uid,
      role: UserRole.MERCHANT,
      merchant_id: user.uid,
    };
  }

  private readRole(value: unknown): UserRole {
    return Object.values(UserRole).includes(value as UserRole)
      ? (value as UserRole)
      : UserRole.CUSTOMER;
  }

  private readString(value: unknown): string | null {
    return typeof value === 'string' ? value : null;
  }

  private toRecord(value: unknown): StoredUser {
    return value !== null && typeof value === 'object'
      ? { ...(value as StoredUser) }
      : {};
  }
}
