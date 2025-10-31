import 'dart:convert';
import 'api_service.dart';
import '../models/user.dart';
import '../config.dart';

class AuthService {
  final ApiService api = ApiService();

  Future<bool> login(String email, String password) async {
    try {
      print('[AUTH] Tentative de connexion pour: $email');

      final res = await api.post('/login', {
        'email': email,
        'password': password,
      });

      print('[AUTH] Status code: ${res.statusCode}');
      print('[AUTH] Response body: ${res.body}');

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);

        final token =
            json['access_token'] ??
            json['token'] ??
            json['jwt'] ??
            (json['data'] != null ? json['data']['access_token'] : null) ??
            (json['data'] != null ? json['data']['token'] : null);

        if (token != null) {
          print('[AUTH] Token reçu, sauvegarde...');
          await api.saveToken(token);
          return true;
        } else {
          print('[AUTH] Aucun token trouvé dans la réponse');
          print('[AUTH] Structure JSON: ${json.keys.toList()}');
        }
      } else {
        print('[AUTH] Échec de connexion: ${res.body}');
      }
    } catch (e) {
      print('[AUTH] Erreur lors de la connexion: $e');
    }
    return false;
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String passwordConfirmation,
  ) async {
    try {
      print('[AUTH] Tentative d\'inscription pour: $email');
      print('[AUTH] Données envoyées: name=$name, email=$email');
      print('[AUTH] URL complète: $baseUrl/enregistrement');

      final res = await api.post('/enregistrement', {
        'name': name,
        'email': email,
        'password': password,
        'c_password': passwordConfirmation,
      });

      print('[AUTH] Status code: ${res.statusCode}');
      print('[AUTH] Response body: ${res.body}');

      if (res.body.trim().startsWith('<') || res.body.trim().startsWith('<!')) {
        print('[AUTH] ERREUR: L\'API a renvoyé du HTML au lieu de JSON');
        return {
          'success': false,
          'message':
              'Erreur serveur: L\'endpoint /api/register n\'existe pas. Vérifiez votre API Laravel.',
        };
      }

      if (res.statusCode == 422) {
        final json = jsonDecode(res.body);
        print('[AUTH] Erreur de validation: $json');

        // Laravel renvoie les erreurs dans un objet "errors"
        if (json['errors'] != null) {
          final errors = json['errors'] as Map<String, dynamic>;
          final errorMessages = <String>[];

          errors.forEach((field, messages) {
            if (messages is List) {
              errorMessages.addAll(messages.cast<String>());
            } else {
              errorMessages.add(messages.toString());
            }
          });

          return {
            'success': false,
            'message': errorMessages.join('\n'),
            'errors': errors,
          };
        }

        return {
          'success': false,
          'message': json['message'] ?? 'Erreur de validation',
        };
      }

      if (res.statusCode == 200 || res.statusCode == 201) {
        final json = jsonDecode(res.body);

        final token =
            json['access_token'] ??
            json['token'] ??
            json['jwt'] ??
            (json['data'] != null ? json['data']['access_token'] : null) ??
            (json['data'] != null ? json['data']['token'] : null);

        if (token != null) {
          print('[AUTH] Inscription réussie, token reçu');
          await api.saveToken(token);
          return {'success': true, 'message': 'Inscription réussie'};
        }
        return {'success': true, 'message': 'Inscription réussie'};
      } else {
        try {
          final json = jsonDecode(res.body);
          return {
            'success': false,
            'message': json['message'] ?? 'Erreur: ${res.statusCode}',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Erreur serveur: ${res.statusCode}',
          };
        }
      }
    } catch (e) {
      print('[AUTH] Exception lors de l\'inscription: $e');
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  Future<void> logout() async {
    await api.post('/logout', {}, auth: true);
    await api.deleteToken();
  }

  Future<User?> profile() async {
    final res = await api.get('/profile', auth: true);
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final data = json['data'] ?? json['user'] ?? json;
      return User.fromJson(data as Map<String, dynamic>);
    }
    return null;
  }

  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? password,
    String? passwordConfirmation,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (password != null) {
      body['password'] = password;
      body['password_confirmation'] = passwordConfirmation ?? '';
    }

    final res = await api.put('/profile', body, auth: true);
    final json = jsonDecode(res.body);
    final success = res.statusCode == 200;
    return {
      'success': success,
      'message': json['message'] ?? (success ? 'OK' : 'Erreur'),
      'data': json['data'] ?? json,
    };
  }
}
