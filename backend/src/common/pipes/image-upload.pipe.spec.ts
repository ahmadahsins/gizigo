import { UnprocessableEntityException } from '@nestjs/common';
import {
  buildImageUploadPipe,
  IMAGE_UPLOAD_MAX_SIZE_BYTES,
} from './image-upload.pipe';

describe('buildImageUploadPipe', () => {
  const pngBuffer = Buffer.from([
    0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a,
  ]);
  const jpegBuffer = Buffer.from([0xff, 0xd8, 0xff, 0xdb]);
  const webpBuffer = Buffer.from('RIFF0000WEBP', 'ascii');

  it.each([
    ['JPEG', 'image/jpeg', jpegBuffer],
    ['PNG', 'image/png', pngBuffer],
    ['WebP', 'image/webp', webpBuffer],
  ])('accepts a valid %s image', async (_, mimetype, buffer) => {
    const file = { mimetype, buffer, size: buffer.length };

    await expect(buildImageUploadPipe().transform(file)).resolves.toBe(file);
  });

  it('rejects a non-image file', async () => {
    const file = {
      mimetype: 'application/pdf',
      buffer: Buffer.from('%PDF-1.7'),
      size: 8,
    };

    await expect(buildImageUploadPipe().transform(file)).rejects.toBeInstanceOf(
      UnprocessableEntityException,
    );
  });

  it('rejects an image MIME type with non-image content', async () => {
    const file = {
      mimetype: 'image/jpeg',
      buffer: Buffer.from('%PDF-1.7'),
      size: 8,
    };

    await expect(buildImageUploadPipe().transform(file)).rejects.toBeInstanceOf(
      UnprocessableEntityException,
    );
  });

  it('rejects an image larger than 5 MB', async () => {
    const file = {
      mimetype: 'image/png',
      buffer: pngBuffer,
      size: IMAGE_UPLOAD_MAX_SIZE_BYTES + 1,
    };

    await expect(buildImageUploadPipe().transform(file)).rejects.toBeInstanceOf(
      UnprocessableEntityException,
    );
  });
});
