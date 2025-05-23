import 'package:flutter/material.dart';

import '../interactive_gantt_chart.dart';

class ArrowPainter extends CustomPainter {

  late Path path;

  /// The index of the dependent data from the top of the list
  final int dependentIndex;

  /// The index of the pointed data from the top of the list
  final int pointedIndex;
  final double widthPerDay;
  final double heightPerRow;
  final double indicatorWidth;
  final double arrowSize;
  final DateTime firstDateShown;
  final Color arrowColor;
  final bool isSelected;

  ArrowPainter({
    required this.dependentIndex,
    required this.pointedIndex,
    required this.widthPerDay,
    required this.heightPerRow,
    required this.indicatorWidth,
    required this.arrowSize,
    required this.firstDateShown,
    required this.arrowColor,
    this.isSelected = false,
  }) {
    final startX =
            widthPerDay;
    final startY = dependentIndex * heightPerRow + heightPerRow / 2;
    final endX = isSelected
        ?
                widthPerDay -
            indicatorWidth * 1.5
        :
            widthPerDay;
    final endY = pointedIndex * heightPerRow + heightPerRow / 2;

    final midPointX = (startX + endX) / 2;
    late final double midPointY;
    if (pointedIndex < dependentIndex) {
      midPointY = endY + heightPerRow / 2;
    } else {
      midPointY = endY - heightPerRow / 2;
    }

    path = Path()..moveTo(startX, startY);

    if (midPointX < startX + indicatorWidth + 5) {
      path
        ..lineTo(startX + indicatorWidth + 5, startY)
        ..lineTo(startX + indicatorWidth + 5, midPointY)
        ..lineTo(endX - (indicatorWidth * 2), midPointY)
        ..lineTo(endX - (indicatorWidth * 2), endY);
    } else {
      path
        ..lineTo(midPointX, startY)
        ..lineTo(midPointX, endY);
    }

    path.lineTo(endX - (indicatorWidth + 5), endY);

    // draw arrow head
    path
      ..moveTo((endX - indicatorWidth) - arrowSize, endY - arrowSize)
      ..lineTo((endX - indicatorWidth), endY)
      ..lineTo((endX - indicatorWidth) - arrowSize, endY + arrowSize);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = arrowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = arrowSize / 2;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  @override
  bool? hitTest(Offset position) {
    return path.contains(position);
  }
}
