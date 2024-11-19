/// Wrapper Class to be rendered in the Gantt chart
/// [T] is for the main data type
/// [S] is for the sub data type
class GanttData<T, S> {
  DateTime dateStart;
  DateTime dateEnd;
  final T data;
  final String label;
  List<GanttSubData<S>> subData;

  GanttData({
    required this.dateStart,
    required this.dateEnd,
    required this.data,
    required this.label,
    required this.subData,
  });

  GanttData<T, S> copyWith({
    DateTime? dateStart,
    DateTime? dateEnd,
    T? data,
    String? label,
    List<GanttSubData<S>>? subData,
  }) {
    return GanttData<T, S>(
      dateStart: dateStart ?? this.dateStart,
      dateEnd: dateEnd ?? this.dateEnd,
      data: data ?? this.data,
      label: label ?? this.label,
      subData: subData ?? this.subData,
    );
  }

  double getBarHeight(double baseHeight) {
    return baseHeight * (subData.length + 1);
  }

  /// Method to update start & end date based on the subData
  void calculateMainDate() {
    if (subData.isEmpty) return;
    dateStart = subData
        .map((e) => e.dateStart)
        .reduce((value, element) => value.isBefore(element) ? value : element);
    dateEnd = subData
        .map((e) => e.dateEnd)
        .reduce((value, element) => value.isAfter(element) ? value : element);
  }

  /// Method to update all subData based on the main date
  /// Intended to be used when dragging the main bar
  void calculateAllDate(DateTime newDateStart, DateTime newDateEnd) {
    final diff = newDateStart.difference(dateStart);
    dateStart = newDateStart;
    dateEnd = newDateEnd;
    for (GanttSubData<S> element in subData) {
      element.dateStart = element.dateStart.add(diff);
      element.dateEnd = element.dateEnd.add(diff);
    }
  }
}

/// Wrapper Class to be placed inside GanttData
/// This class is used to represent a subtask
class GanttSubData<T> {
  DateTime dateStart;
  DateTime dateEnd;
  final T data;
  final String label;
  final String id; // Unique identifier for each GanttSubData
  final List<String> dependencies; // List of IDs of dependent GanttSubData

  GanttSubData({
    required this.dateStart,
    required this.dateEnd,
    required this.data,
    required this.label,
    required this.id,
    this.dependencies = const [],
  });

  List<GanttSubData<T>> getDependencies(List<GanttSubData<T>> subData) {
    return subData.where((element) {
      if (element.id == id) return false;
      return dependencies.contains(element.id);
    }).toList();
  }

  /// Method to get current SubData index counted from the entire List<GanttData> (including other Data subData)
  int getIndexFromEntireData(List<GanttData> entireData) {
    int index = 0;
    for (GanttData data in entireData) {
      index++;
      for (GanttSubData subData in data.subData) {
        if (subData.id == id) return index;
        index++;
      }
    }
    return index;
  }

  GanttSubData<T> copyWith({
    DateTime? dateStart,
    DateTime? dateEnd,
    T? data,
    String? label,
    String? id,
    List<String>? dependencies,
  }) {
    return GanttSubData<T>(
      dateStart: dateStart ?? this.dateStart,
      dateEnd: dateEnd ?? this.dateEnd,
      data: data ?? this.data,
      label: label ?? this.label,
      id: id ?? this.id,
      dependencies: dependencies ?? this.dependencies,
    );
  }

  static int getUniqueIndex(int parentIndex, int subIndex) {
    return int.parse('${parentIndex + 1}0${subIndex + 1}');
  }
}
