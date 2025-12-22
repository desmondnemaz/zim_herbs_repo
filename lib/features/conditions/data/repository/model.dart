
import 'package:zim_herbs_repo/utils/enums.dart';

class ConditionModel {
  final String id;
  final String name;
  final BodySystem bodySystem;
  final String? description;
  final List<String> symptoms;
  final List<String> precautions;

  ConditionModel({
    required this.id,
    required this.name,
    required this.bodySystem,
    this.description,
    this.symptoms = const [],
    this.precautions = const [],
  });

  /// Factory constructor to parse JSON from Supabase
  factory ConditionModel.fromJson(Map<String, dynamic> json) {
    return ConditionModel(
      id: json['id'],
      name: json['name'],
      bodySystem: bodySystemFromString(json['body_system']),
      description: json['description'],
      symptoms: (json['symptoms'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      precautions: (json['precautions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  /// Convert model to JSON for insert/update
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'body_system': bodySystemToString(bodySystem),
      'description': description,
      'symptoms': symptoms,
      'precautions': precautions,
    };
  }
}
