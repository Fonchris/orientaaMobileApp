import { AvailabilityRule } from '../src/types';
import {
  generateSlots,
  isValidSlot,
  minutesToTime,
  parseTimeToMinutes,
  roundMoney,
} from '../src/helpers';

// Deterministic DST: tests below construct dates in America/New_York where
// daylight saving begins the second Sunday of March.
process.env.TZ = 'America/New_York';

const mondayRule: AvailabilityRule = {
  dayOfWeek: 1,
  startTime: '09:00',
  endTime: '17:00',
};

describe('parseTimeToMinutes / minutesToTime / roundMoney', () => {
  it('parses HH:MM into minutes since midnight', () => {
    expect(parseTimeToMinutes('09:30')).toBe(570);
    expect(parseTimeToMinutes('00:00')).toBe(0);
    expect(parseTimeToMinutes('23:59')).toBe(1439);
  });

  it('formats minutes back into HH:MM with padding', () => {
    expect(minutesToTime(570)).toBe('09:30');
    expect(minutesToTime(0)).toBe('00:00');
    expect(minutesToTime(1439)).toBe('23:59');
  });

  it('rounds money to 2 decimals', () => {
    expect(roundMoney(10.005)).toBe(10.01);
    expect(roundMoney(10)).toBe(10);
    expect(roundMoney(0.1 * 3)).toBe(0.3);
  });
});

describe('generateSlots', () => {
  it('generates 60-minute slots every 30 minutes across a rule window', () => {
    // 2026-10-05 is a Monday (dates must be in the future: generateSlots
    // drops anything starting before `now`).
    const rangeStart = new Date(2026, 9, 5, 0, 0);
    const rangeEnd = new Date(2026, 9, 5, 23, 59);

    const slots = generateSlots([mondayRule], rangeStart, rangeEnd, []);
    expect(slots).toHaveLength(15); // 09:00 .. 16:00 in 30-min steps
    expect(slots[0].start).toBe(new Date(2026, 9, 5, 9, 0).toISOString());
    expect(slots[1].start).toBe(new Date(2026, 9, 5, 9, 30).toISOString());
    expect(slots[14].start).toBe(new Date(2026, 9, 5, 16, 0).toISOString());
    // Every slot is exactly 60 minutes.
    for (const s of slots) {
      expect(new Date(s.end).getTime() - new Date(s.start).getTime()).toBe(3600000);
    }
  });

  it('skips slots that overlap an existing occupying booking', () => {
    const rangeStart = new Date(2026, 9, 5, 0, 0);
    const rangeEnd = new Date(2026, 9, 5, 23, 59);
    const existing = [
      { scheduledStart: new Date(2026, 9, 5, 10, 0), scheduledEnd: new Date(2026, 9, 5, 11, 0) },
    ];

    const slots = generateSlots([mondayRule], rangeStart, rangeEnd, existing);
    const starts = slots.map((s) => new Date(s.start).getHours() * 60 + new Date(s.start).getMinutes());
    // 09:30, 10:00 and 10:30 all overlap the 10:00-11:00 booking and must be
    // excluded; 09:00 remains free.
    expect(starts).not.toContain(570);
    expect(starts).not.toContain(600);
    expect(starts).not.toContain(630);
    expect(starts).toContain(540); // 09:00 still free
    expect(slots).toHaveLength(12);
  });

  it('returns no slots when the whole range is in the past', () => {
    const rangeStart = new Date(2020, 0, 6); // Monday
    const rangeEnd = new Date(2020, 0, 6, 23, 59);
    expect(generateSlots([mondayRule], rangeStart, rangeEnd, [])).toHaveLength(0);
  });

  it('keeps local slot times correct across a DST spring-forward day', () => {
    // 2027-03-14 (Sunday) is the US DST spring-forward day (23h long). A
    // rule that covers both Sunday and Monday must still produce the Monday
    // 01:00 slot at exactly 01:00 — a naive `+86400000ms` day loop drifts it
    // to 02:00 and drops the real slot.
    const rules: AvailabilityRule[] = [
      { dayOfWeek: 7, startTime: '01:00', endTime: '05:00' },
      { dayOfWeek: 1, startTime: '01:00', endTime: '05:00' },
    ];
    const rangeStart = new Date(2027, 2, 14, 0, 0);
    const rangeEnd = new Date(2027, 2, 15, 23, 59);

    const slots = generateSlots(rules, rangeStart, rangeEnd, []);
    const monday0100 = slots.find((s) => {
      const d = new Date(s.start);
      return d.getDay() === 1 && d.getHours() === 1 && d.getMinutes() === 0;
    });
    expect(monday0100).toBeDefined();
    expect(new Date(monday0100!.start).getTime()).toBe(
      new Date(2027, 2, 15, 1, 0).getTime(),
    );
  });
});

describe('isValidSlot', () => {
  it('accepts rule-aligned 60-minute slots', () => {
    expect(isValidSlot([mondayRule], new Date(2026, 9, 5, 9, 0))).toBe(true);
    expect(isValidSlot([mondayRule], new Date(2026, 9, 5, 16, 0))).toBe(true);
  });

  it('rejects slots outside the rule or shorter than 60 minutes', () => {
    expect(isValidSlot([mondayRule], new Date(2026, 9, 5, 8, 0))).toBe(false);
    expect(isValidSlot([mondayRule], new Date(2026, 9, 5, 16, 30))).toBe(false);
    expect(isValidSlot([mondayRule], new Date(2026, 9, 5, 17, 0))).toBe(false);
  });

  it('rejects non-30-minute-aligned starts', () => {
    expect(isValidSlot([mondayRule], new Date(2026, 9, 5, 9, 15))).toBe(false);
  });

  it('aligns relative to the rule start (rules can start at :15)', () => {
    const quarterPast: AvailabilityRule = {
      dayOfWeek: 1,
      startTime: '09:15',
      endTime: '12:15',
    };
    expect(isValidSlot([quarterPast], new Date(2026, 9, 5, 9, 15))).toBe(true);
    expect(isValidSlot([quarterPast], new Date(2026, 9, 5, 9, 45))).toBe(true);
    expect(isValidSlot([quarterPast], new Date(2026, 9, 5, 9, 30))).toBe(false);
  });

  it('rejects the wrong weekday', () => {
    expect(isValidSlot([mondayRule], new Date(2026, 9, 4, 9, 0))).toBe(false); // Sunday
  });
});
