// test/filters/card_filter_toggle_test.dart
//
// The overview cards on the eRFC and vendor participation reports apply
// their own slice of the data, and clear it when tapped a second time.
import 'package:etender_reports/reports/models/report_filters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('eRFC status groups', () {
    const endorsed = {
      'Endorsed',
      'Ready for Tender/Quotation',
      'Tender Created',
    };
    const cancelled = {'Cancelled'};

    test('tapping a group applies it, tapping again clears it', () {
      final applied = const ErfcFilters().toggleStatuses(endorsed);
      expect(applied.statuses, endorsed);
      expect(applied.toggleStatuses(endorsed).statuses, isEmpty);
    });

    test('a different group switches rather than clears', () {
      final applied = const ErfcFilters().toggleStatuses(endorsed);
      expect(applied.toggleStatuses(cancelled).statuses, cancelled);
    });

    test('toggling leaves the other filters alone', () {
      const filters = ErfcFilters(searchQuery: 'substation');
      final toggled = filters.toggleStatuses(cancelled);
      expect(toggled.searchQuery, 'substation');
      expect(toggled.toggleStatuses(cancelled).searchQuery, 'substation');
    });
  });

  group('eRFC overdue', () {
    test('turns on and off again', () {
      const filters = ErfcFilters();
      expect(filters.overdueOnly, isFalse);
      final on = filters.toggleOverdueOnly();
      expect(on.overdueOnly, isTrue);
      expect(on.toggleOverdueOnly().overdueOnly, isFalse);
    });
  });

  group('vendor funnel cards', () {
    test('invitation status toggles on and off', () {
      final applied = const VendorFilters().toggleInvitationStatus('Sent');
      expect(applied.invitationStatus, 'Sent');
      expect(applied.toggleInvitationStatus('Sent').invitationStatus, isNull);
    });

    test('a different invitation value switches rather than clears', () {
      final applied = const VendorFilters().toggleInvitationStatus('Sent');
      expect(
        applied.toggleInvitationStatus('Not Sent').invitationStatus,
        'Not Sent',
      );
    });

    test('document purchased toggles on and off', () {
      final applied = const VendorFilters().togglePurchaseOption('Yes');
      expect(applied.purchaseOption, 'Yes');
      expect(applied.togglePurchaseOption('Yes').purchaseOption, isNull);
    });

    test('submission statuses toggle as one unit', () {
      const submitted = {'Submitted', 'Late'};
      final applied = const VendorFilters().toggleSubmissionStatuses(submitted);
      expect(applied.submissionStatuses, submitted);
      expect(
        applied.toggleSubmissionStatuses(submitted).submissionStatuses,
        isEmpty,
      );
    });

    test('a subset is a different selection, so it applies', () {
      final applied = const VendorFilters().toggleSubmissionStatuses({
        'Submitted',
        'Late',
      });
      expect(applied.toggleSubmissionStatuses({'Late'}).submissionStatuses, {
        'Late',
      });
    });

    test('each card toggles independently of the others', () {
      final filters = const VendorFilters()
          .toggleInvitationStatus('Sent')
          .togglePurchaseOption('Yes');
      expect(filters.invitationStatus, 'Sent');
      expect(filters.purchaseOption, 'Yes');

      final cleared = filters.togglePurchaseOption('Yes');
      expect(cleared.purchaseOption, isNull);
      expect(cleared.invitationStatus, 'Sent');
    });
  });
}
