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

  /// Corrige as respostas de um aluno contra o gabarito. A nota vai de 0 a 10
  /// com uma casa decimal; respostas não identificadas ('?') contam como erro.
  factory ResultadoAluno.corrigir({
    required Aluno aluno,
    required List<String> respostas,
    required List<String> gabarito,
    String? provaId,
    String? turmaId,
    DateTime? corrigidoEm,
  }) {
    final marcadas = List<String>.generate(
      gabarito.length,
      (i) => i < respostas.length ? respostas[i].trim().toUpperCase() : '?',
    );

    var acertos = 0;
    for (var i = 0; i < gabarito.length; i++) {
      if (marcadas[i] == gabarito[i].trim().toUpperCase()) acertos++;
    }

    final nota = gabarito.isEmpty ? 0.0 : (acertos / gabarito.length) * 10;

    return ResultadoAluno(
      id: aluno.id,
      aluno: aluno,
      nota: double.parse(nota.toStringAsFixed(1)),
      acertos: acertos,
      alternativasMarcadas: marcadas,
      provaId: provaId,
      turmaId: turmaId,
      corrigidoEm: corrigidoEm ?? DateTime.now(),
    );
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

  static const faixasNota = ['0-2', '2-4', '4-6', '6-8', '8-10'];

  /// Calcula as estatísticas da prova (geral, por questão e por aluno)
  /// a partir dos resultados individuais já corrigidos.
  factory ResultadoProva.calcular({
    required Prova prova,
    required List<String> gabarito,
    required List<ResultadoAluno> porAluno,
  }) {
    final alunos = List<ResultadoAluno>.of(porAluno)
      ..sort((a, b) => a.aluno.nome.toLowerCase().compareTo(b.aluno.nome.toLowerCase()));
    final notas = alunos.map((r) => r.nota).toList();

    final media = notas.isEmpty ? 0.0 : notas.reduce((a, b) => a + b) / notas.length;
    final minimo = notas.isEmpty ? 0.0 : notas.reduce((a, b) => a < b ? a : b);
    final maximo = notas.isEmpty ? 0.0 : notas.reduce((a, b) => a > b ? a : b);

    final contagemFaixas = List<int>.filled(faixasNota.length, 0);
    for (final nota in notas) {
      final indice = (nota ~/ 2).clamp(0, faixasNota.length - 1);
      contagemFaixas[indice]++;
    }

    // Mostra sempre A–D; E só aparece se estiver no gabarito ou em alguma resposta.
    final usaE = gabarito.contains('E') ||
        alunos.any((r) => r.alternativasMarcadas.contains('E'));
    final letras = ['A', 'B', 'C', 'D', if (usaE) 'E'];

    final porQuestao = <ResultadoQuestao>[];
    for (var i = 0; i < gabarito.length; i++) {
      final correta = gabarito[i];
      final total = alunos.length;
      final alternativas = letras.map((letra) {
        final quantidade = alunos
            .where((r) => i < r.alternativasMarcadas.length && r.alternativasMarcadas[i] == letra)
            .length;
        return AlternativaDistribuicao(
          letra: letra,
          quantidade: quantidade,
          percentual: total == 0 ? 0 : (quantidade / total) * 100,
          correta: letra == correta,
        );
      }).toList();
      final acertos = alternativas
          .where((a) => a.correta)
          .fold<int>(0, (soma, a) => soma + a.quantidade);

      porQuestao.add(
        ResultadoQuestao(
          numero: i + 1,
          alternativaCorreta: correta,
          percentualAcerto: total == 0 ? 0 : (acertos / total) * 100,
          alternativas: alternativas,
        ),
      );
    }

    return ResultadoProva(
      prova: prova,
      media: double.parse(media.toStringAsFixed(1)),
      minimo: minimo,
      maximo: maximo,
      distribuicao: [
        for (var i = 0; i < faixasNota.length; i++)
          FaixaDistribuicao(faixa: faixasNota[i], quantidade: contagemFaixas[i]),
      ],
      porQuestao: porQuestao,
      porAluno: alunos,
    );
  }

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
