class TimeBasedStats {
  final double totalHours;
  final double thisYearHours;
  final double thisMonthHours;
  final double thisWeekHours;
  final double todayHours;
  final int totalFlights;
  final int thisYearFlights;
  final int thisMonthFlights;
  final int thisWeekFlights;
  final int todayFlights;

  const TimeBasedStats({
    required this.totalHours,
    required this.thisYearHours,
    required this.thisMonthHours,
    required this.thisWeekHours,
    required this.todayHours,
    required this.totalFlights,
    required this.thisYearFlights,
    required this.thisMonthFlights,
    required this.thisWeekFlights,
    required this.todayFlights,
  });

  factory TimeBasedStats.empty() {
    return const TimeBasedStats(
      totalHours: 0.0,
      thisYearHours: 0.0,
      thisMonthHours: 0.0,
      thisWeekHours: 0.0,
      todayHours: 0.0,
      totalFlights: 0,
      thisYearFlights: 0,
      thisMonthFlights: 0,
      thisWeekFlights: 0,
      todayFlights: 0,
    );
  }
}
