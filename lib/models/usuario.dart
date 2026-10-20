import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}

class Usuario {
  final String id;
  final String nome;
  final String email;
  final String instituicao;
  final String? fotoUrl;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.instituicao,
    this.fotoUrl,
    this.criadoEm,
    this.atualizadoEm,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'instituicao': instituicao,
      'fotoUrl': fotoUrl,
      'criadoEm': criadoEm?.toIso8601String(),
      'atualizadoEm': atualizadoEm?.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'email': email,
      'instituicao': instituicao,
      'fotoUrl': fotoUrl,
      'criadoEm': criadoEm != null
          ? Timestamp.fromDate(criadoEm!)
          : FieldValue.serverTimestamp(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    };
  }

  factory Usuario.fromMap(Map<String, dynamic> map, {String? id}) {
    return Usuario(
      id: id ?? map['id'] as String? ?? '',
      nome: map['nome'] as String? ?? '',
      email: map['email'] as String? ?? '',
      instituicao: map['instituicao'] as String? ?? '',
      fotoUrl: map['fotoUrl'] as String?,
      criadoEm: _parseDateTime(map['criadoEm']),
      atualizadoEm: _parseDateTime(map['atualizadoEm']),
    );
  }

  factory Usuario.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Usuario.fromMap(data, id: doc.id);
  }

  Usuario copyWith({
    String? id,
    String? nome,
    String? email,
    String? instituicao,
    String? fotoUrl,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) {
    return Usuario(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      instituicao: instituicao ?? this.instituicao,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }
}
