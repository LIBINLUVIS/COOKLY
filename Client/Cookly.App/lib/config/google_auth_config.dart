/// OAuth client IDs from the Google Cloud Console credentials page
/// (APIs & Services -> Credentials) for this app's project.
///
/// - [iosClientId] comes from the "iOS" OAuth client (bundle ID
///   com.socxo.cookly.cooklyApp) and must also be set as `GIDClientID`
///   and its reversed form as a URL scheme in ios/Runner/Info.plist.
/// - [serverClientId] comes from the "Web application" OAuth client and is
///   what lets both platforms return a Google ID token the backend can
///   verify later; Android's Credential Manager flow requires it too.
class GoogleAuthConfig {
  GoogleAuthConfig._();

  static const String iosClientId =
      '947422810085-jthtgijib0n1u3i81tmjai2nadjqmsr1.apps.googleusercontent.com';
  static const String serverClientId =
      '947422810085-125fj1i329j5ifnebh3sepeqvtq1u65f.apps.googleusercontent.com';
}
