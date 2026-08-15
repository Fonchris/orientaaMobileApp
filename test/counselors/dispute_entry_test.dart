import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:orientaa_mobile_app/widgets/counselors/models/counselor_models.dart';

void main() {
  group('DisputeEntry', () {
    test('parses an open dispute document', () {
      final now = DateTime.now();
      final snap = _snap({
        'studentUid': 's1',
        'studentName': 'Chidi',
        'counselorUid': 'c1',
        'counselorName': 'Dr. Amina Yusuf',
        'counselorPhotoUrl': 'https://example.com/a.jpg',
        'scheduledStart': Timestamp.fromDate(now),
        'feeAmount': 100.0,
        'currency': 'NGN',
        'reason': 'Session did not happen',
        'status': 'open',
        'createdAt': Timestamp.fromDate(now),
      });

      final entry = DisputeEntry.fromSnapshot(snap);
      expect(entry.bookingId, 'b1');
      expect(entry.studentName, 'Chidi');
      expect(entry.counselorName, 'Dr. Amina Yusuf');
      expect(entry.counselorPhotoUrl, 'https://example.com/a.jpg');
      expect(entry.feeAmount, 100.0);
      expect(entry.currency, 'NGN');
      expect(entry.reason, 'Session did not happen');
      expect(entry.isOpen, isTrue);
      expect(entry.resolvedAsPaidOut, isFalse);
    });

    test('flags resolved outcomes', () {
      final open = DisputeEntry.fromSnapshot(_snap({'status': 'open'}));
      expect(open.isOpen, isTrue);

      final paid = DisputeEntry.fromSnapshot(_snap({'status': 'resolved_paid_out'}));
      expect(paid.isOpen, isFalse);
      expect(paid.resolvedAsPaidOut, isTrue);

      final refunded = DisputeEntry.fromSnapshot(_snap({'status': 'resolved_refunded'}));
      expect(refunded.isOpen, isFalse);
      expect(refunded.resolvedAsRefunded, isTrue);
    });

    test('defaults missing fields safely', () {
      final entry = DisputeEntry.fromSnapshot(_snap({}));
      expect(entry.studentName, 'Student');
      expect(entry.counselorName, 'Counselor');
      expect(entry.feeAmount, 0);
      expect(entry.currency, 'USD');
      expect(entry.reason, '');
      expect(entry.isOpen, isTrue);
    });
  });
}

DocumentSnapshot<Map<String, dynamic>> _snap(Map<String, dynamic> data) {
  final doc = _FakeDocSnapshot(data);
  return doc as DocumentSnapshot<Map<String, dynamic>>;
}

// DocumentSnapshot is sealed; a minimal test fake is the standard escape hatch.
// ignore: subtype_of_sealed_class
class _FakeDocSnapshot extends DocumentSnapshot<Map<String, dynamic>> {
  _FakeDocSnapshot(this._data);

  final Map<String, dynamic> _data;

  @override
  String get id => 'b1';

  @override
  bool get exists => true;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
