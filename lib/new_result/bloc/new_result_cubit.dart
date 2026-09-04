import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:respyr_clinical/shared/nodeurl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../log_manager/log_manager.dart';
import '../data/model/result_model.dart';
import 'new_result_bloc.dart';
class NewResultCubit extends Cubit<NewResultState> {
  NewResultCubit() : super(NewResultInitial());

  Future<void> fetchResults({
    required String testdata,
    required String subjectId,
    required String gender,
    required String age,
    required String height,
    required String region,
    required String blowData,
  }) async {
    emit(NewResultLoading());

    // Log attempt
    LogManager().logEvent(
      event: 'FETCH_RESULT_ATTEMPT',
      apiUrl: NodeUrls.resultAnalysis2,
      status: 'ATTEMPT',
      details: 'Attempting to fetch result for subject: $subjectId, region: $region',
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      if (token.isEmpty) {
        // Log missing token
        LogManager().logEvent(
          event: 'FETCH_RESULT_UNAUTHORIZED',
          apiUrl: NodeUrls.resultAnalysis,
          status: 'FAILED',
          details: 'JWT token missing when fetching result for subject: $subjectId',
        );
        emit(NewResultFailure('Missing token'));
        return;
      }

      final response = await http.post(
        Uri.parse(NodeUrls.resultAnalysis2),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          'testdata': testdata,
          'subid': subjectId,
          'gender': gender,
          'age': age,
          'height': height,
          'blow_region': region,
          'blow_raw_values': blowData,
        }),
      );


      print(response.body);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        final obj = extractResultObject(json);
        if (obj != null) {
          // Log success
          LogManager().logEvent(
            event: 'FETCH_RESULT_SUCCESS',
            apiUrl: NodeUrls.resultAnalysis2,
            status: 'SUCCESS',
            details: 'Result fetched successfully for subject: $subjectId',
          );
          final model = NewResultModel.fromJson(obj);
          emit(NewResultSuccess(model));
        } else {
          final msg = json is Map ? (json['message'] ?? 'Unknown error') : 'Unknown error';
          // Log API error
          LogManager().logEvent(
            event: 'FETCH_RESULT_FAILED',
            apiUrl: NodeUrls.resultAnalysis2,
            status: 'FAILED',
            details: 'API error: $msg for subject: $subjectId',
          );
          emit(NewResultFailure(msg));
        }
      } else {
        // Log HTTP error
        LogManager().logEvent(
          event: 'FETCH_RESULT_FAILED',
          apiUrl: NodeUrls.resultAnalysis2,
          status: 'FAILED',
          details: 'HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'Unknown error'} for subject: $subjectId',
        );
        emit(NewResultFailure(
          'HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'Unknown error'}',
        ));
      }
    } catch (e) {
      // Log exception
      LogManager().logEvent(
        event: 'FETCH_RESULT_EXCEPTION',
        apiUrl: NodeUrls.resultAnalysis2,
        status: 'EXCEPTION',
        details: 'Exception: $e for subject: $subjectId',
      );
      emit(NewResultFailure('Exception: ${e.toString()}'));
    }
  }

  void emitDataEmpty(int statusCode, String message) {
    emit(NewResultFailure('HTTP $statusCode: $message'));
  }

  void emitNoResponse(int statusCode, String message) {
    emit(NewResultFailure('HTTP $statusCode: $message'));
  }

  Future<void> fetchHistory({
    required String loginId,
    required String profileId,
    required String id,
  }) async {
    emit(NewResultLoading());

    // Log attempt
    LogManager().logEvent(
      event: 'FETCH_HISTORY_ATTEMPT',
      apiUrl: NodeUrls.fetchHistory,
      status: 'ATTEMPT',
      details: 'Fetching history for loginId: $loginId, profileId: $profileId',
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      if (token.isEmpty) {
        // Log missing token
        LogManager().logEvent(
          event: 'FETCH_HISTORY_UNAUTHORIZED',
          apiUrl: NodeUrls.fetchHistory,
          status: 'FAILED',
          details: 'JWT token missing for history fetch loginId: $loginId',
        );
        emit(NewResultFailure('Missing token'));
        return;
      }

      final uri = Uri.parse(
        NodeUrls.fetchHistory,
      );

      final response = await http.post(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "login_id": loginId,
          "profile_id": profileId,
          "id": id,
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        final obj = extractResultObject(json);
        if (obj != null) {
          // Log history fetch success
          LogManager().logEvent(
            event: 'FETCH_HISTORY_SUCCESS',
            apiUrl: uri.toString(),
            status: 'SUCCESS',
            details: 'Fetched history for loginId: $loginId, profileId: $profileId',
          );
          final model = NewResultModel.fromJson(obj);
          emit(NewResultSuccess(model));
        } else {
          final msg = json is Map ? (json['message'] ?? 'Unknown error') : 'Unknown error';
          // Log API error
          LogManager().logEvent(
            event: 'FETCH_HISTORY_FAILED',
            apiUrl: uri.toString(),
            status: 'FAILED',
            details: 'API error: $msg for loginId: $loginId',
          );
          emit(NewResultFailure(msg));
        }
      } else {
        // Log HTTP error
        LogManager().logEvent(
          event: 'FETCH_HISTORY_FAILED',
          apiUrl: uri.toString(),
          status: 'FAILED',
          details: 'HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'Unknown error'} for loginId: $loginId',
        );
        emit(NewResultFailure(
          'HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'Unknown error'}',
        ));
      }
    } catch (e) {
      // Log exception
      LogManager().logEvent(
        event: 'FETCH_HISTORY_EXCEPTION',
        apiUrl: NodeUrls.fetchHistory,
        status: 'EXCEPTION',
        details: 'Exception: $e for loginId: $loginId',
      );
      emit(NewResultFailure('Exception: ${e.toString()}'));
    }
  }
}
