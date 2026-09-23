// lib/reports/models/certification_types.dart
//
// Vendor certification types, grouped by the body that issues them: CIDB,
// KKM and PUKONSA. The body is the prefix, the certificate the suffix.
//
// Declared rather than derived from the records, for the same reason as
// kProcurementModes: a certificate nobody in the current page holds still
// has to be selectable, so the filter can return an honest empty result
// rather than hiding the option.

const List<String> kCertificationTypes = [
  'CIDB-KONTRAKTOR KERJA & PERKHIDMATAN',
  'CIDB-SIJIL KEBENARAN KHAS UNTUK TENDER T.XXXX SAHAJA',
  'KKM-SIJIL AKUAN PERKHIDMATAN JURUPERUNDING',
  'KKM-BEKALAN',
  'PUKONSA-KONTRAKTOR KERJA & PERKHIDMATAN',
  'PUKONSA-BEKALAN',
  'PUKONSA-PERKHIDMATAN JURUPERUNDING',
];
