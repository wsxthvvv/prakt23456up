class Confectioner {
  final int id;
  final String lastName;
  final String firstName;
  final String country;
  final String specialty;
  final DateTime? deletedAt;

  const Confectioner({
    required this.id,
    required this.lastName,
    required this.firstName,
    required this.country,
    required this.specialty,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  String get fullName => '$lastName $firstName';

  Confectioner copyWith({
    String? lastName,
    String? firstName,
    String? country,
    String? specialty,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Confectioner(
      id: id,
      lastName: lastName ?? this.lastName,
      firstName: firstName ?? this.firstName,
      country: country ?? this.country,
      specialty: specialty ?? this.specialty,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
