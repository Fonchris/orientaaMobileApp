import { AvailabilityRule, AvailableSlot } from './types';
import { SESSION_DURATION_MIN } from './config';

export function parseTimeToMinutes(time: string): number {
  const [h, m] = time.split(':').map((p) => parseInt(p, 10));
  return (Number.isFinite(h) ? h : 0) * 60 + (Number.isFinite(m) ? m : 0);
}

export function minutesToTime(minutes: number): string {
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
}

function startOfDay(d: Date): Date {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate());
}

/**
 * Generates 60-minute slot candidates from a counselor's recurring
 * availability between [rangeStart, rangeEnd], excluding any slot that
 * overlaps an existing booking that still occupies its calendar slot.
 *
 * Alignment: slots snap to the availability rule start and advance in
 * 30-minute steps so a rule like 09:00–17:00 yields 09:00, 09:30, 10:00, …
 * (each 60 minutes long). Anything starting before `now` is dropped.
 */
export function generateSlots(
  availability: AvailabilityRule[],
  rangeStart: Date,
  rangeEnd: Date,
  existingBookings: Array<{ scheduledStart: Date; scheduledEnd: Date }>,
): AvailableSlot[] {
  const now = Date.now();
  const slots: AvailableSlot[] = [];
  let day = startOfDay(rangeStart);
  const lastDay = startOfDay(rangeEnd);

  // Iterate by calendar day (setDate) rather than adding 86400000 ms, which
  // drifts by an hour across DST boundaries.
  for (; day.getTime() <= lastDay.getTime(); day.setDate(day.getDate() + 1)) {
    const date = day; // the calendar day currently being scanned
    const weekday = date.getDay() === 0 ? 7 : date.getDay(); // 1..7

    for (const rule of availability) {
      if (rule.dayOfWeek !== weekday) continue;

      const ruleStart = parseTimeToMinutes(rule.startTime);
      const ruleEnd = parseTimeToMinutes(rule.endTime);
      if (ruleEnd - ruleStart < SESSION_DURATION_MIN) continue;

      for (
        let slotMin = ruleStart;
        slotMin + SESSION_DURATION_MIN <= ruleEnd;
        slotMin += 30
      ) {
        const start = new Date(date.getTime() + slotMin * 60000);
        const end = new Date(start.getTime() + SESSION_DURATION_MIN * 60000);
        if (start.getTime() < now || end.getTime() > rangeEnd.getTime()) continue;

        const overlaps = existingBookings.some(
          (b) => b.scheduledStart.getTime() < end.getTime() && start.getTime() < b.scheduledEnd.getTime(),
        );
        if (overlaps) continue;

        slots.push({ start: start.toISOString(), end: end.toISOString() });
      }
    }
  }

  slots.sort((a, b) => a.start.localeCompare(b.start));
  return slots;
}

/**
 * Validates that [start] is a legitimate slot derived from the counselor's
 * availability schedule (server-side re-validation at booking time).
 */
export function isValidSlot(
  availability: AvailabilityRule[],
  start: Date,
): boolean {
  const weekday = start.getDay() === 0 ? 7 : start.getDay();
  const slotStart = start.getHours() * 60 + start.getMinutes();
  const slotEnd = slotStart + SESSION_DURATION_MIN;

  return availability.some((rule) => {
    if (rule.dayOfWeek !== weekday) return false;
    const ruleStart = parseTimeToMinutes(rule.startTime);
    const ruleEnd = parseTimeToMinutes(rule.endTime);
    // Slot must be inside the rule and aligned to the same 30-minute grid the
    // generator uses (relative to the rule start, so 09:15 rules still match).
    const aligned = slotStart >= ruleStart && (slotStart - ruleStart) % 30 === 0;
    return aligned && slotEnd <= ruleEnd;
  });
}

export function roundMoney(n: number): number {
  return Math.round(n * 100) / 100;
}
