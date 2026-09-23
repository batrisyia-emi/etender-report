import 'package:flutter/material.dart';

import 'package:etender_reports/shared/app_colors.dart';
import 'package:etender_reports/reports/reports_shell.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SESB eTender Reports',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        // Every scrolling region in the app is a panel inside a fixed
        // page rather than the document itself, so a thumb that only
        // appears once you are already scrolling leaves no sign there is
        // anything below the fold. Keep them visible.
        scrollbarTheme: ScrollbarThemeData(
          thumbVisibility: const WidgetStatePropertyAll(true),
          thickness: const WidgetStatePropertyAll(8),
          radius: const Radius.circular(4),
          thumbColor: WidgetStatePropertyAll(
            AppColors.heading.withValues(alpha: 0.28),
          ),
        ),
      ),
      home: const ReportsPage(),
    );
  }
}
