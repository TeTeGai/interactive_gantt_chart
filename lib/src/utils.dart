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
  required Widget arrowConnector,
  required double connectorSize,
}) {
  final arrows = <Widget>[];
  final arrowsConnector = <Widget>[];
  for (GanttData data in listData) {
    final parentIndex = listData.indexOf(data);
    for (GanttSubData subData in data.subData) {
      // Generate arrows connector for each subData
      final subIndex = data.subData.indexOf(subData);
      final isSelected =
          selectedIndex == GanttSubData.getUniqueIndex(parentIndex, subIndex);
      final distanceFromStart =
          subData.dateStart.difference(firstDateShown).inDays * widthPerDay;
      arrowsConnector.add(
        Positioned(
          left: isSelected
              ? distanceFromStart - connectorSize * 2.5
              : distanceFromStart - connectorSize - 1,
          top: subData.getIndexFromEntireData(listData) * heightPerRow +
              heightPerRow / 2 -
              connectorSize / 2,
          child: arrowConnector,
        ),
      );

      // Generate arrows for each subData dependencies
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
              isSelected: isSelected,
            ),
          ),
        );
      }
    }
  }

  arrows.addAll(arrowsConnector);
  return arrows;
}
