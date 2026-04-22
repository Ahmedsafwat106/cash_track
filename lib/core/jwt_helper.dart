import 'dart:convert';

class JwtHelper {
  static Map<String, dynamic> decode(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};
      String payload = parts[1];

      while (payload.length % 4 != 0) payload += '=';
      final decoded = utf8.decode(base64Url.decode(payload));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  static String getName(String token) {
    final data = decode(token);
    return data['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name']
        ?.toString() ??
        '';
  }

  static String getEmail(String token) {
    final data = decode(token);
    return data['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress']
        ?.toString() ??
        '';
  }

  static String getRole(String token) {
    final data = decode(token);
    return data['http://schemas.microsoft.com/ws/2008/06/identity/claims/role']
        ?.toString() ??
        '';
  }
}