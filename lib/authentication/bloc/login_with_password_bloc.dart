

import 'package:flutter_bloc/flutter_bloc.dart';

import '../model/login_with_password_response.dart';
import '../repository/login_with_password_repository.dart';

abstract class LoginWithPasswordEvent {}

class LoginButtonPressed extends LoginWithPasswordEvent {
  final String adminId;
  final String password;

  LoginButtonPressed(this.adminId, this.password);
}

abstract class LoginWithPasswordState {}

class LoginWithPasswordInitial extends LoginWithPasswordState {}

class LoginWithPasswordLoading extends LoginWithPasswordState {}

class LoginWithPasswordSuccess extends LoginWithPasswordState {
  final LoginWithPasswordResponse response;
  LoginWithPasswordSuccess(this.response);
}

class LoginFailure extends LoginWithPasswordState {
  final String error;
  LoginFailure(this.error);
}

class LoginBloc extends Bloc<LoginWithPasswordEvent, LoginWithPasswordState> {
  final LoginWithPasswordRepository repository;

  LoginBloc(this.repository) : super(LoginWithPasswordInitial()) {
    on<LoginButtonPressed>((event, emit) async {
      emit(LoginWithPasswordLoading());
      try {
        final response = await repository.login(event.adminId, event.password);
        emit(LoginWithPasswordSuccess(response));
      } catch (e) {
        emit(LoginFailure(e.toString()));
      }
    });
  }
}

