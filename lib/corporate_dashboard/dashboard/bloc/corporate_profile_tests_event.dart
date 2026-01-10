import 'package:equatable/equatable.dart';

abstract class CorporateProfileTestsEvent extends Equatable {
  const CorporateProfileTestsEvent();

  @override
  List<Object?> get props => [];
}

class CorporateProfileTestsFetchRequested extends CorporateProfileTestsEvent {
  final String loginId;
  final String profileId;
  final String? date; // MM/DD/YYYY (optional)

  const CorporateProfileTestsFetchRequested({
    required this.loginId,
    required this.profileId,
    this.date,
  });

  @override
  List<Object?> get props => [loginId, profileId, date];
}

class CorporateProfileTestsClear extends CorporateProfileTestsEvent {
  const CorporateProfileTestsClear();
}
