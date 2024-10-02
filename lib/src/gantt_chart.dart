import 'dart:math';

import 'package:flutter/material.dart';
import 'package:interactive_gantt_chart/src/gantt_data.dart';
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
  final widthPerDay = 25.0;
  final heightPerRow = 50.0;
  final labelWidth = 100.0;
  final rowSpacing = 15.0;
  final gridLineColor = Colors.grey[300];
  final headerLabelStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  @override
  void initState() {
    labelScrollController = linkedScrollController.addAndGet();
    chartScrollController = linkedScrollController.addAndGet();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final firstStartDate = widget.data.fold(DateTime.now(), (previousValue, element) {
      return element.dateStart.isBefore(previousValue) ? element.dateStart : previousValue;
    });
    final firstEndDate = widget.data.fold(DateTime.now(), (previousValue, element) {
      return element.dateEnd.isAfter(previousValue) ? element.dateEnd : previousValue;
    });
    final maxChartWidth = (firstEndDate.difference(firstStartDate).inDays * widthPerDay);

    return LayoutBuilder(builder: (context, constraints) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          SizedBox(
            width: constraints.maxWidth - labelWidth,
            height: widget.data.length * (heightPerRow + rowSpacing),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
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
                        Builder(builder: (context) {
                          DateTime dateLabel = firstStartDate;
                          return Row(
                            children: [
                              for (int i = 0; i < maxChartWidth / widthPerDay; i++)
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Builder(builder: (context) {
                                      final currentDate = firstStartDate.add(Duration(days: i));
                                      if (currentDate.month != dateLabel.month) {
                                        dateLabel = currentDate;
                                        return SizedBox(
                                          width: widthPerDay,
                                          height: heightPerRow,
                                          child: Center(
                                            child: Text(
                                              '${currentDate.year}\n${currentDate.month}',
                                              style: headerLabelStyle,
                                            ),
                                          ),
                                        );
                                      }
                                      return Container(
                                        height: heightPerRow,
                                      );
                                    }),
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
                            ],
                          );
                        }),
                        Expanded(
                          child: ListView.builder(
                            controller: chartScrollController,
                            itemCount: widget.data.length,
                            itemBuilder: (context, index) {
                              final data = widget.data[index];
                              final duration = data.dateEnd.difference(data.dateStart);
                              final width = duration.inDays * widthPerDay;
                              final start = data.dateStart.difference(DateTime.now()).inDays * widthPerDay;

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
                                                        newEnd =
                                                            data.dateEnd.add(Duration(days: (newWidth / widthPerDay).round()));
                                                      }
                                                      setState(() {
                                                        widget.data[index] = widget.data[index].copyWith(dateEnd: newEnd);
                                                      });
                                                    },
                                                    onHorizontalDragUpdate: (details) {
                                                      print(details.localPosition.dx);
                                                      newWidth.value = details.localPosition.dx;
                                                    },
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
      );
    });
  }
}
