import 'package:bloc/bloc.dart';

import 'package:etender_reports/reports/report_type.dart';

class ReportSelectionCubit extends Cubit<ReportType> {
  ReportSelectionCubit() : super(ReportType.seDashboard);

  void select(ReportType reportType) {
    if (reportType == state) return;
    emit(reportType);
  }
}
