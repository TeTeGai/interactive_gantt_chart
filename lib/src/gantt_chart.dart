import 'package:flutter/material.dart';
import 'package:interactive_gantt_chart/src/gantt_data.dart';
import 'package:interactive_gantt_chart/src/gantt_mode.dart';
import 'package:intl/intl.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

class GanttChart<T, S> extends StatefulWidget {
  /// List of data to be rendered in the Gantt chart
  final List<GanttData<T, S>> data;

  /// Initial mode of the Gantt chart
  final GanttMode ganttMode;

  /// Width of each day in the chart
  final double widthPerDayDaily;
  final double widthPerDayWeekly;
  final double widthPerDayMonthly;

  /// Height of each row in the chart
  final double heightPerRow;

  /// Width of the label section
  final double labelWidth;

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

  final String labelText;
  final bool showLabelOnChartBar;
  final Color chartBarColor;
  final Color subTaskBarColor;
  final BorderRadiusGeometry chartBarBorderRadius;
  final Color activeBorderColor;
  final double activeBorderWidth;
  final Color tableOuterColor;

  /// Make sure that current date is visible when the widget is first rendered
  final bool onInitScrollToCurrentDate;

  /// Width of the draggable indicator
  /// Used to calculate the position of the draggable indicator especially when custom builder is used
  final double dragIndicatorWidth;

  /// Builder for the draggable end date indicator
  final Widget Function(
          double rowHeight, double rowSpacing, GanttData<T, S> data)?
      draggableEndIndicatorBuilder;

  /// Builder for the draggable start date indicator
  final Widget Function(
          double rowHeight, double rowSpacing, GanttData<T, S> data)?
      draggableStartIndicatorBuilder;

  /// Builder for the task label
  final Widget Function(String textLabel, int index)? taskLabelBuilder;

  final void Function(
          GanttData<T, S> newData, int index, DragEndDetails dragDetails)?
      onDragEnd;

  const GanttChart({
    super.key,
    required this.data,
    this.ganttMode = GanttMode.daily,
    this.tableOuterColor = Colors.black,
    this.widthPerDayDaily = 50.0,
    this.widthPerDayWeekly = 25.0,
    this.widthPerDayMonthly = 5.0,
    this.heightPerRow = 50.0,
    this.labelWidth = 100.0,
    this.rowSpacing = 15.0,
    this.gridLineColor = Colors.grey,
    this.headerLabelStyle = const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
    this.dayLabelStyle = const TextStyle(
      fontSize: 12,
    ),
    this.daysAfterLastTask = 10,
    this.daysBeforeFirstTask = 5,
    this.draggableEndIndicatorBuilder,
    this.draggableStartIndicatorBuilder,
    this.dragIndicatorWidth = 25.0,
    this.onDragEnd,
    this.labelText = 'Task',
    this.showLabelOnChartBar = true,
    this.chartBarColor = Colors.blue,
    this.chartBarBorderRadius = const BorderRadius.all(Radius.circular(5)),
    this.taskLabelBuilder,
    this.onInitScrollToCurrentDate = false,
    this.activeBorderColor = Colors.red,
    this.activeBorderWidth = 2,
    this.subTaskBarColor = Colors.blueGrey,
  });

  @override
  State<GanttChart> createState() => _GanttChartState<T, S>();
}

class _GanttChartState<T, S> extends State<GanttChart<T, S>> {
  final linkedScrollController = LinkedScrollControllerGroup();
  late ScrollController labelScrollController;
  late ScrollController chartScrollController;
  final chartHorizontalScrollController = ScrollController();
  final dateLabel = ValueNotifier(DateTime.now());
  final selectedTaskIndex = ValueNotifier<int>(0);
  late double widthPerDay;
  late GanttMode ganttMode;

  @override
  void initState() {
    // init width per day value
    changeGanttMode(widget.ganttMode);

    labelScrollController = linkedScrollController.addAndGet();
    chartScrollController = linkedScrollController.addAndGet();

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
    final firstStartDate =
        widget.data.fold(DateTime.now(), (previousValue, element) {
      return element.dateStart.isBefore(previousValue)
          ? element.dateStart
          : previousValue;
    }).subtract(
      Duration(days: widget.daysBeforeFirstTask),
    );
    final firstEndDate =
        widget.data.fold(DateTime.now(), (previousValue, element) {
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

    return LayoutBuilder(builder: (context, constraints) {
      return GestureDetector(
        child: SizedBox(
          height: constraints.maxHeight,
          width: constraints.maxWidth,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side (Task label Section)
              _buildTaskLabel(),

              // Right side
              SizedBox(
                width: constraints.maxWidth - widget.labelWidth,
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Date label for Years & month
                        _buildYearMonthLabel(constraints),
                        Expanded(
                          child: Container(
                            alignment: Alignment.bottomRight,
                            child: DropdownButton<GanttMode>(
                              items: GanttMode.values.map((mode) {
                                return DropdownMenuItem(
                                  value: mode,
                                  child: Text(mode.name),
                                );
                              }).toList(),
                              value: ganttMode,
                              onChanged: (value) =>
                                  {if (value != null) changeGanttMode(value)},
                            ),
                          ),
                        ),
                      ],
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
              ),
            ],
          ),
        ),
      );
    });
  }

  SizedBox _buildTaskLabel() {
    return SizedBox(
      width: widget.labelWidth,
      child: Column(
        children: [
          SizedBox(
            height: widget.heightPerRow * 1.5,
            child: Center(
              child: Text(widget.labelText, style: widget.headerLabelStyle),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: widget.tableOuterColor),
                  top: BorderSide(color: widget.tableOuterColor),
                ),
              ),
              child: ListView.builder(
                controller: labelScrollController,
                itemCount: widget.data.length,
                itemBuilder: (context, index) {
                  final data = widget.data[index];

                  if (widget.taskLabelBuilder != null) {
                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: widget.tableOuterColor),
                          left: BorderSide(color: widget.tableOuterColor),
                        ),
                      ),
                      height:
                          widget.data[index].getBarHeight(widget.heightPerRow),
                      child: widget.taskLabelBuilder!(data.label, index),
                    );
                  }

                  return SizedBox(
                    height:
                        widget.data[index].getBarHeight(widget.heightPerRow),
                    child: Center(
                      child: Text(data.label),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
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
    List<Positioned> verticalGuideLines =
        []; // additional vertical lines for week or month

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
            'Week of ${currentDate.day} ${DateFormat('MMM').format(currentDate)}';
        labelWidth =
            widthPerDay * daysToShow; // Dynamically calculate the label width
      } else if (ganttMode == GanttMode.monthly && isStartOfMonth) {
        // Show month label (e.g., 'Jan 2022') and calculate the dynamic width
        labelText =
            '${DateFormat('MMM').format(currentDate)} ${currentDate.year}';
        labelWidth =
            widthPerDay * daysToShow; // Dynamically calculate the label width
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
      width: constraints.maxWidth - widget.labelWidth,
      height: realChartHeight > constraints.maxHeight - widget.heightPerRow
          ? constraints.maxHeight - widget.heightPerRow
          : realChartHeight,
      decoration: BoxDecoration(
        border: Border.all(color: widget.tableOuterColor),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: chartHorizontalScrollController,
        child: Stack(
          children: [
            // Vertical line for days
            for (int i = 0; i < maxChartWidth / widthPerDay; i++)
              Positioned(
                left: i * widthPerDay,
                child: Container(
                  height: (realChartHeight),
                  width: 1,
                  color: (ganttMode == GanttMode.daily)
                      ? widget.gridLineColor
                      : widget.gridLineColor.withOpacity(0.5),
                ),
              ),

            // Additional vertical line for each week or month
            ...verticalGuideLines,

            SizedBox(
              width: maxChartWidth,
              child: Column(
                children: [
                  Row(
                    children: labelWidgets,
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: chartScrollController,
                      itemCount: widget.data.length,
                      itemBuilder: (context, index) {
                        final data = widget.data[index];
                        final duration =
                            data.dateEnd.difference(data.dateStart).inDays + 1;
                        final width = duration * widthPerDay;
                        final startDistance = ValueNotifier(
                            data.dateStart.difference(firstStartDate).inDays *
                                widthPerDay);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: widget.heightPerRow,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  ValueListenableBuilder(
                                    valueListenable: selectedTaskIndex,
                                    builder: (context, selectedIndex, _) {
                                      final isSelected = selectedIndex == index;

                                      // variable for storing bar current distance from the start
                                      // Fixed value for calculating the new date while dragging
                                      final distanceFromStart =
                                          startDistance.value;

                                      // Variable for storing upcoming start and end date while dragging.
                                      // Only means to used for updating the actual data at the end of the drag
                                      // to avoid calling setState multiple times
                                      DateTime newStart = data.dateStart;
                                      DateTime newEnd = data.dateEnd;
                                      return ValueListenableBuilder(
                                          valueListenable: startDistance,
                                          builder:
                                              (context, startDistanceValue, _) {
                                            return Positioned(
                                              left: startDistanceValue,
                                              child: GestureDetector(
                                                onTap: () => selectedTaskIndex
                                                    .value = index,
                                                onHorizontalDragEnd: !isSelected
                                                    ? null
                                                    : (details) {
                                                        setState(() {
                                                          data.calculateAllDate(
                                                              newStart, newEnd);
                                                        });
                                                        widget.onDragEnd?.call(
                                                          widget.data[index],
                                                          index,
                                                          details,
                                                        );
                                                      },
                                                onHorizontalDragUpdate:
                                                    !isSelected
                                                        ? null
                                                        : (details) {
                                                            final delta =
                                                                details
                                                                    .delta.dx;

                                                            late int
                                                                newDistanceInDays;
                                                            if (delta > 0) {
                                                              newDistanceInDays =
                                                                  ((startDistance.value -
                                                                              distanceFromStart) /
                                                                          widthPerDay)
                                                                      .ceil();
                                                            } else {
                                                              newDistanceInDays =
                                                                  ((startDistance.value -
                                                                              distanceFromStart) /
                                                                          widthPerDay)
                                                                      .floor();
                                                            }
                                                            newStart = data
                                                                .dateStart
                                                                .add(
                                                              Duration(
                                                                  days:
                                                                      newDistanceInDays),
                                                            );
                                                            newEnd = data
                                                                .dateEnd
                                                                .add(
                                                              Duration(
                                                                  days:
                                                                      newDistanceInDays),
                                                            );
                                                            startDistance
                                                                    .value =
                                                                startDistance
                                                                        .value +
                                                                    delta;
                                                          },
                                                child: Tooltip(
                                                  textAlign: TextAlign.center,
                                                  message:
                                                      '${data.label}\n${DateFormat('dd MMM yyyy').format(data.dateStart)} - ${DateFormat('dd MMM yyyy').format(data.dateEnd)}',
                                                  child: Container(
                                                    width: width,
                                                    height:
                                                        widget.heightPerRow -
                                                            widget.rowSpacing,
                                                    decoration: BoxDecoration(
                                                      color:
                                                          widget.chartBarColor,
                                                      borderRadius: widget
                                                          .chartBarBorderRadius,
                                                      border: Border.all(
                                                        color: isSelected
                                                            ? widget
                                                                .activeBorderColor
                                                            : Colors
                                                                .transparent,
                                                        width: isSelected
                                                            ? widget
                                                                .activeBorderWidth
                                                            : 0,
                                                      ),
                                                    ),
                                                    child: Visibility(
                                                      visible: widget
                                                          .showLabelOnChartBar,
                                                      child: Center(
                                                        child: Text(data.label),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          });
                                    },
                                  ),
                                ],
                              ),
                            ),

                            // Render sub task
                            buildSubTask(
                                data, firstStartDate, index, constraints),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SizedBox buildSubTask(GanttData<T, S> data, DateTime firstStartDate,
      int index, BoxConstraints constraints) {
    return SizedBox(
      height: widget.heightPerRow * data.subData.length,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: data.subData.length,
        itemBuilder: (_, subIndex) {
          final subData = data.subData[subIndex];
          final duration =
              subData.dateEnd.difference(subData.dateStart).inDays + 1;
          final width = duration * widthPerDay;

          // variable for storing the start distance from the first start date
          // reactive variable for updating the bar position while dragging
          final startDistance = ValueNotifier(
              subData.dateStart.difference(firstStartDate).inDays *
                  widthPerDay);

          // variable for storing bar current distance from the start
          // Fixed value for calculating the new date while dragging
          final distanceFromStart = startDistance.value;

          return ValueListenableBuilder(
            valueListenable: selectedTaskIndex,
            builder: (context, selectedIndex, _) {
              final isSelected =
                  selectedIndex == int.parse('${index + 1}0${subIndex + 1}');

              // Variable for storing upcoming start and end date while dragging.
              // Only means to used for updating the actual data at the end of the drag
              // to avoid calling setState multiple times
              DateTime newStart = subData.dateStart;
              DateTime newEnd = subData.dateEnd;

              // To notify the indicator that the parent is dragging
              final isDragging = ValueNotifier(false);

              // To notify the parent that the indicator is dragging
              final isIndicatorDragging = ValueNotifier(false);

              return SizedBox(
                height: widget.heightPerRow,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ValueListenableBuilder(
                        valueListenable: isIndicatorDragging,
                        builder: (context, isIndicatorDraggingState, _) {
                          if (isIndicatorDraggingState)
                            return const SizedBox.shrink();
                          return ValueListenableBuilder(
                            valueListenable: startDistance,
                            builder: (context, startDistanceValue, _) {
                              return Positioned(
                                left: startDistanceValue,
                                child: GestureDetector(
                                  onTap: () => selectedTaskIndex.value =
                                      int.parse('${index + 1}0${subIndex + 1}'),
                                  onHorizontalDragEnd: !isSelected
                                      ? null
                                      : (details) {
                                          setState(
                                            () {
                                              widget.data[index]
                                                      .subData[subIndex] =
                                                  subData.copyWith(
                                                dateStart: newStart,
                                                dateEnd: newEnd,
                                              );
                                              widget.data[index]
                                                  .calculateMainDate();
                                            },
                                          );

                                          widget.onDragEnd?.call(
                                            widget.data[index],
                                            index,
                                            details,
                                          );

                                          isDragging.value = false;
                                        },
                                  onHorizontalDragUpdate: !isSelected
                                      ? null
                                      : (details) {
                                          isDragging.value = true;

                                          // move entire bar
                                          final delta = details.delta.dx;

                                          late int newDistanceInDays;
                                          if (delta > 0) {
                                            newDistanceInDays =
                                                ((startDistance.value -
                                                            distanceFromStart) /
                                                        widthPerDay)
                                                    .ceil();
                                          } else {
                                            newDistanceInDays =
                                                ((startDistance.value -
                                                            distanceFromStart) /
                                                        widthPerDay)
                                                    .floor();
                                          }
                                          newStart = subData.dateStart.add(
                                            Duration(days: newDistanceInDays),
                                          );
                                          newEnd = subData.dateEnd.add(
                                            Duration(days: newDistanceInDays),
                                          );

                                          startDistance.value =
                                              startDistance.value + delta;
                                        },
                                  child: Tooltip(
                                    textAlign: TextAlign.center,
                                    message:
                                        '${subData.label}\n${DateFormat('dd MMM yyyy').format(subData.dateStart)} - ${DateFormat('dd MMM yyyy').format(subData.dateEnd)}',
                                    child: Container(
                                      width: width,
                                      height: widget.heightPerRow -
                                          widget.rowSpacing,
                                      decoration: BoxDecoration(
                                        color: widget.subTaskBarColor,
                                        borderRadius: !isSelected
                                            ? widget.chartBarBorderRadius
                                            : null,
                                        border: Border.all(
                                          color: isSelected
                                              ? widget.activeBorderColor
                                              : Colors.transparent,
                                          width: isSelected
                                              ? widget.activeBorderWidth
                                              : 0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }),

                    // SubDraggable Start Indicator
                    _buildSubDataIndicator(
                      data,
                      index,
                      isSelected: isSelected,
                      isStart: true,
                      subIndex: subIndex,
                      parentDistanceFromStart: startDistance.value,
                      isParentDragging: isDragging,
                      isIndicatorDragging: isIndicatorDragging,
                      barWidth: width,
                    ),

                    // SubDraggable End Indicator
                    _buildSubDataIndicator(
                      data,
                      index,
                      isSelected: isSelected,
                      isStart: false,
                      subIndex: subIndex,
                      parentDistanceFromStart: startDistance.value,
                      isParentDragging: isDragging,
                      isIndicatorDragging: isIndicatorDragging,
                      barWidth: width,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSubDataIndicator(
    GanttData<T, S> data,
    int index, {
    required bool isSelected,
    required bool isStart,
    required double parentDistanceFromStart,
    required ValueNotifier<bool> isParentDragging,
    required ValueNotifier<bool> isIndicatorDragging,
    required int subIndex,
    required double barWidth,
  }) {
    // assert(!isSubTask || subIndex != -1);
    if (!isSelected) return const SizedBox();

    final subData = data.subData[subIndex];

    // Used to make the indicator independent from the parent while only dragging the indicator
    final indicatorDistance = ValueNotifier(parentDistanceFromStart);

    // variable for storing bar current distance from the start
    // Fixed value for calculating the new date while dragging
    final distanceFromStart = indicatorDistance.value;

    // Variable for storing upcoming start and end date while dragging.
    // Only means to used for updating the actual data at the end of the drag
    // to avoid calling setState multiple times
    DateTime newDate = isStart ? subData.dateStart : subData.dateEnd;

    double indicatorLocalPosition = 0.0;

    return ValueListenableBuilder(
      valueListenable: isParentDragging,
      builder: (context, isParentDraggingState, _) {
        if (isParentDraggingState) return const SizedBox.shrink();
        return ValueListenableBuilder(
          valueListenable: indicatorDistance,
          builder: (context, indicatorDistanceValue, _) {
            return Positioned(
              left: isStart
                  ? indicatorDistanceValue - (widget.dragIndicatorWidth)
                  : (isIndicatorDragging.value)
                      ? indicatorDistanceValue - indicatorLocalPosition
                      : indicatorDistanceValue + barWidth,
              child: GestureDetector(
                onHorizontalDragEnd: !isSelected
                    ? null
                    : (details) {
                        setState(() {
                          if (isStart) {
                            data.subData[subIndex] = subData.copyWith(
                              dateStart: newDate,
                            );
                          } else {
                            data.subData[subIndex] = subData.copyWith(
                              dateEnd: newDate,
                            );
                          }

                          data.calculateMainDate();
                        });

                        widget.onDragEnd?.call(
                          data,
                          index,
                          details,
                        );
                      },
                onHorizontalDragUpdate: !isSelected
                    ? null
                    : (details) {
                        isIndicatorDragging.value = true;

                        final delta = details.localPosition.dx;

                        // prevent indicator to be dragged outside the endDate for start indicator and vice versa
                        if (isStart && delta > barWidth - widthPerDay) {
                          return;
                        } else if (!isStart &&
                            delta < -barWidth + widthPerDay) {
                          return;
                        }

                        late int newDistanceInDays;
                        if (delta > 0) {
                          newDistanceInDays =
                              ((indicatorDistanceValue - distanceFromStart) /
                                      widthPerDay)
                                  .ceil();
                        } else {
                          newDistanceInDays =
                              ((indicatorDistanceValue - distanceFromStart) /
                                      widthPerDay)
                                  .floor();
                        }

                        if (isStart) {
                          newDate = subData.dateStart.add(
                            Duration(days: newDistanceInDays),
                          );
                        } else {
                          newDate = subData.dateEnd.add(
                            Duration(days: newDistanceInDays),
                          );
                        }

                        indicatorDistance.value =
                            delta + parentDistanceFromStart;

                        indicatorLocalPosition = details.localPosition.dx;
                      },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Widget for replace the chart bar while dragging the indicator
                    if (isIndicatorDragging.value && !isStart)
                      Container(
                        width: barWidth + indicatorLocalPosition,
                        height: widget.heightPerRow - widget.rowSpacing,
                        decoration: BoxDecoration(
                          color: widget.subTaskBarColor,
                          border: Border.all(
                            color: widget.activeBorderColor,
                            width: widget.activeBorderWidth,
                          ),
                        ),
                      ),

                    _buildIndicator(data, isStart),

                    // Widget for replace the chart bar while dragging the indicator
                    if (isIndicatorDragging.value && isStart)
                      Container(
                        width: barWidth - indicatorLocalPosition,
                        height: widget.heightPerRow - widget.rowSpacing,
                        decoration: BoxDecoration(
                          color: widget.subTaskBarColor,
                          border: Border.all(
                            color: widget.activeBorderColor,
                            width: widget.activeBorderWidth,
                          ),
                        ),
                      ),
                  ],
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

  Widget _buildIndicator(GanttData<T, S> data, bool isStart) {
    if (isStart && widget.draggableStartIndicatorBuilder != null) {
      return widget.draggableStartIndicatorBuilder!(
        widget.heightPerRow,
        widget.rowSpacing,
        data,
      );
    } else if (!isStart && widget.draggableEndIndicatorBuilder != null) {
      return widget.draggableEndIndicatorBuilder!(
        widget.heightPerRow,
        widget.rowSpacing,
        data,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: widget.activeBorderColor,
        borderRadius: isStart
            ? const BorderRadius.only(
                topLeft: Radius.circular(5),
                bottomLeft: Radius.circular(5),
              )
            : const BorderRadius.only(
                topRight: Radius.circular(5),
                bottomRight: Radius.circular(5),
              ),
      ),
      height: widget.heightPerRow - widget.rowSpacing,
      width: widget.dragIndicatorWidth,
      child: const Icon(Icons.drag_indicator, color: Colors.white),
    );
  }
}
