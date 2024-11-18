import 'package:flutter/material.dart';
import 'package:interactive_gantt_chart/interactive_gantt_chart.dart';

import 'arrow_painter.dart';

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

List<Widget> generateArrows(
  List<GanttData> listData, {
  required double widthPerDay,
  required double heightPerRow,
  required DateTime firstDateShown,
  required double indicatorWidth,
  required Color arrowColor,
  required double arrowSize,
}) {
  final arrows = <Widget>[];
// int pointedIndex = 0;
  for (GanttData data in listData) {
// pointedIndex++;
    for (GanttSubData subData in data.subData) {
// pointedIndex++;
      for (String dependency in subData.dependencies) {
        final dependentSubData =
            subData.getDependencies(data.subData).firstWhere(
                  (element) => element.id == dependency,
                );
        final pointedSubData = subData;
        final dependentIndex =
            dependentSubData.getIndexFromEntireData(listData);
        final pointedIndex = pointedSubData.getIndexFromEntireData(listData);

        arrows.add(
          CustomPaint(
            painter: ArrowPainter(
              dependentSubData: dependentSubData,
              dependentIndex: dependentIndex,
              pointedSubData: pointedSubData,
              pointedIndex: pointedIndex,
              widthPerDay: widthPerDay,
              heightPerRow: heightPerRow,
              indicatorWidth: indicatorWidth,
              firstDateShown: firstDateShown,
              arrowColor: arrowColor,
              arrowSize: arrowSize,
            ),
          ),
        );
      }
    }
  }

  return arrows;
}
