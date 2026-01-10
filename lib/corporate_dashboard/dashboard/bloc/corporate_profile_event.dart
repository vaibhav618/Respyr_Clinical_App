import 'package:equatable/equatable.dart';

abstract class CorporateProfileEvent extends Equatable {
  const CorporateProfileEvent();

  @override
  List<Object?> get props => [];
}

class CorporateProfileFetchRequested extends CorporateProfileEvent {
  final String email;
  const CorporateProfileFetchRequested(this.email);

  @override
  List<Object?> get props => [email];
}

class CorporateProfileReset extends CorporateProfileEvent {
  const CorporateProfileReset();
}
