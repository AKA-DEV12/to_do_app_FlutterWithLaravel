import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';

class ApiService {
  final _storage = const FlutterSecureStorage();

  Future<String?> getToken() async {
    try {
      return await _storage.read(key: 'jwt');
    } catch (e) {
      print('[API] Erreur lors de la lecture du token: $e');
      return null;
    }
  }

  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: 'jwt', value: token);
      print('[API] Token sauvegardé avec succès');
    } catch (e) {
      print('[API] Erreur lors de la sauvegarde du token: $e');
    }
  }

  Future<void> deleteToken() async {
    try {
      await _storage.delete(key: 'jwt');
      print('[API] Token supprimé avec succès');
    } catch (e) {
      print('[API] Erreur lors de la suppression du token: $e');
    }
  }

  Future<http.Response> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final url = Uri.parse('$baseUrl$path');
    print('[API] POST request to: $url');
    print('[API] Body: ${jsonEncode(body)}');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (auth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
        print('[API] Token ajouté aux headers');
      }
    }

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      print('[API] Response status: ${response.statusCode}');
      return response;
    } catch (e) {
      print('[API] Erreur lors de la requête POST: $e');
      rethrow;
    }
  }

  Future<http.Response> put(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final url = Uri.parse('$baseUrl$path');
    print('[API] PUT request to: $url');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (auth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    try {
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      print('[API] Response status: ${response.statusCode}');
      return response;
    } catch (e) {
      print('[API] Erreur lors de la requête PUT: $e');
      rethrow;
    }
  }

  Future<http.Response> get(
    String path, {
    Map<String, String>? params,
    bool auth = false,
  }) async {
    var uri = Uri.parse('$baseUrl$path');

    if (params != null && params.isNotEmpty) {
      uri = uri.replace(queryParameters: params);
    }

    print('[API] GET request to: $uri');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (auth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    try {
      final response = await http.get(uri, headers: headers);
      print('[API] Response status: ${response.statusCode}');
      return response;
    } catch (e) {
      print('[API] Erreur lors de la requête GET: $e');
      rethrow;
    }
  }

  Future<http.Response> delete(String path, {bool auth = false}) async {
    final url = Uri.parse('$baseUrl$path');
    print('[API] DELETE request to: $url');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (auth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    try {
      final response = await http.delete(url, headers: headers);
      print('[API] Response status: ${response.statusCode}');
      return response;
    } catch (e) {
      print('[API] Erreur lors de la requête DELETE: $e');
      rethrow;
    }
  }
}
