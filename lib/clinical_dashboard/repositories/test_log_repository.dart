import '../model/test_log_model.dart';

abstract class TestLogEvent {}

class FetchTestLogs extends TestLogEvent {
  final String loginId;
  FetchTestLogs(this.loginId);
}

/// Append the next page of the test log to what's already shown.
class LoadMoreTestLogs extends TestLogEvent {}

/// Server-side search — reloads page 1 filtered by [query].
class FilterTestLogs extends TestLogEvent {
  final String query;
  FilterTestLogs(this.query);
}

abstract class TestLogState {}

class TestLogInitial extends TestLogState {}

class TestLogLoading extends TestLogState {}

class TestLogLoaded extends TestLogState {
  final List<TestLogModel> logs;
  final bool hasMore;
  final bool isLoadingMore;

  TestLogLoaded(this.logs, {this.hasMore = false, this.isLoadingMore = false});
}

class TestLogError extends TestLogState {
  final String message;
  TestLogError(this.message);
}
