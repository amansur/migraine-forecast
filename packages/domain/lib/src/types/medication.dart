import 'package:equatable/equatable.dart';

enum MedClass { triptan, simpleAnalgesic, combination, preventive, other }

class MedicationDose extends Equatable {
  final int? id;
  final DateTime at;
  final String name;
  final MedClass medClass;

  /// 0 = didn't help, 1 = helped some, 2 = helped. Null = not rated.
  final int? reliefRating;
  const MedicationDose({
    this.id,
    required this.at,
    required this.name,
    required this.medClass,
    this.reliefRating,
  });
  @override
  List<Object?> get props => [id, at, name, medClass, reliefRating];
}
