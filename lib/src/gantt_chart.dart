import 'dart:math';

import 'package:flutter/material.dart';
import 'package:interactive_gantt_chart/src/gantt_data.dart';
import 'package:interactive_gantt_chart/src/gantt_mode.dart';
import 'package:interactive_gantt_chart/src/utils/gantt_utils.dart';
import 'package:intl/intl.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

class GanttChart<T, S> extends StatefulWidget {
  /// List of data to be rendered in the Gantt chart
  final List<GanttData<T, S>> data;

  /// Initial mode of the Gantt chart
  final GanttMode ganttMode;

  /// Width of each day in the chart
  final double widthPerDay;
  final double widthPerDayDaily;
  final double widthPerDayWeekly;
  final double widthPerDayMonthly;

  /// Height of each row in the chart
  final double heightPerRow;

  /// Initial width of the label section
  final double initialLabelWidth;

  /// Spacing between each row
  /// Is actually act like a vertical padding to make the chart bar looks smaller
  /// Set the [heightPerRow] to set the actual height of each row
  final double rowSpacing;

  /// Color of the grid line
  final Color gridLineColor;

  /// Style of the header label
  /// Used for the task label and date (Years & Month) label
  final TextStyle headerLabelStyle;

  /// Style of the day label
  final TextStyle dayLabelStyle;

  /// Set how many days to be shown after the last task end date
  final int daysAfterLastTask;

  /// Set how many days to be shown before the first task start date
  final int daysBeforeFirstTask;

  final Widget headerTitle;
  final bool showLabelOnChartBar;
  final Color chartBarColor;
  final Color subTaskBarColor;
  final BorderRadiusGeometry chartBarBorderRadius;
  final Color activeBorderColor;
  final double activeBorderWidth;
  final Color tableOuterColor;
  final Color arrowColor;
  final double arrowSize;
  final double connectorSize;
  final Color connectorColor;
  final Color labelBackgroundColor;
  final Color reorderIndicatorColor;
  /// Enable the magnet drag feature
  /// If enabled, the draggable bar & indicator will snap to the nearest date
  final bool enableMagnetDrag;

  /// Animation duration used on some elements
  final Duration animationDuration;

  /// Make sure that current date is visible when the widget is first rendered
  final bool onInitScrollToCurrentDate;

  /// Width of the draggable indicator
  /// Used to calculate the position of the draggable indicator especially when custom builder is used
  final double dragIndicatorWidth;

  /// Builder for the draggable end date indicator
  final Widget Function(
    double rowHeight,
    double rowSpacing,
    GanttData<T, S> data,
  )? draggableEndIndicatorBuilder;

  /// Builder for the draggable start date indicator
  final Widget Function(
    double rowHeight,
    double rowSpacing,
    GanttData<T, S> data,
  )? draggableStartIndicatorBuilder;

  /// Builder for the task label
  final Widget Function(T data, int index)? taskLabelBuilder;

  /// Disable the horizontal drag of chart elements
  final bool enableHorizontalDrag;

  final void Function(
    GanttData<T, S> newData,
    int index,
    DragEndDetails dragDetails,
  )? onDragEnd;

  /// Function that called when certain label reordered.
  /// Function will not be called if [enableReorder] is set to false.
  /// [orderedIndex] is the index of the label that is reordered,
  /// [targetIndex] is the index of the label that is the target of the reorder,
  /// [targetIndex] returns -1 if the label is not reordered to a valid location.
  final void Function(
    int orderedIndex,
    int targetIndex,
  )? onReordered;

  /// Enable the reorder feature of rows. Default is true
  final bool enableReorder;

  /// Enable the resizing feature of the label section. Default is true
  final bool enableResizing;

  const GanttChart({
    super.key,
    required this.data,
    this.ganttMode = GanttMode.daily,
    this.tableOuterColor = Colors.black,
    this.widthPerDay =  65.0,
    this.widthPerDayDaily = 45.0,
    this.widthPerDayWeekly = 25.0,
    this.widthPerDayMonthly = 5.0,
    this.heightPerRow = 50.0,
    this.initialLabelWidth = 100.0,
    this.rowSpacing = 15.0,
    this.gridLineColor = Colors.grey,
    this.headerLabelStyle = const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
    this.dayLabelStyle = const TextStyle(fontSize: 12),
    this.daysAfterLastTask = 15,
    this.daysBeforeFirstTask = 15,
    this.draggableEndIndicatorBuilder,
    this.draggableStartIndicatorBuilder,
    this.dragIndicatorWidth = 14.0,
    this.onDragEnd,
    this.enableHorizontalDrag = true,
    this.enableReorder = true,
    this.enableResizing = true,
    this.headerTitle = const Text('Project'),
    this.showLabelOnChartBar = true,
    this.chartBarColor = Colors.blue,
    this.chartBarBorderRadius = const BorderRadius.all(Radius.circular(5)),
    this.taskLabelBuilder,
    this.onInitScrollToCurrentDate = false,
    this.activeBorderColor = Colors.red,
    this.activeBorderWidth = 2,
    this.subTaskBarColor = Colors.blueGrey,
    this.animationDuration = const Duration(milliseconds: 300),
    this.arrowColor = Colors.blue,
    this.arrowSize = 6,
    this.enableMagnetDrag = true,
    this.connectorSize = 12,
    this.connectorColor = Colors.red,
    this.onReordered,
    this.labelBackgroundColor = Colors.white,
    this.reorderIndicatorColor = Colors.black,
  });

  @override
  State<GanttChart> createState() => _GanttChartState<T, S>();
}

class _GanttChartState<T, S> extends State<GanttChart<T, S>> {
  final linkedScrollController = LinkedScrollControllerGroup();
  late ScrollController labelScrollController;
  late ScrollController chartScrollController;
  late ScrollController arrowsScrollController;
  late double widthPerDay;
  late GanttMode ganttMode;
  final chartHorizontalScrollController = ScrollController();
  final dateLabel = ValueNotifier(DateTime.now());
  final selectedTaskIndex = ValueNotifier<int>(0);
  final arrowState = ValueNotifier(false);
  final labelWidth = ValueNotifier(0.0);
  final isArrowConnecting = ValueNotifier(false);
  final selectedLabelI = ValueNotifier(-1);

  @override
  void initState() {
    // init any necessary value
    changeGanttMode(widget.ganttMode);
    labelWidth.value = widget.initialLabelWidth;
    labelScrollController = linkedScrollController.addAndGet();
    chartScrollController = linkedScrollController.addAndGet();
    arrowsScrollController = linkedScrollController.addAndGet();

    labelScrollController.addListener(() {
      selectedLabelI.value = -1;
    });

    // Handle dynamic date label
    chartHorizontalScrollController.addListener(() {
      final firstStartDate = widget.data.fold(
        DateTime.now(),
        (previousValue, element) {
          return element.dateStart.isBefore(previousValue)
              ? element.dateStart
              : previousValue;
        },
      ).subtract(
        Duration(days: widget.daysBeforeFirstTask),
      );
      final offsetInDays =
          (chartHorizontalScrollController.offset / widthPerDay).round();
      final visibleDate = firstStartDate.add(Duration(days: offsetInDays));
      dateLabel.value = visibleDate;
    });

    // Scroll to the current date
    if (widget.onInitScrollToCurrentDate) {
      Future.delayed(const Duration(seconds: 1), () {
        final firstStartDate = widget.data.fold(
          DateTime.now(),
          (previousValue, element) {
            return element.dateStart.isBefore(previousValue)
                ? element.dateStart
                : previousValue;
          },
        );
        final offsetInDays = (DateTime.now().difference(firstStartDate).inDays);
        chartHorizontalScrollController.jumpTo(offsetInDays * widthPerDay);
      });
    }
    super.initState();
  }

  void changeGanttMode(GanttMode newGanttMode) {
    widthPerDay = switch (newGanttMode) {
      GanttMode.day => widget.widthPerDay,
      GanttMode.daily => widget.widthPerDayDaily,
      GanttMode.weekly => widget.widthPerDayWeekly,
      GanttMode.monthly => widget.widthPerDayMonthly,
    };

    setState(() => ganttMode = newGanttMode);
  }

  @override
  void dispose() {
    labelScrollController.dispose();
    chartScrollController.dispose();
    chartHorizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firstStartDate = widget.data.fold(DateTime.now(), (
      previousValue,
      element,
    ) {
      return element.dateStart.isBefore(previousValue)
          ? element.dateStart
          : previousValue;
    }).subtract(
      Duration(days: widget.daysBeforeFirstTask),
    );

    final firstEndDate = widget.data.fold(DateTime.now(), (
      previousValue,
      element,
    ) {
      return element.dateEnd.isAfter(previousValue)
          ? element.dateEnd
          : previousValue;
    }).add(Duration(days: widget.daysAfterLastTask));

    final maxChartWidth =
        (firstEndDate.difference(firstStartDate).inDays * widthPerDay);

    final dayLabelHeight = widget.heightPerRow * 0.5;

    // Sum realChartHeight with all the sub task, +1 for border
    final realChartHeight = 1 +
        dayLabelHeight +
        widget.data.fold(
          0.0,
          (previousValue, element) {
            return previousValue + element.getBarHeight(widget.heightPerRow);
          },
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: constraints.maxHeight,
          width: constraints.maxWidth,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side (Task label Section)
              _buildTaskLabel(
                constraints,
                realChartHeight,
              ),

              // Right side
              ValueListenableBuilder(
                valueListenable: labelWidth,
                builder: (context, labelWidthValue, _) {
                  return SizedBox(
                    width: constraints.maxWidth - labelWidthValue,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 50,
                          child: Row(
                            children: [
                              // Date label for Years & month
                              _buildYearMonthLabel(constraints),
                              Expanded(
                                child: Container(
                                  alignment: Alignment.topRight,
                                  child: DropdownButton<GanttMode>(
                                    items: GanttMode.values.map((mode) {
                                      return DropdownMenuItem(
                                        value: mode,
                                        child: Text(mode.name),
                                      );
                                    }).toList(),
                                    value: ganttMode,
                                    onChanged: (value) => {
                                      if (value != null) changeGanttMode(value)
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Draw all gant chart here
                        _buildMainGanttChart(
                          constraints,
                          realChartHeight,
                          maxChartWidth,
                          dayLabelHeight,
                          firstStartDate,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskLabel(
    BoxConstraints constraints,
    double realChartHeight,
  ) {
    return ValueListenableBuilder(
      valueListenable: labelWidth,
      builder: (context, labelWidthValue, _) {
        return SizedBox(
          width: labelWidthValue,
          height: realChartHeight > constraints.maxHeight - widget.heightPerRow
              ? constraints.maxHeight
              : realChartHeight + widget.heightPerRow,
          child: Stack(
            children: [
              SizedBox(
                width: labelWidthValue,
                height: realChartHeight >
                        constraints.maxHeight - widget.heightPerRow
                    ? constraints.maxHeight
                    : realChartHeight + widget.heightPerRow,
                child: Column(
                  children: [
                    SizedBox(
                      height: widget.heightPerRow * 0.5 + 50,
                      child: widget.headerTitle
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: widget.tableOuterColor),
                            top: BorderSide(color: widget.tableOuterColor),
                          ),
                        ),
                        child: Stack(
                          children: [
                            ListView.builder(
                              controller: labelScrollController,
                              itemCount: widget.data.length,
                              itemBuilder: (context, index) {
                                final data = widget.data[index];

                                return labelItem(
                                  selectedLabelI: selectedLabelI,
                                  index: index,
                                  data: data,
                                );
                              },
                            ),

                            // Widget for reorder indicator
                            ValueListenableBuilder(
                              valueListenable: selectedLabelI,
                              builder: (context, selectedLabelIValue, _) {
                                if (selectedLabelIValue == -1) {
                                  return const SizedBox();
                                }
                                final data = widget.data[selectedLabelIValue];
                                final currentLabelHeight =
                                    widget.heightPerRow;
                                final topPosition = ValueNotifier(
                                    currentLabelHeight -
                                        labelScrollController.offset +
                                        (widget.heightPerRow / 2) -
                                        widget.heightPerRow * 1.5);
                                return ValueListenableBuilder(
                                  valueListenable: topPosition,
                                  builder: (context, topPositionValue, _) {
                                    return Positioned(
                                      left: 0,
                                      top: topPositionValue,
                                      child: SizedBox(
                                        height: data
                                            .getBarHeight(widget.heightPerRow),
                                        width: labelWidth.value,
                                        child: Stack(
                                          alignment: Alignment.centerLeft,
                                          children: [
                                            labelItem(
                                              selectedLabelI: selectedLabelI,
                                              index: selectedLabelIValue,
                                              data: data,
                                            ),

                                            /// Show reorder indicator if reordering is enabled
                                            if (widget.enableReorder)
                                              GestureDetector(
                                                onVerticalDragEnd: (details) {
                                                  final newIndex =
                                                      getReorderingDestinationIndex(
                                                    listData: widget.data,
                                                    currentIndex:
                                                        selectedLabelIValue,
                                                    details: details,
                                                    heightPerRow:
                                                        widget.heightPerRow,
                                                    rowSpacing:
                                                        widget.rowSpacing,
                                                  );

                                                  widget.onReordered?.call(
                                                    selectedLabelIValue,
                                                    newIndex,
                                                  );

                                                  setState(() {
                                                    if (newIndex != -1) {
                                                      final temp = widget.data
                                                          .removeAt(
                                                              selectedLabelIValue);
                                                      selectedLabelI.value =
                                                          newIndex;
                                                      selectedTaskIndex.value =
                                                          newIndex;
                                                      widget.data.insert(
                                                          newIndex, temp);
                                                    }
                                                  });
                                                },
                                                onVerticalDragUpdate:
                                                    (details) {
                                                  topPosition.value +=
                                                      details.delta.dy;
                                                },
                                                child: Icon(
                                                  Icons.drag_indicator,
                                                  color: widget
                                                      .reorderIndicatorColor,
                                                  size: 20,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Widget to resize the label section
              Positioned(
                right: 0,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (!widget.enableResizing) return;
                    final newWidth = labelWidth.value + details.delta.dx;
                    if (newWidth > 50 && newWidth < constraints.maxWidth / 2) {
                      labelWidth.value = newWidth;
                    }
                  },
                  child: Container(
                    height: realChartHeight >
                            constraints.maxHeight - widget.heightPerRow
                        ? constraints.maxHeight
                        : realChartHeight + widget.heightPerRow,
                    width: 12,
                    color: Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget labelItem({
    required ValueNotifier<int> selectedLabelI,
    required int index,
    required GanttData<T, S> data,
  }) {
    return ValueListenableBuilder(
      valueListenable: selectedLabelI,
      builder: (context, selectedLabelIValue, _) {
        final isSelected = selectedLabelIValue == index;
        return GestureDetector(
          onTap: () {
            (isSelected)
                ? selectedLabelI.value = -1
                : {
                    selectedLabelI.value = index,
                    selectedTaskIndex.value = index,
                  };
          },
          child: Container(
            decoration: BoxDecoration(
              color: widget.labelBackgroundColor,
              border: isSelected
                  ? Border.all(color: widget.activeBorderColor)
                  : Border(
                      bottom: BorderSide(color: widget.tableOuterColor),
                      left: BorderSide(color: widget.tableOuterColor),
                    ),
            ),
            height: widget.data[index].getBarHeight(widget.heightPerRow),
            width: labelWidth.value,
            child: widget.taskLabelBuilder != null
                ? widget.taskLabelBuilder!(data.data, index)
                : SizedBox(
                    height: widget.data[index].getBarHeight(
                      widget.heightPerRow,
                    ),
                    child: Center(child: Text(data.label)),
                  ),
          ),
        );
      },
    );
  }

  Container _buildMainGanttChart(
    BoxConstraints constraints,
    double realChartHeight,
    double maxChartWidth,
    double dayLabelHeight,
    DateTime firstStartDate,
  ) {
    List<Widget> labelWidgets = [];
    // additional vertical lines for week or month
    List<Positioned> verticalGuideLines = [];

    DateFormat weekFormat = DateFormat('EEEE');

    // Loop through and generate labels
    for (int i = 0; i < maxChartWidth / widthPerDay;) {
      DateTime currentDate = firstStartDate.add(Duration(days: i));

      // Check if the current date is the start of the week
      // Assuming the first day of the week is Monday (adjust to 'Sunday' if needed)
      bool isStartOfWeek = weekFormat.format(currentDate) == 'Monday' || i == 0;
      bool isStartOfMonth = currentDate.day == 1 || i == 0;

      // Calculate the remaining days in the week
      late int daysLeftInWeek;
      late int daysLeftInMonth;

      if (ganttMode == GanttMode.weekly) {
        daysLeftInWeek = 8 - currentDate.weekday;
      } else if (ganttMode == GanttMode.monthly) {
        daysLeftInMonth =
            DateTime(currentDate.year, currentDate.month + 1, 0).day -
                currentDate.day +
                1;
      }

      // Ensure it doesn't go beyond the chart width
      int daysToShow = ganttMode == GanttMode.weekly
          ? (i + daysLeftInWeek >
                  maxChartWidth / widthPerDay) // If last week has fewer days
              ? (maxChartWidth / widthPerDay - i)
                  .toInt() // Only show remaining days
              : daysLeftInWeek
          : ganttMode == GanttMode.monthly
              ? (i + daysLeftInMonth >
                      maxChartWidth /
                          widthPerDay) // If last month has fewer days
                  ? (maxChartWidth / widthPerDay - i)
                      .toInt() // Only show remaining days
                  : daysLeftInMonth
              : 1;

      // Avoid showing 0 days
      if (daysToShow == 0) {
        i++;
        continue;
      }

      // Generate labels based on the mode
      String labelText = '';
      double labelWidth = 0;

      if (ganttMode == GanttMode.daily) {
        labelText = currentDate.day.toString();
        labelWidth = widthPerDay;
      } else if (ganttMode == GanttMode.weekly && isStartOfWeek) {
        // Show week label (e.g., 'Week of 1st Jan') and calculate the dynamic width
        labelText =
            '${DateFormat('dd MMM').format(currentDate)} - ${DateFormat('dd MMM').format(currentDate.add(Duration(days: daysToShow - 1)))}';
        labelWidth = widthPerDay * daysToShow;
      } else if (ganttMode == GanttMode.monthly && isStartOfMonth) {
        // Show month label (e.g., 'Jan 2022') and calculate the dynamic width
        labelText =
            '${DateFormat('MMM').format(currentDate)} ${currentDate.year}';
        labelWidth = widthPerDay * daysToShow;
      }else if (ganttMode == GanttMode.day) {

        for (int hour = 0; hour < 24; hour++) {
          DateTime hourDate = currentDate.add(Duration(hours: hour));
          String hourLabelText = '$hour:00'; // Hiển thị giờ như "0:00", "1:00", ...
          // Tính chiều rộng cho từng giờ
          double hourLabelWidth = widthPerDay ;

          labelWidgets.add(
            Tooltip(
              message: DateFormat('dd MMM yyyy HH:mm').format(hourDate), // Tooltip chi tiết
              child: Container(
                width: hourLabelWidth,
                height: dayLabelHeight,
                decoration: BoxDecoration(
                  color: widget.chartBarColor,
                  border: Border(
                    right: BorderSide(color: widget.tableOuterColor),
                    bottom: BorderSide(color: widget.tableOuterColor),
                  ),
                ),
                child: Center(
                  child: Text(
                    '${DateFormat('dd/MM').format(currentDate)}\n$hourLabelText',
                    style: widget.dayLabelStyle,
                  ),
                ),
              ),
            ),
          );
        }
      }
      final tooltipMessage = switch (ganttMode) {
        GanttMode.weekly =>
          '${DateFormat('dd MMM yyyy').format(currentDate)} - ${DateFormat('dd MMM yyyy').format(currentDate.add(Duration(days: daysToShow - 1)))}',
        GanttMode.monthly => DateFormat('MMMM yyyy').format(currentDate),
        _ => '',
      };
      // Add the label widget to the list
      labelWidgets.add(
        Tooltip(
          message: tooltipMessage,
          child: Container(
            width: labelWidth,
            height: dayLabelHeight,
            decoration: BoxDecoration(
              color: widget.chartBarColor,
              border: Border(
                right: (ganttMode != GanttMode.daily)
                    ? BorderSide(color: widget.tableOuterColor)
                    : BorderSide.none,
                left: BorderSide(color: widget.tableOuterColor),
                bottom: BorderSide(color: widget.tableOuterColor),
              ),
            ),
            child: Center(
              child: Text(
                labelText,
                style: widget.dayLabelStyle,
              ),
            ),
          ),
        ),
      );

      if (ganttMode != GanttMode.daily) {
        // Add vertical line for each week or month
        verticalGuideLines.add(
          Positioned(
            left: i * widthPerDay - 1,
            child: Container(
              height: realChartHeight,
              width: 2,
              color: widget.tableOuterColor,
            ),
          ),
        );
      }

      // Move to the next day or week or month
      i += (ganttMode == GanttMode.daily) ? 1 : daysToShow;
    }

    return Container(
      width: constraints.maxWidth - labelWidth.value,
      height: realChartHeight > constraints.maxHeight - widget.heightPerRow
          ? constraints.maxHeight - widget.heightPerRow + 40
          : realChartHeight,
      decoration: BoxDecoration(
        border: Border.all(color: widget.tableOuterColor),
      ),
      child: ValueListenableBuilder(
          valueListenable: isArrowConnecting,
          builder: (context, isArrowConnectingState, _) {
            return RawScrollbar(
              controller: chartHorizontalScrollController,
              thumbVisibility: true,
              thumbColor: Colors.black,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: chartHorizontalScrollController,
                physics: isArrowConnectingState
                    ? const NeverScrollableScrollPhysics()
                    : const AlwaysScrollableScrollPhysics(),
                child: Stack(
                  children: [
                    // Vertical line for days
                    for (int i = 0; i < maxChartWidth / widthPerDay; i++)
                      Positioned(
                        left: i * widthPerDay,
                        child: Opacity(
                          opacity: (ganttMode == GanttMode.daily) ? 1 : 0.5,
                          child: Container(
                            height: (realChartHeight),
                            width: 1,
                            color: widget.gridLineColor,
                          ),
                        ),
                      ),

                    // Additional vertical line for each week or month
                    ...verticalGuideLines,

                    SizedBox(
                      width: maxChartWidth,
                      child: Column(
                        children: [
                          SizedBox(
                            height: dayLabelHeight, // Chiều cao cố định
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: labelWidgets.length,
                              itemBuilder: (context, index) {
                                return labelWidgets[index];
                              },
                            ),
                          ),
                          Expanded(
                            child: Stack(
                              children: [
                                // All Arrows Dependencies and Connector section
                                ValueListenableBuilder(
                                  valueListenable: arrowState,
                                  builder: (context, _, __) {
                                    return SizedBox(
                                      height: realChartHeight >
                                              constraints.maxHeight -
                                                  widget.heightPerRow
                                          ? constraints.maxHeight
                                          : realChartHeight + widget.heightPerRow,
                                      child: ValueListenableBuilder(
                                        valueListenable: isArrowConnecting,
                                        builder:
                                            (context, isArrowConnectingState, _) {
                                          return SingleChildScrollView(
                                            controller: arrowsScrollController,
                                            physics: isArrowConnectingState
                                                ? const NeverScrollableScrollPhysics()
                                                : const AlwaysScrollableScrollPhysics(),
                                            child: SizedBox(
                                              width: maxChartWidth,
                                              height: realChartHeight -
                                                  widget.heightPerRow / 2,
                                              child: Stack(
                                                clipBehavior: Clip.none,
                                                children: [
                                                  ...generateArrows(
                                                    widget.data,
                                                    widthPerDay: widthPerDay,
                                                    heightPerRow:
                                                        widget.heightPerRow,
                                                    firstDateShown:
                                                        firstStartDate,
                                                    indicatorWidth:
                                                        widget.dragIndicatorWidth,
                                                    arrowColor: widget.arrowColor,
                                                    arrowSize: widget.arrowSize,
                                                    selectedIndex:
                                                        selectedTaskIndex.value,
                                                    connectorSize:
                                                        widget.connectorSize,
                                                    connectorColor:
                                                        widget.connectorColor,
                                                    isArrowConnecting:
                                                        isArrowConnecting,
                                                    arrowState: arrowState,
                                                    mode: ganttMode,
                                                    onArrowStartConnecting: () {
                                                      arrowState.value =
                                                          !arrowState.value;
                                                    },
                                                    onArrowConnected: () =>
                                                        setState(() {}),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),

                                ValueListenableBuilder(
                                  valueListenable: isArrowConnecting,
                                  builder: (context, isArrowConnectingState, _) {
                                    return ListView.builder(
                                      hitTestBehavior:
                                          HitTestBehavior.deferToChild,
                                      controller: chartScrollController,
                                      physics: isArrowConnectingState
                                          ? const NeverScrollableScrollPhysics()
                                          : const AlwaysScrollableScrollPhysics(),
                                      itemCount: widget.data.length,
                                      itemBuilder: (context, index) {
                                        final data = widget.data[index];
                                        final durationInHours = max(
                                            data.dateEnd.difference(data.dateStart).inHours.toDouble(),
                                            1.0
                                        );
                                        final double width = durationInHours * (widthPerDay / 24.0);

                                        final startDistance = ValueNotifier<double>(
                                            data.dateStart.difference(firstStartDate.copyWith(hour: 0,minute: 0)).inHours.toDouble() * (widthPerDay / 24.0));

                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              height: widget.heightPerRow,
                                              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey))),
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  buildMainDataBar(
                                                    index,
                                                    startDistance,
                                                    data,
                                                    width,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
    );
  }

  ValueListenableBuilder<int> buildMainDataBar(
    int index,
    ValueNotifier<double> startDistance,
    GanttData<dynamic, dynamic> data,
    double width,
  ) {
    return ValueListenableBuilder(
      valueListenable: selectedTaskIndex,
      builder: (context, selectedTaskIndexValue, _) {
        final isSelected = selectedTaskIndexValue == index;

        // variable for storing bar current distance from the start
        // Fixed value for calculating the new date while dragging
        final distanceFromStart = startDistance.value;

        // Variable for storing upcoming start and end date while dragging.
        // Only means to used for updating the actual data at the end of the drag
        // to avoid calling setState multiple times
        DateTime newStart = data.dateStart;
        DateTime newEnd = data.dateEnd;
        return ValueListenableBuilder(
          valueListenable: startDistance,
          builder: (context, startDistanceValue, _) {
            // print('index:$index : $startDistanceValue');
            // print('width:$index : $width');

            return AnimatedPositioned(
              duration: widget.animationDuration,
              left: startDistanceValue,
              child: GestureDetector(
                onTap: () {
                  selectedTaskIndex.value = index;
                  selectedLabelI.value = index;

                  // trigger arrow refresh
                  arrowState.value = !arrowState.value;
                },
                onHorizontalDragEnd: !isSelected
                    ? null
                    : (details) {
                        /// Check if horizontal drag is enabled
                        if (!widget.enableHorizontalDrag) {
                          return;
                        }

                        setState(() {
                          data.calculateAllDate(newStart, newEnd);
                        });
                        widget.onDragEnd?.call(
                          widget.data[index],
                          index,
                          details,
                        );
                      },

                onHorizontalDragUpdate: !isSelected
                    ? null
                    : (details) {
                        /// Check if horizontal drag is enabled
                        if (!widget.enableHorizontalDrag) {
                          return;
                        }

                        moveEntireBar(
                          deltaDX: details.delta.dx,
                          startDistance: startDistance.value,
                          distanceFromStart: distanceFromStart,
                          widthPerDay: widthPerDay,
                          enableMagnetDrag: widget.enableMagnetDrag,
                          onNewDistance: (newDistanceInDays, newStartDistance) {
                            newStart = data.dateStart.add(
                              Duration(days: newDistanceInDays),
                            );
                            newEnd = data.dateEnd.add(
                              Duration(days: newDistanceInDays),
                            );
                            startDistance.value = newStartDistance;
                          },
                        );
                      },
                child: Tooltip(
                  textAlign: TextAlign.center,
                  message:
                  '${data.label}\n${data.dateStart} - ${data.dateEnd}',
                  child: Container(
                    width: width,
                    height: widget.heightPerRow - widget.rowSpacing,
                    decoration: BoxDecoration(
                      color: widget.chartBarColor,
                      borderRadius: widget.chartBarBorderRadius,
                      border: Border.all(
                        color: isSelected
                            ? widget.activeBorderColor
                            : Colors.transparent,
                        width: isSelected ? widget.activeBorderWidth : 0,
                      ),
                    ),
                    child: Visibility(
                      visible: widget.showLabelOnChartBar,
                      child: Center(
                        child: Text(data.label),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }


  SizedBox _buildYearMonthLabel(BoxConstraints constraints) {
    return SizedBox(
      height: widget.heightPerRow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ValueListenableBuilder(
            valueListenable: dateLabel,
            builder: (_, value, __) {
              return Text(
                '${value.year}',
                style: widget.headerLabelStyle,
              );
            },
          ),
          if(ganttMode == GanttMode.daily  )
          ValueListenableBuilder(
            valueListenable: dateLabel,
            builder: (_, value, __) {
              return Text(
                DateFormat.MMMM().format(dateLabel.value),
                style: widget.headerLabelStyle,
              );
            },
          ),
        ],
      ),
    );
  }

}
