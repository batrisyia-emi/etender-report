# SESB eTender Reports

A Flutter reporting module for the Sabah Electricity eTender system. It
renders four reports and two dashboards, split between the two audiences
that use them:

| | |
|---|---|
| **Supplier View** | What one signed-in supplier sees: its own dashboard, and its own participation record. Never another supplier's. |
| **SE View** | What Sabah Electricity sees: tenders, vendor participation and the eRFC pipeline across everyone. |

**This is the frontend only, and every figure in it is mock data.** No
network calls are made. The work of connecting it to a backend is
deliberately confined to two files — see *Where the backend work goes*.

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

⚠️ **The suite has never been run on the original development machine.**
Windows Smart App Control blocks the unsigned `flutter_tester.exe`, so
every local run failed before executing a single test. CI runs them on
Linux, where that policy does not apply — see `.github/workflows/ci.yml`.
Treat the first CI run as the first real feedback on the tests.

---

## Where the backend work goes

Two interfaces, both in `lib/data/`. Nothing above them knows where data
comes from or what a button does, so wiring a real backend needs no widget
changes.

### Reads — `repositories/report_repository.dart`

Four methods, one per report. The return types *are* the contract: each
record class's `fromJson` documents the exact JSON expected, field by
field.

```dart
Future<List<TenderRecord>> fetchTenderRecords();               // GET /reports/tenders
Future<List<VendorParticipationRecord>> fetchVendorParticipationRecords();
Future<List<ErfcRecord>> fetchErfcRecords();                   // GET /reports/erfc
Future<List<SupplierRecord>> fetchSupplierRecords();
```

- `MockReportRepository` — what ships today. It parses the mock rows through
  the same `fromJson` the real responses will, so the contract is exercised
  on every run.
- `ApiReportRepository` — the skeleton to fill in. Every method throws
  `UnimplementedError` with instructions until implemented.

### Writes — `actions/report_actions.dart`

Six methods covering every button that leaves this module or calls a server.

```dart
Future<void> uploadNewDocument();                  // "Upload new"
Future<void> uploadRequiredDocument(String name);  // per-document "Upload"
Future<void> renewDocument(String name);           // "Renew" / "Renew now"
void openTenderForBidding(String tenderNo);        // "Bid now"
void viewTender(String tenderNo);                  // "View"
void openModule(AppModule module);                 // RFC · Tender/Quotation · TOC Review · Main menu
```

`UnimplementedReportActions` is the default and throws on every call, by
design: an unwired button should say so rather than appear to work.

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

---

## Layout

```
lib/
  main.dart                   MaterialApp + theme
  data/
    actions/                  ← what the buttons do          (backend seam)
    repositories/             ← where records come from      (backend seam)
    mock/                     five mock datasets
    services/                 CSV / Excel export
  reports/
    reports_shell.dart        sidebar + page routing
    report_type.dart          every page the sidebar can open
    bloc/                     one bloc + event + state per report
    models/                   records, metrics, status enums, filters, sorting
    views/                    one file per report and per dashboard
    widgets/                  tables, filter panels, cards; `shared/` is cross-report
  shared/                     colours, formatters, sidebar, export menu
test/                         mirrors lib/
docs/                         this contract, and the HTML the Supplier View follows
```

Two conventions worth knowing before editing:

- **Status vocabularies are enums, not strings.** `ErfcStatus`,
  `SupplierStatus`, `TenderStatus`. Every comparison goes through
  `fromWire`, so renaming a status is a compile error rather than a card
  that silently counts zero.
- **Imports are always `package:`.** Enforced by
  `always_use_package_imports` in `analysis_options.yaml`.

---

## Known gaps

Honest list of what is unfinished, for whoever picks this up.

1. **The test suite has never executed.** See above.
2. **The typed record layer is only used at the seam.** The repository
   returns `ErfcRecord` etc., but the blocs immediately call `toJson()`
   because the filters, metrics, tables and sorting all still work on
   `Map<String, dynamic>`. Each bloc marks the spot. Migrating a report off
   maps is a self-contained piece of work and deletes the duplicate
   map-based helpers in `*_metrics.dart` when done.
3. **`My Participation` is not scoped to one supplier.** It shows all 30
   mock rows across 8 suppliers. The supplier column, the supplier filter
   and the supplier export columns have been removed so no competitor is
   *named*, but the rows are still there. **The server must return only the
   signed-in supplier's rows** — see the contract doc.
4. **The app breaks below ~900px width.** A pre-existing layout fault; the
   collapsed sidebar renders but the page does not. Desktop-only for now.
5. **The supplier dashboard's notifications, vendor score and document
   metadata are invented.** No such data existed; it was added to make the
   panels render. Replace with real sources or drop the panels.
