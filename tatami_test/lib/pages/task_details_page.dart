import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/tache.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'share_task_sheet.dart';

class TaskDetailsPage extends StatefulWidget {
  final int tacheId;
  const TaskDetailsPage({super.key, required this.tacheId});

  @override
  State<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  final api = ApiService();
  final auth = AuthService();
  Tache? tache;
  bool loading = true;
  int? currentUserId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final me = await auth.profile();
    setState(() {
      currentUserId = me?.id;
    });
    await fetch();
  }

  Future<void> fetch() async {
    setState(() => loading = true);
    final res = await api.get('/taches/${widget.tacheId}', auth: true);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        tache = Tache.fromJson(
          data is Map<String, dynamic> ? data : (data['data'] ?? {}),
        );
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = tache;
    final isOwner =
        t != null && t.ownerId != null && t.ownerId == currentUserId;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la tâche'),
        actions: [
          if (t != null && isOwner)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () async {
                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => ShareTaskSheet(tache: t),
                );
              },
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : t == null
          ? const Center(child: Text('Introuvable'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Échéance: ${DateFormat('dd/MM/yyyy').format(t.date)}'),
                  const SizedBox(height: 8),
                  Text('Statut: ${t.etat}'),
                  const SizedBox(height: 16),
                  const Text(
                    'Description',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(t.description ?? '—'),
                ],
              ),
            ),
    );
  }
}
