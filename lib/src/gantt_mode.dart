enum GanttMode {
  daily('Daily'),
  weekly('Weekly'),
  monthly('Monthly'),
  ;

  final String name;
  const GanttMode(this.name);
}
