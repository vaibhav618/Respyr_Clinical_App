import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../log_manager/log_manager.dart';
import '../model/test_log_model.dart';
import '../repositories/test_log_repository.dart';
import 'package:respyr_clinical/shared/urls.dart';
import 'package:http/http.dart' as http;

class TestLogBloc extends Bloc<TestLogEvent, TestLogState> {
  TestLogBloc() : super(TestLogInitial()) {
    on<FetchTestLogs>(_onFetch);
    on<FilterTestLogs>(_onFilter);
  }

  List<TestLogModel> _fullList = [];

  Future<void> _onFetch(FetchTestLogs event, Emitter<TestLogState> emit) async {
    emit(TestLogLoading());

    // Log fetch attempt
    LogManager().logEvent(
      event: 'FETCH_TEST_LOGS_ATTEMPT',
      apiUrl: '${Urls.fetchTestLog}login_id=${event.loginId}',
      status: 'ATTEMPT',
      details: 'Attempting to fetch test logs for ${event.loginId}',
    );

    try {
      final uri = Uri.parse('${Urls.fetchTestLog}login_id=${event.loginId}');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        final data = responseBody['data'] as List;
        _fullList = data.map((e) => TestLogModel.fromJson(e)).toList();
        emit(TestLogLoaded(_fullList, List.from(_fullList)));

        // Log fetch success
        LogManager().logEvent(
          event: 'FETCH_TEST_LOGS_SUCCESS',
          apiUrl: uri.toString(),
          status: 'SUCCESS',
          details: 'Fetched ${_fullList.length} test logs for ${event.loginId}',
        );
      } else {
        emit(TestLogError('Failed to load data'));
        // Log error
        LogManager().logEvent(
          event: 'FETCH_TEST_LOGS_FAILED',
          apiUrl: uri.toString(),
          status: 'FAILED',
          details: 'Failed to load test logs. Status: ${response.statusCode} for ${event.loginId}',
        );
      }
    } catch (e) {
      emit(TestLogError('Something went wrong'));
      // Log exception
      LogManager().logEvent(
        event: 'FETCH_TEST_LOGS_EXCEPTION',
        apiUrl: '${Urls.fetchTestLog}login_id=${event.loginId}',
        status: 'EXCEPTION',
        details: 'Exception: $e for ${event.loginId}',
      );
    }
  }

  void _onFilter(FilterTestLogs event, Emitter<TestLogState> emit) {
    final filtered = _fullList
        .where((element) => element.profileName.toLowerCase().contains(event.query.toLowerCase()))
        .toList();
    emit(TestLogLoaded(_fullList, filtered));

    // Log filter usage
    LogManager().logEvent(
      event: 'FILTER_TEST_LOGS',
      status: 'SUCCESS',
      details: 'Filter applied with query "${event.query}". Found ${filtered.length} logs.',
    );
  }
}
