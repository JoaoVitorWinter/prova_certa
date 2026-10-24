import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}

class Aluno {
  final String id;
  final String nome;
  final String ra;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  Aluno({
    required this.id,
    required this.nome,
    required this.ra,
    this.criadoEm,
    this.atualizadoEm,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'ra': ra,
      'criadoEm': criadoEm?.toIso8601String(),
      'atualizadoEm': atualizadoEm?.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'ra': ra, // Mantém explicitamente como String, preservando zeros à esquerda
      'criadoEm': criadoEm != null
          ? Timestamp.fromDate(criadoEm!)
          : FieldValue.serverTimestamp(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    };
  }

  factory Aluno.fromMap(Map<String, dynamic> map, {String? id}) {
    return Aluno(
      id: id ?? map['id'] as String? ?? '',
      nome: map['nome'] as String? ?? '',
      ra: map['ra']?.toString() ?? '',
      criadoEm: _parseDateTime(map['criadoEm']),
      atualizadoEm: _parseDateTime(map['atualizadoEm']),
    );
  }

  factory Aluno.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Aluno.fromMap(data, id: doc.id);
  }

  Aluno copyWith({
    String? id,
    String? nome,
    String? ra,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) {
    return Aluno(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      ra: ra ?? this.ra,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }
}