bool isTargetInRange(DateTime target, DateTime origin, {int rangeInDays = 1}) {
  return target.isAfter(origin.subtract(Duration(days: rangeInDays))) &&
      target.isBefore(origin.add(Duration(days: rangeInDays)));
}