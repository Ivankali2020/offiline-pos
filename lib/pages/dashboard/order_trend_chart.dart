import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:abpos/data/repositories/dashboard_repository.dart';
import 'package:get/get.dart';

class OrderTrendChart extends StatefulWidget {
  const OrderTrendChart({
    super.key,
    required this.points,
    required this.filterLabel,
  });

  final List<DashboardTrendPoint> points;
  final String filterLabel;

  @override
  State<OrderTrendChart> createState() => _OrderTrendChartState();
}

class _OrderTrendChartState extends State<OrderTrendChart> {
  static final NumberFormat _numberFormat = NumberFormat('#,##0', 'en_US');
  int? _selectedIndex;

  @override
  void didUpdateWidget(covariant OrderTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.points != widget.points) {
      _selectedIndex = null;
    }
  }

  void _handleGesture(Offset localPosition, Size size) {
    if (widget.points.isEmpty) return;

    const horizontalPadding = 8.0;
    final chartWidth = size.width - horizontalPadding * 2;
    if (chartWidth <= 0) return;

    final dx = localPosition.dx - horizontalPadding;
    final pct = dx / chartWidth;
    final index = (pct * (widget.points.length - 1)).round().clamp(0, widget.points.length - 1);

    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final totalSales = widget.points.fold<double>(
      0,
      (sum, item) => sum + item.totalSales,
    );
    final totalOrders = widget.points.fold<int>(
      0,
      (sum, item) => sum + item.orderCount,
    );

    final hasSelection = _selectedIndex != null && _selectedIndex! < widget.points.length;
    final selectedPoint = hasSelection ? widget.points[_selectedIndex!] : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: hasSelection && selectedPoint != null
                ? Container(
                    key: const ValueKey('selection_header'),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.calendarDays, size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('dd MMM yyyy').format(selectedPoint.date),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '${selectedPoint.orderCount} ${selectedPoint.orderCount == 1 ? 'order'.tr : 'orders'.tr}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${_numberFormat.format(selectedPoint.totalSales)} MMK',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          icon: const Icon(LucideIcons.x, size: 16, color: Colors.black45),
                          onPressed: () => setState(() => _selectedIndex = null),
                        ),
                      ],
                    ),
                  )
                : Wrap(
                    key: const ValueKey('default_header'),
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(icon: LucideIcons.calendarRange, label: widget.filterLabel),
                      _InfoChip(
                        icon: LucideIcons.shoppingBag,
                        label: '$totalOrders ${'orders'.tr.toLowerCase()}',
                      ),
                      _InfoChip(
                        icon: LucideIcons.banknote,
                        label: '${_numberFormat.format(totalSales)} MMK',
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 18),
          if (widget.points.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  const Icon(LucideIcons.chartNoAxesCombined, size: 28),
                  const SizedBox(height: 10),
                  Text(
                    'no_order_trend'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            )
          else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, 210);
                return GestureDetector(
                  onTapDown: (details) => _handleGesture(details.localPosition, size),
                  onPanStart: (details) => _handleGesture(details.localPosition, size),
                  onPanUpdate: (details) => _handleGesture(details.localPosition, size),
                  child: SizedBox(
                    height: 210,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _InteractiveTrendLinePainter(
                        points: widget.points,
                        color: theme.colorScheme.primary,
                        selectedIndex: _selectedIndex,
                      ),
                      child: Container(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat('dd MMM').format(widget.points.first.date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                Text(
                  DateFormat('dd MMM').format(widget.points.last.date),
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ],
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveTrendLinePainter extends CustomPainter {
  const _InteractiveTrendLinePainter({
    required this.points,
    required this.color,
    this.selectedIndex,
  });

  final List<DashboardTrendPoint> points;
  final Color color;
  final int? selectedIndex;

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
        .map((point) => point.totalSales)
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
          chartHeight * (points[i].totalSales / safeMax);
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

    if (selectedIndex != null && selectedIndex! < offsets.length) {
      final selectedOffset = offsets[selectedIndex!];
      final guidePaint = Paint()
        ..color = color.withValues(alpha: 0.25)
        ..strokeWidth = 1.5;

      const dashHeight = 5;
      const dashGap = 3;
      double startY = verticalPadding;
      while (startY < size.height - verticalPadding) {
        canvas.drawLine(
          Offset(selectedOffset.dx, startY),
          Offset(selectedOffset.dx, startY + dashHeight),
          guidePaint,
        );
        startY += dashHeight + dashGap;
      }
    }

    for (var i = 0; i < offsets.length; i++) {
      final offset = offsets[i];
      final isSelected = selectedIndex == i;

      if (isSelected) {
        canvas.drawCircle(offset, 8, Paint()..color = color.withValues(alpha: 0.22));
        canvas.drawCircle(offset, 5, Paint()..color = color);
        canvas.drawCircle(offset, 2.5, Paint()..color = Colors.white);
      } else {
        canvas.drawCircle(offset, 4.5, Paint()..color = color);
        canvas.drawCircle(offset, 2.5, Paint()..color = Colors.white);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _InteractiveTrendLinePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.color != color ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}
