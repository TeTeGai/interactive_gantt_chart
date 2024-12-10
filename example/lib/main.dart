import 'package:flutter/material.dart';
import 'package:interactive_gantt_chart/interactive_gantt_chart.dart';

import 'dummy_data.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<GanttData<Task, String>> ganttData = DummyData.data.map((task) {
    return GanttData<Task, String>(
      dateStart: task.start,
      dateEnd: task.end,
      data: task,
      label: task.name,
      subData: [
        GanttSubData(
          id: GanttSubData.generateId(),
          dateStart: task.start.add(const Duration(days: 1)),
          dateEnd: task.end,
          data: 'Sub ${task.name}',
          label: 'Sub ${task.name} 1',
        ),
        GanttSubData(
          id: GanttSubData.generateId(),
          dateStart: task.start.add(const Duration(days: 1)),
          dateEnd: task.end,
          data: 'Sub ${task.name}',
          label: 'Sub ${task.name} 2',
        ),
      ],
    );
  }).toList();

  @override
  void initState() {
    final firstData = ganttData.first;
    firstData.subData.add(
      GanttSubData<String>(
        id: GanttSubData.generateId(),
        dateStart: ganttData[0].data.start,
        dateEnd: ganttData[0].data.end,
        data: ganttData[0].label,
        label: ganttData[0].data.name,
      ),
    );
    // firstData.subData[1].addDependency(firstData.subData[0].id);
    // firstData.subData[2].addDependency(firstData.subData[0].id);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              const Text('Hello, Gantt!'),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GanttChart<Task, String>(
                    connectorColor: Colors.deepPurple,
                    gridLineColor: Colors.grey.withOpacity(0.5),
                    tableOuterColor: Colors.grey.withOpacity(0.8),
                    dayLabelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    taskLabelBuilder: (textLabel, index) {
                      return Container(
                        alignment: Alignment.center,
                        child: Text(textLabel),
                      );
                    },
                    onInitScrollToCurrentDate: true,
                    data: ganttData,
                    onDragEnd: (data, index, _) {
                      ganttData[index] = data;
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
