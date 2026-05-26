import { NotFoundException } from '@nestjs/common';
import { MerchantsService } from './merchants.service';

describe('MerchantsService', () => {
  let merchantRef: {
    id: string;
    set: jest.Mock;
    get: jest.Mock;
    update: jest.Mock;
  };
  let merchantsCollection: {
    doc: jest.Mock;
    get: jest.Mock;
  };
  let service: MerchantsService;
  let getUser: jest.Mock;

  beforeEach(() => {
    merchantRef = {
      id: 'merchant_a',
      set: jest.fn(),
      get: jest.fn(),
      update: jest.fn(),
    };

    merchantsCollection = {
      doc: jest.fn((id?: string) => {
        if (id) {
          merchantRef.id = id;
        }
        return merchantRef;
      }),
      get: jest.fn(),
    };
    getUser = jest.fn().mockResolvedValue({ email: null });

    const firebaseService = {
      getFirestore: jest.fn().mockReturnValue({
        collection: jest.fn().mockReturnValue(merchantsCollection),
      }),
      getAuth: jest.fn().mockReturnValue({
        getUser,
      }),
    };

    service = new MerchantsService(firebaseService as never);
  });

  it('creates merchant with geohash and active flag', async () => {
    const result = await service.createMerchant(
      {
        name: 'Warteg Sendowo',
        address: 'Depok',
        lat: -6.3729,
        lng: 106.8346,
      },
      { merchantId: 'merchant_a', ownerUid: 'uid123' },
    );

    expect(result.id).toBe('merchant_a');
    expect(merchantRef.set).toHaveBeenCalledWith(
      expect.objectContaining({
        merchant_id: 'merchant_a',
        owner_uid: 'uid123',
        is_active: true,
        geohash: expect.any(String),
      }),
    );
  });

  it('soft deletes merchant', async () => {
    merchantRef.get.mockResolvedValue({
      exists: true,
      data: () => ({ name: 'X' }),
    });

    const result = await service.deleteMerchant('merchant_a');

    expect(result.message).toContain('soft-deleted');
    expect(merchantRef.update).toHaveBeenCalledWith(
      expect.objectContaining({ is_active: false }),
    );
  });

  it('throws when merchant is missing', async () => {
    merchantRef.get.mockResolvedValue({ exists: false });

    await expect(service.getMerchant('missing')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('returns stored business email for the business profile', async () => {
    merchantRef.get.mockResolvedValue({
      exists: true,
      data: () => ({
        merchant_id: 'merchant_a',
        business_email: 'owner@store.test',
      }),
    });

    const result = await service.getMerchant('merchant_a');

    expect(result.business_email).toBe('owner@store.test');
  });

  it('reads business email from Auth for a legacy merchant profile', async () => {
    getUser.mockResolvedValue({ email: 'legacy@store.test' });
    merchantRef.get.mockResolvedValue({
      exists: true,
      data: () => ({ merchant_id: 'merchant_a', owner_uid: 'owner_a' }),
    });

    const result = await service.getMerchant('merchant_a');

    expect(getUser).toHaveBeenCalledWith('owner_a');
    expect(result.business_email).toBe('legacy@store.test');
  });

  it('filters inactive merchants in list query', async () => {
    merchantsCollection.get.mockResolvedValue({
      docs: [
        {
          id: 'm1',
          data: () => ({
            merchant_id: 'm1',
            name: 'Active',
            is_active: true,
          }),
        },
        {
          id: 'm2',
          data: () => ({
            merchant_id: 'm2',
            name: 'Inactive',
            is_active: false,
          }),
        },
      ],
    });

    const result = await service.listMerchants({ is_active: true });

    expect(result.items).toHaveLength(1);
    expect(result.items[0].merchant_id).toBe('m1');
  });
});
