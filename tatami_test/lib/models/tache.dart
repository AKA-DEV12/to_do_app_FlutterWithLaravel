class Tache {
  final int? id;
  final String title;
  final String? description;
  final DateTime date;
  final int categoryId;
  final String etat;
  final int? ownerId;

  Tache({
    this.id,
    required this.title,
    this.description,
    required this.date,
    required this.categoryId,
    required this.etat,
    this.ownerId,
  });

  factory Tache.fromJson(Map<String, dynamic> json) => Tache(
    id: json['id'],
    title: json['title'] ?? '',
    description: json['description'],
    date: DateTime.parse(json['date']),
    categoryId: json['category_id'],
    etat: json['etat'] ?? 'en attente',
    ownerId:
        json['owner_id'] ??
        (json['owner'] != null ? json['owner']['id'] : null),
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'date': date.toIso8601String().split('T')[0], // yyyy-mm-dd
    'category_id': categoryId,
    'etat': etat,
  };
}
