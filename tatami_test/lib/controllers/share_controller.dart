import 'dart:convert';
import 'package:get/get.dart';
import '../models/user.dart';
import '../models/tache.dart';
import '../services/api_service.dart';
import 'package:flutter/material.dart';

class ShareController extends GetxController {
  final ApiService api = ApiService();

  // Etat observable
  final users = <User>[].obs;
  final loading = false.obs;
  final error = RxnString();
  final query = ''.obs;
  final selectedUserIds = <int>{}.obs;

  Future<void> fetchUsers() async {
    loading.value = true;
    error.value = null;
    try {
      final res = await api.get('/users', auth: true);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        List<dynamic> items;
        if (body is List) {
          items = body;
        } else if (body is Map<String, dynamic>) {
          items = (body['data'] ?? body['users'] ?? []) as List<dynamic>;
        } else {
          items = [];
        }
        users.value = items.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        error.value = 'Erreur: ${res.statusCode}';
      }
    } catch (e) {
      error.value = 'Erreur: $e';
    } finally {
      loading.value = false;
    }
  }

  List<User> get filteredUsers {
    final q = query.value.toLowerCase();
    if (q.isEmpty) return users;
    return users.where((u) => u.name.toLowerCase().contains(q) || u.email.toLowerCase().contains(q)).toList();
  }

  void toggleUser(User u, bool checked) {
    if (u.id == null) return;
    if (checked) {
      selectedUserIds.add(u.id!);
    } else {
      selectedUserIds.remove(u.id!);
    }
  }

  Future<void> shareTask(Tache tache, BuildContext context) async {
    if (selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner au moins 1 utilisateur')),
      );
      return;
    }
    try {
      final res = await api.post(
        '/taches/${tache.id}/share',
        {
          'user_ids': selectedUserIds.toList(),
        },
        auth: true,
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tâche partagée avec succès')),
        );
        Get.back(result: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Echec du partage: ${res.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }
}
