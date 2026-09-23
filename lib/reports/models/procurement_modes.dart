// lib/reports/models/procurement_modes.dart
//
// The procurement modes from Appendix A section 7, in the order the form
// lists them.
//
// Declared rather than derived from the records: a mode nobody has used yet
// still has to be selectable, otherwise the filter cannot answer "are there
// any Variation Orders this quarter?" with a confident no.

const List<String> kProcurementModes = [
  'Tender/Quotation',
  'Selective Tender/Quotation',
  'Restricted Tender/Quotation',
  'Direct Negotiation - Normal',
  'Direct Negotiation - Emergency',
  'Tender Through Pre-Qualification',
  'Schedule Rate/JHT',
  'Direct Purchase using Published Rate',
  'Procurement under CEO Approval Limit',
  'Extension of Contract',
  'Repeat Purchase',
  'Optional Value',
  'Variation Order',
  'Fuel Ordering',
  'Others',
  'Non-PO Items',
];
