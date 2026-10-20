// lib/reports/procurement_lead_time/data/mock_lead_time_repository.dart
//
// Twenty-five tenders and quotations published between 8 September and
// 15 October 2026: fifteen Tenders (T.) and ten Quotations (Q. and Zone
// Quotations, Z.). Search a published date range covering those dates to see
// them all.
//
// Fixed dates rather than offsets from today: a lead time depends on which
// weekdays it spans, so sliding the dates would move records between bands.
//
// With no holidays loaded the bands come out as:
//   Tender     9 × 1–3, 5 × 4–7, 1 × more than 7 working days  -> Good
//   Quotation  7 × 1–3, 2 × 4–7, 1 × more than 7 working days  -> Good
//
// T.10434 is received on a Saturday, and T.10440 and Q.20525 were
// re-published after an addendum, so the edge cases show up on screen.
import 'package:etender_reports/reports/procurement_lead_time/data/lead_time_repository.dart';
import 'package:etender_reports/reports/procurement_lead_time/models/lead_time_query.dart';
import 'package:etender_reports/reports/procurement_lead_time/models/lead_time_record.dart';

class MockLeadTimeRepository extends LeadTimeRepository {
  const MockLeadTimeRepository({
    this.latency = const Duration(milliseconds: 400),
  });

  /// Long enough to see the loading state.
  final Duration latency;

  // TODO(holidays): Replace with the maintained Malaysia + Sabah public
  // holiday table once it exists. Deliberately empty: real dates must come
  // from SE's calendar, not be typed in here.
  static final Set<DateTime> _holidays = <DateTime>{};

  @override
  Future<List<LeadTimeRecord>> fetchRecords({
    required DateTime publishedFrom,
    required DateTime publishedTo,
    DocumentTypeFilter type = DocumentTypeFilter.tender,
    String? procurementMode,
  }) async {
    await Future<void>.delayed(latency);
    final from = DateTime(
      publishedFrom.year,
      publishedFrom.month,
      publishedFrom.day,
    );
    final to = DateTime(
      publishedTo.year,
      publishedTo.month,
      publishedTo.day + 1,
    );
    return [
      for (final record in _records)
        if (!record.publishedDate.isBefore(from) &&
            record.publishedDate.isBefore(to) &&
            type.includes(record.documentType) &&
            (procurementMode == null ||
                record.procurementMode == procurementMode))
          record,
    ];
  }

  @override
  Future<Set<DateTime>> fetchHolidays() async => Set.of(_holidays);
}

DateTime _at(int month, int day, [int hour = 10, int minute = 0]) =>
    DateTime(2026, month, day, hour, minute);

LeadTimeRecord _record(
  String tenderNo,
  String projectTitle,
  String mode,
  String erfcNo,
  String division,
  DateTime received,
  DateTime published,
) => LeadTimeRecord(
  tenderNo: tenderNo,
  projectTitle: projectTitle,
  procurementMode: mode,
  erfcNo: erfcNo,
  division: division,
  vtmReceivedDate: received,
  publishedDate: published,
);

final List<LeadTimeRecord> _records = [
  // ---- Tenders ----------------------------------------------------------
  _record(
    'T.10411',
    'Supply and Delivery of 11kV Ring Main Units for Kota Kinabalu Zone',
    '7.1',
    'ERFC/2026/00009210',
    'Distribution',
    _at(9, 7, 9, 12),
    _at(9, 9, 16, 40),
  ),
  _record(
    'T.10412',
    'Refurbishment of 132kV Substation Control Building, Sandakan',
    '7.2',
    'ERFC/2026/00009214',
    'Transmission',
    _at(9, 8, 8, 30),
    _at(9, 8, 17, 5),
  ),
  _record(
    'T.10415',
    'Overhaul of Gas Turbine Unit 2, Patau-Patau Power Station',
    '7.3',
    'ERFC/2026/00009221',
    'Generation',
    _at(9, 10, 14),
    _at(9, 14, 11, 20),
  ),
  _record(
    'T.10418',
    'Construction of 33kV Overhead Line from Keningau to Tenom',
    '7.1',
    'ERFC/2026/00009230',
    'Distribution',
    _at(9, 14, 10, 15),
    _at(9, 16, 15),
  ),
  _record(
    'T.10420',
    'Provision of Security Services for SESB Offices, Tawau Region',
    '7.5',
    'ERFC/2026/00009236',
    'Corporate Services',
    _at(9, 16, 9),
    _at(9, 17, 10, 30),
  ),
  _record(
    'T.10423',
    'Supply of Distribution Transformers 500kVA for West Coast Region',
    '7.1',
    'ERFC/2026/00009241',
    'Distribution',
    _at(9, 18, 15, 45),
    _at(9, 22, 9, 10),
  ),
  _record(
    'T.10426',
    'Replacement of Protection Relays at Segaliud 275kV Substation',
    '7.2',
    'ERFC/2026/00009248',
    'Transmission',
    _at(9, 21, 8, 5),
    _at(9, 21, 16, 50),
  ),
  _record(
    'T.10429',
    'Civil Works for New Lahad Datu 132/33kV Substation',
    '7.6',
    'ERFC/2026/00009252',
    'Transmission',
    _at(9, 22, 11),
    _at(9, 30, 14, 30),
  ),
  _record(
    'T.10431',
    'Supply and Installation of Smart Meters, Kota Kinabalu Phase 3',
    '7.1',
    'ERFC/2026/00009257',
    'Distribution',
    _at(9, 23, 9, 40),
    _at(9, 28, 12),
  ),
  // Received on a Saturday: Day 1 is the Monday after.
  _record(
    'T.10434',
    'Vegetation Management along 275kV Lines, Kudat to Kota Belud',
    '7.3',
    'ERFC/2026/00009263',
    'Transmission',
    _at(9, 26, 11, 25),
    _at(9, 29, 10),
  ),
  _record(
    'T.10436',
    'Rehabilitation of Tenom Pangi Hydro Station Penstock',
    '7.2',
    'ERFC/2026/00009266',
    'Generation',
    _at(9, 28, 14, 10),
    _at(10, 1, 9, 30),
  ),
  _record(
    'T.10438',
    'Design and Build of Semporna Mobile Diesel Power Plant Upgrade',
    '7.6',
    'ERFC/2026/00009271',
    'Generation',
    _at(9, 29, 10),
    _at(10, 9, 15, 15),
  ),
  // Published 6 Oct, then re-published 13 Oct after Addendum 1. Only the
  // first counts.
  LeadTimeRecord.fromPublishHistory(
    tenderNo: 'T.10440',
    projectTitle: 'Supply of Underground Cables 33kV XLPE for Sandakan Zone',
    procurementMode: '7.1',
    erfcNo: 'ERFC/2026/00009275',
    division: 'Distribution',
    vtmReceivedDate: _at(10, 1, 13, 35),
    publishedDates: [_at(10, 13, 10), _at(10, 6, 11, 45)],
  ),
  _record(
    'T.10443',
    'Maintenance of SCADA System for Sabah Grid Control Centre',
    '7.5',
    'ERFC/2026/00009280',
    'Transmission',
    _at(10, 5, 9, 15),
    _at(10, 7, 16),
  ),
  _record(
    'T.10445',
    'Upgrading of Beaufort Customer Service Centre',
    '7.2',
    'ERFC/2026/00009284',
    'Corporate Services',
    _at(10, 7, 10, 50),
    _at(10, 14, 14, 20),
  ),

  // ---- Quotations (Q.) and Zone Quotations (Z.) -------------------------
  _record(
    'Q.20511',
    'Supply of Personal Protective Equipment for Ranau Depot',
    '7.3',
    'ERFC/2026/00009212',
    'Distribution',
    _at(9, 7, 11),
    _at(9, 8, 10, 15),
  ),
  _record(
    'Q.20514',
    'Servicing of Air Conditioning Units, Wisma SESB Kota Kinabalu',
    '7.5',
    'ERFC/2026/00009224',
    'Corporate Services',
    _at(9, 10, 9, 20),
    _at(9, 11, 15, 30),
  ),
  _record(
    'Z.30102',
    'Repair of Feeder Pillars, Papar Zone',
    '7.1',
    'ERFC/2026/00009232',
    'Distribution',
    _at(9, 14, 8, 45),
    _at(9, 24, 11),
  ),
  _record(
    'Q.20518',
    'Supply of Insulating Oil for Melawa Power Station',
    '7.2',
    'ERFC/2026/00009238',
    'Generation',
    _at(9, 15, 14),
    _at(9, 17, 9, 45),
  ),
  _record(
    'Q.20521',
    'Calibration of Test Equipment for Tawau Protection Unit',
    '7.6',
    'ERFC/2026/00009243',
    'Transmission',
    _at(9, 18, 8, 30),
    _at(9, 18, 15, 10),
  ),
  _record(
    'Z.30105',
    'Replacement of Street Lighting Poles, Kudat Zone',
    '7.1',
    'ERFC/2026/00009250',
    'Distribution',
    _at(9, 21, 10, 40),
    _at(9, 28, 16, 25),
  ),
  // Published 2 Oct, re-published 8 Oct after an addendum.
  LeadTimeRecord.fromPublishHistory(
    tenderNo: 'Q.20525',
    projectTitle: 'Supply of Office Furniture for Keningau Regional Office',
    procurementMode: '7.5',
    erfcNo: 'ERFC/2026/00009268',
    division: 'Corporate Services',
    vtmReceivedDate: _at(9, 30, 9, 5),
    publishedDates: [_at(10, 2, 14), _at(10, 8, 9, 30)],
  ),
  _record(
    'Q.20528',
    'Hire of Crane Services for Sandakan Substation Works',
    '7.3',
    'ERFC/2026/00009277',
    'Transmission',
    _at(10, 5, 13, 30),
    _at(10, 6, 11),
  ),
  _record(
    'Z.30109',
    'Minor Civil Works for Pole Foundations, Lahad Datu Zone',
    '7.2',
    'ERFC/2026/00009282',
    'Distribution',
    _at(10, 8, 9, 50),
    _at(10, 15, 10, 30),
  ),
  _record(
    'Q.20531',
    'Supply of Lubricants for Gantisan Diesel Power Station',
    '7.6',
    'ERFC/2026/00009288',
    'Generation',
    _at(10, 12, 15, 20),
    _at(10, 14, 12, 40),
  ),
];
