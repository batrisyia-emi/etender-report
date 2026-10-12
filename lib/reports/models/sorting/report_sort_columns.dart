// lib/reports/models/sorting/report_sort_columns.dart
//
// One entry per table column, in the same order as the columns. null means
// that column is not sortable, and only value and date columns are.
//
// Keep these lists in step with the tables: a mismatch sorts by the wrong
// field rather than failing loudly.
import 'package:etender_reports/reports/models/sorting/report_sorting.dart';

/// Tender/quotation summary — 15 columns, 5 sortable.
final List<SortableColumn?> tenderSortColumns = [
  null, // 0  Tender/Quotation No
  null, // 1  Title
  null, // 2  Ref No
  null, // 3  Category
  null, // 4  Division
  null, // 5  Department
  SortableColumn.number('value'), // 6  Tender Value
  null, // 7  Mode of Procurement
  null, // 8  Envelope
  null, // 9  Item Type
  SortableColumn.date('endorsedDate'), // 10 RFC Endorsed Date
  SortableColumn.date('floatingDate'), // 11 Published Date
  SortableColumn.date('openingDate'), // 12 Tender Opening Date
  SortableColumn.date('closingDate'), // 13 Tender Closing Date
  null, // 14 Tender Overall Status
];

/// Vendor participation — 9 columns, 2 sortable. The only value or date
/// column on this report is the submission timestamp.
final List<SortableColumn?> vendorSortColumns = [
  null, // 0 Tender/Quotation ID
  null, // 1 Tender Description
  null, // 2 Vendor Name
  null, // 3 Document Purchased
  null, // 4 Tender Respond Status
  SortableColumn.date('requestedDate'), // 5 Requested Date
  SortableColumn.date('submissionDateTime'), // 6 Submission Date
  null, // 7 Open To
  null, // 8 Vendor Certification Type
];

/// eRFC lifecycle — 12 columns, 5 sortable.
///
/// Aging is left off to match "value and date columns only". It is derived
/// from the submission date, so if you want it sortable later, swap the last
/// entry for:
///
///   SortableColumn.computed((record) => erfcAgingDays(record)),
///
/// and set that column's sortable flag back to true in
/// erfc_report_table.dart.
final List<SortableColumn?> erfcSortColumns = [
  null, // 0 RFC Number
  null, // 1 Subject
  null, // 2 Division
  null, // 3 Department
  null, // 4 Mode of Procurement
  SortableColumn.number('value'), // 5
  SortableColumn.date('submissionDate'), // 6
  SortableColumn.date('verified1Date'), // 7
  SortableColumn.date('verified2Date'), // 8
  SortableColumn.date('endorsedDate'), // 9
  null, // 10 eRFC Status
  null, // 11 Aging
];

/// Supplier view - 11 columns, 6 sortable. Same rule as the others: only
/// value and date columns sort.
///
/// There is no Supplier column: the report is the signed-in supplier's own,
/// and naming the supplier on each row would tell them who else bid.
final List<SortableColumn?> supplierSortColumns = [
  null, // 0  Tender/Quotation No
  null, // 1  Title
  null, // 2  Category
  SortableColumn.date('publishedDate'), // 3
  SortableColumn.date('requestDate'), // 4
  SortableColumn.date('decisionDate'), // 5
  SortableColumn.number('documentFee'), // 6
  SortableColumn.date('closingDate'), // 7
  SortableColumn.number('bidAmount'), // 8
  null, // 9  Status
  null, // 10 Days to Close
];
