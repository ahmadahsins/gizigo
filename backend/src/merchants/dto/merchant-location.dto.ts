import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsNumber, IsString, Max, Min } from 'class-validator';

export class MerchantLocationDto {
  @ApiProperty({ example: 'Warteg Sendowo' })
  @IsString()
  name!: string;

  @ApiProperty({ example: 'Jl. Margonda Raya No. 12, Depok' })
  @IsString()
  address!: string;

  @ApiProperty({ example: -6.3729 })
  @Type(() => Number)
  @IsNumber()
  @Min(-90)
  @Max(90)
  lat!: number;

  @ApiProperty({ example: 106.8346 })
  @Type(() => Number)
  @IsNumber()
  @Min(-180)
  @Max(180)
  lng!: number;
}
