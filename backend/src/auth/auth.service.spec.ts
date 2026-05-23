import { ConflictException, ForbiddenException } from '@nestjs/common';
import { AuthService } from './auth.service';
import { UserRole } from '../common/enums/user-role.enum';

describe('AuthService', () => {
  const merchantProfile = {
    name: 'Warteg Sendowo',
    address: 'Jl. Margonda Raya No. 12, Depok',
    lat: -6.3729,
    lng: 106.8346,
  };

  let userRef: {
    get: jest.Mock;
    set: jest.Mock;
  };
  let runTransaction: jest.Mock;
  let authService: AuthService;
  let merchantsService: { createMerchant: jest.Mock };

  beforeEach(() => {
    userRef = {
      get: jest.fn(),
      set: jest.fn(),
    };

    runTransaction = jest.fn(
      async (fn: (tx: { get: jest.Mock; set: jest.Mock }) => Promise<void>) => {
        const tx = {
          get: jest.fn().mockResolvedValue({ exists: false }),
          set: jest.fn(),
        };
        await fn(tx);
      },
    );

    const firebaseService = {
      getFirestore: jest.fn().mockReturnValue({
        collection: jest.fn().mockReturnValue({
          doc: jest.fn().mockReturnValue(userRef),
        }),
        runTransaction,
      }),
    };

    merchantsService = {
      createMerchant: jest.fn().mockResolvedValue({ id: 'uid123' }),
    };

    authService = new AuthService(
      firebaseService as never,
      merchantsService as never,
    );
  });

  it('creates a customer account on first sync', async () => {
    userRef.get.mockResolvedValue({ exists: false });

    const result = await authService.sync(
      { uid: 'uid123', name: 'User', email: 'user@example.com' },
      {},
    );

    expect(result).toEqual({
      message: 'Synced successfully',
      uid: 'uid123',
      role: UserRole.CUSTOMER,
      merchant_id: null,
    });
    expect(userRef.set).toHaveBeenCalled();
    expect(merchantsService.createMerchant).not.toHaveBeenCalled();
  });

  it('creates a merchant account and store profile on first sync', async () => {
    userRef.get.mockResolvedValue({ exists: false });

    const result = await authService.sync(
      { uid: 'uid123', name: 'Owner', email: 'owner@example.com' },
      { account_type: UserRole.MERCHANT, merchant: merchantProfile },
    );

    expect(result.role).toBe(UserRole.MERCHANT);
    expect(result.merchant_id).toBe('uid123');
    expect(merchantsService.createMerchant).toHaveBeenCalledWith(
      merchantProfile,
      {
        merchantId: 'uid123',
        ownerUid: 'uid123',
        isVerified: true,
      },
    );
  });

  it('rejects admin signup', async () => {
    await expect(
      authService.sync(
        { uid: 'uid123', email: 'admin@example.com' },
        { account_type: UserRole.ADMIN as never },
      ),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('rejects merchant signup without profile', async () => {
    userRef.get.mockResolvedValue({ exists: false });

    await expect(
      authService.sync(
        { uid: 'uid123', email: 'owner@example.com' },
        { account_type: UserRole.MERCHANT },
      ),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it('rejects changing account type after signup', async () => {
    userRef.get.mockResolvedValue({
      exists: true,
      data: () => ({ role: UserRole.CUSTOMER, merchant_id: null }),
    });

    await expect(
      authService.sync(
        { uid: 'uid123', email: 'user@example.com' },
        { account_type: UserRole.MERCHANT, merchant: merchantProfile },
      ),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it('returns existing user on repeat sync', async () => {
    userRef.get.mockResolvedValue({
      exists: true,
      data: () => ({ role: UserRole.MERCHANT, merchant_id: 'uid123' }),
    });

    const result = await authService.sync(
      { uid: 'uid123', email: 'owner@example.com' },
      {},
    );

    expect(result).toEqual({
      message: 'Synced successfully',
      uid: 'uid123',
      role: UserRole.MERCHANT,
      merchant_id: 'uid123',
    });
  });
});
