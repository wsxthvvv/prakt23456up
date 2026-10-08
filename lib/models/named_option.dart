import '../core/json_values.dart';

class NamedOption {
  final String name;

  const NamedOption(this.name);

  Map<String, dynamic> toJson() => {'name': name};

  factory NamedOption.fromJson(Map<String, dynamic> json) =>
      NamedOption(jsonString(json['name']));
}
