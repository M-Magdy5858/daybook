import 'dart:convert';

abstract final class FakeJwt {
  static String create(String userId, Duration validFor) {
    String part(Map<String, Object> m) =>
        base64Url.encode(utf8.encode(jsonEncode(m)));
    final exp = DateTime.now().add(validFor).millisecondsSinceEpoch ~/ 1000;
    return '${part({'alg': 'none'})}.${part({'sub': userId, 'exp': exp})}.fake';
  }

  static Map<String, dynamic> payload(String token) =>
      jsonDecode(
            utf8.decode(
              base64Url.decode(base64Url.normalize(token.split('.')[1])),
            ),
          )
          as Map<String, dynamic>;

  static bool isExpired(String token) =>
      (payload(token)['exp'] as int) * 1000 <
      DateTime.now().millisecondsSinceEpoch;
}
