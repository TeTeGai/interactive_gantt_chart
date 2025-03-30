class GanttData<T, S> {
  DateTime dateStart;
  DateTime dateEnd;
  final T data;
  final String label;

  GanttData({
    required this.dateStart,
    required this.dateEnd,
    required this.data,
    required this.label,
  });

  GanttData<T, S> copyWith({
    DateTime? dateStart,
    DateTime? dateEnd,
    T? data,
    String? label,
  }) {
    return GanttData<T, S>(
      dateStart: dateStart ?? this.dateStart,
      dateEnd: dateEnd ?? this.dateEnd,
      data: data ?? this.data,
      label: label ?? this.label,
    );
  }

  double getBarHeight(double baseHeight) {
    return baseHeight ;
  }

  /// Method to update start & end date based on the subData
  void calculateMainDate() {
    return;
  }

  /// Method to update all subData based on the main date
  /// Intended to be used when dragging the main bar
  void calculateAllDate(DateTime newDateStart, DateTime newDateEnd) {
    dateStart = newDateStart;
    dateEnd = newDateEnd;
  }
}
