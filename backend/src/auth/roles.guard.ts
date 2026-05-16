import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ROLES_KEY } from './roles.decorator';
import { FirebaseService } from '../firebase/firebase.service';

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

    const request = context.switchToHttp().getRequest();
    const user = request.user; // Set by FirebaseAuthGuard

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

      const userData = userDoc.data();
      const userRole = userData?.role || 'customer';

      request['userRole'] = userRole;

      if (!requiredRoles.includes(userRole)) {
        throw new ForbiddenException('Insufficient permissions');
      }

      return true;
    } catch (error) {
      throw new ForbiddenException('Error checking roles');
    }
  }
}
