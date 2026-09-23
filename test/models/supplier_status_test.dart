// test/models/supplier_status_test.dart
//
// The enum is the source of truth for every status comparison on the
// supplier report. These pin the wire text and the groups, so a rename that
// would have silently zeroed a card fails here instead.
import 'package:etender_reports/data/mock/report_mock_data.dart';
import 'package:etender_reports/reports/models/supplier_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SupplierStatus', () {
    test('every status in the data resolves to an enum value', () {
      final statuses = ReportMockData.supplierRecords
          .map((r) => r['status'].toString())
          .toSet();

      for (final status in statuses) {
        expect(
          SupplierStatus.fromWire(status),
          isNotNull,
          reason: '$status is in the data but not in SupplierStatus',
        );
      }
    });

    test('unknown text resolves to null rather than throwing', () {
      expect(SupplierStatus.fromWire('Nonsense'), isNull);
      expect(SupplierStatus.fromWire(null), isNull);
    });

    test('the lifecycle reads in portal order', () {
      expect(SupplierStatus.wireValues, [
        'Published',
        'Participation Requested',
        'Request Rejected',
        'Request Approved',
        'Pending Payment',
        'Paid',
        'Participated',
        'No Participate',
        'Draft',
        'Submitted',
      ]);
    });

    test('open, cleared, rejected and closed out partition the lifecycle', () {
      final groups = [
        SupplierStatus.open,
        SupplierStatus.cleared,
        SupplierStatus.rejected,
        SupplierStatus.closedOut,
      ];

      for (var i = 0; i < groups.length; i++) {
        for (var j = i + 1; j < groups.length; j++) {
          expect(
            groups[i].intersection(groups[j]),
            isEmpty,
            reason: 'groups $i and $j overlap',
          );
        }
      }

      expect({
        for (final group in groups) ...group,
      }, SupplierStatus.values.toSet());
    });

    test('terminal is exactly the rejections plus the closed-out pair', () {
      expect(SupplierStatus.terminal, containsAll(SupplierStatus.rejected));
      expect(SupplierStatus.terminal, containsAll(SupplierStatus.closedOut));
      // One rejection since the three gates collapsed into
      // 'Request Rejected', plus Participated and No Participate.
      expect(SupplierStatus.terminal, hasLength(3));
      expect(
        SupplierStatus.terminal.intersection(SupplierStatus.open),
        isEmpty,
      );
      expect(
        SupplierStatus.terminal.intersection(SupplierStatus.cleared),
        isEmpty,
      );
    });

    test('a turned-back request is the only rejection', () {
      expect(SupplierStatus.wiresOf(SupplierStatus.rejected), {
        'Request Rejected',
      });
    });

    test('wiresOf returns the text the records are keyed by', () {
      expect(SupplierStatus.wiresOf(SupplierStatus.cleared), {
        'Request Approved',
        'Pending Payment',
        'Paid',
      });
    });
  });
}
