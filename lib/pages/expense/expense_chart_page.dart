import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:abpos/controllers/expense_controller.dart';
import 'package:abpos/models/expense.dart';
import 'package:abpos/widgets/app_scaffold.dart';
import 'package:abpos/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ExpenseChartPage extends StatefulWidget {
  const ExpenseChartPage({super.key});

  @override
  State<ExpenseChartPage> createState() => _ExpenseChartPageState();
}

enum _ExpenseTrendMode { monthly, yearly }

class _ExpenseChartPageState extends State<ExpenseChartPage> {
  final ExpenseController controller = Get.find<ExpenseController>();
  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'en_US');
  _ExpenseTrendMode _trendMode = _ExpenseTrendMode.monthly;
  int? _selectedYear;
  int? _selectedTrendIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Expense Charts',
      appBar: const CustomAppBar(
        title: 'Expense Charts',
        subtitle: 'Review trends over time and category distribution.',
      ),
      body: Obx(() {
        final expenses = controller.expenses.toList(growable: false);
        final availableYears = _availableYears(expenses);

        if (availableYears.isNotEmpty &&
            (_selectedYear == null ||
                !availableYears.contains(_selectedYear))) {
          _selectedYear = availableYears.first;
        }

        if (expenses.isEmpty) {
          return _EmptyChartsState(onRefresh: controller.loadExpenses);
        }

        final linePoints = _trendMode == _ExpenseTrendMode.monthly
            ? _monthlyPoints(expenses, _selectedYear!)
            : _yearlyPoints(expenses);
        final pieSlices = _categorySlicesForYear(expenses, _selectedYear!);
        final trendTotal = linePoints.fold<double>(
          0,
          (sum, item) => sum + item.amount,
        );
        final selectedTrendIndex =
            _selectedTrendIndex != null &&
                _selectedTrendIndex! >= 0 &&
                _selectedTrendIndex! < linePoints.length
            ? _selectedTrendIndex
            : null;

        return RefreshIndicator(
          onRefresh: controller.loadExpenses,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _ExpenseChartsHero(
                title: _trendMode == _ExpenseTrendMode.monthly
                    ? 'Monthly Trend'
                    : 'Yearly Trend',
                subtitle: _trendMode == _ExpenseTrendMode.monthly
                    ? 'Tracking ${_selectedYear ?? ''} expense movement month by month.'
                    : 'Comparing expense totals across all available years.',
                totalLabel: _trendMode == _ExpenseTrendMode.monthly
                    ? 'Year Total'
                    : 'Trend Total',
                totalValue: 'MMK ${_currencyFormat.format(trendTotal)}',
                accentColor: const Color(0xFFB91C1C),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<_ExpenseTrendMode>(
                      segments: const [
                        ButtonSegment<_ExpenseTrendMode>(
                          value: _ExpenseTrendMode.monthly,
                          icon: Icon(LucideIcons.chartSpline),
                          label: Text('Monthly'),
                        ),
                        ButtonSegment<_ExpenseTrendMode>(
                          value: _ExpenseTrendMode.yearly,
                          icon: Icon(LucideIcons.chartColumnIncreasing),
                          label: Text('Yearly'),
                        ),
                      ],
                      selected: {_trendMode},
                      onSelectionChanged: (selection) {
                        setState(() {
                          _trendMode = selection.first;
                          _selectedTrendIndex = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SectionLabel(
                      title: 'Category Breakdown',
                      subtitle:
                          'Pie chart for ${_selectedYear ?? ''} expense categories',
                    ),
                  ),
                  if (availableYears.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.10),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedYear,
                          borderRadius: BorderRadius.circular(14),
                          items: availableYears
                              .map(
                                (year) => DropdownMenuItem<int>(
                                  value: year,
                                  child: Text('$year'),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedYear = value;
                              _selectedTrendIndex = null;
                            });
                          },
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _TrendCard(
                mode: _trendMode,
                points: linePoints,
                currencyFormat: _currencyFormat,
                accentColor: const Color(0xFFB91C1C),
                selectedPointIndex: selectedTrendIndex,
                onSelectPoint: (index) {
                  setState(() {
                    _selectedTrendIndex = index;
                  });
                },
              ),
              const SizedBox(height: 18),
              _CategoryPieCard(
                year: _selectedYear,
                slices: pieSlices,
                currencyFormat: _currencyFormat,
              ),
            ],
          ),
        );
      }),
    );
  }

  List<int> _availableYears(List<Expense> expenses) {
    final years =
        expenses
            .map((expense) => _parseExpenseDate(expense.createdAt)?.year)
            .whereType<int>()
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));
    return years;
  }

  List<_TrendPoint> _monthlyPoints(List<Expense> expenses, int year) {
    final totals = List<double>.filled(12, 0);
    for (final expense in expenses) {
      final date = _parseExpenseDate(expense.createdAt);
      if (date == null || date.year != year) continue;
      totals[date.month - 1] += expense.amount;
    }

    return List.generate(
      12,
      (index) => _TrendPoint(
        label: DateFormat('MMM').format(DateTime(year, index + 1)),
        amount: totals[index],
      ),
    );
  }

  List<_TrendPoint> _yearlyPoints(List<Expense> expenses) {
    final totals = <int, double>{};
    for (final expense in expenses) {
      final date = _parseExpenseDate(expense.createdAt);
      if (date == null) continue;
      totals.update(
        date.year,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    final sortedYears = totals.keys.toList()..sort();
    return sortedYears
        .map((year) => _TrendPoint(label: '$year', amount: totals[year] ?? 0))
        .toList();
  }

  List<_CategorySlice> _categorySlicesForYear(
    List<Expense> expenses,
    int year,
  ) {
    final totals = <String, double>{};
    for (final expense in expenses) {
      final date = _parseExpenseDate(expense.createdAt);
      if (date == null || date.year != year) continue;
      final label = (expense.categoryName?.trim().isNotEmpty ?? false)
          ? expense.categoryName!.trim()
          : 'Uncategorized';
      totals.update(
        label,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    final palette = <Color>[
      const Color(0xFFB91C1C),
      const Color(0xFFEA580C),
      const Color(0xFFD97706),
      const Color(0xFF2563EB),
      const Color(0xFF0891B2),
      const Color(0xFF059669),
      const Color(0xFF7C3AED),
      const Color(0xFFDB2777),
    ];

    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return _CategorySlice(
        label: item.key,
        amount: item.value,
        color: palette[index % palette.length],
      );
    }).toList();
  }

  DateTime? _parseExpenseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}

class _ExpenseChartsHero extends StatelessWidget {
  const _ExpenseChartsHero({
    required this.title,
    required this.subtitle,
    required this.totalLabel,
    required this.totalValue,
    required this.accentColor,
  });

  final String title;
  final String subtitle;
  final String totalLabel;
  final String totalValue;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF111827),
            Color.alphaBlend(Colors.white.withValues(alpha: 0.05), accentColor),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  totalLabel,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  totalValue,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.72),
          ),
        ),
      ],
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.mode,
    required this.points,
    required this.currencyFormat,
    required this.accentColor,
    required this.selectedPointIndex,
    required this.onSelectPoint,
  });

  final _ExpenseTrendMode mode;
  final List<_TrendPoint> points;
  final NumberFormat currencyFormat;
  final Color accentColor;
  final int? selectedPointIndex;
  final ValueChanged<int> onSelectPoint;

  @override
  Widget build(BuildContext context) {
    final total = points.fold<double>(0, (sum, item) => sum + item.amount);
    final peak = points.isEmpty
        ? null
        : points.reduce((a, b) => a.amount >= b.amount ? a : b);
    final selectedPoint =
        selectedPointIndex != null &&
            selectedPointIndex! >= 0 &&
            selectedPointIndex! < points.length
        ? points[selectedPointIndex!]
        : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: mode == _ExpenseTrendMode.monthly
                    ? LucideIcons.chartSpline
                    : LucideIcons.chartColumnIncreasing,
                label: mode == _ExpenseTrendMode.monthly
                    ? 'Monthly line chart'
                    : 'Yearly line chart',
              ),
              _InfoChip(
                icon: LucideIcons.banknote,
                label: 'MMK ${currencyFormat.format(total)}',
              ),
              if (peak != null)
                _InfoChip(
                  icon: LucideIcons.sparkles,
                  label:
                      'Peak ${peak.label}: ${currencyFormat.format(peak.amount)}',
                ),
              if (selectedPoint != null)
                _InfoChip(
                  icon: LucideIcons.pointer,
                  label:
                      '${selectedPoint.label}: MMK ${currencyFormat.format(selectedPoint.amount)}',
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (points.isEmpty || points.every((point) => point.amount == 0))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                children: [
                  Icon(LucideIcons.chartNoAxesCombined, size: 28),
                  SizedBox(height: 10),
                  Text(
                    'No expense trend data in this range.',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            )
          else ...[
            SizedBox(
              height: 220,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final chartWidth = constraints.maxWidth;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) {
                      onSelectPoint(
                        _nearestPointIndex(
                          points: points,
                          chartWidth: chartWidth,
                          tapX: details.localPosition.dx,
                        ),
                      );
                    },
                    onHorizontalDragUpdate: (details) {
                      onSelectPoint(
                        _nearestPointIndex(
                          points: points,
                          chartWidth: chartWidth,
                          tapX: details.localPosition.dx,
                        ),
                      );
                    },
                    child: CustomPaint(
                      painter: _ExpenseTrendPainter(
                        points: points,
                        color: accentColor,
                        selectedPointIndex: selectedPointIndex,
                        selectedValueLabel: selectedPoint == null
                            ? null
                            : 'MMK ${currencyFormat.format(selectedPoint.amount)}',
                      ),
                      child: Container(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: points
                  .map(
                    (point) => Expanded(
                      child: Text(
                        point.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryPieCard extends StatelessWidget {
  const _CategoryPieCard({
    required this.year,
    required this.slices,
    required this.currencyFormat,
  });

  final int? year;
  final List<_CategorySlice> slices;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<double>(0, (sum, item) => sum + item.amount);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Pie - ${year ?? ''}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'See which expense categories carry the most weight for the selected year.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          if (slices.isEmpty || total == 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                children: [
                  Icon(LucideIcons.pieChart, size: 28),
                  SizedBox(height: 10),
                  Text(
                    'No category data for this year.',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                SizedBox(
                  height: 220,
                  child: CustomPaint(
                    painter: _ExpensePiePainter(slices: slices),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Year Total',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'MMK ${currencyFormat.format(total)}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ...slices.map((slice) {
                  final percent = total == 0 ? 0 : (slice.amount / total) * 100;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: slice.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            slice.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${percent.toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          currencyFormat.format(slice.amount),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }
}

class _EmptyChartsState extends StatelessWidget {
  const _EmptyChartsState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: _cardDecoration(radius: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.chartArea,
                size: 32,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No expense data yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a few expense records and this page will start showing trend and category charts.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.72,
                ),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(LucideIcons.refreshCcw, size: 16),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black54),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ExpenseTrendPainter extends CustomPainter {
  const _ExpenseTrendPainter({
    required this.points,
    required this.color,
    required this.selectedPointIndex,
    required this.selectedValueLabel,
  });

  final List<_TrendPoint> points;
  final Color color;
  final int? selectedPointIndex;
  final String? selectedValueLabel;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        4,
        Paint()..color = color,
      );
      return;
    }

    const horizontalPadding = 8.0;
    const verticalPadding = 16.0;
    final chartWidth = size.width - horizontalPadding * 2;
    final chartHeight = size.height - verticalPadding * 2;
    final maxValue = points
        .map((point) => point.amount)
        .reduce((a, b) => a > b ? a : b);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

    final gridPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = verticalPadding + chartHeight / 3 * i;
      canvas.drawLine(
        Offset(horizontalPadding, y),
        Offset(size.width - horizontalPadding, y),
        gridPaint,
      );
    }

    final offsets = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final dx = horizontalPadding + chartWidth * (i / (points.length - 1));
      final dy =
          verticalPadding +
          chartHeight -
          chartHeight * (points[i].amount / safeMax);
      offsets.add(Offset(dx, dy));
    }

    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (var i = 1; i < offsets.length; i++) {
      final previous = offsets[i - 1];
      final current = offsets[i];
      final controlX = (previous.dx + current.dx) / 2;
      path.cubicTo(
        controlX,
        previous.dy,
        controlX,
        current.dy,
        current.dx,
        current.dy,
      );
    }

    final fillPath = Path.from(path)
      ..lineTo(offsets.last.dx, size.height - verticalPadding)
      ..lineTo(offsets.first.dx, size.height - verticalPadding)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          colors: [
            color.withValues(alpha: 0.26),
            color.withValues(alpha: 0.02),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );

    for (final offset in offsets) {
      canvas.drawCircle(offset, 4.5, Paint()..color = color);
      canvas.drawCircle(offset, 2.5, Paint()..color = Colors.white);
    }

    if (selectedPointIndex != null &&
        selectedPointIndex! >= 0 &&
        selectedPointIndex! < offsets.length &&
        selectedValueLabel != null) {
      final selectedOffset = offsets[selectedPointIndex!];
      canvas.drawCircle(
        selectedOffset,
        7,
        Paint()..color = color.withValues(alpha: 0.22),
      );
      canvas.drawCircle(selectedOffset, 5, Paint()..color = color);
      canvas.drawCircle(selectedOffset, 2.8, Paint()..color = Colors.white);
      _drawTooltip(
        canvas,
        size,
        anchor: selectedOffset,
        title: points[selectedPointIndex!].label,
        value: selectedValueLabel!,
      );
    }
  }

  void _drawTooltip(
    Canvas canvas,
    Size size, {
    required Offset anchor,
    required String title,
    required String value,
  }) {
    final titlePainter = TextPainter(
      text: TextSpan(
        text: title,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    final valuePainter = TextPainter(
      text: TextSpan(
        text: value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    const horizontalPadding = 12.0;
    const verticalPadding = 10.0;
    const gap = 4.0;
    const arrowHeight = 7.0;
    final bubbleWidth =
        math.max(titlePainter.width, valuePainter.width) +
        horizontalPadding * 2;
    final bubbleHeight =
        titlePainter.height + valuePainter.height + verticalPadding * 2 + gap;

    final desiredLeft = anchor.dx - bubbleWidth / 2;
    final left = desiredLeft.clamp(8.0, size.width - bubbleWidth - 8.0);
    final top = (anchor.dy - bubbleHeight - arrowHeight - 12).clamp(
      8.0,
      size.height - bubbleHeight - arrowHeight - 8.0,
    );
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, bubbleWidth, bubbleHeight),
      const Radius.circular(14),
    );
    final arrowTipX = anchor.dx.clamp(left + 14.0, left + bubbleWidth - 14.0);
    final arrowBaseY = top + bubbleHeight;

    final bubblePath = Path()..addRRect(rect);
    bubblePath.moveTo(arrowTipX - 7, arrowBaseY);
    bubblePath.lineTo(arrowTipX, arrowBaseY + arrowHeight);
    bubblePath.lineTo(arrowTipX + 7, arrowBaseY);
    bubblePath.close();

    canvas.drawShadow(
      bubblePath,
      Colors.black.withValues(alpha: 0.22),
      8,
      false,
    );
    canvas.drawPath(bubblePath, Paint()..color = const Color(0xFF111827));

    titlePainter.paint(
      canvas,
      Offset(left + horizontalPadding, top + verticalPadding),
    );
    valuePainter.paint(
      canvas,
      Offset(
        left + horizontalPadding,
        top + verticalPadding + titlePainter.height + gap,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _ExpenseTrendPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.color != color ||
        oldDelegate.selectedPointIndex != selectedPointIndex ||
        oldDelegate.selectedValueLabel != selectedValueLabel;
  }
}

class _ExpensePiePainter extends CustomPainter {
  const _ExpensePiePainter({required this.slices});

  final List<_CategorySlice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2.6;
    final holeRadius = radius * 0.56;
    final total = slices.fold<double>(0, (sum, item) => sum + item.amount);
    if (total <= 0) return;

    var startAngle = -math.pi / 2;
    for (final slice in slices) {
      final sweepAngle = (slice.amount / total) * math.pi * 2;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt
        ..strokeWidth = radius - holeRadius
        ..color = slice.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: (radius + holeRadius) / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _ExpensePiePainter oldDelegate) {
    return oldDelegate.slices != slices;
  }
}

class _TrendPoint {
  const _TrendPoint({required this.label, required this.amount});

  final String label;
  final double amount;
}

class _CategorySlice {
  const _CategorySlice({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final double amount;
  final Color color;
}

BoxDecoration _cardDecoration({double radius = 22}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.03),
        blurRadius: 18,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

int _nearestPointIndex({
  required List<_TrendPoint> points,
  required double chartWidth,
  required double tapX,
}) {
  if (points.length <= 1) return 0;

  const horizontalPadding = 8.0;
  final usableWidth = math.max(chartWidth - horizontalPadding * 2, 1);
  final normalizedX = (tapX - horizontalPadding).clamp(0.0, usableWidth);
  final ratio = normalizedX / usableWidth;
  return (ratio * (points.length - 1)).round();
}
