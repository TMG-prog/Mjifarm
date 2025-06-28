// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'firebase_ui_auth_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class FirebaseUiAuthLocalizationsEn extends FirebaseUiAuthLocalizations {
  FirebaseUiAuthLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get wrongPasswordErrorText =>
      'Oops! That\'s not the right password. Please double-check and try again.';

  @override
  String get userNotFound =>
      'It seems there\'s no account with that email. Maybe try signing up?';

  @override
  String get invalidEmailErrorText =>
      'Looks like an invalid email address. Please fix it.';

  @override
  String get emailAlreadyInUseErrorText =>
      'This email is already registered. Please sign in or use a different email.';

  @override
  String get passwordIsTooWeakErrorText =>
      'Your password is a bit weak. Please choose a stronger one!';

  @override
  String get networkRequestFailed =>
      'Can\'t connect to the server. Please check your internet connection and try again.';

  @override
  String get goBackButtonLabel => 'Go Back';

  @override
  String get signInActionText => 'Sign in';

  @override
  String get registerActionText => 'Register';

  @override
  String get forgotPasswordButtonLabel => 'Forgot password?';

  @override
  String get invalidCredential => 'Invalid email or password.';

  @override
  String get unknownError => 'Invalid email or password.';
}
