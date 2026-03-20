import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Item de données pour le graphique en camembert.
class PieChartItem {
  final String label;
  final double value;
  final Color color;

  const PieChartItem({
    required this.label,
    required this.value,
    required this.color,
  });
}

/// Widget wrappant PieChart de fl_chart pour afficher la répartition des budgets.
///
/// Chaque section correspond à un [PieChartItem] avec une couleur et une valeur.
/// Si [onSectionTapped] est fourni, un tap sur une section appelle le callback
/// avec l'index de la section touchée.
class BudgetPieChart extends StatelessWidget {
  const BudgetPieChart({
    super.key,
    required this.items,
    this.onSectionTapped,
    this.size = 200,
  });

  final List<PieChartItem> items;
  final void Function(int index)? onSectionTapped;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: size,
      child: PieChart(
        PieChartData(
          sections: items.asMap().entries.map((entry) {
            final item = entry.value;
            return PieChartSectionData(
              value: item.value,
              color: item.color,
              title: '',
              radius: 40,
            );
          }).toList(),
          sectionsSpace: 2,
          centerSpaceRadius: size / 2 - 50,
          pieTouchData: onSectionTapped != null
              ? PieTouchData(
                  touchCallback: (event, response) {
                    if (event is FlTapUpEvent &&
                        response?.touchedSection != null) {
                      final index =
                          response!.touchedSection!.touchedSectionIndex;
                      if (index >= 0) onSectionTapped!(index);
                    }
                  },
                )
              : null,
        ),
      ),
    );
  }
}
