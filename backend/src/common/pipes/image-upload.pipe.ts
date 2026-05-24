import {
  FileValidator,
  HttpStatus,
  ParseFilePipe,
  ParseFilePipeBuilder,
} from '@nestjs/common';

export const IMAGE_UPLOAD_MAX_SIZE_BYTES = 5 * 1024 * 1024;
export const IMAGE_UPLOAD_MIME_TYPE = /^image\/(?:jpeg|png|webp)$/;

interface ImageValidationFile {
  mimetype: string;
  size: number;
  buffer?: Buffer;
}

type ImageValidationInput =
  | ImageValidationFile
  | ImageValidationFile[]
  | Record<string, ImageValidationFile[]>;

class ImageContentValidator extends FileValidator<
  Record<string, never>,
  ImageValidationFile
> {
  isValid(file?: ImageValidationInput): boolean {
    if (!this.isImageFileWithBuffer(file)) {
      return false;
    }

    if (!IMAGE_UPLOAD_MIME_TYPE.test(file.mimetype)) {
      return false;
    }

    if (file.mimetype === 'image/jpeg') {
      return (
        file.buffer.length >= 3 &&
        file.buffer[0] === 0xff &&
        file.buffer[1] === 0xd8 &&
        file.buffer[2] === 0xff
      );
    }

    if (file.mimetype === 'image/png') {
      return file.buffer
        .subarray(0, 8)
        .equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]));
    }

    return (
      file.buffer.subarray(0, 4).toString('ascii') === 'RIFF' &&
      file.buffer.subarray(8, 12).toString('ascii') === 'WEBP'
    );
  }

  buildErrorMessage(file?: ImageValidationFile): string {
    return `Validation failed (current file type is ${file?.mimetype ?? 'unknown'}, expected a valid JPEG, PNG, or WebP image)`;
  }

  private isImageFileWithBuffer(
    file?: ImageValidationInput,
  ): file is ImageValidationFile & { buffer: Buffer } {
    if (!file || Array.isArray(file)) {
      return false;
    }

    return (
      typeof file.mimetype === 'string' &&
      typeof file.size === 'number' &&
      Buffer.isBuffer(file.buffer)
    );
  }
}

export function buildImageUploadPipe(): ParseFilePipe {
  return new ParseFilePipeBuilder()
    .addValidator(new ImageContentValidator({}))
    .addMaxSizeValidator({ maxSize: IMAGE_UPLOAD_MAX_SIZE_BYTES })
    .build({ errorHttpStatusCode: HttpStatus.UNPROCESSABLE_ENTITY });
}
