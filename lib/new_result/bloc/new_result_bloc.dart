

import '../data/model/result_model.dart';

abstract class NewResultState {}

class NewResultInitial extends NewResultState {}

class NewResultLoading extends NewResultState {}

class NewResultSuccess extends NewResultState {
  final NewResultModel result;
  NewResultSuccess(this.result);
}

class NewResultFailure extends NewResultState {
  final String error;
  NewResultFailure(this.error);
}
