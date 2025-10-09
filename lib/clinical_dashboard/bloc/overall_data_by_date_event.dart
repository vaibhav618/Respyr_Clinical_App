abstract class OverallDataByDateEvent {}

class FetchHealthScoreData extends OverallDataByDateEvent {
  final String loginId;
  final String date;

  FetchHealthScoreData({
    required this.loginId,
    required this.date
  });
}
