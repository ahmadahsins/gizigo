import {
  ConflictException,
  InternalServerErrorException,
} from '@nestjs/common';
import { AdminMerchantsService } from './admin-merchants.service';

type StoredRecord = Record<string, unknown>;
type CollectionName = 'users' | 'merchants' | 'foods';

describe('AdminMerchantsService', () => {
  const createDto = {
    name: 'Warung Sehat',
    business_email: 'owner@warung.test',
    password: 'Secret123',
    address: 'Jl. Sehat 1',
    lat: -6.2,
    lng: 106.8,
  };

  let store: Record<CollectionName, Map<string, StoredRecord>>;
  let createUser: jest.Mock;
  let updateUser: jest.Mock;
  let deleteUser: jest.Mock;
  let getUser: jest.Mock;
  let commitFails: boolean;
  let service: AdminMerchantsService;

  beforeEach(() => {
    store = {
      users: new Map(),
      merchants: new Map(),
      foods: new Map(),
    };
    commitFails = false;
    createUser = jest.fn().mockResolvedValue({ uid: 'uid_new' });
    updateUser = jest.fn().mockResolvedValue(undefined);
    deleteUser = jest.fn().mockResolvedValue(undefined);
    getUser = jest.fn().mockImplementation((uid: string) =>
      Promise.resolve({
        uid,
        email: store.users.get(uid)?.['email'] ?? 'legacy@warung.test',
      }),
    );

    const documentRef = (collectionName: CollectionName, id: string) => ({
      id,
      get: jest.fn().mockImplementation(() =>
        Promise.resolve({
          exists: store[collectionName].has(id),
          id,
          data: () => store[collectionName].get(id),
        }),
      ),
      update: jest.fn().mockImplementation((patch: StoredRecord) => {
        store[collectionName].set(id, {
          ...(store[collectionName].get(id) ?? {}),
          ...patch,
        });
        return Promise.resolve();
      }),
    });

    const db = {
      collection: jest.fn().mockImplementation((name: CollectionName) => ({
        doc: jest
          .fn()
          .mockImplementation((id: string) => documentRef(name, id)),
        get: jest.fn().mockImplementation(() =>
          Promise.resolve({
            docs: [...store[name].entries()].map(([id, value]) => ({
              id,
              data: () => value,
            })),
          }),
        ),
      })),
      batch: jest.fn().mockImplementation(() => {
        const operations: Array<() => void> = [];
        return {
          set: jest
            .fn()
            .mockImplementation(
              (
                ref: { id: string },
                value: StoredRecord,
                options?: { merge?: boolean },
              ) => {
                const collectionName: CollectionName =
                  value['role'] === 'merchant' ? 'users' : 'merchants';
                operations.push(() => {
                  const previous = options?.merge
                    ? (store[collectionName].get(ref.id) ?? {})
                    : {};
                  store[collectionName].set(ref.id, { ...previous, ...value });
                });
              },
            ),
          update: jest
            .fn()
            .mockImplementation((ref: { id: string }, value: StoredRecord) => {
              operations.push(() => {
                store.merchants.set(ref.id, {
                  ...(store.merchants.get(ref.id) ?? {}),
                  ...value,
                });
              });
            }),
          commit: jest.fn().mockImplementation(() => {
            if (commitFails) {
              return Promise.reject(new Error('commit failed'));
            }
            operations.forEach((operation) => operation());
            return Promise.resolve();
          }),
        };
      }),
    };

    service = new AdminMerchantsService({
      getFirestore: jest.fn().mockReturnValue(db),
      getAuth: jest.fn().mockReturnValue({
        createUser,
        updateUser,
        deleteUser,
        getUser,
      }),
    } as never);
  });

  it('creates linked Auth, user, and merchant records without persisting password', async () => {
    const result = await service.createMerchant(createDto);

    expect(createUser).toHaveBeenCalledWith(
      expect.objectContaining({
        email: createDto.business_email,
        password: createDto.password,
      }),
    );
    expect(store.users.get('uid_new')).toEqual(
      expect.objectContaining({ role: 'merchant', merchant_id: 'uid_new' }),
    );
    expect(store.merchants.get('uid_new')).toEqual(
      expect.objectContaining({
        merchant_id: 'uid_new',
        owner_uid: 'uid_new',
        business_email: createDto.business_email,
      }),
    );
    expect(store.users.get('uid_new')).not.toHaveProperty('password');
    expect(store.merchants.get('uid_new')).not.toHaveProperty('password');
    expect(result).not.toHaveProperty('password');
  });

  it('returns conflict when Firebase reports an email collision', async () => {
    createUser.mockRejectedValue({ code: 'auth/email-already-exists' });

    await expect(service.createMerchant(createDto)).rejects.toBeInstanceOf(
      ConflictException,
    );
  });

  it('deletes the Auth account when Firestore create commit fails', async () => {
    commitFails = true;

    await expect(service.createMerchant(createDto)).rejects.toBeInstanceOf(
      InternalServerErrorException,
    );
    expect(deleteUser).toHaveBeenCalledWith('uid_new');
  });

  it('synchronizes email, password, and activation changes with Firebase Auth', async () => {
    store.merchants.set('merchant_a', {
      merchant_id: 'merchant_a',
      owner_uid: 'uid_a',
      name: 'Old',
      business_email: 'old@test.dev',
      is_active: false,
    });

    await service.updateMerchant('merchant_a', {
      business_email: 'new@test.dev',
      password: 'Changed123',
      is_active: true,
    });

    expect(updateUser).toHaveBeenCalledWith('uid_a', {
      email: 'new@test.dev',
      password: 'Changed123',
      disabled: false,
    });
    expect(store.merchants.get('merchant_a')?.['business_email']).toBe(
      'new@test.dev',
    );
    expect(store.users.get('uid_a')?.['email']).toBe('new@test.dev');
  });

  it('provisions an account for a legacy merchant on credential update', async () => {
    store.merchants.set('legacy_store', {
      merchant_id: 'legacy_store',
      name: 'Legacy',
      is_active: true,
    });

    await service.updateMerchant('legacy_store', {
      business_email: 'legacy@new.test',
      password: 'Secret123',
    });

    expect(store.merchants.get('legacy_store')?.['owner_uid']).toBe('uid_new');
    expect(store.users.get('uid_new')?.['merchant_id']).toBe('legacy_store');
  });

  it('disables merchant Auth on soft delete', async () => {
    store.merchants.set('merchant_a', {
      merchant_id: 'merchant_a',
      owner_uid: 'uid_a',
      is_active: true,
    });

    await service.deleteMerchant('merchant_a');

    expect(updateUser).toHaveBeenCalledWith('uid_a', { disabled: true });
    expect(store.merchants.get('merchant_a')?.['is_active']).toBe(false);
  });

  it('searches merchants and computes dashboard visibility totals', async () => {
    store.merchants.set('active', {
      merchant_id: 'active',
      name: 'Mie Ayam Gonel',
      business_email: 'mie@example.test',
      is_active: true,
    });
    store.merchants.set('inactive', {
      merchant_id: 'inactive',
      name: 'Closed Store',
      is_active: false,
    });
    store.foods.set('visible', { merchant_id: 'active', is_available: true });
    store.foods.set('hidden', { merchant_id: 'inactive', is_available: true });
    store.foods.set('off', { merchant_id: 'active', is_available: false });

    const list = await service.listMerchants({ q: 'mie@example' });
    const dashboard = await service.getDashboard();

    expect(list.items).toHaveLength(1);
    expect(dashboard).toEqual({
      total_merchants: 2,
      total_active_items: 1,
      total_inactive_items: 2,
    });
  });
});
