abstract class ClinicNameCheckEvent {
  const ClinicNameCheckEvent();
}

class ClinicNameChanged extends ClinicNameCheckEvent {
  final String clinicName;
  const ClinicNameChanged(this.clinicName);
}

class ClinicNameCheckSubmitted extends ClinicNameCheckEvent {
  final String clinicName;
  const ClinicNameCheckSubmitted(this.clinicName);
}

class ClinicNameCheckReset extends ClinicNameCheckEvent {
  const ClinicNameCheckReset();
}
