
import '../model/OverallDataByDateModel.dart';

abstract class HealthScoreState {}

class HealthScoreInitial extends HealthScoreState {}

class HealthScoreLoading extends HealthScoreState {}

class HealthScoreLoaded extends HealthScoreState {
  final OverallDataByDateModel response;

  HealthScoreLoaded(this.response);
}

class HealthScoreEmpty extends HealthScoreState {}

class HealthScoreError extends HealthScoreState {
  final String message;

  HealthScoreError(this.message);
}
