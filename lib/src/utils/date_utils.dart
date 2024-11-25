/// To check if a target date is in range of A or B
bool isTargetInRangeOfTwoOrigin(
    DateTime target, DateTime originA, DateTime originB,
    {int rangeInDays = 1}) {
  return target.isAfter(
            originA.subtract(Duration(days: rangeInDays)),
          ) &&
          target.isBefore(
            originA.add(Duration(days: rangeInDays)),
          ) ||
      target.isAfter(
            originB.subtract(Duration(days: rangeInDays)),
          ) &&
          target.isBefore(
            originB.add(Duration(days: rangeInDays)),
          );
}
