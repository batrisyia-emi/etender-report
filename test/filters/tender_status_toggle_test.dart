// test/filters/tender_status_toggle_test.dart
import 'package:etender_reports/reports/models/report_filters.dart';
import 'package:flutter_test/flutter_test.dart';

/// The overview cards tap through [TenderFilters.toggleStatuses], so tapping
/// the card you are already filtered by clears the filter instead of
/// reapplying it.
void main() {
  const pending = {'Draft', 'Submitted', 'Verified'};
  const closed = {'Closed'};

  test('tapping a group applies it', () {
    const filters = TenderFilters();
    expect(filters.toggleStatuses(closed).statuses, closed);
  });

  test('tapping the same group again clears it', () {
    final applied = const TenderFilters().toggleStatuses(closed);
    expect(applied.toggleStatuses(closed).statuses, isEmpty);
  });

  test('tapping a different group switches rather than clears', () {
    final applied = const TenderFilters().toggleStatuses(closed);
    expect(applied.toggleStatuses(pending).statuses, pending);
  });

  test('a multi-status group toggles as one unit', () {
    final applied = const TenderFilters().toggleStatuses(pending);
    expect(applied.statuses, pending);
    expect(applied.toggleStatuses(pending).statuses, isEmpty);
  });

  test('order does not matter when comparing the selection', () {
    final applied = const TenderFilters().toggleStatuses(pending);
    expect(
      applied.hasExactStatuses({'Verified', 'Submitted', 'Draft'}),
      isTrue,
    );
    expect(
      applied.toggleStatuses({'Verified', 'Submitted', 'Draft'}).statuses,
      isEmpty,
    );
  });

  test('a subset is not the same selection, so it applies instead', () {
    final applied = const TenderFilters().toggleStatuses(pending);
    expect(applied.hasExactStatuses({'Draft'}), isFalse);
    expect(applied.toggleStatuses({'Draft'}).statuses, {'Draft'});
  });

  test('toggling leaves the other filters alone', () {
    const filters = TenderFilters(searchQuery: 'cable', minimumValue: 1000);
    final toggled = filters.toggleStatuses(closed);
    expect(toggled.searchQuery, 'cable');
    expect(toggled.minimumValue, 1000);
    expect(toggled.toggleStatuses(closed).searchQuery, 'cable');
  });
}
