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
  for (GanttData data in listData) {
    final parentIndex = listData.indexOf(data);
    bool isParentSelected = selectedIndex == parentIndex;
    if (!isParentSelected) {
      for (int i = 0; i < data.subData.length; i++) {
        if (selectedIndex == GanttSubData.getUniqueIndex(parentIndex, i)) {
          isParentSelected = true;
        }
      }
    }
    for (GanttSubData subData in data.subData) {
      // Generate arrows connector for each subData
      final subIndex = data.subData.indexOf(subData);
      final isSelected =
          selectedIndex == GanttSubData.getUniqueIndex(parentIndex, subIndex);
      final distanceFromStart =
          subData.dateStart.difference(firstDateShown).inDays * widthPerDay;

      if (isParentSelected) {
        // Start connector
        arrowsConnector.add(
          Positioned(
            left: isSelected
                ? distanceFromStart - connectorSize * 2.5
                : distanceFromStart - connectorSize - 1.5,
            top: subData.getIndexFromEntireData(listData) * heightPerRow +
                heightPerRow / 2 -
                connectorSize / 2,
            child: ArrowConnector(
              widthPerDay: widthPerDay,
              heightPerRow: heightPerRow,
              size: connectorSize,
              connectorColor: connectorColor,
              originIndex: subIndex,
              originDateStart: subData.dateStart,
              originDateEnd: subData.dateEnd,
              onDragStart: () {
                isArrowConnecting.value = true;
                onArrowStartConnecting();
              },
              onDragEnd: (targetIndex, targetDate) {
                try {
                  isArrowConnecting.value = false;
                  final targetData = listData[parentIndex].subData[targetIndex];
                  final isTargetSelected = selectedIndex ==
                      GanttSubData.getUniqueIndex(parentIndex, targetIndex);
                  final additionalDays = !isTargetSelected
                      ? const Duration(days: 0)
                      : switch (mode) {
                          GanttMode.daily => const Duration(days: 0),
                          GanttMode.weekly => const Duration(days: 1),
                          GanttMode.monthly => const Duration(days: 3),
                        };
                  final rangeInDays = (mode == GanttMode.monthly) ? 4 : 1;
                  if (isTargetInRangeOfTwoOrigin(
                        targetDate,
                        targetData.dateStart.subtract(additionalDays),
                        targetData.dateEnd
                            .add(additionalDays)
                            .add(const Duration(days: 1)),
                        rangeInDays: rangeInDays,
                      ) &&
                      targetIndex != subIndex) {
                    listData[parentIndex]
                        .subData[targetIndex]
                        .addDependency(subData.id);
                  }
                  onArrowConnected();
                } catch (e) {
                  print('Error: $e');
                }
              },
            ),
          ),
        );

        // End connector
        arrowsConnector.add(
          Positioned(
            left: isSelected
                ? (subData.dateEnd.difference(firstDateShown).inDays + 1) *
                        widthPerDay +
                    connectorSize * 1.5
                : (subData.dateEnd.difference(firstDateShown).inDays + 1) *
                        widthPerDay +
                    1.5,
            top: subData.getIndexFromEntireData(listData) * heightPerRow +
                heightPerRow / 2 -
                connectorSize / 2,
            child: ArrowConnector(
              widthPerDay: widthPerDay,
              heightPerRow: heightPerRow,
              size: connectorSize,
              connectorColor: connectorColor,
              originIndex: subIndex,
              originDateStart: subData.dateStart,
              originDateEnd: subData.dateEnd,
              isStart: false,
              onDragStart: () {
                isArrowConnecting.value = true;
                onArrowStartConnecting();
              },
              onDragEnd: (targetIndex, targetDate) {
                try {
                  isArrowConnecting.value = false;
                  final targetData = listData[parentIndex].subData[targetIndex];
                  final isTargetSelected = selectedIndex ==
                      GanttSubData.getUniqueIndex(parentIndex, targetIndex);
                  final additionalDays = !isTargetSelected
                      ? const Duration(days: 0)
                      : switch (mode) {
                          GanttMode.daily => const Duration(days: 1),
                          GanttMode.weekly => const Duration(days: 1),
                          GanttMode.monthly => const Duration(days: 3),
                        };
                  final rangeInDays = (mode == GanttMode.monthly) ? 3 : 1;
                  if (isTargetInRangeOfTwoOrigin(
                        targetDate,
                        targetData.dateStart.subtract(additionalDays),
                        targetData.dateEnd.add(additionalDays),
                        rangeInDays: rangeInDays,
                      ) &&
                      targetIndex != subIndex) {
                    listData[parentIndex]
                        .subData[targetIndex]
                        .addDependency(subData.id);
                  }
                  onArrowConnected();
                } catch (e) {
                  print('Error: $e');
                }
              },
            ),
          ),
        );
      }

      // Generate arrows for each subData dependencies
      for (String dependency in subData.dependencies) {
        try {
          final dependentSubData =
              subData.getDependencies(data.subData).firstWhere(
                    (element) => element.id == dependency,
                  );
          final pointedSubData = subData;
          final dependentIndex =
              dependentSubData.getIndexFromEntireData(listData);
          final pointedIndex = pointedSubData.getIndexFromEntireData(listData);

          arrows.add(
            GestureDetector(
              onLongPress: () {
                subData.removeDependency(dependency);
                arrowState.value = !arrowState.value;
              },
              child: CustomPaint(
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
                child: Container(),
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
