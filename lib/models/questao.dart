import 'package:cloud_firestore/cloud_firestore.dart';

import 'alternativa.dart';

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}

class Questao {
  final String id;
  final String enunciado;
  final List<Alternativa> alternativas;
  final String correta;
  final String assunto;
  final String dificuldade;
  final String disciplina;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  Questao({
    required this.id,
    required this.enunciado,
    required this.alternativas,
    required this.correta,
    required this.assunto,
    required this.dificuldade,
    required this.disciplina,
    this.criadoEm,
    this.atualizadoEm,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enunciado': enunciado,
      'alternativas': alternativas.map((a) => a.toMap()).toList(),
      'correta': correta,
      'assunto': assunto,
      'dificuldade': dificuldade,
      'disciplina': disciplina,
      'criadoEm': criadoEm?.toIso8601String(),
      'atualizadoEm': atualizadoEm?.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'enunciado': enunciado,
      'alternativas': alternativas.map((a) => a.toFirestore()).toList(),
      'correta': correta,
      'assunto': assunto,
      'dificuldade': dificuldade,
      'disciplina': disciplina,
      'criadoEm': criadoEm != null
          ? Timestamp.fromDate(criadoEm!)
          : FieldValue.serverTimestamp(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    };
  }

  factory Questao.fromMap(Map<String, dynamic> map, {String? id}) {
    final rawAlternativas = map['alternativas'] as List<dynamic>? ?? [];
    final alternativas = rawAlternativas
        .map((a) => Alternativa.fromMap(Map<String, dynamic>.from(a as Map)))
        .toList();

    return Questao(
      id: id ?? map['id'] as String? ?? '',
      enunciado: map['enunciado'] as String? ?? '',
      alternativas: alternativas,
      correta: map['correta'] as String? ?? '',
      assunto: map['assunto'] as String? ?? '',
      dificuldade: map['dificuldade'] as String? ?? '',
      disciplina: map['disciplina'] as String? ?? '',
      criadoEm: _parseDateTime(map['criadoEm']),
      atualizadoEm: _parseDateTime(map['atualizadoEm']),
    );
  }

  factory Questao.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Questao.fromMap(data, id: doc.id);
  }

  Questao copyWith({
    String? id,
    String? enunciado,
    List<Alternativa>? alternativas,
    String? correta,
    String? assunto,
    String? dificuldade,
    String? disciplina,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) {
    return Questao(
      id: id ?? this.id,
      enunciado: enunciado ?? this.enunciado,
      alternativas: alternativas ?? this.alternativas,
      correta: correta ?? this.correta,
      assunto: assunto ?? this.assunto,
      dificuldade: dificuldade ?? this.dificuldade,
      disciplina: disciplina ?? this.disciplina,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }
}
