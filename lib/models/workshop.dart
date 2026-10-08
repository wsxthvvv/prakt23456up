import '../core/json_values.dart';

class Workshop {
  final int id;
  final String name;
  final String city;
  final String phone;
  final int dailyCapacityKg;
  final List<int> flavorIds;
  final DateTime? deletedAt;

  const Workshop({
    required this.id,
    required this.name,
    required this.city,
    required this.phone,
    required this.flavorIds,
    this.dailyCapacityKg = 20,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Workshop copyWith({
    String? name,
    String? city,
    String? phone,
    int? dailyCapacityKg,
    List<int>? flavorIds,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Workshop(
      id: id,
      name: name ?? this.name,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      dailyCapacityKg: dailyCapacityKg ?? this.dailyCapacityKg,
      flavorIds: flavorIds ?? this.flavorIds,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'city': city,
    'phone': phone,
    'dailyCapacityKg': dailyCapacityKg,
    'flavorIds': flavorIds,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Workshop.fromJson(Map<String, dynamic> json) => Workshop(
    id: jsonInt(json['id']),
    name: jsonString(json['name']),
    city: jsonString(json['city']),
    phone: jsonString(json['phone']),
    dailyCapacityKg: jsonInt(json['dailyCapacityKg'], 20),
    flavorIds: jsonRelationIds(json, 'flavorIds', 'flavors'),
    deletedAt: jsonDate(json['deletedAt']),
  );
}
