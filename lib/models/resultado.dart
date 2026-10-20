import 'package:cloud_firestore/cloud_firestore.dart';

import 'aluno.dart';
import 'prova.dart';

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}

class FaixaDistribuicao {
  final String faixa;
  final int quantidade;

  FaixaDistribuicao({required this.faixa, required this.quantidade});

  Map<String, dynamic> toMap() {
    return {
      'faixa': faixa,
      'quantidade': quantidade,
    };
  }

  factory FaixaDistribuicao.fromMap(Map<String, dynamic> map) {
    return FaixaDistribuicao(
      faixa: map['faixa'] as String? ?? '',
      quantidade: (map['quantidade'] as num?)?.toInt() ?? 0,
    );
  }
}

class AlternativaDistribuicao {
  final String letra;
  final int quantidade;
  final double percentual;
  final bool correta;

  AlternativaDistribuicao({
    required this.letra,
    required this.quantidade,
    required this.percentual,
    required this.correta,
  });

  Map<String, dynamic> toMap() {
    return {
      'letra': letra,
      'quantidade': quantidade,
      'percentual': percentual,
      'correta': correta,
    };
  }

  factory AlternativaDistribuicao.fromMap(Map<String, dynamic> map) {
    return AlternativaDistribuicao(
      letra: map['letra'] as String? ?? '',
      quantidade: (map['quantidade'] as num?)?.toInt() ?? 0,
      percentual: (map['percentual'] as num?)?.toDouble() ?? 0.0,
      correta: map['correta'] as bool? ?? false,
    );
  }
}

class ResultadoQuestao {
  final int numero;
  final String alternativaCorreta;
  final double percentualAcerto;
  final List<AlternativaDistribuicao> alternativas;

  ResultadoQuestao({
    required this.numero,
    required this.alternativaCorreta,
    required this.percentualAcerto,
    required this.alternativas,
  });

  Map<String, dynamic> toMap() {
    return {
      'numero': numero,
      'alternativaCorreta': alternativaCorreta,
      'percentualAcerto': percentualAcerto,
      'alternativas': alternativas.map((a) => a.toMap()).toList(),
    };
  }

  factory ResultadoQuestao.fromMap(Map<String, dynamic> map) {
    final rawAlternativas = map['alternativas'] as List<dynamic>? ?? [];
    final alternativas = rawAlternativas
        .map((a) => AlternativaDistribuicao.fromMap(Map<String, dynamic>.from(a as Map)))
        .toList();

    return ResultadoQuestao(
      numero: (map['numero'] as num?)?.toInt() ?? 0,
      alternativaCorreta: map['alternativaCorreta'] as String? ?? '',
      percentualAcerto: (map['percentualAcerto'] as num?)?.toDouble() ?? 0.0,
      alternativas: alternativas,
    );
  }
}

class ResultadoAluno {
  final String? id;
  final Aluno aluno;
  final double nota;
  final int acertos;
  final List<String> alternativasMarcadas;
  final String? provaId;
  final String? turmaId;
  final DateTime? corrigidoEm;

  ResultadoAluno({
    this.id,
    required this.aluno,
    required this.nota,
    required this.acertos,
    required this.alternativasMarcadas,
    this.provaId,
    this.turmaId,
    this.corrigidoEm,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id ?? aluno.id,
      'alunoId': aluno.id,
      'alunoNome': aluno.nome,
      'alunoRa': aluno.ra,
      'nota': nota,
      'acertos': acertos,
      'totalQuestoes': alternativasMarcadas.length,
      'alternativasMarcadas': alternativasMarcadas,
      'provaId': provaId,
      'turmaId': turmaId,
      'corrigidoEm': corrigidoEm?.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'alunoId': aluno.id,
      'alunoNome': aluno.nome,
      'alunoRa': aluno.ra, // Preserva explicitamente como String com zeros à esquerda
      'nota': nota,
      'acertos': acertos,
      'totalQuestoes': alternativasMarcadas.length,
      'alternativasMarcadas': alternativasMarcadas,
      if (provaId != null) 'provaId': provaId,
      if (turmaId != null) 'turmaId': turmaId,
      'corrigidoEm': corrigidoEm != null
          ? Timestamp.fromDate(corrigidoEm!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory ResultadoAluno.fromMap(
    Map<String, dynamic> map, {
    String? id,
    Aluno? aluno,
  }) {
    final resolvedAluno = aluno ??
        Aluno(
          id: map['alunoId'] as String? ?? id ?? '',
          nome: map['alunoNome'] as String? ?? '',
          ra: map['alunoRa']?.toString() ?? '',
        );

    final rawMarcadas = map['alternativasMarcadas'] as List<dynamic>? ?? [];
    final marcadas = rawMarcadas.map((e) => e.toString()).toList();

    return ResultadoAluno(
      id: id ?? map['id'] as String?,
      aluno: resolvedAluno,
      nota: (map['nota'] as num?)?.toDouble() ?? 0.0,
      acertos: (map['acertos'] as num?)?.toInt() ?? 0,
      alternativasMarcadas: marcadas,
      provaId: map['provaId'] as String?,
      turmaId: map['turmaId'] as String?,
      corrigidoEm: _parseDateTime(map['corrigidoEm']),
    );
  }

  factory ResultadoAluno.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    Aluno? aluno,
  }) {
    final data = doc.data() ?? {};
    return ResultadoAluno.fromMap(data, id: doc.id, aluno: aluno);
  }

  ResultadoAluno copyWith({
    String? id,
    Aluno? aluno,
    double? nota,
    int? acertos,
    List<String>? alternativasMarcadas,
    String? provaId,
    String? turmaId,
    DateTime? corrigidoEm,
  }) {
    return ResultadoAluno(
      id: id ?? this.id,
      aluno: aluno ?? this.aluno,
      nota: nota ?? this.nota,
      acertos: acertos ?? this.acertos,
      alternativasMarcadas: alternativasMarcadas ?? this.alternativasMarcadas,
      provaId: provaId ?? this.provaId,
      turmaId: turmaId ?? this.turmaId,
      corrigidoEm: corrigidoEm ?? this.corrigidoEm,
    );
  }
}

class ResultadoProva {
  final Prova prova;
  final double media;
  final double minimo;
  final double maximo;
  final List<FaixaDistribuicao> distribuicao;
  final List<ResultadoQuestao> porQuestao;
  final List<ResultadoAluno> porAluno;

  ResultadoProva({
    required this.prova,
    required this.media,
    required this.minimo,
    required this.maximo,
    required this.distribuicao,
    required this.porQuestao,
    required this.porAluno,
  });

  /// Serializa o resumo agregado estatístico para persistência no documento da Prova
  Map<String, dynamic> toFirestoreResumo() {
    return {
      'media': media,
      'minimo': minimo,
      'maximo': maximo,
      'totalFolhasCorrigidas': porAluno.length,
      'distribuicao': distribuicao.map((d) => d.toMap()).toList(),
      'porQuestao': porQuestao.map((q) => q.toMap()).toList(),
    };
  }

  factory ResultadoProva.fromResumo(
    Map<String, dynamic> resumo, {
    required Prova prova,
    List<ResultadoAluno>? porAluno,
  }) {
    final rawDistribuicao = resumo['distribuicao'] as List<dynamic>? ?? [];
    final distribuicao = rawDistribuicao
        .map((d) => FaixaDistribuicao.fromMap(Map<String, dynamic>.from(d as Map)))
        .toList();

    final rawQuestoes = resumo['porQuestao'] as List<dynamic>? ?? [];
    final porQuestao = rawQuestoes
        .map((q) => ResultadoQuestao.fromMap(Map<String, dynamic>.from(q as Map)))
        .toList();

    return ResultadoProva(
      prova: prova,
      media: (resumo['media'] as num?)?.toDouble() ?? 0.0,
      minimo: (resumo['minimo'] as num?)?.toDouble() ?? 0.0,
      maximo: (resumo['maximo'] as num?)?.toDouble() ?? 0.0,
      distribuicao: distribuicao,
      porQuestao: porQuestao,
      porAluno: porAluno ?? const [],
    );
  }
}
