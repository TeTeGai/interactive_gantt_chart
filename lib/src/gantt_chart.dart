import 'package:flutter/material.dart';
import 'package:interactive_gantt_chart/src/gantt_data.dart';
import 'package:interactive_gantt_chart/src/gantt_mode.dart';
import 'package:intl/intl.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

class GanttChart<T> extends StatefulWidget {
  /// List of data to be rendered in the Gantt chart
  final List<GanttData<T>> data;

  /// Width of each day in the chart
  final double widthPerDay;

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
  final BorderRadiusGeometry chartBarBorderRadius;
  final Color activeBorderColor;
  final double activeBorderWidth;

  /// Make sure that current date is visible when the widget is first rendered
  final bool onInitScrollToCurrentDate;

  /// Builder for the draggable end date indicator
  final Widget Function(double rowHeight, double rowSpacing, GanttData<T> data)? draggableEndIndicatorBuilder;

  /// Builder for the draggable start date indicator
  final Widget Function(double rowHeight, double rowSpacing, GanttData<T> data)? draggableStartIndicatorBuilder;

  /// Builder for the task label
  final Widget Function(String textLabel, int index)? taskLabelBuilder;

  final void Function(GanttData<T> newData, int index, DragEndDetails dragDetails)? onDragEnd;

  /// Set weather the chart should scroll while dragging the draggable indicator on the edge of the screen
  /// Still buggy
  final bool scrollWhileDrag;

  final Color tableOuterColor;

  const GanttChart({
    super.key,
    required this.data,
    this.tableOuterColor = Colors.black,
    this.widthPerDay = 50.0,
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
    this.onDragEnd,
    this.labelText = 'Task',
    this.showLabelOnChartBar = true,
    this.chartBarColor = Colors.blue,
    this.chartBarBorderRadius = const BorderRadius.all(Radius.circular(5)),
    this.scrollWhileDrag = false,
    this.taskLabelBuilder,
    this.onInitScrollToCurrentDate = false,
    this.activeBorderColor = Colors.red,
    this.activeBorderWidth = 2,
  });

  @override
  State<GanttChart> createState() => _GanttChartState<T>();
}

class _GanttChartState<T> extends State<GanttChart<T>> {
  final linkedScrollController = LinkedScrollControllerGroup();
  late ScrollController labelScrollController;
  late ScrollController chartScrollController;
  final chartHorizontalScrollController = ScrollController();
  final dateLabel = ValueNotifier(DateTime.now());
  final selectedTaskIndex = ValueNotifier<int>(0);
  double widthPerDay = 50.0;
  GanttMode ganttMode = GanttMode.daily;

  @override
  void initState() {
    labelScrollController = linkedScrollController.addAndGet();
    chartScrollController = linkedScrollController.addAndGet();

    chartHorizontalScrollController.addListener(() {
      final firstStartDate = widget.data.fold(
        DateTime.now(),
        (previousValue, element) {
          return element.dateStart.isBefore(previousValue) ? element.dateStart : previousValue;
        },
      ).subtract(
        Duration(days: widget.daysBeforeFirstTask),
      );
      final offsetInDays = (chartHorizontalScrollController.offset / widthPerDay).round();
      final visibleDate = firstStartDate.add(Duration(days: offsetInDays));
      dateLabel.value = visibleDate;
    });

    // Scroll to the current date
    if (widget.onInitScrollToCurrentDate) {
      Future.delayed(const Duration(seconds: 1), () {
        final firstStartDate = widget.data.fold(
          DateTime.now(),
          (previousValue, element) {
            return element.dateStart.isBefore(previousValue) ? element.dateStart : previousValue;
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
      GanttMode.daily => 50.0,
      GanttMode.weekly => 25.0,
      GanttMode.monthly => 5.0,
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
    final firstStartDate = widget.data.fold(DateTime.now(), (previousValue, element) {
      return element.dateStart.isBefore(previousValue) ? element.dateStart : previousValue;
    }).subtract(
      Duration(days: widget.daysBeforeFirstTask),
    );
    final firstEndDate = widget.data.fold(DateTime.now(), (previousValue, element) {
      return element.dateEnd.isAfter(previousValue) ? element.dateEnd : previousValue;
    }).add(Duration(days: widget.daysAfterLastTask));
    final maxChartWidth = (firstEndDate.difference(firstStartDate).inDays * widthPerDay);

    final dayLabelHeight = widget.heightPerRow * 0.5;
    final realChartHeight = widget.data.length * widget.heightPerRow + dayLabelHeight;

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
                              onChanged: (value) => {if (value != null) changeGanttMode(value)},
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
            child: ListView.builder(
              controller: labelScrollController,
              itemCount: widget.data.length,
              itemBuilder: (context, index) {
                final data = widget.data[index];

                if (widget.taskLabelBuilder != null) {
                  return SizedBox(
                    height: widget.heightPerRow,
                    child: widget.taskLabelBuilder!(data.label, index),
                  );
                }

                return SizedBox(
                  height: widget.heightPerRow,
                  child: Center(
                    child: Text(data.label),
                  ),
                );
              },
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
    List<Positioned> verticalGuideLines = []; // additional vertical lines for week or month

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
        daysLeftInMonth = DateTime(currentDate.year, currentDate.month + 1, 0).day - currentDate.day + 1;
      }

      // Ensure it doesn't go beyond the chart width
      int daysToShow = ganttMode == GanttMode.weekly
          ? (i + daysLeftInWeek > maxChartWidth / widthPerDay) // If last week has fewer days
          ? (maxChartWidth / widthPerDay - i).toInt() // Only show remaining days
          : daysLeftInWeek
          : ganttMode == GanttMode.monthly
          ? (i + daysLeftInMonth > maxChartWidth / widthPerDay) // If last month has fewer days
          ? (maxChartWidth / widthPerDay - i).toInt() // Only show remaining days
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
        labelText = 'Week of ${currentDate.day} ${DateFormat('MMM').format(currentDate)}';
        labelWidth = widthPerDay * daysToShow; // Dynamically calculate the label width
      } else if (ganttMode == GanttMode.monthly && isStartOfMonth) {
        // Show month label (e.g., 'Jan 2022') and calculate the dynamic width
        labelText = '${DateFormat('MMM').format(currentDate)} ${currentDate.year}';
        labelWidth = widthPerDay * daysToShow; // Dynamically calculate the label width
      }

      // Add the label widget to the list
      labelWidgets.add(
        Container(
          width: labelWidth,
          height: dayLabelHeight,
          decoration: BoxDecoration(
            color: widget.chartBarColor,
            border: Border(
              right: (ganttMode != GanttMode.daily) ? BorderSide(color: widget.tableOuterColor) : BorderSide.none,
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
                  color: (ganttMode == GanttMode.daily) ? widget.gridLineColor : widget.gridLineColor.withOpacity(0.5),
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
                        final duration = data.dateEnd.difference(data.dateStart);
                        final width = duration.inDays * widthPerDay;
                        final start = data.dateStart.difference(firstStartDate).inDays * widthPerDay;

                        return Stack(
                          children: [
                            // horizontal line for rows
                            for (int i = 0; i < widget.data.length; i++)
                              Positioned(
                                top: i * widget.heightPerRow,
                                child: Container(
                                  height: 1,
                                  width: maxChartWidth,
                                  color: (ganttMode == GanttMode.daily) ? widget.gridLineColor : widget.gridLineColor.withOpacity(0.5),
                                ),
                              ),

                            // Main Data rendering
                            SizedBox(
                              height: widget.heightPerRow,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: start,
                                  ),
                                  ValueListenableBuilder(
                                    valueListenable: selectedTaskIndex,
                                    builder: (context, selectedIndex, _) {
                                      final isSelected = selectedIndex == index;
                                      return GestureDetector(
                                        onTap: () => selectedTaskIndex.value = index,
                                        onHorizontalDragEnd: !isSelected
                                            ? null
                                            : (details) {
                                                widget.onDragEnd?.call(
                                                  widget.data[index],
                                                  index,
                                                  details,
                                                );
                                              },
                                        onHorizontalDragUpdate: !isSelected
                                            ? null
                                            : (details) {
                                                // move entire bar
                                                final delta = details.delta.dx / 2; //slow down the drag
                                                final deltaDays = ((delta / widget.widthPerDay) * 24).round();
                                                final newStart = data.dateStart.add(
                                                  Duration(days: deltaDays),
                                                );
                                                final newEnd = data.dateEnd.add(
                                                  Duration(days: deltaDays),
                                                );
                                                setState(
                                                  () {
                                                    widget.data[index] = widget.data[index].copyWith(
                                                      dateStart: newStart,
                                                      dateEnd: newEnd,
                                                    );
                                                  },
                                                );

                                                // scroll while dragging
                                                if (widget.scrollWhileDrag) {
                                                  // TODO: Implement scroll while dragging
                                                }
                                              },
                                        child: Tooltip(
                                          message:
                                              '${DateFormat('dd MMM yyyy').format(data.dateStart)} - ${DateFormat('dd MMM yyyy').format(data.dateEnd)}',
                                          child: Container(
                                            width: width,
                                            height: widget.heightPerRow - widget.rowSpacing,
                                            decoration: BoxDecoration(
                                              color: widget.chartBarColor,
                                              borderRadius: widget.chartBarBorderRadius,
                                              border: Border.all(
                                                color: isSelected ? widget.activeBorderColor : Colors.transparent,
                                                width: isSelected ? widget.activeBorderWidth : 0,
                                              ),
                                            ),
                                            child: Stack(
                                              clipBehavior: Clip.none,
                                              alignment: Alignment.center,
                                              children: [
                                                Visibility(
                                                  visible: widget.showLabelOnChartBar,
                                                  child: Center(
                                                    child: Text(data.label),
                                                  ),
                                                ),

                                                // Draggable Start Indicator
                                                _buildDraggableStart(
                                                  data,
                                                  index,
                                                  constraints,
                                                  isSelected,
                                                ),

                                                // Draggable End Indicator
                                                _buildDraggableEnd(
                                                  data,
                                                  index,
                                                  constraints,
                                                  isSelected,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
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

  Positioned _buildDraggableEnd(
    GanttData<dynamic> data,
    int index,
    BoxConstraints constraints,
    bool isSelected,
  ) {
    return Positioned(
      right: 0,
      child: Builder(builder: (context) {
        final newWidth = ValueNotifier(0.0);
        return GestureDetector(
          onHorizontalDragEnd: !isSelected
              ? null
              : (details) {
                  final newWidth = details.localPosition.dx;
                  late DateTime newEnd;
                  // check if direction is right or left
                  if (details.velocity.pixelsPerSecond.dx < 0) {
                    newEnd = data.dateEnd.subtract(
                      Duration(days: (newWidth / widthPerDay).round()),
                    );
                  } else {
                    newEnd = data.dateEnd.add(
                      Duration(days: (newWidth / widthPerDay).round()),
                    );
                  }
                  setState(() {
                    widget.data[index] = widget.data[index].copyWith(dateEnd: newEnd);
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
                  newWidth.value = details.localPosition.dx;

                  if (widget.scrollWhileDrag) {
                    if (details.globalPosition.dx > (constraints.maxWidth) - 50) {
                      chartHorizontalScrollController.jumpTo(
                        chartHorizontalScrollController.offset + details.delta.dx,
                      );
                      newWidth.value += details.primaryDelta! + widthPerDay - 10;
                    } else if (details.globalPosition.dx < 150) {
                      chartHorizontalScrollController.jumpTo(
                        chartHorizontalScrollController.offset + details.delta.dx,
                      );
                      newWidth.value += details.primaryDelta! - widthPerDay + 10;
                    }
                  }
                },
          child: Visibility(
            visible: isSelected,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Visual indicator for the draggableEnd indicator
                ValueListenableBuilder(
                  valueListenable: newWidth,
                  builder: (_, value, __) {
                    return Positioned(
                      left: value,
                      child: _buildDraggableEndIndicator(index),
                    );
                  },
                ),
                _buildDraggableEndIndicator(index),
              ],
            ),
          ),
        );
      }),
    );
  }

  Positioned _buildDraggableStart(
    GanttData<dynamic> data,
    int index,
    BoxConstraints constraints,
    bool isSelected,
  ) {
    return Positioned(
      left: 0,
      child: Builder(builder: (context) {
        final newWidth = ValueNotifier(0.0);
        return GestureDetector(
          onHorizontalDragEnd: !isSelected
              ? null
              : (details) {
                  final newWidth = details.localPosition.dx;
                  late DateTime newStart;
                  // check if direction is right or left
                  if (details.velocity.pixelsPerSecond.dx < 0) {
                    newStart = data.dateStart.subtract(
                      Duration(days: (newWidth / widthPerDay).round()),
                    );
                  } else {
                    newStart = data.dateStart.add(
                      Duration(days: (newWidth / widthPerDay).round()),
                    );
                  }
                  setState(() {
                    widget.data[index] = widget.data[index].copyWith(dateStart: newStart);
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
                  newWidth.value = details.localPosition.dx;

                  if (widget.scrollWhileDrag) {
                    if (details.globalPosition.dx > (constraints.maxWidth) - 50) {
                      chartHorizontalScrollController.jumpTo(
                        chartHorizontalScrollController.offset + details.delta.dx,
                      );
                      newWidth.value += details.primaryDelta! + widthPerDay - 10;
                    } else if (details.globalPosition.dx < 150) {
                      chartHorizontalScrollController.jumpTo(
                        chartHorizontalScrollController.offset + details.delta.dx,
                      );
                      newWidth.value += details.primaryDelta! - widthPerDay + 10;
                    }
                  }
                },
          child: Visibility(
            visible: isSelected,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Visual indicator for the draggableEnd indicator
                ValueListenableBuilder(
                  valueListenable: newWidth,
                  builder: (_, value, __) {
                    return Positioned(
                      left: value,
                      child: _buildDraggableStartIndicator(index),
                    );
                  },
                ),
                _buildDraggableStartIndicator(index),
              ],
            ),
          ),
        );
      }),
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

  Widget _buildDraggableStartIndicator(int index) {
    if (widget.draggableEndIndicatorBuilder != null) {
      return widget.draggableEndIndicatorBuilder!(widget.heightPerRow, widget.rowSpacing, widget.data[index]);
    }

    return Container(
      decoration: BoxDecoration(
        color: widget.activeBorderColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(5),
          bottomLeft: Radius.circular(5),
        ),
      ),
      height: widget.heightPerRow - widget.rowSpacing,
      child: const Icon(Icons.drag_indicator, color: Colors.white),
    );
  }

  Widget _buildDraggableEndIndicator(int index) {
    if (widget.draggableEndIndicatorBuilder != null) {
      return widget.draggableEndIndicatorBuilder!(
        widget.heightPerRow,
        widget.rowSpacing,
        widget.data[index],
      );
    }

    return Container(
      height: widget.heightPerRow - widget.rowSpacing,
      decoration: BoxDecoration(
        color: widget.activeBorderColor,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(5),
          bottomRight: Radius.circular(5),
        ),
      ),
      child: const Icon(Icons.drag_indicator, color: Colors.white),
    );
  }
}
