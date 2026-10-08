import '../core/json_values.dart';

class LoyaltyCard {
  final String number;
  final String issuedOn;
  final int discountPercent;
  final bool active;

  const LoyaltyCard({
    required this.number,
    required this.issuedOn,
    required this.discountPercent,
    required this.active,
  });

  Map<String, dynamic> toJson() => {
    'number': number,
    'issuedOn': issuedOn,
    'discountPercent': discountPercent,
    'active': active,
  };

  factory LoyaltyCard.fromJson(Map<String, dynamic> json) => LoyaltyCard(
    number: jsonString(json['number']),
    issuedOn: jsonString(json['issuedOn']),
    discountPercent: jsonInt(json['discountPercent']),
    active: jsonBool(json['active']),
  );
}
