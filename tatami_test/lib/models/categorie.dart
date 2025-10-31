class Categorie {
  final int id;
  final String name;

  Categorie({required this.id, required this.name});

  factory Categorie.fromJson(Map<String, dynamic> json) =>
      Categorie(id: json['id'], name: json['name']);
}
