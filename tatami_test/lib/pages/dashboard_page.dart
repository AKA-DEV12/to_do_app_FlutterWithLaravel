import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/tache.dart';
import 'task_form_page.dart';
import '../services/auth_service.dart';
import 'share_task_sheet.dart';
import 'task_details_page.dart';
import 'profile_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ApiService api = ApiService();
  final AuthService auth = AuthService();
  List<Tache> taches = [];
  bool loading = true;
  DateTime? selectedDate;
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
    await fetchTaches();
  }

  Future<void> fetchTaches() async {
    setState(() {
      loading = true;
    });

    try {
      final params = <String, String>{};
      if (selectedDate != null) {
        params['date'] = DateFormat('yyyy-MM-dd').format(selectedDate!);
      } else {
        params['limit'] = '100';
      }

      final res = await api.get('/taches', params: params, auth: true);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        List<dynamic> items = [];

        if (body is List) {
          items = body;
        } else if (body is Map<String, dynamic>) {
          items = (body['data'] ?? body['taches'] ?? []) as List<dynamic>;
        }

        final list = items
            .map((e) => Tache.fromJson(e as Map<String, dynamic>))
            .toList();
        list.sort((a, b) => b.date.compareTo(a.date));

        setState(() {
          taches = list.take(10).toList();
          loading = false;
        });
      } else if (res.statusCode == 401) {
        await auth.logout();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/');
      } else {
        setState(() {
          loading = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${res.statusCode}')));
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      setState(() {
        selectedDate = d;
      });
      await fetchTaches();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: () async {
              final changed = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
              if (changed == true) {
                _init();
              }
            },
            icon: const Icon(Icons.person),
          ),
          IconButton(
            onPressed: () async {
              await auth.logout();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TaskFormPage()),
          );
          if (result == true) fetchTaches();
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.filter_alt),
                  label: Text(
                    selectedDate == null
                        ? 'Filtrer par date'
                        : DateFormat('yyyy-MM-dd').format(selectedDate!),
                  ),
                ),
                if (selectedDate != null)
                  TextButton(
                    onPressed: () {
                      setState(() => selectedDate = null);
                      fetchTaches();
                    },
                    child: const Text('Annuler filtre'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : taches.isEmpty
                ? const Center(child: Text('Aucune tâche'))
                : ListView.builder(
                    itemCount: taches.length,
                    itemBuilder: (c, i) {
                      final t = taches[i];
                      final isOwner =
                          (t.ownerId != null && t.ownerId == currentUserId);
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TaskDetailsPage(tacheId: t.id!),
                              ),
                            );
                          },
                          title: Text(t.title),
                          subtitle: Text(
                            '${DateFormat('dd/MM/yyyy').format(t.date)} • ${t.etat}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.share),
                                onPressed: isOwner
                                    ? () async {
                                        await showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          builder: (_) =>
                                              ShareTaskSheet(tache: t),
                                        );
                                      }
                                    : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: isOwner
                                    ? () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                TaskFormPage(tache: t),
                                          ),
                                        );
                                        if (result == true) fetchTaches();
                                      }
                                    : null,
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: isOwner
                                    ? () => _confirmDelete(t)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Tache t) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer'),
        content: Text('Supprimer "${t.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final res = await api.delete('/taches/${t.id}', auth: true);
        if (!mounted) return;

        if (res.statusCode == 200 || res.statusCode == 204) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Tâche supprimée')));
          fetchTaches();
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erreur: ${res.statusCode}')));
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }
}
