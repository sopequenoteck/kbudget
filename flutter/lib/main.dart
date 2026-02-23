import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:k_budget/app.dart';
import 'package:k_budget/src/common_widgets/restart_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr');

  runApp(
    const RestartWidget(
      child: ProviderScope(
        child: KBudgetApp(),
      ),
    ),
  );
}
