import 'package:cloud_firestore/cloud_firestore.dart';

import 'aluno.dart';

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}

class Turma {
  final String id;
  final String nome;
  final String ano;
  final String disciplina;
  final String periodo;
  final List<Aluno> alunos;
  final int? quantidadeAlunos;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  Turma({
    required this.id,
    required this.nome,
    required this.ano,
    required this.disciplina,
    required this.periodo,
    required this.alunos,
    this.quantidadeAlunos,
    this.criadoEm,
    this.atualizadoEm,
  });

  int get totalAlunos => quantidadeAlunos ?? alunos.length;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'ano': ano,
      'disciplina': disciplina,
      'periodo': periodo,
      'quantidadeAlunos': totalAlunos,
      'criadoEm': criadoEm?.toIso8601String(),
      'atualizadoEm': atualizadoEm?.toIso8601String(),
    };
  }

  /// Converte a turma para persistência no Firestore.
  /// IMPORTANTE: Conforme diretrizes de arquitetura, a lista completa de alunos
  /// NÃO é salva no documento da turma, residindo na subcoleção `/alunos`.
  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'ano': ano,
      'disciplina': disciplina,
      'periodo': periodo,
      'quantidadeAlunos': totalAlunos,
      'criadoEm': criadoEm != null
          ? Timestamp.fromDate(criadoEm!)
          : FieldValue.serverTimestamp(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    };
  }

  factory Turma.fromMap(
    Map<String, dynamic> map, {
    String? id,
    List<Aluno>? alunos,
  }) {
    final rawAlunos = map['alunos'];
    List<Aluno> resolvedAlunos = alunos ?? const [];

    if (alunos == null && rawAlunos is List) {
      resolvedAlunos = rawAlunos
          .map((item) => Aluno.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList();
    }

    final parsedQtd = (map['quantidadeAlunos'] as num?)?.toInt();

    return Turma(
      id: id ?? map['id'] as String? ?? '',
      nome: map['nome'] as String? ?? '',
      ano: map['ano'] as String? ?? '',
      disciplina: map['disciplina'] as String? ?? '',
      periodo: map['periodo'] as String? ?? '',
      alunos: resolvedAlunos,
      quantidadeAlunos: parsedQtd ?? resolvedAlunos.length,
      criadoEm: _parseDateTime(map['criadoEm']),
      atualizadoEm: _parseDateTime(map['atualizadoEm']),
    );
  }

  factory Turma.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    List<Aluno>? alunos,
  }) {
    final data = doc.data() ?? {};
    return Turma.fromMap(data, id: doc.id, alunos: alunos);
  }

  Turma copyWith({
    String? id,
    String? nome,
    String? ano,
    String? disciplina,
    String? periodo,
    List<Aluno>? alunos,
    int? quantidadeAlunos,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) {
    return Turma(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      ano: ano ?? this.ano,
      disciplina: disciplina ?? this.disciplina,
      periodo: periodo ?? this.periodo,
      alunos: alunos ?? this.alunos,
      quantidadeAlunos: quantidadeAlunos ?? this.quantidadeAlunos,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }
}