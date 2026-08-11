class RecurrenceHelper {
  RecurrenceHelper._();

  static DateTime calculateNextDueDate(String frequency, [DateTime? from]) {
    final base = from ?? DateTime.now();
    switch (frequency) {
      case 'weekly':
        return base.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(base.year, base.month + 1, base.day);
      default:
        return base;
    }
  }

  static bool isDue(DateTime? nextDueDate) {
    if (nextDueDate == null) return false;
    return DateTime.now().isAfter(nextDueDate);
  }
}
