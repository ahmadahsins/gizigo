import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ROLES_KEY } from './roles.decorator';
import { FirebaseService } from '../firebase/firebase.service';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthenticatedRequest } from './firebase-auth.guard';

type AuthorizedRequest = AuthenticatedRequest & {
  userRole?: UserRole;
  merchantId?: string | null;
};

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(
    private reflector: Reflector,
    private firebaseService: FirebaseService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const requiredRoles = this.reflector.getAllAndOverride<string[]>(
      ROLES_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (!requiredRoles || requiredRoles.length === 0) {
      return true;
    }

    const request = context.switchToHttp().getRequest<AuthorizedRequest>();
    const user = request.user;

    if (!user) {
      throw new ForbiddenException('User not authenticated');
    }

    try {
      const userDoc = await this.firebaseService
        .getFirestore()
        .collection('users')
        .doc(user.uid)
        .get();
      if (!userDoc.exists) {
        throw new ForbiddenException('User not found in database');
      }

      const userData = (userDoc.data() ?? {}) as unknown as Record<
        string,
        unknown
      >;
      const roleValue = userData['role'];
      const userRole = Object.values(UserRole).includes(roleValue as UserRole)
        ? (roleValue as UserRole)
        : UserRole.CUSTOMER;
      const merchantId =
        typeof userData['merchant_id'] === 'string'
          ? userData['merchant_id']
          : null;

      request.userRole = userRole;
      request.merchantId = merchantId;

      if (
        userRole === UserRole.MERCHANT &&
        requiredRoles.includes(UserRole.MERCHANT) &&
        !merchantId
      ) {
        throw new ForbiddenException('Merchant account is missing merchant_id');
      }

      if (!requiredRoles.includes(userRole)) {
        throw new ForbiddenException('Insufficient permissions');
      }

      return true;
    } catch (error) {
      if (error instanceof ForbiddenException) {
        throw error;
      }
      throw new ForbiddenException('Error checking roles');
    }
  }
}
