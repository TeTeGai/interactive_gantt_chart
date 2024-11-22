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
  final newDistanceInDays = (deltaDX > 0) ? rawDistance.ceil() : rawDistance.floor();

  // distance for current animation
  double newStartDistance = startDistance + deltaDX;
  if (enableMagnetDrag) {
    if (newStartDistance % widthPerDay < widthPerDay * 0.5 / 10) {
      newStartDistance = newStartDistance - (newStartDistance % widthPerDay);
    } else if (newStartDistance % widthPerDay > widthPerDay * 9.5 / 10) {
      newStartDistance = newStartDistance + widthPerDay - (newStartDistance % widthPerDay);
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
  required ValueNotifier<bool> isArrowConnecting,
  required void Function() onArrowConnected,
}) {
  final arrows = <Widget>[];
  final arrowsConnector = <Widget>[];
  for (GanttData data in listData) {
    final parentIndex = listData.indexOf(data);
    for (GanttSubData subData in data.subData) {
      // Generate arrows connector for each subData
      final subIndex = data.subData.indexOf(subData);
      final isSelected = selectedIndex == GanttSubData.getUniqueIndex(parentIndex, subIndex);
      final distanceFromStart = subData.dateStart.difference(firstDateShown).inDays * widthPerDay;

      // Start connector
      arrowsConnector.add(
        Positioned(
          left: isSelected ? distanceFromStart - connectorSize * 2.5 : distanceFromStart - connectorSize - 1,
          top: subData.getIndexFromEntireData(listData) * heightPerRow + heightPerRow / 2 - connectorSize / 2,
          child: ArrowConnector(
            widthPerDay: widthPerDay,
            heightPerRow: heightPerRow,
            size: connectorSize,
            originIndex: subIndex,
            originDateStart: subData.dateStart,
            originDateEnd: subData.dateEnd,
            onDragStart: () {
              isArrowConnecting.value = true;
            },
            onDragEnd: (targetIndex, targetDate) {
              try {
                isArrowConnecting.value = false;
                // Todo: fix how to determined whether the targetDate in range or not
                // Currently still not quite accurate
                if (isTargetInRange(targetDate, subData.dateStart) && targetIndex != subIndex) {
                  listData[parentIndex].subData[targetIndex].addDependency(subData.id);
                }
                onArrowConnected();
              } catch (e) {
                // Todo: show error message either with snackbar or dialog
                print('Error: $e');
              }
            },
          ),
        ),
      );

      // Generate arrows for each subData dependencies
      for (String dependency in subData.dependencies) {
        try {
          final dependentSubData = subData.getDependencies(data.subData).firstWhere(
                (element) => element.id == dependency,
          );
          final pointedSubData = subData;
          final dependentIndex = dependentSubData.getIndexFromEntireData(listData);
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
        } catch (e) {
          print('Error: $e');
        }
      }
    }
  }

  arrows.addAll(arrowsConnector);
  return arrows;
}
