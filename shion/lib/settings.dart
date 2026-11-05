// ==== [ IDRUS - FRONTEND ] ==== //
/// Alamat server SHION yang digunakan aplikasi.
class Settings {
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://app.daffaputra.id/api');
  static const pointsPerScan = 1;
  static const rewardedScansPerDay = 5;
  static const guideCost = 20;
  static const searchRadiusMeters = 15000;

}
