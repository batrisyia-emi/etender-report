// test/models/tender_security_test.dart
import 'package:etender_reports/data/actions/report_actions.dart';
import 'package:etender_reports/data/mock/tender_security_records.dart';
import 'package:etender_reports/reports/models/records/tender_security_record.dart';
import 'package:etender_reports/reports/models/tender_security_attributes.dart';
import 'package:etender_reports/reports/models/tender_security_filters.dart';
import 'package:etender_reports/reports/models/tender_security_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixed so "expiring soon" never depends on when the suite runs.
final DateTime asOf = DateTime(2026, 9, 28);

TenderSecurityRecord build({
  String uniqueNo = 'TS/2026/000001',
  String tenderNo = 'T.10001',
  String vendorName = 'Vendor A Sdn Bhd',
  String paymentType = 'BANK_GUARANTEE',
  double amount = 30000,
  String? expiry = '2026-12-31',
  bool originalCopyReceived = true,
  String? submittedToRevenueAssuranceDate = '2026-09-22',
  Object? unsuccessfulTenderer,
  String? refundDate,
}) => TenderSecurityRecord.fromJson({
  'tenderNo': tenderNo,
  'vendorName': vendorName,
  'uniqueNo': uniqueNo,
  'amount': amount,
  'bankName': 'Maybank',
  'paymentType': paymentType,
  'referenceNo': 'BK00101102',
  'scanCopy': '/files/tender-security/TS-2026-000001.pdf',
  'expiryDate': expiry,
  'originalCopyReceived': originalCopyReceived,
  'submittedToRevenueAssuranceDate': submittedToRevenueAssuranceDate,
  'unsuccessfulTenderer': unsuccessfulTenderer,
  'refundDate': refundDate,
});

void main() {
  group('parsing', () {
    test('reads every field', () {
      final record = build();
      expect(record.uniqueNo, 'TS/2026/000001');
      expect(record.amount, 30000);
      expect(record.expiryDate, DateTime(2026, 12, 31));
      expect(record.submittedToRevenueAssuranceDate, DateTime(2026, 9, 22));
      expect(record.paymentTypeValue, PaymentType.bankGuarantee);
      expect(record.paymentTypeLabel, 'Bank Guarantee');
      expect(record.scanCopy, isNotNull);
    });

    test('unsuccessfulTenderer keeps all three states apart', () {
      // The field that must not be flattened: blank is not NO.
      expect(
        build(unsuccessfulTenderer: 'YES').outcome,
        UnsuccessfulTenderer.yes,
      );
      expect(
        build(unsuccessfulTenderer: 'NO').outcome,
        UnsuccessfulTenderer.no,
      );
      expect(
        build(unsuccessfulTenderer: null).outcome,
        UnsuccessfulTenderer.notDecided,
      );
      expect(build(unsuccessfulTenderer: null).unsuccessfulTenderer, isNull);
    });

    test('anything unrecognised reads as undecided, never as NO', () {
      // An empty string, a stray value and an absent key must not look like
      // a decision that the tenderer was successful.
      for (final value in ['', 'maybe', 'yes', 0]) {
        expect(
          build(unsuccessfulTenderer: value).outcome,
          UnsuccessfulTenderer.notDecided,
          reason: '$value should read as undecided',
        );
      }
      final absent = TenderSecurityRecord.fromJson({'uniqueNo': 'TS/1'});
      expect(absent.outcome, UnsuccessfulTenderer.notDecided);
    });

    test('an unknown payment code shows itself rather than a blank', () {
      expect(build(paymentType: 'CRYPTO').paymentTypeLabel, 'CRYPTO');
      expect(build(paymentType: 'CRYPTO').paymentTypeValue, isNull);
    });

    test('a blank RA date means not submitted', () {
      expect(build().isSubmittedToRevenueAssurance, isTrue);
      expect(
        build(submittedToRevenueAssuranceDate: null)
            .isSubmittedToRevenueAssurance,
        isFalse,
      );
    });

    test('survives a round trip through json', () {
      final record = build(
        unsuccessfulTenderer: 'YES',
        refundDate: '2026-09-23',
      );
      expect(TenderSecurityRecord.fromJson(record.toJson()), record);
    });
  });

  group('state of a row', () {
    test('days to expiry counts whole days, negative once lapsed', () {
      expect(
        tenderSecurityDaysToExpiry(build(expiry: '2026-10-08'), asOf: asOf),
        10,
      );
      expect(
        tenderSecurityDaysToExpiry(build(expiry: '2026-09-25'), asOf: asOf),
        -3,
      );
      expect(tenderSecurityDaysToExpiry(build(expiry: null)), isNull);
    });

    test('expiring soon is the window before expiry, inclusive', () {
      for (final days in [0, 1, kTenderSecurityExpiringSoonDays]) {
        expect(
          tenderSecurityIsExpiringSoon(
            build(expiry: asOf.add(Duration(days: days)).toIso8601String()),
            asOf: asOf,
          ),
          isTrue,
          reason: '$days days out should count',
        );
      }
      expect(
        tenderSecurityIsExpiringSoon(
          build(
            expiry: asOf
                .add(const Duration(days: kTenderSecurityExpiringSoonDays + 1))
                .toIso8601String(),
          ),
          asOf: asOf,
        ),
        isFalse,
      );
    });

    test('a refunded security is neither expired nor expiring', () {
      // Its expiry stopped mattering when the money went back.
      final lapsed = build(expiry: '2026-01-01', refundDate: '2026-09-23');
      expect(tenderSecurityIsRefunded(lapsed), isTrue);
      expect(tenderSecurityIsExpired(lapsed, asOf: asOf), isFalse);
      expect(tenderSecurityIsExpiringSoon(lapsed, asOf: asOf), isFalse);
    });

    test('pending refund needs an explicit YES', () {
      expect(
        tenderSecurityIsPendingRefund(build(unsuccessfulTenderer: 'YES')),
        isTrue,
      );
      // Undecided is not the same as owed back.
      expect(
        tenderSecurityIsPendingRefund(build(unsuccessfulTenderer: null)),
        isFalse,
      );
      expect(
        tenderSecurityIsPendingRefund(build(unsuccessfulTenderer: 'NO')),
        isFalse,
      );
      expect(
        tenderSecurityIsPendingRefund(
          build(unsuccessfulTenderer: 'YES', refundDate: '2026-09-23'),
        ),
        isFalse,
      );
    });
  });

  group('summary', () {
    final records = [
      build(uniqueNo: 'TS/1', amount: 30000),
      build(uniqueNo: 'TS/2', amount: 85000, refundDate: '2026-09-23'),
      build(
        uniqueNo: 'TS/3',
        amount: 5000,
        originalCopyReceived: false,
        submittedToRevenueAssuranceDate: null,
      ),
    ];

    test('total counts everything, held excludes what went back', () {
      expect(tenderSecurityTotal(records), 120000);
      expect(tenderSecurityHeld(records), 35000);
    });

    test('counts the states the cards show', () {
      expect(tenderSecurityRefundedCount(records), 1);
      expect(tenderSecurityOriginalNotReceivedCount(records), 1);
      expect(tenderSecurityNotSubmittedCount(records), 1);
    });
  });

  group('filters', () {
    test('tender number and tenderer both match on a fragment', () {
      const byTender = TenderSecurityFilters(tenderNoQuery: 't.100');
      expect(byTender.matches(build()), isTrue);
      expect(byTender.matches(build(tenderNo: 'Q.20417')), isFalse);

      const byVendor = TenderSecurityFilters(vendorQuery: 'vendor a');
      expect(byVendor.matches(build()), isTrue);
      expect(byVendor.matches(build(vendorName: 'Vendor B Sdn Bhd')), isFalse);
    });

    test('payment type filters on the code, not the label', () {
      const filters = TenderSecurityFilters(paymentType: 'BANK_DRAFT');
      expect(filters.matches(build(paymentType: 'BANK_DRAFT')), isTrue);
      expect(filters.matches(build()), isFalse);
    });

    test('every named view picks out what it says', () {
      bool shows(TenderSecurityView view, TenderSecurityRecord record) =>
          TenderSecurityFilters(view: view).matches(record, asOf: asOf);

      expect(shows(TenderSecurityView.all, build()), isTrue);
      expect(
        shows(TenderSecurityView.expired, build(expiry: '2026-09-25')),
        isTrue,
      );
      expect(
        shows(TenderSecurityView.expiringSoon, build(expiry: '2026-10-08')),
        isTrue,
      );
      expect(
        shows(TenderSecurityView.refunded, build(refundDate: '2026-09-23')),
        isTrue,
      );
      expect(
        shows(
          TenderSecurityView.pendingRefund,
          build(unsuccessfulTenderer: 'YES'),
        ),
        isTrue,
      );
      expect(
        shows(
          TenderSecurityView.originalNotReceived,
          build(originalCopyReceived: false),
        ),
        isTrue,
      );
      expect(
        shows(
          TenderSecurityView.notSubmitted,
          build(submittedToRevenueAssuranceDate: null),
        ),
        isTrue,
      );
    });

    test('toggling a view twice returns to All', () {
      const filters = TenderSecurityFilters();
      final expired = filters.toggleView(TenderSecurityView.expired);
      expect(expired.view, TenderSecurityView.expired);
      expect(
        expired.toggleView(TenderSecurityView.expired).view,
        TenderSecurityView.all,
      );
    });

    test('copyWith clears the nullable field rather than ignoring null', () {
      const filters = TenderSecurityFilters(paymentType: 'BANK_DRAFT');
      expect(filters.copyWith(paymentType: null).paymentType, isNull);
      expect(filters.copyWith(vendorQuery: 'x').paymentType, 'BANK_DRAFT');
    });
  });

  group('the PATCH body', () {
    test('carries only what changed', () {
      const patch = TenderSecurityPatch(originalCopyReceived: true);
      expect(patch.toJson(), {'originalCopyReceived': true});
      expect(const TenderSecurityPatch().toJson(), isEmpty);
    });

    test('an explicit clear sends null, an untouched field sends nothing', () {
      // The distinction the whole patch shape exists for.
      expect(const TenderSecurityPatch(clearRefundDate: true).toJson(), {
        'refundDate': null,
      });
      expect(
        const TenderSecurityPatch(clearUnsuccessfulTenderer: true).toJson(),
        {'unsuccessfulTenderer': null},
      );
      expect(
        const TenderSecurityPatch(clearSubmittedToRevenueAssuranceDate: true)
            .toJson(),
        {'submittedToRevenueAssuranceDate': null},
      );
    });

    test('the outcome travels as the blueprint spells it', () {
      expect(const TenderSecurityPatch(unsuccessfulTenderer: 'YES').toJson(), {
        'unsuccessfulTenderer': 'YES',
      });
    });

    test('false is a value, not an absence', () {
      expect(const TenderSecurityPatch(originalCopyReceived: false).toJson(), {
        'originalCopyReceived': false,
      });
    });
  });

  group('editing a record', () {
    test('copyWith changes one field and leaves the rest', () {
      final record = build();
      final edited = record.copyWith(originalCopyReceived: false);
      expect(edited.originalCopyReceived, isFalse);
      expect(edited.uniqueNo, record.uniqueNo);
      expect(edited.amount, record.amount);
    });

    test('clearing beats setting, so a clear is never ignored', () {
      expect(
        build(refundDate: '2026-09-23')
            .copyWith(clearRefundDate: true)
            .refundDate,
        isNull,
      );
      expect(
        build(unsuccessfulTenderer: 'YES')
            .copyWith(clearUnsuccessfulTenderer: true)
            .unsuccessfulTenderer,
        isNull,
      );
      expect(
        build()
            .copyWith(clearSubmittedToRevenueAssuranceDate: true)
            .submittedToRevenueAssuranceDate,
        isNull,
      );
    });
  });

  group('section 8.6 validity periods', () {
    test('120 days for Work or Service, 90 for Supply & Delivery', () {
      expect(kPrevailingPppValidityDays['Work'], 120);
      expect(kPrevailingPppValidityDays['Service'], 120);
      expect(kPrevailingPppValidityDays['Supply & Delivery'], 90);
    });

    test('the three requirement options round-trip', () {
      for (final option in TenderSecurityRequirement.values) {
        expect(TenderSecurityRequirement.fromWire(option.wireValue), option);
      }
      expect(TenderSecurityRequirement.fromWire('SOMETHING_ELSE'), isNull);
    });
  });

  group('the sample set', () {
    for (final day in [
      DateTime(2026, 9, 28),
      DateTime(2026, 1, 1),
      DateTime(2026, 12, 31),
      DateTime(2028, 2, 29),
    ]) {
      test('read on ${day.year}-${day.month}-${day.day}, every view fills', () {
        final records = [
          for (final json in buildTenderSecurityRecords(asOf: day))
            TenderSecurityRecord.fromJson(json),
        ];
        expect(records, hasLength(5));

        for (final view in TenderSecurityView.values) {
          expect(
            records.where((r) => view.matches(r, asOf: day)),
            isNotEmpty,
            reason: 'nothing shows under "${view.label}"',
          );
        }
      });
    }

    test('covers every payment type and every outcome', () {
      final records = [
        for (final json in buildTenderSecurityRecords(asOf: asOf))
          TenderSecurityRecord.fromJson(json),
      ];
      expect(
        records.map((r) => r.paymentTypeValue).toSet(),
        PaymentType.values.toSet(),
      );
      expect(
        records.map((r) => r.outcome).toSet(),
        UnsuccessfulTenderer.values.toSet(),
      );
    });

    test('unique numbers follow TS/YYYY/NNNNNN and are distinct', () {
      final numbers = [
        for (final json in buildTenderSecurityRecords(asOf: asOf))
          json['uniqueNo'] as String,
      ];
      expect(numbers.toSet(), hasLength(numbers.length));
      for (final number in numbers) {
        expect(number, matches(RegExp(r'^TS/\d{4}/\d{6}$')));
      }
    });

    test('nothing is refunded without having lost the tender', () {
      for (final json in buildTenderSecurityRecords(asOf: asOf)) {
        final record = TenderSecurityRecord.fromJson(json);
        if (record.refundDate == null) continue;
        expect(
          record.outcome,
          UnsuccessfulTenderer.yes,
          reason: '${record.uniqueNo} refunded but not marked unsuccessful',
        );
      }
    });
  });
}
