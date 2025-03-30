import 'package:flutter/material.dart';
import 'package:interactive_gantt_chart/interactive_gantt_chart.dart';
import 'package:interactive_gantt_chart/src/utils/date_utils.dart';

import '../arrow_connector.dart';
import '../arrow_painter.dart';

void moveEntireBar({
  required double deltaDX,
  required double startDistance,
  required double distanceFromStart,
  required double widthPerDay,
  required bool enableMagnetDrag,
  required Function(int distanceInDays, double newStartDistance) onNewDistance,
}) {
  final rawDistance = (startDistance - distanceFromStart) / widthPerDay;
  final newDistanceInDays =
      (deltaDX > 0) ? rawDistance.ceil() : rawDistance.floor();

  // distance for current animation
  double newStartDistance = startDistance + deltaDX;
  if (enableMagnetDrag) {
    if (newStartDistance % widthPerDay < widthPerDay * 0.5 / 10) {
      newStartDistance = newStartDistance - (newStartDistance % widthPerDay);
    } else if (newStartDistance % widthPerDay > widthPerDay * 9.5 / 10) {
      newStartDistance =
          newStartDistance + widthPerDay - (newStartDistance % widthPerDay);
    }
  }

  onNewDistance(newDistanceInDays, newStartDistance);
}

/// For now also generate arrows connector to avoid too much nested loop
List<Widget> generateArrows(
  List<GanttData> listData, {
  required double widthPerDay,
  required double heightPerRow,
  required DateTime firstDateShown,
  required double indicatorWidth,
  required Color arrowColor,
  required double arrowSize,
  required int selectedIndex,
  required double connectorSize,
  required Color connectorColor,
  required ValueNotifier<bool> isArrowConnecting,
  required ValueNotifier<bool> arrowState,
  required GanttMode mode,
  required void Function() onArrowConnected,
  required void Function() onArrowStartConnecting,
}) {
  final arrows = <Widget>[];
  final arrowsConnector = <Widget>[];

  arrows.addAll(arrowsConnector);
  return arrows;
}

// Give List of GanttData, current data index, scrolled vertical distance in pixels(double), heightPerRow, and rowSpacing(each row will have this * 2)
// Return the index of the data that is currently shown on the screen based on the vertical distance, return -1 if not found
int getReorderingDestinationIndex({
  required List<GanttData> listData,
  required int currentIndex,
  required DragEndDetails details,
  required double heightPerRow,
  required double rowSpacing,
}) {
  final baseRowHeight = heightPerRow + (rowSpacing * 2);

  /// The drag indicator is in the middle of the bar, so might need to adjust the vertical distance
  /// based on drag direction
  double verticalDistance = details.localPosition.dy;
  double expectedRow = 0;

  if (verticalDistance < 0) {
    for (int i = currentIndex - 1; i >= 0; i--) {
      verticalDistance -= listData[currentIndex].getBarHeight(baseRowHeight) /
          2; // adjust the vertical distance
      expectedRow -= listData[i].getBarHeight(heightPerRow + rowSpacing * 2);

      if (verticalDistance > expectedRow) return -1;

      if (i == 0) return i;

      final nextExpectedRow =
          expectedRow - listData[i - 1].getBarHeight(baseRowHeight);

      if (verticalDistance > nextExpectedRow) {
        return i;
      }
    }
  } else {
    for (int i = currentIndex + 1; i < listData.length; i++) {
      verticalDistance += listData[currentIndex].getBarHeight(baseRowHeight) /
          2; // adjust the vertical distance
      expectedRow += listData[i].getBarHeight(baseRowHeight);

      if (verticalDistance < expectedRow) return -1;

      if (i == listData.length - 1) return i;

      final nextExpectedRow =
          expectedRow + listData[i + 1].getBarHeight(baseRowHeight);
      if (verticalDistance < nextExpectedRow) {
        return i;
      }
    }
  }
  return -1;
}
