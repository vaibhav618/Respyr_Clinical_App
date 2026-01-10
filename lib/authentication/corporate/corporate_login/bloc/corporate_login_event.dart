abstract class CorporateLoginEvent {
  const CorporateLoginEvent();
}

class CorporateLoginEmailChanged extends CorporateLoginEvent {
  final String email;
  const CorporateLoginEmailChanged(this.email);
}

class CorporateLoginPasswordChanged extends CorporateLoginEvent {
  final String password;
  const CorporateLoginPasswordChanged(this.password);
}

class CorporateLoginSubmitted extends CorporateLoginEvent {
  const CorporateLoginSubmitted();
}
