/// Values are supplied by settings/private.json at build/run time.
/// Do not put a production shared key inside a publicly distributed APK.
class Settings {
  static const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-3.5-flash-lite',
  );
  static const geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const overpassUrl = 'https://overpass-api.de/api/interpreter';
  static const geocodingUrl = 'https://nominatim.openstreetmap.org/search';
  static const mapTiles = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const userAgent = 'SHION/1.0 (https://github.com/Daff404/perlombaan)';
  static const pointsPerScan = 10;
  static const rewardedScansPerDay = 5;
  static const guideCost = 20;
  static const searchRadiusMeters = 15000;
  static bool get aiConfigured => geminiApiKey.trim().isNotEmpty;
}
