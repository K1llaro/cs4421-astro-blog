import { describe, expect, it } from 'vitest';

const formatDate = (value: string | Date) => {
  const date = new Date(value);

  if (Number.isNaN(date.getTime())) {
    return 'Invalid Date';
  }

  return new Intl.DateTimeFormat('en-US', {
    month: 'long',
    day: 'numeric',
    year: 'numeric',
    timeZone: 'UTC',
  }).format(date);
};

const isSameDay = (left: string | Date, right: string | Date) => {
  const a = new Date(left);
  const b = new Date(right);

  return a.getUTCFullYear() === b.getUTCFullYear()
    && a.getUTCMonth() === b.getUTCMonth()
    && a.getUTCDate() === b.getUTCDate();
};

describe('date utilities', () => {
  it('formats a standard ISO date as a readable US date', () => {
    expect(formatDate('2025-01-15')).toBe('January 15, 2025');
  });

  it('formats a leap-day date correctly', () => {
    expect(formatDate('2024-02-29')).toBe('February 29, 2024');
  });

  it('keeps dates consistent across month boundaries', () => {
    expect(formatDate('2023-12-31')).toBe('December 31, 2023');
  });

  it('detects when two date values represent the same calendar day', () => {
    expect(isSameDay('2025-03-10T00:00:00Z', '2025-03-10T12:00:00Z')).toBe(true);
  });

  it('returns an invalid date label for malformed input', () => {
    expect(formatDate('not-a-date')).toBe('Invalid Date');
  });
});
