// lib/reports/models/tender_attributes.dart
//
// Two facts every tender carries alongside its mode of procurement. They are
// independent of the mode and of each other: a Tender/Quotation can be one
// envelope or two, stock or non-stock, in any combination.
//
// Declared rather than derived from the records, for the same reason as
// kProcurementModes: an option nobody has used yet still has to be
// selectable, otherwise the filter cannot answer "any two-envelope tenders
// this quarter?" with a confident no.

/// What is being bought. Fixed for the same reason: a category with no
/// tender against it today must still be selectable.
const List<String> kTenderCategories = ['Work', 'Service', 'Supply & Delivery'];

/// How bids arrive. One envelope submits technical and price together; two
/// keeps the price sealed until the technical evaluation is done.
const List<String> kEnvelopeTypes = ['1 Envelope', '2 Envelope'];

/// Whether the tender draws on warehouse stock or is bought in for the job.
const List<String> kItemTypes = ['Stock Item', 'Non-Stock Item'];
