import 'package:flutter/material.dart';
import 'package:interactive_gantt_chart/src/gantt_data.dart';
import 'package:intl/intl.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

class GanttChart<T> extends StatefulWidget {
  final List<GanttData<T>> data;

  const GanttChart({super.key, required this.data});

  @override
  State<GanttChart> createState() => _GanttChartState();
}

class _GanttChartState extends State<GanttChart> {
  final linkedScrollController = LinkedScrollControllerGroup();
  late ScrollController labelScrollController;
  late ScrollController chartScrollController;
  final chartHorizontalScrollController = ScrollController();
  final widthPerDay = 50.0;
  final heightPerRow = 50.0;
  final labelWidth = 100.0;
  final rowSpacing = 15.0;
  final gridLineColor = Colors.grey[300];
  final headerLabelStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );
  // for displaying years and months
  final dateLabel = ValueNotifier(DateTime.now());

  @override
  void initState() {
    labelScrollController = linkedScrollController.addAndGet();
    chartScrollController = linkedScrollController.addAndGet();

    chartHorizontalScrollController.addListener(() {
      final firstStartDate = widget.data.fold(DateTime.now(), (previousValue, element) {
        return element.dateStart.isBefore(previousValue) ? element.dateStart : previousValue;
      });
      final offsetInDays = (chartHorizontalScrollController.offset / widthPerDay).round();
      final visibleDate = firstStartDate.add(Duration(days: offsetInDays));
      dateLabel.value = visibleDate;
    });
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
    final firstStartDate = widget.data.fold(DateTime.now(), (previousValue, element) {
      return element.dateStart.isBefore(previousValue) ? element.dateStart : previousValue;
    });
    final firstEndDate = widget.data.fold(DateTime.now(), (previousValue, element) {
      return element.dateEnd.isAfter(previousValue) ? element.dateEnd : previousValue;
    }).add(const Duration(days: 5));
    final maxChartWidth = (firstEndDate.difference(firstStartDate).inDays * widthPerDay);

    return LayoutBuilder(builder: (context, constraints) {
      return SizedBox(
        height: constraints.maxHeight,
        width: constraints.maxWidth,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side (Task label Section)
            SizedBox(
              width: labelWidth,
              child: Column(
                children: [
                  SizedBox(
                    height: heightPerRow * 1.5,
                    child: Center(
                      child: Text('Task', style: headerLabelStyle),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: labelScrollController,
                      itemCount: widget.data.length,
                      itemBuilder: (context, index) {
                        final data = widget.data[index];
                        return SizedBox(
                          height: heightPerRow,
                          child: Center(
                            child: Text(data.label),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Right side
            SizedBox(
              child: Column(
                children: [
                  // Date label for Years & month
                  SizedBox(
                    height: heightPerRow,
                    width: constraints.maxWidth - labelWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ValueListenableBuilder(
                          valueListenable: dateLabel,
                          builder: (_, value, __) {
                            return Text(
                              '${value.year}',
                              style: headerLabelStyle,
                            );
                          },
                        ),
                        ValueListenableBuilder(
                          valueListenable: dateLabel,
                          builder: (_, value, __) {
                            return Text(
                              DateFormat.MMMM().format(dateLabel.value),
                              style: headerLabelStyle,
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Draw all gant chart here
                  SizedBox(
                    width: constraints.maxWidth - labelWidth,
                    height: constraints.maxHeight - heightPerRow,
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
                                height: heightPerRow * widget.data.length,
                                width: 1,
                                color: gridLineColor,
                              ),
                            ),

                          SizedBox(
                            width: maxChartWidth,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    for (int i = 0; i < maxChartWidth / widthPerDay; i++)
                                      SizedBox(
                                        width: widthPerDay,
                                        height: heightPerRow * 0.5,
                                        child: Center(
                                          child: Text(
                                            firstStartDate.add(Duration(days: i)).day.toString(),
                                            style: headerLabelStyle,
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
                                      final duration = data.dateEnd.difference(data.dateStart);
                                      final width = duration.inDays * widthPerDay;
                                      final start = data.dateStart.difference(firstStartDate).inDays * widthPerDay;

                                      return Stack(
                                        children: [
                                          // horizontal line for rows
                                          for (int i = 0; i < widget.data.length; i++)
                                            Positioned(
                                              top: i * heightPerRow,
                                              child: Container(
                                                height: 1,
                                                width: maxChartWidth,
                                                color: gridLineColor,
                                              ),
                                            ),

                                          // Main Data rendering
                                          SizedBox(
                                            height: heightPerRow,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: start,
                                                ),
                                                Container(
                                                  width: width,
                                                  height: heightPerRow - rowSpacing,
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue,
                                                    borderRadius: BorderRadius.circular(5),
                                                  ),
                                                  child: Stack(
                                                    alignment: Alignment.center,
                                                    children: [
                                                      Center(
                                                        child: Text(data.label),
                                                      ),
                                                      Positioned(
                                                        right: 0,
                                                        child: Builder(builder: (context) {
                                                          final newWidth = ValueNotifier(0.0);
                                                          return GestureDetector(
                                                            onHorizontalDragEnd: (details) {
                                                              final newWidth = details.localPosition.dx;
                                                              late DateTime newEnd;
                                                              // check if direction is right or left
                                                              if (details.velocity.pixelsPerSecond.dx < 0) {
                                                                newEnd = data.dateEnd
                                                                    .subtract(Duration(days: (newWidth / widthPerDay).round()));
                                                              } else {
                                                                newEnd = data.dateEnd
                                                                    .add(Duration(days: (newWidth / widthPerDay).round()));
                                                              }
                                                              setState(() {
                                                                widget.data[index] = widget.data[index].copyWith(dateEnd: newEnd);
                                                              });
                                                            },
                                                            onHorizontalDragUpdate: (details) =>
                                                                newWidth.value = details.localPosition.dx,
                                                            child: Stack(
                                                              clipBehavior: Clip.none,
                                                              children: [
                                                                ValueListenableBuilder(
                                                                  valueListenable: newWidth,
                                                                  builder: (_, value, __) {
                                                                    return Positioned(
                                                                      left: value,
                                                                      child: Container(
                                                                        width: 14,
                                                                        height: heightPerRow - rowSpacing,
                                                                        decoration: BoxDecoration(
                                                                          color: Colors.red.withOpacity(0.5),
                                                                          borderRadius: const BorderRadius.only(
                                                                            topRight: Radius.circular(5),
                                                                            bottomRight: Radius.circular(5),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    );
                                                                  },
                                                                ),
                                                                Container(
                                                                  height: heightPerRow - rowSpacing,
                                                                  width: 14,
                                                                  decoration: const BoxDecoration(
                                                                    color: Colors.red,
                                                                    borderRadius: BorderRadius.only(
                                                                      topRight: Radius.circular(5),
                                                                      bottomRight: Radius.circular(5),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        }),
                                                      ),
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
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
