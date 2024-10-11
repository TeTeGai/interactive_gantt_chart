import 'package:flutter/material.dart';
import 'package:interactive_gantt_chart/src/gantt_data.dart';
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

  /// Make sure that current date is visible when the widget is first rendered
  final bool onInitScrollToCurrentDate;

  /// Builder for the draggable end date indicator
  final Widget Function(double rowHeight, double rowSpacing, GanttData<T> data)?
      draggableEndIndicatorBuilder;

  /// Builder for the draggable start date indicator
  final Widget Function(double rowHeight, double rowSpacing, GanttData<T> data)?
      draggableStartIndicatorBuilder;

  /// Builder for the task label
  final Widget Function(String textLabel, int index)? taskLabelBuilder;

  final void Function(
      GanttData<T> newData, int index, DragEndDetails dragDetails)? onDragEnd;

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
    this.daysBeforeFirstTask = 3,
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
  });

  @override
  State<GanttChart> createState() => _GanttChartState();
}

class _GanttChartState extends State<GanttChart> {
  final linkedScrollController = LinkedScrollControllerGroup();
  late ScrollController labelScrollController;
  late ScrollController chartScrollController;
  final chartHorizontalScrollController = ScrollController();
  final dateLabel = ValueNotifier(DateTime.now());

  @override
  void initState() {
    labelScrollController = linkedScrollController.addAndGet();
    chartScrollController = linkedScrollController.addAndGet();

    chartHorizontalScrollController.addListener(() {
      final firstStartDate =
          widget.data.fold(DateTime.now(), (previousValue, element) {
        return element.dateStart.isBefore(previousValue)
            ? element.dateStart
            : previousValue;
      });
      final offsetInDays =
          (chartHorizontalScrollController.offset / widget.widthPerDay).round();
      final visibleDate = firstStartDate.add(Duration(days: offsetInDays));
      dateLabel.value = visibleDate;
    });

    // Scroll to the current date
    if (widget.onInitScrollToCurrentDate) {
      Future.delayed(const Duration(seconds: 1), () {
        final firstStartDate =
            widget.data.fold(DateTime.now(), (previousValue, element) {
          return element.dateStart.isBefore(previousValue)
              ? element.dateStart
              : previousValue;
        });
        final offsetInDays = (DateTime.now().difference(firstStartDate).inDays);
        chartHorizontalScrollController
            .jumpTo(offsetInDays * widget.widthPerDay);
      });
    }
    super.initState();
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
    }).subtract(Duration(days: widget.daysBeforeFirstTask));
    final firstEndDate =
        widget.data.fold(DateTime.now(), (previousValue, element) {
      return element.dateEnd.isAfter(previousValue)
          ? element.dateEnd
          : previousValue;
    }).add(Duration(days: widget.daysAfterLastTask));
    final maxChartWidth =
        (firstEndDate.difference(firstStartDate).inDays * widget.widthPerDay);

    final dayLabelHeight = widget.heightPerRow * 0.5;
    final realChartHeight =
        widget.data.length * widget.heightPerRow + dayLabelHeight;

    return LayoutBuilder(builder: (context, constraints) {
      return SizedBox(
        height: constraints.maxHeight,
        width: constraints.maxWidth,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side (Task label Section)
            _buildTaskLabel(),

            // Right side
            Column(
              children: [
                // Date label for Years & month
                _buildYearMonthLabel(constraints),

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
          ],
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
            for (int i = 0; i < maxChartWidth / widget.widthPerDay; i++)
              Positioned(
                left: i * widget.widthPerDay,
                child: Container(
                  height: (realChartHeight),
                  width: 1,
                  color: widget.gridLineColor,
                ),
              ),

            SizedBox(
              width: maxChartWidth,
              child: Column(
                children: [
                  Row(
                    children: [
                      for (int i = 0;
                          i < maxChartWidth / widget.widthPerDay;
                          i++)
                        Container(
                          width: widget.widthPerDay,
                          height: dayLabelHeight,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: widget.gridLineColor),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              firstStartDate
                                  .add(Duration(days: i))
                                  .day
                                  .toString(),
                              style: widget.dayLabelStyle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: chartScrollController,
                      itemCount: widget.data.length,
                      itemBuilder: (context, index) {
                        final data = widget.data[index];
                        final duration =
                            data.dateEnd.difference(data.dateStart);
                        final width = duration.inDays * widget.widthPerDay;
                        final start =
                            data.dateStart.difference(firstStartDate).inDays *
                                widget.widthPerDay;

                        return Stack(
                          children: [
                            // horizontal line for rows
                            for (int i = 0; i < widget.data.length; i++)
                              Positioned(
                                top: i * widget.heightPerRow,
                                child: Container(
                                  height: 1,
                                  width: maxChartWidth,
                                  color: widget.gridLineColor,
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
                                  Container(
                                    width: width,
                                    height:
                                        widget.heightPerRow - widget.rowSpacing,
                                    decoration: BoxDecoration(
                                      color: widget.chartBarColor,
                                      borderRadius: widget.chartBarBorderRadius,
                                    ),
                                    child: Stack(
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
                                            data, index, constraints),

                                        // Draggable End Indicator
                                        _buildDraggableEnd(
                                            data, index, constraints),
                                      ],
                                    ),
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
      GanttData<dynamic> data, int index, BoxConstraints constraints) {
    return Positioned(
      right: 0,
      child: Builder(builder: (context) {
        final newWidth = ValueNotifier(0.0);
        return GestureDetector(
          onHorizontalDragEnd: (details) {
            final newWidth = details.localPosition.dx;
            late DateTime newEnd;
            // check if direction is right or left
            if (details.velocity.pixelsPerSecond.dx < 0) {
              newEnd = data.dateEnd.subtract(
                  Duration(days: (newWidth / widget.widthPerDay).round()));
            } else {
              newEnd = data.dateEnd
                  .add(Duration(days: (newWidth / widget.widthPerDay).round()));
            }
            setState(() {
              widget.data[index] = widget.data[index].copyWith(dateEnd: newEnd);
            });
            if (widget.onDragEnd != null) {
              widget.onDragEnd!(widget.data[index], index, details);
            }
          },
          onHorizontalDragUpdate: (details) {
            newWidth.value = details.localPosition.dx;

            if (widget.scrollWhileDrag) {
              if (details.globalPosition.dx > (constraints.maxWidth) - 50) {
                chartHorizontalScrollController.jumpTo(
                  chartHorizontalScrollController.offset + details.delta.dx,
                );
                newWidth.value +=
                    details.primaryDelta! + widget.widthPerDay - 10;
              } else if (details.globalPosition.dx < 150) {
                chartHorizontalScrollController.jumpTo(
                  chartHorizontalScrollController.offset + details.delta.dx,
                );
                newWidth.value +=
                    details.primaryDelta! - widget.widthPerDay + 10;
              }
            }
          },
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
        );
      }),
    );
  }

  Positioned _buildDraggableStart(
      GanttData<dynamic> data, int index, BoxConstraints constraints) {
    return Positioned(
      left: 0,
      child: Builder(builder: (context) {
        final newWidth = ValueNotifier(0.0);
        return GestureDetector(
          onHorizontalDragEnd: (details) {
            final newWidth = details.localPosition.dx;
            late DateTime newStart;
            // check if direction is right or left
            if (details.velocity.pixelsPerSecond.dx < 0) {
              newStart = data.dateStart.subtract(
                  Duration(days: (newWidth / widget.widthPerDay).round()));
            } else {
              newStart = data.dateStart
                  .add(Duration(days: (newWidth / widget.widthPerDay).round()));
            }
            setState(() {
              widget.data[index] =
                  widget.data[index].copyWith(dateStart: newStart);
            });
            if (widget.onDragEnd != null) {
              widget.onDragEnd!(widget.data[index], index, details);
            }
          },
          onHorizontalDragUpdate: (details) {
            newWidth.value = details.localPosition.dx;

            if (widget.scrollWhileDrag) {
              if (details.globalPosition.dx > (constraints.maxWidth) - 50) {
                chartHorizontalScrollController.jumpTo(
                  chartHorizontalScrollController.offset + details.delta.dx,
                );
                newWidth.value +=
                    details.primaryDelta! + widget.widthPerDay - 10;
              } else if (details.globalPosition.dx < 150) {
                chartHorizontalScrollController.jumpTo(
                  chartHorizontalScrollController.offset + details.delta.dx,
                );
                newWidth.value +=
                    details.primaryDelta! - widget.widthPerDay + 10;
              }
            }
          },
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
        );
      }),
    );
  }

  SizedBox _buildYearMonthLabel(BoxConstraints constraints) {
    return SizedBox(
      height: widget.heightPerRow,
      width: constraints.maxWidth - widget.labelWidth,
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
      return widget.draggableEndIndicatorBuilder!(
          widget.heightPerRow, widget.rowSpacing, widget.data[index]);
    }

    return Container(
      decoration: BoxDecoration(
        color: widget.chartBarColor.withOpacity(0.5),
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
          widget.heightPerRow, widget.rowSpacing, widget.data[index]);
    }

    return Container(
      height: widget.heightPerRow - widget.rowSpacing,
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.5),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(5),
          bottomRight: Radius.circular(5),
        ),
      ),
      child: const Icon(Icons.drag_indicator, color: Colors.white),
    );
  }
}
