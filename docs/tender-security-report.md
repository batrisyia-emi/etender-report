# Tender Security Submission

Notes for whoever picks this report up — what was built, where it departs
from the blueprint, and what is still open.

Source: eTender Blueprint v1.3 (27.08.2026), chapter 9.1 Tender Security
Submission (page 85); process flow 3.5 process 1.12. VTM users.

---

## It is the only report that writes

Chapter 9.1 names three functions: Search, List and Update. Update is what
makes this different from every other report here — four columns belong to
VTM and are edited in the table:

| Column | Control | Source |
|---|---|---|
| Original Copy Received | tick box | Appendix F item (m) |
| Submitted to RA/CSU | date, with a clear button | 9.1 List column 7 |
| Unsuccessful Tenderer | YES / NO / Not decided | 9.1 List column 8 |
| Date of Refund | date, with a clear button | 9.1 List column 10 |

An edit goes two places in the same gesture. `TenderSecurityBloc` applies it
to its own copy, so the control the user touched responds and the summary
cards recount. `ReportActions.updateTenderSecurity` is what would make it
stick, and until that is implemented it throws and the notice says the
change is on screen only.

**That is the seam to implement.** Everything else about this report is a
read. See `TenderSecurityPatch` for the body shape.

### Blank is not NO

`unsuccessfulTenderer` carries the blueprint's own `YES` / `NO`, or nothing
at all, and the three mean different things:

- **blank** — VTM has not decided
- **YES** — the tenderer lost, so the security is owed back
- **NO** — the tenderer won, so it stays lodged

Only `YES` puts a row in the Pending Refund queue. A blank defaulted to `NO`
would quietly empty that queue, so the field is kept as the wire string
rather than parsed to a bool, and anything unrecognised — an empty string, a
value from some later vocabulary, an absent key — reads as undecided.

The same distinction shapes the patch: a field left out means "unchanged",
so clearing one needs its own flag (`clearUnsuccessfulTenderer`,
`clearRefundDate`, `clearSubmittedToRevenueAssuranceDate`).

---

## Open items carried from the spec

These are unresolved. Each is implemented on a stated assumption.

**Q1 — Is "Submitted to Revenue Assurance/CSU" a date, a Yes/No or a
reference number?** The blueprint says only "VTM Manual Entry". *Built as a
date, blank meaning not yet submitted*, following the Date of Refund column
beside it. A date is the most informative of the three and degrades to the
other two: a Yes/No reading is "is it blank", and a reference number would
be an extra field rather than a change to this one.

**Q2 — Which screen marks the original copy of the BG/cheque as received?**
The blueprint requires the function (Appendix F item m) without saying where
it lives. *Built here*, as a tick box beside the scan copy, since this is
the screen that already lists every instrument.

**Q3 — What export format?** *Not built.* The table accepts an `onExport`
callback and `ReportExportService` already writes CSV and xlsx, so wiring it
is a one-line change in the view — but the blueprint does not specify the
format and the spec lists xlsx and pdf as a recommendation. PDF has no
support in this app today.

---

## Recommendations from the spec

| | Built |
|---|---|
| **R1** Scan copy as a view link | Yes — a "View" link per row, routed through `ReportActions.openTenderSecurityScanCopy` |
| **R2** Highlight expired instruments not refunded | Yes — red with an icon once lapsed, amber with a countdown while close. A refunded row shows neither: its expiry stopped mattering |
| **R3** Warn when expiry gives less validity than section 8.6 requires | **No** — needs the tender's closing date and category, and the 9.1 endpoint sends neither. The periods are in `kPrevailingPppValidityDays` ready for it |
| **R4** Unique number `TS/YYYY/NNNNNN` | Yes — the sample data follows it and a test asserts the shape |

R2 sets no threshold, so the amber warning window is an assumption:
`kTenderSecurityExpiringSoonDays = 14`. **This is not the blueprint's 14 / 7
/ 5 / 3 day reminder schedule** — those count down to the *tender closing
date* and are sent by the notification engine, not by this screen. The two
are unrelated and it would be easy to conflate them.

---

## Where it departs from the blueprint

Each was a deliberate choice; reverse any of them freely.

| Blueprint | Built as | Why |
|---|---|---|
| `dd.MM.yyyy` dates | `dd/MM/yyyy` | Every other report shares one formatter. Mixing separators across six reports reads as a bug. |
| `MYR#,##0.00` | `RM 30,000.00` | Same reason — `formatValue` is used app-wide. |
| Search on `tenderNo` | Plus tenderer name and payment type | "Which securities is this vendor holding out on?" is the other question people ask of this table. |
| — | A "Show" dropdown of seven named views | Mutually exclusive questions about a row, so one at a time, with All as the way back. |
| — | Five summary cards | Held, expiring, expired, pending refund. The monitoring purpose in 9.1 stated as figures. |

`accessRoles` has no counterpart here: this frontend has no sign-in and no
role check. Whatever serves `/api/vtm/tender-security` has to enforce it.

Not carried on the record, because 9.1 does not send them: project title,
tender closing date, and the submission timestamp. The closing date is what
R3 and the reminder schedule would both need.

---

## The sample data is dated relative to today

`buildTenderSecurityRecords()` builds every date as an offset from the day
the report is opened, like the TOC sample and for the same reason: "expiring
soon" and "expired" are questions about today, and fixed dates answer them
correctly for a fortnight and then stop.

Five rows cover all seven named views, all three payment types and all three
outcome states. `test/models/tender_security_test.dart` reads the set at
four dates — including year and leap-day rollover — and asserts every view
still has something in it.

**One row differs from the blueprint's own sample.** Q.10003 is marked
`YES` rather than left undecided. As written, the sample's only `YES` row is
already refunded, which left the Pending Refund view empty. Marking Q.10003
unsuccessful makes it both expired and owed back — the worst combination the
report can show, and exactly what R2 is for.

Tenderer names are fictional, matching the other mock files. Bank names are
left as real institutions: they name no party to a tender, and one of them
carries a rule worth seeing — the blueprint allows the offshore bank in the
Federal Territory of Labuan alongside the mainland ones.

---

## Where things live

| Thing | File |
|---|---|
| Payment type, outcome, section 8.6 validity periods | `lib/reports/models/tender_security_attributes.dart` |
| Record and the JSON contract | `lib/reports/models/records/tender_security_record.dart` |
| Expiry, refund state, summary figures | `lib/reports/models/tender_security_metrics.dart` |
| Filters and the seven named views | `lib/reports/models/tender_security_filters.dart` |
| Bloc, event, state | `lib/reports/bloc/tender_security/` |
| Page | `lib/reports/views/tender_security_view.dart` |
| Summary cards | `lib/reports/views/cards/tender_security_kpi_cards.dart` |
| Filter panel and the editable table | `lib/reports/widgets/tender_security/` |
| Sample data | `lib/data/mock/tender_security_records.dart` |
| Endpoint contract | `docs/api-contract.md`, sections 5 and 6 |
