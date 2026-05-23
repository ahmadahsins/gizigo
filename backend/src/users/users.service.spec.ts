import { NotFoundException } from '@nestjs/common';
import { UsersService } from './users.service';

describe('UsersService profile photo', () => {
  let userRef: { get: jest.Mock; set: jest.Mock };
  let uploadProfilePhoto: jest.Mock;
  let service: UsersService;

  beforeEach(() => {
    userRef = {
      get: jest.fn().mockResolvedValue({
        exists: true,
        data: () => ({
          name: 'User',
          profile_photo_url: 'https://res.cloudinary.com/demo/profile.jpg',
        }),
      }),
      set: jest.fn(),
    };
    const firebaseService = {
      getFirestore: jest.fn().mockReturnValue({
        collection: jest.fn().mockReturnValue({
          doc: jest.fn().mockReturnValue(userRef),
        }),
      }),
    };
    uploadProfilePhoto = jest
      .fn()
      .mockResolvedValue('https://res.cloudinary.com/demo/profile.jpg');
    service = new UsersService(
      firebaseService as never,
      {
        uploadProfilePhoto,
      } as never,
    );
  });

  it('uploads the buffer and stores the resulting profile photo url', async () => {
    const result = await service.uploadProfilePhoto('user1', {
      buffer: Buffer.from('photo'),
    });

    expect(uploadProfilePhoto).toHaveBeenCalledWith(
      'user1',
      Buffer.from('photo'),
    );
    expect(userRef.set).toHaveBeenCalledWith(
      expect.objectContaining({
        profile_photo_url: 'https://res.cloudinary.com/demo/profile.jpg',
      }),
      { merge: true },
    );
    expect(result.profile_photo_url).toBe(
      'https://res.cloudinary.com/demo/profile.jpg',
    );
  });

  it('does not upload for an unsynced user', async () => {
    userRef.get.mockResolvedValue({ exists: false });

    await expect(
      service.uploadProfilePhoto('missing', {
        buffer: Buffer.from('photo'),
      }),
    ).rejects.toBeInstanceOf(NotFoundException);
    expect(uploadProfilePhoto).not.toHaveBeenCalled();
  });
});
