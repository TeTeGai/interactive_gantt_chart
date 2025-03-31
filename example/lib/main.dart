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
      debugShowCheckedModeBanner: false,
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
    );
  }).toList();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GanttChart<Task, String>(
                    connectorColor: Colors.deepPurple,
                    gridLineColor: Colors.grey,
                    tableOuterColor: Colors.grey,
                    initialLabelWidth: 250,
                    heightPerRow: 90,
                    dayLabelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    taskLabelBuilder: (textLabel, index) {
                      return Container(
                        alignment: Alignment.center,
                        width: 70,
                        child: Row(
                          children: [
                            Text(textLabel.name),
                            Text(textLabel.name)
                            ,Text(textLabel.name)
                          ],
                        ),
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
