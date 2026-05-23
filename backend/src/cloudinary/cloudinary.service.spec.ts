import { ServiceUnavailableException } from '@nestjs/common';
import { v2 as cloudinary } from 'cloudinary';
import { CloudinaryService } from './cloudinary.service';

describe('CloudinaryService', () => {
  it('fails cleanly when Cloudinary is not configured', async () => {
    const service = new CloudinaryService({
      get: jest.fn().mockReturnValue(undefined),
    } as never);

    await expect(
      service.uploadProfilePhoto('user1', Buffer.from('photo')),
    ).rejects.toBeInstanceOf(ServiceUnavailableException);
  });

  it('uploads profile photos with a stable user asset path', async () => {
    const service = new CloudinaryService({
      get: jest.fn((key: string) => `value-${key}`),
    } as never);
    const end = jest.fn();
    const uploadSpy = jest.spyOn(
      cloudinary.uploader,
      'upload_stream',
    ) as unknown as jest.Mock;
    uploadSpy.mockImplementation((options, callback) => {
      callback?.(undefined, {
        secure_url: 'https://res.cloudinary.com/demo/profile.jpg',
      });
      expect(options).toEqual(
        expect.objectContaining({
          folder: 'gizigo/profile-photos',
          public_id: 'user1',
          overwrite: true,
        }),
      );
      return { end } as never;
    });

    const result = await service.uploadProfilePhoto(
      'user1',
      Buffer.from('photo'),
    );

    expect(result).toBe('https://res.cloudinary.com/demo/profile.jpg');
    expect(end).toHaveBeenCalled();
    jest.restoreAllMocks();
  });

  it('uploads food photos with a stable food asset path', async () => {
    const service = new CloudinaryService({
      get: jest.fn((key: string) => `value-${key}`),
    } as never);
    const end = jest.fn();
    const uploadSpy = jest.spyOn(
      cloudinary.uploader,
      'upload_stream',
    ) as unknown as jest.Mock;
    uploadSpy.mockImplementation((options, callback) => {
      callback?.(undefined, {
        secure_url: 'https://res.cloudinary.com/demo/foods/food1.jpg',
      });
      expect(options).toEqual(
        expect.objectContaining({
          folder: 'gizigo/foods',
          public_id: 'food1',
          overwrite: true,
        }),
      );
      return { end } as never;
    });

    const result = await service.uploadFoodPhoto('food1', Buffer.from('photo'));

    expect(result).toBe('https://res.cloudinary.com/demo/foods/food1.jpg');
    expect(end).toHaveBeenCalled();
    jest.restoreAllMocks();
  });
});
