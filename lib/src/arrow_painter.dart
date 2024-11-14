import 'package:flutter/material.dart';

import '../interactive_gantt_chart.dart';

class ArrowPainter extends CustomPainter {
  final GanttSubData dependentSubData;

  /// The index of the dependent data from the top of the list
  final int dependentIndex;
  final GanttSubData pointedSubData;

  /// The index of the pointed data from the top of the list
  final int pointedIndex;
  final double widthPerDay;
  final double heightPerRow;
  final double indicatorWidth;
  final double arrowSize;
  final DateTime firstDateShown;
  final Color arrowColor;

  const ArrowPainter({
    required this.dependentSubData,
    required this.dependentIndex,
    required this.pointedSubData,
    required this.pointedIndex,
    required this.widthPerDay,
    required this.heightPerRow,
    required this.indicatorWidth,
    required this.arrowSize,
    required this.firstDateShown,
    required this.arrowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final startX =
        (dependentSubData.dateEnd.difference(firstDateShown).inDays + 1) *
            widthPerDay;
    final startY = dependentIndex * heightPerRow + heightPerRow / 2;
    final endX = pointedSubData.dateStart.difference(firstDateShown).inDays *
        widthPerDay;
    final endY = pointedIndex * heightPerRow + heightPerRow / 2;

    final midPointX = (startX + endX) / 2;
    final midPointY = startY + heightPerRow / 2;
    final paint = Paint()
      ..color = arrowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = arrowSize / 2;

    final path = Path()..moveTo(startX, startY);

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

    path
      ..lineTo(endX - (indicatorWidth + 5), endY)
      ..lineTo(endX, endY);

    // draw arrow head
    path
      ..moveTo((endX - indicatorWidth) - arrowSize, endY - arrowSize)
      ..lineTo((endX - indicatorWidth), endY)
      ..lineTo((endX - indicatorWidth) - arrowSize, endY + arrowSize);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
