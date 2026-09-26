import 'package:flutter/material.dart';

/// A scrollable masonry-style grid built with Flutter's own primitives —
/// no third-party package required.
///
/// ### Why not SingleChildScrollView + Column?
/// The naive approach builds **all** items at once, even those off-screen,
/// causing a noticeable freeze when the product list is long.
///
/// ### How this works
/// Items are grouped into **rows** of [crossAxisCount] and rendered with
/// [ListView.builder], which is **lazy**: only the rows currently visible
/// (plus a small cache buffer) are built. This keeps scrolling smooth even
/// with hundreds of products.
///
/// Each row resolves its height from its **tallest child**, so every card
/// still renders at its natural height — no fixed aspect-ratio, no overflow.
///
/// Usage is intentionally similar to [GridView.builder]:
///
/// ```dart
/// MasonryGridView(
///   crossAxisCount: 2,
///   itemCount: products.length,
///   padding: const EdgeInsets.all(16),
///   itemBuilder: (context, index) => MyCard(products[index]),
/// )
/// ```
class MasonryGridView extends StatelessWidget {
  const MasonryGridView({
    super.key,
    required this.crossAxisCount,
    required this.itemCount,
    required this.itemBuilder,
    this.crossAxisSpacing = 10,
    this.mainAxisSpacing = 10,
    this.padding,
    this.physics,
    this.controller,
  });

  /// Number of columns.
  final int crossAxisCount;

  /// Total number of items to render.
  final int itemCount;

  /// Builder called once per item. [index] matches the original item order.
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// Horizontal gap between columns.
  final double crossAxisSpacing;

  /// Vertical gap between rows.
  final double mainAxisSpacing;

  /// Padding around the entire grid.
  final EdgeInsetsGeometry? padding;

  /// Scroll physics forwarded to the underlying [ListView].
  final ScrollPhysics? physics;

  /// Optional scroll controller.
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    // Total number of lazy rows
    final rowCount = (itemCount / crossAxisCount).ceil();

    return ListView.builder(
      padding: padding,
      physics: physics,
      controller: controller,
      itemCount: rowCount,
      itemBuilder: (ctx, rowIndex) {
        final startIndex = rowIndex * crossAxisCount;
        final isLastRow = rowIndex == rowCount - 1;

        return Padding(
          // Only add bottom spacing between rows, not after the last one
          padding: EdgeInsets.only(
            bottom: isLastRow ? 0 : mainAxisSpacing,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var col = 0; col < crossAxisCount; col++) ...[
                if (col > 0) SizedBox(width: crossAxisSpacing),
                Expanded(
                  child: startIndex + col < itemCount
                      ? Builder(
                          builder: (c) =>
                              itemBuilder(c, startIndex + col),
                        )
                      // Fill empty cells in the last row so columns stay even
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
