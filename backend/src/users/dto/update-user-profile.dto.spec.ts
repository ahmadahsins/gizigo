import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { UpdateUserProfileDto } from './update-user-profile.dto';

describe('UpdateUserProfileDto AI preference validation', () => {
  it('accepts dietary restrictions and taste profile arrays', async () => {
    const dto = plainToInstance(UpdateUserProfileDto, {
      dietary_restrictions: ['Vegetarian'],
      taste_profile: ['Spicy'],
    });

    expect(await validate(dto)).toHaveLength(0);
  });

  it('rejects non-string preference entries', async () => {
    const dto = plainToInstance(UpdateUserProfileDto, {
      dietary_restrictions: [42],
    });

    const errors = await validate(dto);

    expect(
      errors.some((error) => error.property === 'dietary_restrictions'),
    ).toBe(true);
  });
});
