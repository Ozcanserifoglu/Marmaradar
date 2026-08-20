/// OAuth client configuration via `--dart-define` / `--dart-define-from-file`.
///
/// Prefer the repo scripts (`run-local-mobile.sh`, `build-release-mobile.sh`), which
/// load `dart_defines.oauth.json`. Manual:
///   `--dart-define-from-file=dart_defines.oauth.json`
/// iOS also needs the iOS client ID (and URL scheme in GoogleSignInSecrets.xcconfig):
///   `--dart-define=GOOGLE_IOS_CLIENT_ID=IOS_CLIENT_ID`
class OAuthConfig {
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );
  static const googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );

  static bool get hasGoogleServerClientId => googleServerClientId.isNotEmpty;
}
