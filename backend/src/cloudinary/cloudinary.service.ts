import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { v2 as cloudinary, UploadApiResponse } from 'cloudinary';

@Injectable()
export class CloudinaryService {
  private readonly configured: boolean;

  constructor(private readonly configService: ConfigService) {
    const cloudName = this.configService.get<string>('CLOUDINARY_CLOUD_NAME');
    const apiKey = this.configService.get<string>('CLOUDINARY_API_KEY');
    const apiSecret = this.configService.get<string>('CLOUDINARY_API_SECRET');
    this.configured = Boolean(cloudName && apiKey && apiSecret);

    if (this.configured) {
      cloudinary.config({
        cloud_name: cloudName,
        api_key: apiKey,
        api_secret: apiSecret,
        secure: true,
      });
    }
  }

  async uploadProfilePhoto(uid: string, buffer: Buffer): Promise<string> {
    if (!this.configured) {
      throw new ServiceUnavailableException('Image upload is not configured');
    }

    try {
      const result = await new Promise<UploadApiResponse>((resolve, reject) => {
        const stream = cloudinary.uploader.upload_stream(
          {
            resource_type: 'image',
            folder: 'gizigo/profile-photos',
            public_id: uid,
            overwrite: true,
            invalidate: true,
            transformation: [
              {
                width: 512,
                height: 512,
                crop: 'fill',
                gravity: 'face',
                quality: 'auto',
                fetch_format: 'auto',
              },
            ],
          },
          (error, uploaded) => {
            if (error || !uploaded) {
              reject(new Error(error?.message ?? 'Upload response was empty'));
              return;
            }
            resolve(uploaded);
          },
        );
        stream.end(buffer);
      });

      return result.secure_url;
    } catch {
      throw new ServiceUnavailableException(
        'Profile photo upload is temporarily unavailable',
      );
    }
  }

  async uploadFoodPhoto(foodId: string, buffer: Buffer): Promise<string> {
    if (!this.configured) {
      throw new ServiceUnavailableException('Image upload is not configured');
    }

    try {
      const result = await new Promise<UploadApiResponse>((resolve, reject) => {
        const stream = cloudinary.uploader.upload_stream(
          {
            resource_type: 'image',
            folder: 'gizigo/foods',
            public_id: foodId,
            overwrite: true,
            invalidate: true,
            transformation: [
              {
                width: 1200,
                height: 900,
                crop: 'fill',
                gravity: 'auto',
                quality: 'auto',
                fetch_format: 'auto',
              },
            ],
          },
          (error, uploaded) => {
            if (error || !uploaded) {
              reject(new Error(error?.message ?? 'Upload response was empty'));
              return;
            }
            resolve(uploaded);
          },
        );
        stream.end(buffer);
      });

      return result.secure_url;
    } catch {
      throw new ServiceUnavailableException(
        'Food photo upload is temporarily unavailable',
      );
    }
  }
}
