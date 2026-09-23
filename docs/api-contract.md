# API contract

What each endpoint must return, and the rules a server has to enforce.

The authoritative source is each record class's `fromJson` in
`lib/reports/models/records/`. This document mirrors it; if the two ever
disagree, the code wins.

> **Note on the sample data.** The mock records in `lib/data/mock/` name
> suppliers, staff, vendor registration numbers, bid amounts and SESB's
> division / department / unit structure. Confirm whether any of it derives
> from real procurement records before this repository is made public.

**General rules**

- Every endpoint returns a **JSON array** of objects. No envelope, no
  pagination — the app holds the full set and filters, sorts and searches
  client-side. If server-side filtering is wanted later, add parameters to
  `ReportRepository`; the blocs are the only callers.
- Dates are **ISO-8601 strings** (`2026-09-12T17:00:00`). A `?` below means
  the field may be `null` or absent.
- Strings are never null — send `""` rather than omitting them. Numbers
  default to `0`, booleans to `false`.
- A field the record does not know about is **silently dropped**, so extra
  keys are harmless but useless.

---

## 1. `GET /reports/tenders`

Every tender and quotation. → `TenderRecord`

| Field | Type | Notes |
|---|---|---|
| `referenceNo` | string | e.g. `REF-2026-089` |
| `tenderNo` | string | e.g. `SESB/T/2026/012` |
| `title` | string | |
| `tenderCategory` | string | `Service` · `Supply & Delivery` · `Work` |
| `division` | string | |
| `department` | string | |
| `unit` | string | |
| `value` | number | estimated value, RM |
| `modeOfProcurement` | string | see *Procurement modes* |
| `envelopeType` | string | `1 Envelope` · `2 Envelope` |
| `itemType` | string | `Stock Item` · `Non-Stock Item` |
| `requestedDate` | date? | |
| `endorsedDate` | date? | eRFC endorsement |
| `floatingDate` | date? | published to market |
| `closingDate` | date? | |
| `status` | string | see *Tender status* |
| `erfcId` | string | the eRFC this came from |
| `createdBy` | string | |
| `lastUpdate` | date? | |
| `lastUpdatedBy` | string | |

---

## 2. `GET /reports/vendor-participation`

**One row per vendor per tender invited** — not one per tender.
→ `VendorParticipationRecord`

| Field | Type | Notes |
|---|---|---|
| `referenceNo` | string | |
| `tenderNo` | string | |
| `title` | string | |
| `tenderCategory` | string | |
| `division` | string | |
| `vendorName` | string | |
| `invitationStatus` | string | `Sent` · `Not Sent` |
| `documentPurchased` | boolean | |
| `participationStatus` | string | `Participated` · `Rejected` |
| `submissionStatus` | string | `Submitted` · `Late` · `Not Submitted` |
| `submissionDateTime` | date? | null unless submitted |
| `openTo` | string | see *Open to* |
| `vendorCategory` | string | `Bumiputera` · `Non-Bumiputera` |
| `certificationType` | string | see *Certification types* |

### Rules the server must hold

The funnel narrows at every step, and the report's arithmetic assumes it:

```
all records  ⊇  invited  ⊇  participated  ⊇  purchased  ⊇  submitted
```

1. **A vendor cannot participate without being invited** —
   `participationStatus == 'Participated'` requires `invitationStatus == 'Sent'`.
2. **A vendor cannot buy the document without participating** — the document
   only unlocks after clicking participate, so `documentPurchased == true`
   requires `participationStatus == 'Participated'`.
3. **A vendor cannot submit without the document** — `submissionStatus` of
   `Submitted` or `Late` requires `documentPurchased == true`.

Breaking any of these makes a KPI footer read more than its denominator.
The mock data satisfies all three and `test/models/vendor_metrics_test.dart`
pins them.

---

## 3. `GET /reports/erfc`

The eRFC lifecycle. → `ErfcRecord`

| Field | Type | Notes |
|---|---|---|
| `rfcNumber` | string | e.g. `ERFC/2026/00009021` |
| `division` | string | |
| `department` | string | |
| `unit` | string | |
| `modeOfProcurement` | string | |
| `value` | number | requested value, RM |
| `submissionDate` | date? | |
| `verified1Date` | date? | first verification gate |
| `verified2Date` | date? | second verification gate |
| `endorsedDate` | date? | |
| `status` | string | see *eRFC status* |
| `createdBy` | string | |

### Rules

- The two verification dates are **separate gates**, in order. A rejection
  at the first leaves `verified2Date` null.
- Aging freezes at `endorsedDate`, or at the **latest verification reached**
  (`verified2Date ?? verified1Date`) when the RFC was rejected, declined or
  cancelled before endorsement. An in-flight RFC keeps ageing.
- An RFC is **overdue** when it is still in flight and has aged past 14 days
  (`kErfcOverdueDays`).

---

## 4. `GET /reports/supplier-participation`

One row per tender the **signed-in supplier** took part in.
→ `SupplierRecord`

| Field | Type | Notes |
|---|---|---|
| `supplierName` | string | not displayed; see below |
| `supplierId` | string | not displayed; see below |
| `referenceNo` | string | |
| `tenderNo` | string | |
| `title` | string | |
| `tenderCategory` | string | |
| `division` | string | |
| `modeOfProcurement` | string | |
| `openTo` | string | |
| `certificationType` | string | |
| `status` | string | see *Supplier status* |
| `publishedDate` | date? | |
| `requestDate` | date? | request to participate |
| `decisionDate` | date? | approved or rejected |
| `paymentDate` | date? | null until the fee is settled |
| `closingDate` | date? | |
| `submissionDateTime` | date? | |
| `documentFee` | number | RM |
| `bidAmount` | number | RM |

### ⚠️ This endpoint must be scoped server-side

**Return only the signed-in supplier's rows.** The app does not filter by
supplier and has no supplier column, no supplier filter and no supplier
export column — all deliberately removed so one supplier cannot learn who
else bid. That protection is cosmetic only: the rows themselves carry
`bidAmount` and `documentFee`, so returning the whole supplier base would
hand every competitor's bid to whoever is signed in.

`supplierName` and `supplierId` remain in the contract because the record
still parses them, but nothing renders them.

---

## Status vocabularies

Each is an enum in `lib/reports/models/`. Values must match **exactly** —
comparison is by string, and an unknown value renders as a grey chip that
no filter or count will match.

### Tender status — 3

`Published` · `Extended` · `Closed`

Cancellation is *not* one of these; a cancelled tender still reads as
`Closed`.

### eRFC status — 14, in lifecycle order

```
Draft
Submitted
Verified by 1st Verifier      Rejected by 1st Verifier
Verified by 2nd Verifier      Rejected by 2nd Verifier
Endorsed                      Rejected by Endorser
                              Decline
                              Cancelled
Paperwork Received
eRFC Completed
Confirmed to Publish
Closed by System
```

Grouped by the app as:

| Group | Values |
|---|---|
| In flight | Draft, Submitted, Verified by 1st Verifier, Verified by 2nd Verifier |
| Rejected | the three `Rejected by …`, plus Decline |
| Endorsed or beyond | Endorsed, Paperwork Received, eRFC Completed, Confirmed to Publish, Closed by System |
| Cancelled | Cancelled |

In-flight and terminal partition the whole list — every status is in exactly
one.

### Supplier status — 10, in portal order

```
Published
Participation Requested
Request Rejected
Request Approved
Pending Payment
Paid
Participated
No Participate
Draft
Submitted
```

**The review is a single decision.** Which internal gate turned a request
back — clerk, executive, manager — is SE's business; the supplier only ever
sees `Request Rejected`. If SE needs the gate for its own reporting, that
belongs in a separate SE-side field, not in this status.

`No Participate` is set by the system when a tender closes without a bid,
not chosen by the supplier.

### Procurement modes — 16

`Tender/Quotation` · `Selective Tender/Quotation` ·
`Restricted Tender/Quotation` · `Direct Negotiation - Normal` ·
`Direct Negotiation - Emergency` · `Tender Through Pre-Qualification` ·
`Schedule Rate/JHT` · `Direct Purchase using Published Rate` · …

Full list: `lib/reports/models/procurement_modes.dart`.

### Open to — 15

Appendix A 8.1 eligibility, e.g. `Bumiputera Only`,
`Bumiputera (≤ RM250K)`, `Registered Suppliers`, `Open to Public`.
Full list: `lib/reports/models/open_to.dart`.

### Certification types — 7

`CIDB-…` · `KKM-…` · `PUKONSA-…`.
Full list: `lib/reports/models/certification_types.dart`.

---

## Not backed by any real source

The Supplier View dashboard has four panels that were invented to make the
template render. There was no data for them and no endpoint is implied —
decide whether to build one or drop the panel.

| Panel | Mock source |
|---|---|
| Vendor score & profile health (87/100, four PPP criteria) | `supplierProfile` |
| Documents tab (9 mandatory documents, file sizes, upload dates) | `supplierDocuments` |
| Bid pipeline (8 bids with outcomes) | `supplierBidPipeline` |
| Notifications feed | `supplierNotifications` |

All four live in `lib/data/mock/supplier_portal.dart`.

The bid pipeline also uses outcome values — `Under Evaluation`,
`Shortlisted`, `Awarded`, `Unsuccessful` — that exist **only** there.
`SupplierStatus` stops at `Submitted`, because the participation report
never looks past it.
