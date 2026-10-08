# SESB eTender Reports

A Flutter reporting module for the Sabah Electricity eTender system. It
renders seven reports and two dashboards, split between the two audiences
that use them:

|                   |                                                                                                                                                                                |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Supplier View** | What one signed-in supplier sees: its own dashboard, and its own participation record. Never another supplier's.                                                               |
| **SE View**       | What Sabah Electricity sees: tenders, vendor participation, the eRFC pipeline, Tender Opening Committee status, the tender securities held, and VTM's own Appendix F pipeline. The SE dashboard carries a tab per report, so every one of them has a summary view. |

**This is the frontend only, and every figure in it is mock data.** No
network calls are made. The work of connecting it to a backend is
deliberately confined to two files — see _Where the backend work goes_.

---

## Running it

```bash
flutter pub get
flutter run -d chrome        # or -d windows
```

Nothing else is needed: there is no API to point at, no environment file
and no credentials.

### Tests

```bash
flutter test
```

368 tests, all passing. CI runs the same suite on Linux — see
`.github/workflows/ci.yml`.

`test/bloc/report_bloc_test.dart` is the one to look at before wiring a
backend. All seven report blocs are built the same way, so one suite runs
against each in turn and checks that a failed read surfaces as a failure
rather than an empty report — the case `MockReportRepository` can never
produce, and the one a real API will.

If `flutter test` fails on Windows with _"An Application Control policy has
blocked this file"_, that is Smart App Control refusing Flutter's unsigned
`dartvm.exe`, not a problem with the tests. It has no exclusion list, so
the options are to have IT turn it off, work in WSL2, or lean on CI.

---

## Where the backend work goes

Two interfaces, both in `lib/data/`. Nothing above them knows where data
comes from or what a button does, so wiring a real backend needs no widget
changes.

### Reads — `repositories/report_repository.dart`

Seven methods, one per report. The return types _are_ the contract: each
record class's `fromJson` documents the exact JSON expected, field by
field.

```dart
Future<List<TenderRecord>> fetchTenderRecords();               // GET /reports/tenders
Future<List<VendorParticipationRecord>> fetchVendorParticipationRecords();
Future<List<ErfcRecord>> fetchErfcRecords();                   // GET /reports/erfc
Future<List<TocOpeningRecord>> fetchTocRecords();              // GET /reports/toc-openings
Future<List<TenderSecurityRecord>> fetchTenderSecurityRecords();  // GET /api/vtm/tender-security
Future<List<VtmMonitoringRecord>> fetchVtmMonitoringRecords();   // GET /reports/vtm-monitoring
Future<List<SupplierRecord>> fetchSupplierRecords();
```

Two of the seven carry a confidentiality constraint the server has to hold
up, because the app cannot: `fetchSupplierRecords` must be scoped to the
signed-in supplier, and `fetchTocRecords` must never carry bid data. Both
are documented at the method and in the contract.

- `MockReportRepository` — what ships today. It parses the mock rows through
  the same `fromJson` the real responses will, so the contract is exercised
  on every run.
- `ApiReportRepository` — the skeleton to fill in. Every method throws
  `UnimplementedError` with instructions until implemented.

### Writes — `actions/report_actions.dart`

Twelve methods covering every button that leaves this module or calls a
server. Eleven navigate or upload; one, `updateTenderSecurity`, is the only
write the app makes to a record.

```dart
Future<void> uploadNewDocument();                  // "Upload new"
Future<void> uploadRequiredDocument(String name);  // per-document "Upload"
Future<void> renewDocument(String name);           // "Renew" / "Renew now"
void openTenderForBidding(String tenderNo);        // "Bid now"
void viewTender(String tenderNo);                  // "View"

// TOC report, "Needs Attention" panel
void appointTocCommittee(String tenderNo);         // "Appoint committee"
void startTocOpening(String tenderNo);             // "Start opening"
void fileTocAppendixP(String tenderNo);            // "File Appendix P"
void viewTocOpening(String tenderNo);              // "View"

// Tender Security report — the only editable table
Future<void> updateTenderSecurity(String uniqueNo, TenderSecurityPatch patch);
void openTenderSecurityScanCopy(String url);       // "View" on a scan copy

void openModule(AppModule module);                 // "Back To Menu"
```

`updateTenderSecurity` is the one that matters most: four columns on that
report are edited in the table, and until this is implemented an edit shows
on screen and is lost on reload. The notice says so.

`UnimplementedReportActions` is the default and throws on every call, by
design: an unwired button should say so rather than appear to work.

Every call site routes through `runReportAction` in
`lib/shared/utils/run_report_action.dart`, which catches that one exception
and shows the message in a SnackBar. Without it the throw escapes the
`onTap`, Flutter logs it to the console and the button looks like it did
nothing — the precise confusion the throwing was meant to prevent. Only
`UnimplementedError` is caught, so once you supply a real implementation
its own failures propagate normally.

### Switching it on

```dart
ReportsPage(
  repository: ApiReportRepository(baseUrl: 'https://…/api'),
  actions: MyReportActions(),
)
```

That is the whole integration surface.

See **[docs/api-contract.md](docs/api-contract.md)** for the field tables,
the status vocabularies, and the business rules a server has to enforce.
Three reports have notes of their own:
**[docs/toc-report.md](docs/toc-report.md)** — whose status the server sends
and whose vocabulary depends on the envelope type, with five questions for
the BA still open — and
**[docs/tender-security-report.md](docs/tender-security-report.md)**, which
is the only report that writes, and
**[docs/vtm-monitoring-report.md](docs/vtm-monitoring-report.md)**, whose
status is a graph and whose aging rule changes once a document floats.

---

## Layout

```
lib/
  main.dart                   MaterialApp + theme
  data/
    actions/                  ← what the buttons do          (backend seam)
    repositories/             ← where records come from      (backend seam)
    mock/                     eight mock datasets
    services/                 CSV / Excel export
  reports/
    reports_shell.dart        sidebar + page routing
    report_type.dart          every page the sidebar can open
    bloc/                     one bloc + event + state per report
    models/
      records/                the JSON contract — one class per endpoint
      status/                 the status vocabularies, as enums
      metrics/                the figures the cards and panels count
      filters/                what each filter panel binds to
      attributes/             fixed vocabularies: modes, categories, open-to
      sorting/                table sort helpers
      export/                 CSV / Excel column definitions
    views/                    one file per report and per dashboard
    widgets/                  tables and filter panels by report;
                              cards/ is the KPI rows, shared/ is cross-report
  shared/                     colours, formatters, sidebar, export menu
test/
  bloc/                       all seven report blocs, one shared suite
  helpers/                    the failing and counting repositories
  models/ filters/ sorting/   mirroring the buckets above
  export/ shared/ widgets/
docs/                         the API contract, per-report notes, and the HTML the Supplier View follows
```

`models/` is grouped by what a file *is*, so the seven buckets answer most
"where does this go" questions on their own. `records/` is the one to read
first: those classes are the API contract.

Three conventions worth knowing before editing:

- **Status vocabularies are enums, not strings.** `ErfcStatus`,
  `SupplierStatus`, `TenderStatus`, `TocStatus`. Every comparison goes
  through `fromWire`, so renaming a status is a compile error rather than a
  card that silently counts zero. `TocStatus` carries one extra rule: its
  declaration order is the process order, which `isUnderWay` and the status
  sort both read as an index, and each value declares whether it applies to
  one-envelope tenders, two-envelope tenders or both.
- **A model goes in the bucket matching what it is**, not which report
  uses it. A status enum belongs in `models/status/` even if only one
  report reads it, because the next report usually reads it too.
- **Imports are always `package:`.** Enforced by
  `always_use_package_imports` in `analysis_options.yaml`, alongside rules
  for const-correctness, import ordering and unawaited futures. `dart fix
  --apply` handles almost everything they flag.

---

## Known gaps

Honest list of what is unfinished, for whoever picks this up.

1. ~~The test suite has never executed.~~ **It does now** — 190 tests, all
   passing. The local block was Smart App Control refusing Flutter's
   unsigned `dartvm.exe`; it has since been lifted on the machine this
   was built on. CI runs the same suite on Linux regardless.
2. **The typed record layer is only used at the seam — in four of the five
   reports.** The repository returns `ErfcRecord` etc., but those blocs
   immediately call `toJson()` because their filters, metrics, tables and
   sorting all still work on `Map<String, dynamic>`. Each bloc marks the
   spot. Migrating a report off maps is a self-contained piece of work and
   deletes the duplicate map-based helpers in `*_metrics.dart` when done.

   **The TOC report is already done this way** and is the reference:
   `TocBloc` holds `TocOpeningRecord`, `TocFilters` matches against it and
   `TocReportTable` renders it, with `sortRows` in `report_sorting.dart` as
   the typed counterpart to `sortRecords`. It had no choice — its nested
   `committee` list cannot be searched as a map — but the result is what
   the other four should look like.

3. **`My Participation` is not scoped to one supplier.** It shows all 30
   mock rows across 8 suppliers. The supplier column, the supplier filter
   and the supplier export columns have been removed so no competitor is
   _named_, but the rows are still there. **The server must return only the
   signed-in supplier's rows** — see the contract doc.
4. **The app breaks below ~900px width.** A pre-existing layout fault; the
   collapsed sidebar renders but the page does not. Desktop-only for now.
5. **The supplier dashboard's notifications, vendor score and document
   metadata are invented.** No such data existed; it was added to make the
   panels render. Replace with real sources or drop the panels.
6. **Export is half-wired, and the unwired half is unreferenced.** The CSV
   encoding in `report_export.dart` works and is tested, the Export menu
   exists, and all seven tables accept an `onExport` callback — but no view
   passes one, so the menu never appears. Behind it,
   `data/services/report_export_service.dart` (the only file that touches
   the `excel` and `file_saver` packages) and
   `models/export/report_export_columns.dart` (the per-report column lists)
   are imported by nothing and covered by no test. They are kept because
   they are the missing half of this feature, not refactor debris — wiring
   a view to them is roughly a one-line change, and deleting them would
   also orphan two pubspec dependencies. Treat them as untested until a
   view uses them.
7. **The TOC report rests on five unanswered questions.** A threshold, two
   process questions, one about which form Appendix L is, and one the
   frontend added, listed in
   [docs/toc-report.md](docs/toc-report.md). Each is implemented on a stated
   assumption. Put them to the BA before the report is relied on.
8. **Each table matches its sort keys to its columns by position.** Every
   `*_table.dart` holds a `_sortKeys` list whose order has to line up with
   its `_columns` list, and a `minTableWidth` constant that has to equal
   the column widths plus the gaps. Add a column to one list and not the
   other and the table sorts by the wrong field silently — nothing fails.
   Worth folding into a single column descriptor before the tables are
   extended; left alone here because it would move column widths, and the
   layout is signed off as it stands.
