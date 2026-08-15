import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:orientaa_mobile_app/widgets/counselors/models/counselor_models.dart';

void main() {
  group('BookingStatus', () {
    test('parses every storage value', () {
      expect(BookingStatus.fromString('requested'), BookingStatus.requested);
      expect(BookingStatus.fromString('payment_pending'), BookingStatus.paymentPending);
      expect(BookingStatus.fromString('confirmed'), BookingStatus.confirmed);
      expect(BookingStatus.fromString('in_progress'), BookingStatus.inProgress);
      expect(BookingStatus.fromString('completed'), BookingStatus.completed);
      expect(BookingStatus.fromString('cancelled'), BookingStatus.cancelled);
      expect(BookingStatus.fromString('disputed'), BookingStatus.disputed);
      expect(BookingStatus.fromString('refunded'), BookingStatus.refunded);
      expect(BookingStatus.fromString('paid_out'), BookingStatus.paidOut);
    });

    test('round-trips storage values', () {
      for (final s in BookingStatus.values) {
        expect(BookingStatus.fromString(s.storageValue), s);
      }
    });

    test('only confirmed/in_progress bookings occupy a calendar slot', () {
      expect(BookingStatus.paymentPending.occupiesSlot, isTrue);
      expect(BookingStatus.confirmed.occupiesSlot, isTrue);
      expect(BookingStatus.inProgress.occupiesSlot, isTrue);
      expect(BookingStatus.requested.occupiesSlot, isFalse);
      expect(BookingStatus.completed.occupiesSlot, isFalse);
      expect(BookingStatus.cancelled.occupiesSlot, isFalse);
    });

    test('chat opens only for confirmed/in_progress', () {
      expect(BookingStatus.confirmed.chatOpen, isTrue);
      expect(BookingStatus.inProgress.chatOpen, isTrue);
      expect(BookingStatus.completed.chatOpen, isFalse);
      expect(BookingStatus.disputed.chatOpen, isFalse);
    });
  });

  group('AvailabilityRule', () {
    test('parses HH:mm to minutes', () {
      const rule = AvailabilityRule(dayOfWeek: 1, startTime: '09:00', endTime: '17:00');
      expect(rule.startMinutes, 540);
      expect(rule.endMinutes, 1020);
    });

    test('round-trips through toMap', () {
      const rule = AvailabilityRule(dayOfWeek: 5, startTime: '08:30', endTime: '12:30');
      final back = AvailabilityRule.fromMap(rule.toMap());
      expect(back.dayOfWeek, 5);
      expect(back.startTime, '08:30');
      expect(back.endTime, '12:30');
    });
  });

  group('AvailableSlot', () {
    test('groups by calendar day', () {
      final a = AvailableSlot(
        start: DateTime(2026, 8, 14, 9),
        end: DateTime(2026, 8, 14, 10),
      );
      final b = AvailableSlot(
        start: DateTime(2026, 8, 15, 9),
        end: DateTime(2026, 8, 15, 10),
      );
      expect(a.dayKey, isNot(b.dayKey));
      expect(
        AvailableSlot(start: DateTime(2026, 8, 14, 14), end: DateTime(2026, 8, 14, 15)).dayKey,
        a.dayKey,
      );
    });

    test('formats a 12-hour label', () {
      expect(
        AvailableSlot(start: DateTime(2026, 8, 14, 9, 30), end: DateTime(2026, 8, 14, 10, 30)).label12h,
        '9:30 AM',
      );
      expect(
        AvailableSlot(start: DateTime(2026, 8, 14, 15), end: DateTime(2026, 8, 14, 16)).label12h,
        '3:00 PM',
      );
    });

    test('parses ISO-8601 wire format', () {
      final slot = AvailableSlot.fromJson({
        'start': '2026-08-14T09:00:00.000Z',
        'end': '2026-08-14T10:00:00.000Z',
      });
      expect(slot.start, DateTime.parse('2026-08-14T09:00:00.000Z'));
      expect(slot.end, DateTime.parse('2026-08-14T10:00:00.000Z'));
    });
  });

  group('Booking', () {
    Booking bookingWith(BookingStatus status, DateTime start, {DateTime? now}) {
      return Booking(
        id: 'b1',
        studentUid: 'student',
        counselorUid: 'counselor',
        scheduledStart: start,
        scheduledEnd: start.add(const Duration(minutes: 60)),
        feeAmount: 50,
        currency: 'USD',
        platformCommission: 5,
        counselorPayoutAmount: 45,
        status: status,
      );
    }

    test('chat unlocks 10 minutes before start for confirmed bookings', () {
      final start = DateTime(2026, 8, 20, 15);
      final now = start.subtract(const Duration(minutes: 10));
      final booking = bookingWith(BookingStatus.confirmed, start);
      expect(booking.chatOpenAt(now), isTrue);

      final tooEarly = start.subtract(const Duration(minutes: 11));
      expect(booking.chatOpenAt(tooEarly), isFalse);
    });

    test('chat stays locked for non-confirmed statuses', () {
      final start = DateTime(2026, 8, 20, 15);
      final now = start.subtract(const Duration(minutes: 10));
      expect(bookingWith(BookingStatus.completed, start).chatOpenAt(now), isFalse);
      expect(bookingWith(BookingStatus.paymentPending, start).chatOpenAt(now), isFalse);
      expect(bookingWith(BookingStatus.disputed, start).chatOpenAt(now), isFalse);
    });

    test('participant check', () {
      final b = bookingWith(BookingStatus.confirmed, DateTime(2026, 8, 20, 15));
      expect(b.isParticipant('student'), isTrue);
      expect(b.isParticipant('counselor'), isTrue);
      expect(b.isParticipant('stranger'), isFalse);
    });

    test('parses a Firestore document', () {
      final b = Booking.fromMap({
        'studentUid': 's',
        'counselorUid': 'c',
        'scheduledStart': Timestamp.fromDate(DateTime(2026, 8, 20, 15)),
        'scheduledEnd': Timestamp.fromDate(DateTime(2026, 8, 20, 16)),
        'feeAmount': 50,
        'currency': 'USD',
        'platformCommission': 5,
        'counselorPayoutAmount': 45,
        'status': 'paid_out',
        'paymentReference': '1234',
      }, id: 'b1');
      expect(b.status, BookingStatus.paidOut);
      expect(b.counselorPayoutAmount, 45);
      expect(b.paymentReference, '1234');
      expect(b.id, 'b1');
    });
  });

  group('CounselorProfile', () {
    test('parses a Firestore document with defaults', () {
      final p = CounselorProfile.fromMap({
        'displayName': 'Ada',
        'specialties': ['STEM guidance'],
        'languages': ['English'],
        'hourlyRate': 40,
        'currency': 'NGN',
        'verificationStatus': 'approved',
        'isOnline': true,
        'ratingAverage': 4.5,
        'ratingCount': 12,
        'availability': [
          {'dayOfWeek': 1, 'startTime': '09:00', 'endTime': '17:00'},
        ],
      }, uid: 'c1');
      expect(p.uid, 'c1');
      expect(p.displayName, 'Ada');
      expect(p.hourlyRate, 40);
      expect(p.currency, 'NGN');
      expect(p.isApproved, isTrue);
      expect(p.isVerified, isTrue);
      expect(p.availability.single.dayOfWeek, 1);
    });

    test('unapproved profiles are not verified', () {
      final p = CounselorProfile.fromMap({
        'verificationStatus': 'pending',
      }, uid: 'c1');
      expect(p.isApproved, isFalse);
    });
  });
}
