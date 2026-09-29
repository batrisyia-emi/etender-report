# VTM Tender/Quotation Monitoring

Notes for whoever picks this report up.

Source: the VTM Tender/Quotation Monitoring spec, against Blueprint v1.3
(27.08.2026). Read by VTM users. It tracks an Appendix F from preparation
through verification and approval to floating.

---

## It is keyed by the eRFC, not the tender

The tender or quotation number is allocated when the Appendix F is approved.
Everything before that has no number — in the sample, five rows of eight. So
`erfcNo` leads the table, leads the filter panel, and identifies every row
on the Needs Attention panel.

The tender-number search is still there, because once a document is approved
that is what people quote. But it matches nothing on the rows still in
flight, and the panel is ordered to make that obvious.

---

## The status has a shape

Seven codes, forming a graph rather than a line:

| Status | Owner | Goes to |
|---|---|---|
| `DRAFT` | Admin Supervisor / SE Clerk | Submitted |
| `SUBMITTED` | Admin Supervisor / SE Clerk | Verified **or** Rejected by Exec |
| `VERIFIED_BY_EXEC` | Executive | Approved **or** Rejected by Manager |
| `REJECTED_BY_EXEC` | Executive | back to Submitted |
| `APPROVED_BY_MANAGER` | Manager / Sr. Manager | Published |
| `REJECTED_BY_MANAGER` | Manager / Sr. Manager | back to Submitted |
| `PUBLISHED` | Admin Supervisor / SE Clerk | — terminal |

**Both rejections return to Submitted, not to Draft.** The document goes
back to its preparer for correction and is resubmitted; it is not started
again. That is what `nextStatuses` encodes, and a test walks the graph from
Draft to prove every status is reachable and that only Published is a dead
end.

The status chip's tooltip carries the description, the owning role and what
happens next, so a reader does not have to know the process to read the
column.

Sent by the server as a code. An unrecognised one renders as itself in a
grey chip rather than as a blank.

---

## Aging answers two different questions

Days from eRFC endorsement to **today** while the document is moving; days
from endorsement to the **floating date** once it is published.

That is the report's own rule and it is deliberate. While a document is in
flight the useful number is how long it has been waiting, which has to count
to today or it stops meaning anything. Once it floats the useful number is
how long it took, and that stops moving.

`agingDays` arrives in the payload and is **ignored**: a number computed when
the payload was generated is stale by the time anyone reads it. See
`vtmAgingDays`.

The "sitting too long" threshold is `kVtmSlowDays = 21` — an assumption, since
the blueprint sets no limit on preparation. A published document is never
slow: it is finished, however long it took.

---

## One card comes from another endpoint

**Outstanding Tender Security** is the only figure on this report that is
not computed from its own records. It is `tenderSecurityHeld()` over the
tender security dataset — everything lodged, less anything already
refunded — so the screen calls `fetchTenderSecurityRecords()` as well as
`fetchVtmMonitoringRecords()`.

Two consequences, both deliberate:

- **The report's filters do not narrow it.** Filter the table down to one
  division and this card does not move, because the securities are not
  this report's rows. The footer says "across all tenders" so a reader is
  not left to infer that.
- **A missing tender security endpoint does not fail this report.** The
  second read is wrapped separately: if it throws, `securities` stays
  empty, the card shows a dash and "No tender security data", and the rest
  of the report loads normally. Wiring the two endpoints in different weeks
  is the expected case, not an error.

A dash rather than RM 0 when there is nothing to read, because zero held
and no data are different statements.

`test/bloc/vtm_monitoring_bloc_test.dart` pins all of this down.

---

## What the Needs Attention panel raises

| Finding | Severity | Why |
|---|---|---|
| Rejected with no reason given | high | the remark is the whole point of a rejection — without it the preparer cannot act |
| Sitting more than 21 days | high if rejected, else medium | a rejection left untouched is worse than a queue |
| Approved, not floated | medium | one step left and nobody has taken it |
| Published with no tender number | medium | the record and its own status disagree |

---

## Mode of procurement: five, not sixteen

`7.1` `7.2` `7.3` `7.5` `7.6`, by their Appendix A section 7 numbers, with the
same wording `kProcurementModes` uses elsewhere.

Section **7.4, Direct Negotiation, is absent on purpose**: a directly
negotiated purchase is never floated to suppliers, so it has no Appendix F to
monitor. The spec's own filter list omits it too. A 7.4 arriving here shows
as the bare code — a finding rather than something hidden behind a blank
cell.

---

## The sample data is dated relative to today

`buildVtmMonitoringRecords()` builds every date as an offset from the day the
report is opened, like the TOC and tender security samples, and for the same
reason: aging counts to today for anything in flight.

Eight rows, one per status, five tenders and three quotations — which is the
spec's own `byStatus` and `byDocumentType` summary, asserted by a test at four
different read dates. Further tests pin that only approved or published rows
carry a tender number, that every rejected row says why, and that the step
trail never runs backwards.

Staff are named by role rather than by person, which is how the spec's own
sample reads and which suits a report about who owes the next step.

---

## Where things live

| Thing | File |
|---|---|
| Status graph, procurement modes, tender type | `lib/reports/models/status/vtm_monitoring_status.dart` |
| Record and the JSON contract | `lib/reports/models/records/vtm_monitoring_record.dart` |
| Aging, summary figures, findings | `lib/reports/models/metrics/vtm_monitoring_metrics.dart` |
| Filters | `lib/reports/models/filters/vtm_monitoring_filters.dart` |
| Bloc, event, state | `lib/reports/bloc/vtm_monitoring/` |
| Page | `lib/reports/views/vtm_monitoring_view.dart` |
| Summary cards | `lib/reports/widgets/cards/vtm_monitoring_kpi_cards.dart` |
| Filter panel, table, findings panel | `lib/reports/widgets/vtm_monitoring/` |
| Sample data | `lib/data/mock/vtm_monitoring_records.dart` |
| Endpoint contract | `docs/api-contract.md`, section 7 |
