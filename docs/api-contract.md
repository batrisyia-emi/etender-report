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
| `documentType` | string | `Tender` · `Quotation` · `""` — see below |
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

### Document type

The Tender Summary report filters on `documentType`. Send `Tender` or
`Quotation`.

A document that is genuinely neither — a fuel order raised under the Fuel
Ordering mode, for example — should send `""`. Those rows appear when the
filter is cleared and drop out once it is set to either value, which is
honest: they are not tenders and they are not quotations. Do not guess a
value to make them match.

The app does **not** derive this from the tender number. `SESB/T/…` and
`SESB/Q/…` look like they encode it, but `SESB/L/…` and `SESB/D/…` also
exist and parsing a reference format is not a contract.

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

## 4. `GET /reports/toc-openings`

One row per tender or quotation, with the Tender Opening Committee
appointed to open it. → `TocOpeningRecord`

Blueprint v1.3 sections 3.6 / 4.5 / 8.3 / 8.4. Design notes, the status
derivation and the unanswered BA questions are in `docs/toc-report.md`.

| Field | Type | Notes |
|---|---|---|
| `tenderNo` | string | e.g. `T.10001`, `T.10001(2S)`, `Q.20417`, `Z.30008` |
| `documentType` | string | `Tender` · `Quotation` |
| `projectTitle` | string | from eRFC section B-1 |
| `erfcNo` | string | |
| `envelopeType` | string | `1 Envelope` · `2 Envelope` — decides which statuses this tender can reach |
| `status` | string | one of eight; **sent, not derived** — see below |
| `closingDateTime` | date? | |
| `openingDateTime` | date? | defaults to 12:00 on the opening day, editable |
| `isExtended` | bool | an extension after appointment clears the committee |
| `committee` | array | empty or **exactly 3** members, see below |
| `appointedAt` | date? | |
| `replacements` | array | member swaps, see below; usually empty |
| `memoRefNo` | string? | `SE/P/UVTM/{QTN\|TN}/FY{yy}/TOC{running no}` |
| `memoSentAt` | date? | the email that replaces the paper Appendix F |
| `otpIssuedDates` | date[] | one per opening day; a second if the opening runs over |
| `openedAt` | date? | |
| `suppliersSubmittedCount` | number | how many bids were in the box |
| `appendixGSubmittedBy` | string? | |
| `appendixGSubmittedAt` | date? | |
| `appendixPSubmittedBy` | string? | |
| `appendixPSubmittedAt` | date? | closes the opening day |

**`committee[]`** → `TocMember`

| Field | Type | Notes |
|---|---|---|
| `role` | string | `Chairman` · `Member 1` · `Member 2` |
| `staffId` | string | |
| `name` | string | |
| `designation` | string | |
| `department` | string | |
| `division` | string | |
| `email` | string | |
| `appendixIAckAt` | date? | non-conflict / confidentiality / anti-corruption |
| `appendixJAckAt` | date? | Integrity Pledge, BM or EN |
| `appendixGAckAt` | date? | follows the Chairman's, per process 1.6 |

**`replacements[]`** → `TocReplacement`

| Field | Type | Notes |
|---|---|---|
| `role` | string | the seat that changed hands |
| `replacedName` | string | |
| `newName` | string | |
| `remarks` | string | **mandatory** per the blueprint |
| `replacedAt` | date? | |
| `replacedBy` | string | who made the change |

### ⚠️ This endpoint must never carry bid data

VTM staff read this report **before evaluation**. The response must not
contain, in any field:

- Harga Tawaran (Form of Tender / Quotation / Agreement)
- Harga Tawaran (Jadual Harga, Appendix C)
- Tempoh Siap
- Tempoh Sah Laku
- any other Appendix G content
- the OTP values themselves

Only *whether* Appendix G was submitted, by whom and when. `otpIssuedDates`
carries issue dates so the report can show a count — never a password.

Unlike the supplier endpoint, this is not enforced by scoping: the record
class simply has no field to put a price in, so extra keys are dropped. Do
not add one.

### Rules

- `committee` is empty **or** exactly three members. Two is treated as
  "not appointed", which will read as a bug to whoever sees it.
- There is **no `status` field**. The app derives it from the timestamps —
  see `docs/toc-report.md`. Sending one has no effect.
- `isExtended: true` with a non-empty committee contradicts the blueprint
  rule that an extension clears the appointment; the app will show the
  committee and not raise the flag.

---

## 5. `GET /api/vtm/tender-security`

One row per **tenderer per tender**: two bidders on one tender lodge two
securities. → `TenderSecurityRecord`

Blueprint v1.3 chapter 9.1; the unique number is generated when the supplier
submits, at process flow 3.5 process 1.12.

| Field | Type | Source | Notes |
|---|---|---|---|
| `tenderNo` | string | System | |
| `vendorName` | string | System | name of tenderer |
| `uniqueNo` | string | System | `TS/YYYY/NNNNNN` — the key PATCH takes |
| `amount` | number | Supplier | RM |
| `bankName` | string | Supplier | must be a bank domiciled in Malaysia, including the Labuan offshore bank |
| `paymentType` | string | Supplier | `CASHIERS_ORDER` · `BANK_DRAFT` · `BANK_GUARANTEE` |
| `referenceNo` | string | Supplier | the bank's own reference |
| `scanCopy` | string? | Supplier | scan of the instrument; mandatory at submission |
| `expiryDate` | date? | Supplier | |
| `originalCopyReceived` | bool | **VTM** | Appendix F item (m) |
| `submittedToRevenueAssuranceDate` | date? | **VTM** | null = not yet submitted |
| `unsuccessfulTenderer` | string? | **VTM** | `YES` · `NO` · null — see below |
| `refundDate` | date? | **VTM** | |

Optional query: `?tenderNo=` — a case-insensitive *contains* match.

### `unsuccessfulTenderer` is three states, not two

Null — or an absent key — means VTM has not decided. That is **not** the
same as `NO`, which means the tenderer won and keeps its security lodged.
Only `YES` puts the row in the refund queue.

Send null for undecided. Do not send `NO` as a stand-in: the report counts
"pending refund" off `YES` alone, and a defaulted `NO` would quietly empty
that queue. Anything the app does not recognise reads as undecided rather
than as `NO`.

### Not sent, and worth knowing

The blueprint's 9.1 list does not include the project title, the tender
closing date or the submission timestamp. The closing date is what the
14/7/5/3-day reminders count down from and what recommendation R3 would
check an expiry against, so if it is available, say so — the app can use it.

---

## 6. `PATCH /api/vtm/tender-security/{uniqueNo}`

Chapter 9.1's Update function: the four VTM-owned fields. This is the app's
only write beyond navigation.

Body carries **only what changed**:

```json
{ "originalCopyReceived": true }
{ "submittedToRevenueAssuranceDate": "2026-09-22T00:00:00.000" }
{ "unsuccessfulTenderer": "YES" }
{ "refundDate": null }
```

An absent key means "leave it alone". An explicit `null` means "clear it" —
the app distinguishes the two, see `TenderSecurityPatch`.

### Rules the server must hold

- **A refund against a row whose `unsuccessfulTenderer` is not `YES` is
  contradictory.** The app allows the sequence, because a user may set the
  outcome second; the server should decide whether to reject it.
- **A refund cannot predate the submission.** The app has no submission
  timestamp to check against (see above), so this one is entirely the
  server's.

---

## 7. `GET /reports/vtm-monitoring`

One row per **eRFC**, not per tender. → `VtmMonitoringRecord`

Tracks an Appendix F from preparation to floating. The tender number is not
assigned until the document is approved, so most rows in flight carry none —
`erfcNo` is the key throughout.

| Field | Type | Notes |
|---|---|---|
| `erfcNo` | string | the key |
| `tenderQuotationNo` | string? | **null until approved** |
| `projectTitle` | string | |
| `documentType` | string | `Tender` · `Quotation` |
| `tenderType` | string | `1S` · `2S` |
| `modeOfProcurement` | string | an Appendix A section 7 number — see below |
| `division` | string | |
| `department` | string | |
| `estimatedValue` | number | RM |
| `documentPrice` | number | what a supplier pays; 0 on quotations |
| `status` | string | one of seven codes — see below |
| `preparedBy` | object? | `{ userId, name, role }` |
| `verifiedBy` | object? | null until verified |
| `approvedBy` | object? | null until approved |
| `endorsedDate` | date? | where aging counts *from* |
| `submittedDate` | date? | |
| `verifiedDate` | date? | |
| `approvedDate` | date? | |
| `floatingDate` | date? | where aging counts *to*, once published |
| `closingDate` | date? | |
| `rejectionRemarks` | string? | why it was sent back |

### Aging is computed here, not sent

`agingDays` in the sample payload is **ignored**. The rule counts to *today*
for anything still in flight, so a number computed when the payload was
generated is stale by the time anyone reads it. Send it if it is already
there; the app will not use it.

The rule: days from `endorsedDate` to today, or from `endorsedDate` to
`floatingDate` once the status is `PUBLISHED`. Two questions behind one
number — "how long has this waited" while it moves, "how long did this take"
once it is done.

### Status — 7 codes, sent not derived

`DRAFT` · `SUBMITTED` · `VERIFIED_BY_EXEC` · `REJECTED_BY_EXEC` ·
`APPROVED_BY_MANAGER` · `REJECTED_BY_MANAGER` · `PUBLISHED`

Codes, not the words on screen. `lib/reports/models/status/vtm_monitoring_status.dart`
carries the labels, the owning role, the description and what each status can
move to. Both rejections return to `SUBMITTED`, not to `DRAFT`: the document
goes back to its preparer for correction, it is not started again.

An unrecognised code renders as itself in a grey chip rather than as a blank.

### Mode of procurement — 5 of the sixteen

`7.1` · `7.2` · `7.3` · `7.5` · `7.6`

Section 7.4, Direct Negotiation, is deliberately absent: a directly
negotiated purchase is never floated to suppliers, so it has no Appendix F
to monitor here. A `7.4` arriving on this endpoint shows as the bare code,
which is a finding rather than something to hide.

---

## 8. `GET /reports/supplier-participation`

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

### Tender status — 4, in funnel order

`Published` · `Extended` · `Closed` · `Completed`

`Closed` means bidding has stopped. `Completed` means nothing further is
expected of the tender. They are not interchangeable — a closed tender is
still being worked through, and counting the two as one would hide that
work. `TenderStatus.pastClosing` is the pair together, where a report needs
"not open for bidding".

Cancellation is *not* one of these; a cancelled tender still reads as
`Closed`.

### eRFC status — 16, in lifecycle order

```
Draft
Submitted
Verified by 1st Verifier      Rejected by 1st Verifier      Declined by 1st Verifier
Verified by 2nd Verifier      Rejected by 2nd Verifier      Declined by 2nd Verifier
Endorsed                      Rejected by Endorser          Declined by Endorser
                                                            Cancelled
Paperwork Received
eRFC Completed
Confirm to Proceed
Deleted by System
```

**Each of the three gates can both reject and decline.** They are different
answers and are recorded separately, so send the one that happened rather
than collapsing them. The report counts them together on its
Rejected/Declined card, but keeps them apart in the vocabulary and shows the
exact wording in the table.

Grouped by the app as:

| Group | Values |
|---|---|
| In flight | Draft, Submitted, Verified by 1st Verifier, Verified by 2nd Verifier |
| Rejected | the three `Rejected by …` |
| Declined | the three `Declined by …` |
| Rejected or declined | those six together — what the card counts |
| Endorsed or beyond | Endorsed, Paperwork Received, eRFC Completed, Confirm to Proceed, Deleted by System |
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
Not Participate
Draft
Submitted
```

**The review is a single decision.** Which internal gate turned a request
back — clerk, executive, manager — is SE's business; the supplier only ever
sees `Request Rejected`. If SE needs the gate for its own reporting, that
belongs in a separate SE-side field, not in this status.

`Not Participate` is set by the system when a tender closes without a bid,
not chosen by the supplier.

### Tender security payment type — 3

`CASHIERS_ORDER` · `BANK_DRAFT` · `BANK_GUARANTEE`

The one vocabulary in this app sent as a **code rather than as the words on
screen**. `lib/reports/models/attributes/tender_security_attributes.dart` maps each to
its label; an unrecognised code renders as itself rather than as a blank
cell, so a vocabulary change shows up instead of disappearing.

### Unsuccessful tenderer — 2 plus blank

`YES` · `NO` · null. Blank means undecided; see section 5.

### TOC status — 8, sent by the server

| Status | Occurs on |
|---|---|
| `Open` | both |
| `Committee Appointed` | both |
| `Opening in Progress` | both |
| `Technical Opened` | 2 Envelope only |
| `Commercial Sealed` | 2 Envelope only |
| `Commercial Opened` | 2 Envelope only |
| `Tender Opened` | 1 Envelope only |
| `Opening Completed` | both |

**The server sends this; the app does not derive it.** Nothing a frontend
can read means "Commercial Sealed" — that is VTM's decision about a
physical envelope, and any timestamp the app could infer it from would be
the server having decided it already.

Three of the eight belong to two-envelope tenders alone and one to
one-envelope tenders alone. The app checks the pairing and **flags a
contradiction rather than correcting it**: a `Commercial Sealed` on a
`1 Envelope` tender appears on the Needs Attention panel, because the
disagreement is the finding. An unrecognised status renders as itself in a
grey chip rather than as a blank.

`lib/reports/models/status/toc_status.dart`.

### TOC roles — 3

`Chairman` · `Member 1` · `Member 2`. Exactly one of each per committee.

### Procurement modes — 16

`Tender/Quotation` · `Selective Tender/Quotation` ·
`Restricted Tender/Quotation` · `Direct Negotiation - Normal` ·
`Direct Negotiation - Emergency` · `Tender Through Pre-Qualification` ·
`Schedule Rate/JHT` · `Direct Purchase using Published Rate` · …

Full list: `lib/reports/models/attributes/procurement_modes.dart`.

### Open to — 15

Appendix A 8.1 eligibility, e.g. `Bumiputera Only`,
`Bumiputera (≤ RM250K)`, `Registered Suppliers`, `Open to Public`.
Full list: `lib/reports/models/attributes/open_to.dart`.

### Certification types — 7

`CIDB-…` · `KKM-…` · `PUKONSA-…`.
Full list: `lib/reports/models/attributes/certification_types.dart`.

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
