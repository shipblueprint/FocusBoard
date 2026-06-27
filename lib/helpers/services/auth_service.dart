/// Stub auth service retained for the few legacy imports still alive.
///
/// FocusBoard is a local-only productivity app and does not require
/// authentication. This class exists only to satisfy compile-time
/// references in older helpers and is intentionally empty.
class AuthService {
  AuthService._();

  static bool isLoggedIn = false;
}
