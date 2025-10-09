import '../model/test_log_model.dart';

abstract class TestLogEvent {}

class FetchTestLogs extends TestLogEvent {
  final String loginId;
  FetchTestLogs(this.loginId);
}

class FilterTestLogs extends TestLogEvent {
  final String query;
  FilterTestLogs(this.query);
}



abstract class TestLogState {}

class TestLogInitial extends TestLogState {}

class TestLogLoading extends TestLogState {}

class TestLogLoaded extends TestLogState {
  final List<TestLogModel> fullList;
  final List<TestLogModel> filteredList;
  TestLogLoaded(this.fullList, this.filteredList);
}

class TestLogError extends TestLogState {
  final String message;
  TestLogError(this.message);
}
