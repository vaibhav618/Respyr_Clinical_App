import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../log_manager/log_manager.dart';
import '../model/test_log_model.dart';
import '../repositories/test_log_repository.dart';
import 'package:respyr_clinical/shared/nodeurl.dart';
import 'package:http/http.dart' as http;

/// Parses one page of the test-log response on a background isolate — parsing
/// records on the UI thread freezes every animation on screen. Returns the
/// page's models plus whether more pages remain.
Map<String, dynamic> _parseTestLogPage(String body) {
  final responseBody = json.decode(body);
  final data = (responseBody['data'] as List?) ?? [];
  return {
    'logs': data.map((e) => TestLogModel.fromJson(e)).toList(),
    'hasMore': responseBody['hasMore'] == true,
  };
}

class TestLogBloc extends Bloc<TestLogEvent, TestLogState> {
  static const int _pageSize = 15;

  String _loginId = '';
  String _query = '';
  int _page = 1;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  List<TestLogModel> _logs = [];

  TestLogBloc() : super(TestLogInitial()) {
    on<FetchTestLogs>(_onFetch);
    on<LoadMoreTestLogs>(_onLoadMore);
    on<FilterTestLogs>(_onFilter);
  }

  Map<String, dynamic> _pageBody(int page) {
    return {
      'login_id': _loginId,
      'page': page,
      'limit': _pageSize,
      if (_query.isNotEmpty) 'search': _query,
    };
  }

  /// Fetches [page]; replaces the list unless [append] is set.
  Future<void> _fetchPage(
    int page, {
    required bool append,
    required Emitter<TestLogState> emit,
  }) async {
    final response = await http.post(
      Uri.parse(NodeUrls.fetchTestLog),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(_pageBody(page)),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load data (${response.statusCode})');
    }
    final parsed = await compute(_parseTestLogPage, response.body);
    final list = parsed['logs'] as List<TestLogModel>;
    _page = page;
    _hasMore = parsed['hasMore'] == true;
    _logs = append ? [..._logs, ...list] : list;
    emit(TestLogLoaded(_logs, hasMore: _hasMore));
  }

  Future<void> _onFetch(FetchTestLogs event, Emitter<TestLogState> emit) async {
    _loginId = event.loginId;
    _query = '';
    emit(TestLogLoading());
    LogManager().logEvent(
      event: 'FETCH_TEST_LOGS_ATTEMPT',
      apiUrl: NodeUrls.fetchTestLog,
      status: 'ATTEMPT',
      details: 'Fetching test logs for ${event.loginId}',
    );
    try {
      await _fetchPage(1, append: false, emit: emit);
      LogManager().logEvent(
        event: 'FETCH_TEST_LOGS_SUCCESS',
        apiUrl: NodeUrls.fetchTestLog,
        status: 'SUCCESS',
        details: 'Fetched page 1 (${_logs.length}) for ${event.loginId}',
      );
    } catch (e) {
      emit(TestLogError('Something went wrong'));
      LogManager().logEvent(
        event: 'FETCH_TEST_LOGS_EXCEPTION',
        apiUrl: NodeUrls.fetchTestLog,
        status: 'EXCEPTION',
        details: 'Exception: $e for ${event.loginId}',
      );
    }
  }

  Future<void> _onLoadMore(
    LoadMoreTestLogs event,
    Emitter<TestLogState> emit,
  ) async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    emit(TestLogLoaded(_logs, hasMore: _hasMore, isLoadingMore: true));
    try {
      await _fetchPage(_page + 1, append: true, emit: emit);
    } catch (e) {
      emit(TestLogLoaded(_logs, hasMore: _hasMore));
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> _onFilter(
    FilterTestLogs event,
    Emitter<TestLogState> emit,
  ) async {
    _query = event.query.trim();
    emit(TestLogLoading());
    try {
      await _fetchPage(1, append: false, emit: emit);
      LogManager().logEvent(
        event: 'FILTER_TEST_LOGS',
        status: 'SUCCESS',
        details: 'Search "${event.query}" → ${_logs.length} logs.',
      );
    } catch (e) {
      emit(TestLogError('Something went wrong'));
    }
  }
}
