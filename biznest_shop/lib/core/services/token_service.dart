import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenService {
  static final TokenService _instance = TokenService._internal();
  factory TokenService() => _instance;

  final _storage = const FlutterSecureStorage();
  static const String _jwtTokenKey = 'jwt_token';
  static const String _refreshTokenKey = 'refresh_token';

  TokenService._internal();

  Future<String?> getJwtToken() async {
    return await _storage.read(key: _jwtTokenKey);
  }

  Future<void> setJwtToken(String token) async {
    await _storage.write(key: _jwtTokenKey, value: token);
  }

  Future<void> clearJwtToken() async {
    await _storage.delete(key: _jwtTokenKey);
  }

  Future<bool> hasJwtToken() async {
    final token = await getJwtToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> setRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<void> clearRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<void> clearAllTokens() async {
    await clearJwtToken();
    await clearRefreshToken();
  }
}
