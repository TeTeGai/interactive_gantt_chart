# Interactive Gantt Chart

A Flutter package to create interactive Gantt charts. This package allows you to visualize and interact with Gantt charts, including features like scroll, drag, resize and dynamically update the data.

<img src="https://github.com/riVFerd/interactive_gantt_chart/blob/main/doc/example_chart.png?raw=true" height="400" alt="Gantt Chart Example">

## Features

- Display Data with start and end dates
- Support SubData acts as task inside a project
- Scrollable, draggable and resizable Data
- Dynamic sticky date labels
- Customizable task labels and styles
- Provided with some custom builders

## Usage

To use this package, follow these steps:

1. Add the package to your `pubspec.yaml` file:
    ```yaml
    dependencies:
      interactive_gantt_chart: ^0.1.1
    ```

2. Import the package in your Dart file:
    ```dart
    import 'package:interactive_gantt_chart/interactive_gantt_chart.dart';
    ```

3. Create data model and convert it to GanttData or GanttSubData and initialize the Gantt chart:
    ```dart
    List<GanttData<Task, String>> ganttData = [
      GanttData<Task, String>(
        dateStart: DateTime(2023, 1, 1),
        dateEnd: DateTime(2023, 1, 10),
        data: Task(name: 'Task 1'),
        label: 'Task 1',
        subData: [
          GanttSubData(
            dateStart: DateTime(2023, 1, 2),
            dateEnd: DateTime(2023, 1, 5),
            data: 'Sub Task 1',
            label: 'Sub Task 1',
          ),
        ],
      ),
    ];

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        body: SafeArea(
          child: GanttChart<Task, String>(
            data: ganttData,
            onDragEnd: (data, index, details) {
              ganttData[index] = data;
            },
          ),
        ),
      );
    }
    ```

4. Customize the Gantt chart as needed using the available properties and builders.