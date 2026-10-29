import 'package:cloud_firestore/cloud_firestore.dart';

import 'questao.dart';
import 'turma.dart';

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}

enum ProvaStatus { ativa, encerrada, rascunho }

class Prova {
  final String id;
  final String nome;
  final Turma turma;
  final DateTime dataAplicacao;
  final int quantidadeQuestoes;
  final List<Object> questoes;
  final ProvaStatus status;
  final bool embaralharQuestoes;
  final bool embaralharAlternativas;
  final int numeroVersoes;
  final List<String>? gabaritoOficial;
  final List<String>? questoesIds;
  final Map<String, dynamic>? resumoResultado;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  Prova({
    required this.id,
    required this.nome,
    required this.turma,
    required this.dataAplicacao,
    required this.quantidadeQuestoes,
    required this.questoes,
    required this.status,
    this.embaralharQuestoes = false,
    this.embaralharAlternativas = false,
    this.numeroVersoes = 1,
    this.gabaritoOficial,
    this.questoesIds,
    this.resumoResultado,
    this.criadoEm,
    this.atualizadoEm,
  });

  List<String> extrairQuestoesIds() {
    if (questoesIds != null && questoesIds!.isNotEmpty) {
      return questoesIds!;
    }
    final ids = <String>[];
    for (final item in questoes) {
      if (item is Questao && item.id.isNotEmpty) {
        ids.add(item.id);
      } else if (item is String && item.isNotEmpty) {
        ids.add(item);
      } else if (item is Map && item['id'] is String) {
        ids.add(item['id'] as String);
      }
    }
    return ids;
  }

  List<Map<String, dynamic>> extrairQuestoesSnapshot() {
    final snapshot = <Map<String, dynamic>>[];
    for (final item in questoes) {
      if (item is Questao) {
        snapshot.add(item.toMap());
      } else if (item is Map) {
        final map = Map<String, dynamic>.from(item);
        if (map.containsKey('enunciado') && map.containsKey('alternativas')) {
          snapshot.add(map);
        }
      }
    }
    return snapshot;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'turmaId': turma.id,
      'turmaNome': turma.nome,
      'turmaAno': turma.ano,
      'turmaDisciplina': turma.disciplina,
      'turmaPeriodo': turma.periodo,
      'dataAplicacao': dataAplicacao.toIso8601String(),
      'quantidadeQuestoes': quantidadeQuestoes,
      'status': status.name,
      'embaralharQuestoes': embaralharQuestoes,
      'embaralharAlternativas': embaralharAlternativas,
      'numeroVersoes': numeroVersoes,
      'questoesIds': extrairQuestoesIds(),
      'questoesSnapshot': extrairQuestoesSnapshot(),
      'gabaritoOficial': gabaritoOficial,
      'resumoResultado': resumoResultado,
      'criadoEm': criadoEm?.toIso8601String(),
      'atualizadoEm': atualizadoEm?.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'turmaId': turma.id,
      'turmaNome': turma.nome,
      'turmaAno': turma.ano,
      'turmaDisciplina': turma.disciplina,
      'turmaPeriodo': turma.periodo,
      'dataAplicacao': Timestamp.fromDate(dataAplicacao),
      'quantidadeQuestoes': quantidadeQuestoes,
      'status': status.name,
      'embaralharQuestoes': embaralharQuestoes,
      'embaralharAlternativas': embaralharAlternativas,
      'numeroVersoes': numeroVersoes,
      'questoesIds': extrairQuestoesIds(),
      'questoesSnapshot': extrairQuestoesSnapshot(),
      if (gabaritoOficial != null) 'gabaritoOficial': gabaritoOficial,
      if (resumoResultado != null) 'resumoResultado': resumoResultado,
      'criadoEm': criadoEm != null
          ? Timestamp.fromDate(criadoEm!)
          : FieldValue.serverTimestamp(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    };
  }

  factory Prova.fromMap(
    Map<String, dynamic> map, {
    String? id,
    Turma? turma,
    List<Object>? questoes,
  }) {
    final resolvedTurma = turma ??
        Turma(
          id: map['turmaId'] as String? ?? '',
          nome: map['turmaNome'] as String? ?? '',
          ano: map['turmaAno'] as String? ?? '',
          disciplina: map['turmaDisciplina'] as String? ?? '',
          periodo: map['turmaPeriodo'] as String? ?? '',
          alunos: const [],
        );

    final statusStr = map['status'] as String? ?? 'rascunho';
    final parsedStatus = ProvaStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => ProvaStatus.rascunho,
    );

    List<Object> resolvedQuestoes = questoes ?? const [];
    if (questoes == null && map['questoesSnapshot'] is List) {
      final rawList = map['questoesSnapshot'] as List<dynamic>;
      resolvedQuestoes = rawList
          .map((item) => Questao.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList();
    }

    final rawIds = map['questoesIds'] as List<dynamic>?;
    final parsedIds = rawIds?.map((e) => e.toString()).toList();

    final rawGabarito = map['gabaritoOficial'] as List<dynamic>?;
    final parsedGabarito = rawGabarito?.map((e) => e.toString()).toList();

    final parsedResumo = map['resumoResultado'] is Map
        ? Map<String, dynamic>.from(map['resumoResultado'] as Map)
        : null;

    return Prova(
      id: id ?? map['id'] as String? ?? '',
      nome: map['nome'] as String? ?? '',
      turma: resolvedTurma,
      dataAplicacao: _parseDateTime(map['dataAplicacao']) ?? DateTime.now(),
      quantidadeQuestoes: (map['quantidadeQuestoes'] as num?)?.toInt() ?? 10,
      questoes: resolvedQuestoes,
      status: parsedStatus,
      embaralharQuestoes: map['embaralharQuestoes'] as bool? ?? false,
      embaralharAlternativas: map['embaralharAlternativas'] as bool? ?? false,
      numeroVersoes: (map['numeroVersoes'] as num?)?.toInt() ?? 1,
      gabaritoOficial: parsedGabarito,
      questoesIds: parsedIds,
      resumoResultado: parsedResumo,
      criadoEm: _parseDateTime(map['criadoEm']),
      atualizadoEm: _parseDateTime(map['atualizadoEm']),
    );
  }

  factory Prova.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    Turma? turma,
    List<Object>? questoes,
  }) {
    final data = doc.data() ?? {};
    return Prova.fromMap(data, id: doc.id, turma: turma, questoes: questoes);
  }

  Prova copyWith({
    String? id,
    String? nome,
    Turma? turma,
    DateTime? dataAplicacao,
    int? quantidadeQuestoes,
    List<Object>? questoes,
    ProvaStatus? status,
    bool? embaralharQuestoes,
    bool? embaralharAlternativas,
    int? numeroVersoes,
    List<String>? gabaritoOficial,
    List<String>? questoesIds,
    Map<String, dynamic>? resumoResultado,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) {
    return Prova(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      turma: turma ?? this.turma,
      dataAplicacao: dataAplicacao ?? this.dataAplicacao,
      quantidadeQuestoes: quantidadeQuestoes ?? this.quantidadeQuestoes,
      questoes: questoes ?? this.questoes,
      status: status ?? this.status,
      embaralharQuestoes: embaralharQuestoes ?? this.embaralharQuestoes,
      embaralharAlternativas: embaralharAlternativas ?? this.embaralharAlternativas,
      numeroVersoes: numeroVersoes ?? this.numeroVersoes,
      gabaritoOficial: gabaritoOficial ?? this.gabaritoOficial,
      questoesIds: questoesIds ?? this.questoesIds,
      resumoResultado: resumoResultado ?? this.resumoResultado,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }
}
