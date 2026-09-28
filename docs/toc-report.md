# TOC Appointment & Tender Opening Status

Notes for whoever picks this report up — the decisions the frontend had to
make, and the questions it could not answer on its own.

Source: eTender Blueprint v1.3, sections 3.6, 4.5, 8.3 and 8.4.

---

## ⚠️ This report must never carry bid data

VTM staff read it **before evaluation**, so it deliberately stops short of
anything that would reveal a bid. None of the following may ever reach the
endpoint, the record class or a column:

- Harga Tawaran (Form of Tender / Quotation / Agreement)
- Harga Tawaran (Jadual Harga, Appendix C)
- Tempoh Siap
- Tempoh Sah Laku
- any other Appendix G content
- OTP values

What the report *does* show about Appendix G is only **whether** it was
submitted, **by whom**, and **when**. OTPs appear only as a count of issue
dates, on the Opened cell's tooltip — never a password.

This is enforced by omission rather than by a filter: `TocOpeningRecord` has
no field for any of it, so there is nothing to leak. Adding one is a
confidentiality breach, not a feature. The same warning sits on the record
class and on the table widget.

---

## Status is sent, not derived

Eight stages, and which of them a tender can reach depends on how it takes
its bids.

| Status | Occurs on | |
|---|---|---|
| Open | both | published, taking bids, nobody appointed |
| Committee Appointed | both | three members named |
| Opening in Progress | both | the session has started |
| Technical Opened | **2 Envelope** | the technical envelope is open |
| Commercial Sealed | **2 Envelope** | commercial held sealed during technical evaluation |
| Commercial Opened | **2 Envelope** | commercial opened in turn |
| Tender Opened | **1 Envelope** | the single envelope is open |
| Opening Completed | both | nothing further expected |

**This replaced a derived, three-value vocabulary.** The earlier statuses —
Not Appointed / Pending Declaration / Ready for Opening — were computed from
the committee and its Appendix I/J acknowledgements. These are not: nothing
a frontend can read means "Commercial Sealed". That is VTM's decision about
a physical envelope, and any timestamp the app could infer it from would be
the server having decided it already. So `status` is a field now, and
`deriveTocStatus` is gone.

### The pairing is checked, not corrected

A status outside its envelope arrangement — `Commercial Sealed` on a one
envelope tender, `Tender Opened` on a two — is raised on the Needs Attention
panel and left alone in the table. The app does not know which of the two
values is wrong, and guessing would hide the problem. `TocStatus.appliesTo`
and `TocOpeningRecord.hasEnvelopeMismatch`.

An envelope type the app does not recognise permits every status: better to
show the row than to call it wrong over an arrangement nobody told us about.

### Declaration tracking was dropped with it

Appendix I and J acknowledgements are still on the record — the endpoint
sends them and the blueprint requires them — but nothing renders them, and
no status, column, card or alert depends on them any more.

---

---

## This report is typed end to end

The other four reports unwrap their records to `Map<String, dynamic>` at the
bloc. This one does not: `ReportRepository` → `TocBloc` → `TocFilters` →
`TocReportTable` all pass `TocOpeningRecord`.

The reason is the nested `committee` list. A map row cannot be searched by
member name, counted for declarations or read by role without re-parsing it
on every build and every keystroke.

Treat this as the pattern to follow, not the exception. Migrating the other
four the same way is the known gap recorded in the README.

---

## Exception flags

Four conditions raise a flag, in `tocExceptionFlags`:

| Flag | Severity | Condition | Button |
|---|---|---|---|
| No committee, closing soon | high | `Open` and closing within `kTocClosingSoonDays` | Appoint committee |
| Opening day, not started | high | opening is today and still `Open` or `Committee Appointed` | Start opening, or Appoint committee if there is none |
| Committee cleared by extension | medium | `isExtended` with an empty committee | Appoint committee |
| Status does not match envelope type | medium | a stage this envelope arrangement cannot reach | Open record |
| Appendix P overdue | medium | Appendix G in more than `kTocAppendixPDueDays` ago, P still missing | File Appendix P |

Both thresholds are constants at the top of `toc_metrics.dart`. Neither
comes from the blueprint — see the open questions below.

Each flag carries its remedy as a `TocRemedy`, so the button on a row is
decided by the rule that raised it rather than by the widget guessing. Every
row also gets a quieter **View** button for the opening's own record.

The four buttons are four methods on `ReportActions`:
`appointTocCommittee`, `remindTocDeclarations`, `fileTocAppendixP` and
`viewTocOpening`. All four throw until implemented, and the notice says so
on screen. `remindTocDeclarations` deliberately sends only the tender
number — the server decides who is outstanding, because this app must not
be the authority on who has signed.

---

## Open questions for the BA

These came with the report spec and are **still unanswered**. Each one is
implemented on an assumption that may be wrong.

1. **Which form is Appendix L?** Process 1.4 lists "Appendix L — TEC", but
   Appendix L is the Fuel Ordering Limit of Authority elsewhere in the
   blueprint. Which form does TOC actually require?
   *Not implemented either way — no column exists for it yet.*

2. **Who fills and acknowledges Appendix P?** Section 8.3.4 says all three
   TOC members acknowledge it; section 8.4.2 and Process 1.7 say the VTM
   Executive fills it.
   *Implemented as a single `appendixPSubmittedBy` string. If it turns out
   to need three acknowledgements, it becomes a list, like `appendixGAckAt`
   on the member.*

3. **Direct Negotiation committees.** Should modes 7.4a / 7.4b appear here,
   or is this Tender Opening Committees only?
   *Implemented as Tender Opening Committees only. Nothing filters them out,
   so if the endpoint sends them they will simply appear.*

4. **What counts as "closing soon"?** The blueprint sets no threshold.
   *Assumed 3 days — `kTocClosingSoonDays`.*

A fifth question the frontend added:

5. **Is there a ceiling on committee assignments per officer?** The
   blueprint places none, which is why the Committee Workload panel exists
   at all. If a ceiling is introduced, the panel should flag breaches rather
   than just rank people.

---

## What the table shows, and what moved into a tooltip

The blueprint lists more fields than fit a grid. Laid out one per column
they came to 3740px, so the table could not be read without scrolling
sideways through most of it.

Fifteen columns remain: Tender / Quotation No, Type, Project Title, eRFC
No, Closing, Opening, Committee, Declarations, Memo Sent, Opened, Bids In,
Appendix G, Appendix P, Status, Aging. That is 2333px, in line with the
Tender Summary table.

**Nothing was dropped from the record or the endpoint.** Seven former
columns moved into the cell they belong to:

| Field | Where it is now |
|---|---|
| `isExtended` | marker beside the tender number |
| the three committee members | Committee cell — chairman on screen, all three with staff IDs and signing state in its tooltip |
| `appointedAt` | Committee tooltip |
| `replacements` | Committee tooltip, with the mandatory remarks |
| `memoRefNo` | Memo Sent tooltip |
| `otpIssuedDates` | Opened tooltip, as a count |

If a detail view is built later, that is where these belong in full.

## The page pins only its filters

Everything below the filter panel — the overview cards, Needs Attention,
Committee Workload and the table — scrolls as one column. The filters stay
put at the top, and stay collapsible.

The other four reports do the opposite: they pin the whole page and scroll
only the table's rows. That works for them because they have one panel
above the table. This one has three, which together came to about 700px and
left no room for the table on a laptop screen.

Committee Workload still starts folded, being reference rather than
something to act on. Needs Attention starts open.

Both panels render without their own title strip. `ReportPanel` takes a
nullable `title` for this: the `CollapsibleSection` above each one already
shows the same words, and drawing both put the title on two consecutive
lines.

---

## The sample data is dated relative to today

`buildTocRecords()` builds every date as an offset from the day the report
is opened, rather than from literals.

Two of the four exception flags are about *when*: "no committee, closing
soon" needs a tender closing within `kTocClosingSoonDays`, and
"declarations pending on opening day" needs an opening dated today. With
fixed dates both fired for about a week after they were written and then
went quiet, which made the panel look broken rather than genuinely clear.

`test/models/toc_mock_data_test.dart` reads the set at six different dates —
including month, year and leap-day rollover — and asserts that all three
statuses appear, both envelope arrangements are present, no status
contradicts its envelope, all four flag kinds fire, both severities are
present and
nothing price-shaped is in there. If a future edit to the sample data
breaks the demo, that test says so.

**The other five mock datasets still use literal dates.** They read
correctly today, but `Tenders Closing Soon` on the SE dashboard and
`closing within 7 days` on the supplier dashboard will empty out as those
dates pass. Converting them is the same change as this one.

---

## Where things live

| Thing | File |
|---|---|
| Status, role and document type enums | `lib/reports/models/toc_status.dart` |
| Record classes and the JSON contract | `lib/reports/models/records/toc_opening_record.dart` |
| Status derivation, aging, flags, workload | `lib/reports/models/toc_metrics.dart` |
| Filters | `lib/reports/models/toc_filters.dart` |
| Bloc, event, state | `lib/reports/bloc/toc/` |
| Page | `lib/reports/views/toc_report_view.dart` |
| Summary cards | `lib/reports/views/cards/toc_kpi_cards.dart` |
| Filter panel, table, flag and workload panels | `lib/reports/widgets/toc/` |
| Sample data | `lib/data/mock/toc_records.dart` |
| Endpoint contract | `docs/api-contract.md`, section 4 |
