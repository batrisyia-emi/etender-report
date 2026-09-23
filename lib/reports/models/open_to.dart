// lib/reports/models/open_to.dart
//
// Appendix A section 8.1, "Open To".
//
// The blueprint wording runs to about 95 characters, which is unusable as a
// chip or a closed dropdown label, so each option carries three renderings:
//
//   wireValue  what the API sends and the record stores
//   label      chips, table cells, the closed dropdown
//   threshold  the contract value rule, shown under the label in the menu
//   fullLabel  the blueprint sentence, for exports and tooltips
//
// Appendix H shows the same field as two boxes:
//   Bumiputera (<= RM250K)   Open (> RM250K)
// which is why the short labels carry the threshold too.

enum OpenTo {
  bumiputeraOnly(
    wireValue: 'Bumiputera Only',
    label: 'Bumiputera (≤ RM250K)',
    threshold: 'Contract value ≤ RM250,000',
    fullLabel:
        'Open to Sabah Electricity registered suppliers/contractors '
        '(Bumiputera only) — Contract Value ≤ RM250,000',
  ),
  registeredSuppliers(
    wireValue: 'Registered Suppliers',
    label: 'Registered (> RM250K)',
    threshold: 'Contract value RM250,000 and above',
    fullLabel:
        'Open to Sabah Electricity registered suppliers/contractors only '
        '— Contract Value RM250,000 and Above',
  ),
  public(
    wireValue: 'Public',
    label: 'Open to Public',
    threshold: 'No registration requirement',
    fullLabel: 'Open to Public',
  );

  const OpenTo({
    required this.wireValue,
    required this.label,
    required this.threshold,
    required this.fullLabel,
  });

  final String wireValue;
  final String label;
  final String threshold;
  final String fullLabel;

  static OpenTo? fromWire(Object? value) {
    final text = value?.toString();
    for (final option in OpenTo.values) {
      if (option.wireValue == text) return option;
    }
    return null;
  }

  /// Dropdown values, in blueprint order.
  static List<String> get wireValues => [
    for (final option in OpenTo.values) option.wireValue,
  ];

  /// Threshold per value, for the subtitle line under each menu item.
  static Map<String, String> get thresholds => {
    for (final option in OpenTo.values) option.wireValue: option.threshold,
  };

  /// Short label per value, for chips and the closed dropdown.
  static Map<String, String> get labels => {
    for (final option in OpenTo.values) option.wireValue: option.label,
  };

  static String labelFor(Object? value) =>
      fromWire(value)?.label ?? value?.toString() ?? '';

  static String fullLabelFor(Object? value) =>
      fromWire(value)?.fullLabel ?? value?.toString() ?? '';
}
