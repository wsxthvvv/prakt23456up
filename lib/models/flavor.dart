import '../core/json_values.dart';

class Flavor {
  final int id;
  final String name;
  final String description;
  final int intensity;
  final DateTime? deletedAt;

  const Flavor({
    required this.id,
    required this.name,
    required this.description,
    required this.intensity,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Flavor copyWith({
    String? name,
    String? description,
    int? intensity,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Flavor(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      intensity: intensity ?? this.intensity,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'intensity': intensity,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Flavor.fromJson(Map<String, dynamic> json) => Flavor(
    id: jsonInt(json['id']),
    name: jsonString(json['name']),
    description: jsonString(json['description']),
    intensity: jsonInt(json['intensity'], 1),
    deletedAt: jsonDate(json['deletedAt']),
  );
}
