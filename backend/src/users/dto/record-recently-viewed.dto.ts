import { IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class RecordRecentlyViewedDto {
  @ApiProperty({ description: 'Firestore document id of the food item' })
  @IsString()
  food_id: string;
}
