import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/tache.dart';
import '../controllers/share_controller.dart';

// Cette page (Bottom Sheet) permet de PARTAGER une tâche avec d'autres utilisateurs.
// Objectif: afficher la liste des utilisateurs (nom + email) venant du backend Laravel
// et permettre de sélectionner un ou plusieurs utilisateurs pour partager la tâche.
class ShareTaskSheet extends StatelessWidget {
  // La tâche à partager
  final Tache tache;

  const ShareTaskSheet({super.key, required this.tache});

  @override
  Widget build(BuildContext context) {
    // On initialise le contrôleur GetX et on charge les utilisateurs
    return GetX<ShareController>(
      init: ShareController()..fetchUsers(),
      builder: (ctrl) {
        final filtered = ctrl.filteredUsers;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre
                const Text(
                  'Partager la tâche',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Champ de recherche pour filtrer la liste (bind GetX)
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Rechercher par nom ou email',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => ctrl.query.value = v,
                ),
                const SizedBox(height: 12),
                if (ctrl.loading.value)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (ctrl.error.value != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(ctrl.error.value!, style: const TextStyle(color: Colors.red)),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 350),
                    child: filtered.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Text('Aucun utilisateur'),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final u = filtered[index];
                              final selected = u.id != null && ctrl.selectedUserIds.contains(u.id);
                              return CheckboxListTile(
                                value: selected,
                                onChanged: (checked) {
                                  ctrl.toggleUser(u, checked == true);
                                },
                                title: Text(u.name),
                                subtitle: Text(u.email),
                                secondary: const Icon(Icons.person),
                              );
                            },
                          ),
                  ),
                const SizedBox(height: 12),
                // Bouton PARTAGER pour envoyer la requête
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => ctrl.shareTask(tache, context),
                    icon: const Icon(Icons.share),
                    label: const Text('Partager'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
