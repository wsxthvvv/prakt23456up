import '../core/json_values.dart';
import 'loyalty_card.dart';

class Customer {
  final int id;
  final String lastName;
  final String firstName;
  final String email;
  final String phone;
  final LoyaltyCard loyaltyCard;
  final DateTime? deletedAt;

  const Customer({
    required this.id,
    required this.lastName,
    required this.firstName,
    required this.email,
    required this.phone,
    required this.loyaltyCard,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  String get fullName => '$lastName $firstName';

  Customer copyWith({
    String? lastName,
    String? firstName,
    String? email,
    String? phone,
    LoyaltyCard? loyaltyCard,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Customer(
      id: id,
      lastName: lastName ?? this.lastName,
      firstName: firstName ?? this.firstName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      loyaltyCard: loyaltyCard ?? this.loyaltyCard,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'lastName': lastName,
        'firstName': firstName,
        'email': email,
        'phone': phone,
        'loyaltyCard': loyaltyCard.toJson(),
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Customer.fromJson(Map<String, dynamic> json) {
    final rawCard = json['loyaltyCard'];
    final card = rawCard is Map
        ? LoyaltyCard.fromJson(Map<String, dynamic>.from(rawCard))
        : const LoyaltyCard(number: '', issuedOn: '', discountPercent: 0, active: false);
    return Customer(
      id: jsonInt(json['id']),
      lastName: jsonString(json['lastName']),
      firstName: jsonString(json['firstName']),
      email: jsonString(json['email']),
      phone: jsonString(json['phone']),
      loyaltyCard: card,
      deletedAt: jsonDate(json['deletedAt']),
    );
  }
}
