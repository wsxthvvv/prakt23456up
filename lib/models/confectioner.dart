import '../core/json_values.dart';

class Confectioner {
  final int id;
  final String lastName;
  final String firstName;
  final String country;
  final String specialty;
  final int workshopId;
  final DateTime? deletedAt;

  const Confectioner({
    required this.id,
    required this.lastName,
    required this.firstName,
    required this.country,
    required this.specialty,
    required this.workshopId,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  String get fullName => '$lastName $firstName';

  Confectioner copyWith({
    String? lastName,
    String? firstName,
    String? country,
    String? specialty,
    int? workshopId,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Confectioner(
      id: id,
      lastName: lastName ?? this.lastName,
      firstName: firstName ?? this.firstName,
      country: country ?? this.country,
      specialty: specialty ?? this.specialty,
      workshopId: workshopId ?? this.workshopId,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'lastName': lastName,
    'firstName': firstName,
    'country': country,
    'specialty': specialty,
    'workshopId': workshopId,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Confectioner.fromJson(Map<String, dynamic> json) => Confectioner(
    id: jsonInt(json['id']),
    lastName: jsonString(json['lastName']),
    firstName: jsonString(json['firstName']),
    country: jsonString(json['country']),
    specialty: jsonString(json['specialty']),
    workshopId: jsonRelationId(json, 'workshopId', 'workshop', 1),
    deletedAt: jsonDate(json['deletedAt']),
  );
}
