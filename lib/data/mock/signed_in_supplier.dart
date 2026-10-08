// lib/data/mock/signed_in_supplier.dart
//
// Which supplier is signed in.
//
// This is the only thing about the supplier that cannot come from the
// report data, because it is a property of the session rather than of the
// records. A real app takes it from the auth token; the endpoint then
// scopes its rows to that supplier server-side and this constant goes away
// — see the warning on `fetchSupplierRecords`.
//
// Everything else the dashboard shows about the supplier — their name and
// the categories they bid in — is read off their own rows rather than
// stored here, so nothing on the page is invented.

const String kSignedInSupplierId = 'VEN/2000/000004';
