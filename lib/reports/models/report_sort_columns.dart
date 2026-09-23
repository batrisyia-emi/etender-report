// lib/reports/models/report_sort_columns.dart
//
// One entry per table column, in the same order as the columns. null means
// that column is not sortable, and only value and date columns are.
//
// Keep these lists in step with the tables: a mismatch sorts by the wrong
// field rather than failing loudly.
import 'package:etender_reports/reports/models/report_sorting.dart';

/// Tender/quotation summary — 15 columns, 4 sortable.
final List<SortableColumn?> tenderSortColumns = [
  null, // 0  Ref No
  null, // 1  Tender/Quotation No
  null, // 2  Title
  null, // 3  Category
  null, // 4  Division
  null, // 5  Department
  null, // 6  Unit
  SortableColumn.number('value'), // 7  Tender Value
  null, // 8  Mode of Procurement
  null, // 9  Envelope
  null, // 10 Item Type
  SortableColumn.date('endorsedDate'), // 11 RFC Endorsed Date
  SortableColumn.date('floatingDate'), // 12
  SortableColumn.date('closingDate'), // 13 Tender Closing Date
  null, // 14 Status
];

/// Vendor participation — 9 columns, 1 sortable. The only value or date
/// column on this report is the submission timestamp.
final List<SortableColumn?> vendorSortColumns = [
  null, // 0 Tender/Quotation ID
  null, // 1 Vendor Name
  null, // 2 Invitation Status
  null, // 3 Document Purchased
  null, // 4 Participation
  null, // 5 Submission Status
  SortableColumn.date('submissionDateTime'), // 6
  null, // 7 Open To
  null, // 8 Vendor Certification Type
];

/// eRFC lifecycle — 11 columns, 5 sortable.
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
  null, // 1 Division / Dept
  null, // 2 Unit
  null, // 3 Mode of Procurement
  SortableColumn.number('value'), // 4
  SortableColumn.date('submissionDate'), // 5
  SortableColumn.date('verified1Date'), // 6
  SortableColumn.date('verified2Date'), // 7
  SortableColumn.date('endorsedDate'), // 8
  null, // 9  Current Status
  null, // 10 Aging
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
