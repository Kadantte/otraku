import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';

class Repository {
  static final _url = Uri.parse('https://graphql.anilist.co');

  const Repository.guest()
      : _headers = const {
          'Accept': 'application/json',
          'Content-type': 'application/json',
        };

  Repository(String accessToken)
      : _headers = {
          'Accept': 'application/json',
          'Content-type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        };

  final Map<String, String> _headers;

  Future<Map<String, dynamic>> request(
    String query, [
    Map<String, dynamic> variables = const {},
  ]) async {
    try {
      final response = await post(
        _url,
        body: json.encode({'query': query, 'variables': variables}),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      final Map<String, dynamic> body = json.decode(response.body);

      if (body.containsKey('errors')) {
        throw StateError(
          (body['errors'] as List).map((e) => e['message'].toString()).join(),
        );
      }

      return body['data'];
    } on TimeoutException {
      throw Exception('Request took too long');
    }
  }
}
