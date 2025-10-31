import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/tache.dart';
import '../services/api_service.dart';

class TaskFormPage extends StatefulWidget {
  final Tache? tache;
  const TaskFormPage({super.key, this.tache});

  @override
  State<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends State<TaskFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  DateTime _date = DateTime.now();
  int _categoryId = 1;
  String _etat = 'en attente';
  final ApiService api = ApiService();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.tache != null) {
      _title.text = widget.tache!.title;
      _description.text = widget.tache!.description ?? '';
      _date = widget.tache!.date;
      _categoryId = widget.tache!.categoryId;
      _etat = widget.tache!.etat;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final body = {
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'date': DateFormat('yyyy-MM-dd').format(_date),
        'category_id': _categoryId,
        'etat': _etat,
      };

      final resp = (widget.tache == null)
          ? await api.post('/taches', body, auth: true)
          : await api.put('/taches/${widget.tache!.id}', body, auth: true);

      setState(() => _loading = false);

      if (!mounted) return;

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        Navigator.pop(context, true);
      } else {
        // Afficher les détails de l'erreur
        String errorMessage = 'Erreur: ${resp.statusCode}';
        try {
          final errorBody = jsonDecode(resp.body);
          if (errorBody['message'] != null) {
            errorMessage = errorBody['message'];
          }
          if (errorBody['errors'] != null) {
            final errors = errorBody['errors'] as Map<String, dynamic>;
            final errorList = <String>[];
            errors.forEach((key, value) {
              if (value is List) {
                errorList.addAll(value.map((e) => e.toString()));
              } else {
                errorList.add(value.toString());
              }
            });
            errorMessage = errorList.join('\n');
          }
        } catch (e) {
          errorMessage = 'Erreur ${resp.statusCode}: ${resp.body}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = d);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tache == null ? 'Nouvelle tâche' : 'Modifier tâche'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le titre est obligatoire';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  title: const Text('Date'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(_date)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _categoryId,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Programmation')),
                  DropdownMenuItem(value: 2, child: Text('Lecture')),
                  DropdownMenuItem(value: 3, child: Text('Sport')),
                  DropdownMenuItem(value: 4, child: Text('Gaming')),
                ],
                onChanged: (v) => setState(() => _categoryId = v ?? 1),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _etat,
                decoration: const InputDecoration(
                  labelText: 'État',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'en attente',
                    child: Text('En attente'),
                  ),
                  DropdownMenuItem(value: 'en cours', child: Text('En cours')),
                  DropdownMenuItem(value: 'terminee', child: Text('Terminée')),
                ],
                onChanged: (v) => setState(() => _etat = v ?? 'en attente'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Enregistrer', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
