/// Wrapper Class to be rendered in the Gantt chart
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
  void updateDate() {
    if (subData.isEmpty) return;
    dateStart = subData.map((e) => e.dateStart).reduce((value, element) => value.isBefore(element) ? value : element);
    dateEnd = subData.map((e) => e.dateEnd).reduce((value, element) => value.isAfter(element) ? value : element);
  }
}

/// Wrapper Class to be placed inside GanttData
/// This class is used to represent a subtask
class GanttSubData<T> {
  final DateTime dateStart;
  final DateTime dateEnd;
  final T data;
  final String label;

  GanttSubData({
    required this.dateStart,
    required this.dateEnd,
    required this.data,
    required this.label,
  });

  GanttSubData<T> copyWith<T>({
    DateTime? dateStart,
    DateTime? dateEnd,
    T? data,
    String? label,
  }) {
    return GanttSubData<T>(
      dateStart: dateStart ?? this.dateStart,
      dateEnd: dateEnd ?? this.dateEnd,
      data: data ?? this.data as T,
      label: label ?? this.label,
    );
  }
}
