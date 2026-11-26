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
    return {'faixa': faixa, 'quantidade': quantidade};
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
  final String texto;
  final int quantidade;
  final double percentual;
  final bool correta;

  AlternativaDistribuicao({
    required this.letra,
    this.texto = '',
    required this.quantidade,
    required this.percentual,
    required this.correta,
  });

  Map<String, dynamic> toMap() {
    return {
      'letra': letra,
      'texto': texto,
      'quantidade': quantidade,
      'percentual': percentual,
      'correta': correta,
    };
  }

  factory AlternativaDistribuicao.fromMap(Map<String, dynamic> map) {
    return AlternativaDistribuicao(
      letra: map['letra'] as String? ?? '',
      texto: map['texto'] as String? ?? '',
      quantidade: (map['quantidade'] as num?)?.toInt() ?? 0,
      percentual: (map['percentual'] as num?)?.toDouble() ?? 0.0,
      correta: map['correta'] as bool? ?? false,
    );
  }
}

class ResultadoQuestao {
  final int numero;
  final String enunciado;
  final String alternativaCorreta;
  final double percentualAcerto;
  final List<AlternativaDistribuicao> alternativas;

  ResultadoQuestao({
    required this.numero,
    this.enunciado = '',
    required this.alternativaCorreta,
    required this.percentualAcerto,
    required this.alternativas,
  });

  Map<String, dynamic> toMap() {
    return {
      'numero': numero,
      'enunciado': enunciado,
      'alternativaCorreta': alternativaCorreta,
      'percentualAcerto': percentualAcerto,
      'alternativas': alternativas.map((a) => a.toMap()).toList(),
    };
  }

  factory ResultadoQuestao.fromMap(Map<String, dynamic> map) {
    final rawAlternativas = map['alternativas'] as List<dynamic>? ?? [];
    final alternativas = rawAlternativas
        .map(
          (a) => AlternativaDistribuicao.fromMap(
            Map<String, dynamic>.from(a as Map),
          ),
        )
        .toList();

    return ResultadoQuestao(
      numero: (map['numero'] as num?)?.toInt() ?? 0,
      enunciado: map['enunciado'] as String? ?? '',
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
  final int? numeroVersao;
  final List<String>? gabaritoCorreto;
  final List<Map<String, dynamic>>? questoesSnapshot;
  final DateTime? corrigidoEm;

  ResultadoAluno({
    this.id,
    required this.aluno,
    required this.nota,
    required this.acertos,
    required this.alternativasMarcadas,
    this.provaId,
    this.turmaId,
    this.numeroVersao,
    this.gabaritoCorreto,
    this.questoesSnapshot,
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
      'numeroVersao': numeroVersao,
      'gabaritoCorreto': gabaritoCorreto,
      'questoesSnapshot': questoesSnapshot,
      'corrigidoEm': corrigidoEm?.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'alunoId': aluno.id,
      'alunoNome': aluno.nome,
      'alunoRa':
          aluno.ra, // Preserva explicitamente como String com zeros à esquerda
      'nota': nota,
      'acertos': acertos,
      'totalQuestoes': alternativasMarcadas.length,
      'alternativasMarcadas': alternativasMarcadas,
      if (provaId != null) 'provaId': provaId,
      if (turmaId != null) 'turmaId': turmaId,
      if (numeroVersao != null) 'numeroVersao': numeroVersao,
      if (gabaritoCorreto != null) 'gabaritoCorreto': gabaritoCorreto,
      if (questoesSnapshot != null) 'questoesSnapshot': questoesSnapshot,
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
    int? numeroVersao,
    List<Map<String, dynamic>>? questoesSnapshot,
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
      numeroVersao: numeroVersao,
      gabaritoCorreto: List<String>.from(gabarito),
      questoesSnapshot: questoesSnapshot,
      corrigidoEm: corrigidoEm ?? DateTime.now(),
    );
  }

  factory ResultadoAluno.fromMap(
    Map<String, dynamic> map, {
    String? id,
    Aluno? aluno,
  }) {
    final resolvedAluno =
        aluno ??
        Aluno(
          id: map['alunoId'] as String? ?? id ?? '',
          nome: map['alunoNome'] as String? ?? '',
          ra: map['alunoRa']?.toString() ?? '',
        );

    final rawMarcadas = map['alternativasMarcadas'] as List<dynamic>? ?? [];
    final marcadas = rawMarcadas.map((e) => e.toString()).toList();
    final rawGabarito = map['gabaritoCorreto'] as List<dynamic>? ?? [];
    final gabaritoCorreto = rawGabarito.map((e) => e.toString()).toList();
    final rawQuestoes = map['questoesSnapshot'] as List<dynamic>? ?? [];
    final questoesSnapshot = rawQuestoes
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return ResultadoAluno(
      id: id ?? map['id'] as String?,
      aluno: resolvedAluno,
      nota: (map['nota'] as num?)?.toDouble() ?? 0.0,
      acertos: (map['acertos'] as num?)?.toInt() ?? 0,
      alternativasMarcadas: marcadas,
      provaId: map['provaId'] as String?,
      turmaId: map['turmaId'] as String?,
      numeroVersao: (map['numeroVersao'] as num?)?.toInt(),
      gabaritoCorreto: gabaritoCorreto.isEmpty ? null : gabaritoCorreto,
      questoesSnapshot: questoesSnapshot.isEmpty ? null : questoesSnapshot,
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
    int? numeroVersao,
    List<String>? gabaritoCorreto,
    List<Map<String, dynamic>>? questoesSnapshot,
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
      numeroVersao: numeroVersao ?? this.numeroVersao,
      gabaritoCorreto: gabaritoCorreto ?? this.gabaritoCorreto,
      questoesSnapshot: questoesSnapshot ?? this.questoesSnapshot,
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
      ..sort(
        (a, b) =>
            a.aluno.nome.toLowerCase().compareTo(b.aluno.nome.toLowerCase()),
      );
    final notas = alunos.map((r) => r.nota).toList();

    final media = notas.isEmpty
        ? 0.0
        : notas.reduce((a, b) => a + b) / notas.length;
    final minimo = notas.isEmpty ? 0.0 : notas.reduce((a, b) => a < b ? a : b);
    final maximo = notas.isEmpty ? 0.0 : notas.reduce((a, b) => a > b ? a : b);

    final contagemFaixas = List<int>.filled(faixasNota.length, 0);
    for (final nota in notas) {
      final indice = (nota ~/ 2).clamp(0, faixasNota.length - 1);
      contagemFaixas[indice]++;
    }

    // Considera o gabarito individual de cada aluno ao agregar por questão.
    final usaE =
        gabarito.contains('E') ||
        alunos.any(
          (r) =>
              r.gabaritoCorreto?.contains('E') == true ||
              r.alternativasMarcadas.contains('E'),
        );
    final letras = ['A', 'B', 'C', 'D', if (usaE) 'E'];

    final porQuestao = <ResultadoQuestao>[];
    final questoesOriginais = prova.extrairQuestoesSnapshot();
    final questoesAgrupadas = <String, Map<String, dynamic>>{};

    List<Map<String, dynamic>>? resolverSnapshot(ResultadoAluno r) {
      if (r.questoesSnapshot != null) return r.questoesSnapshot;
      for (final versao in prova.versoes ?? const []) {
        if (versao.numero == r.numeroVersao) {
          final snapshot = <Map<String, dynamic>>[];
          for (final questao in versao.questoes) {
            snapshot.add(Map<String, dynamic>.from(questao.toMap()));
          }
          return snapshot;
        }
      }
      if (questoesOriginais.isNotEmpty) return questoesOriginais;
      if (gabarito.isNotEmpty) {
        return List<Map<String, dynamic>>.generate(
          gabarito.length,
          (i) => <String, dynamic>{},
        );
      }
      return null;
    }

    for (var i = 0; i < questoesOriginais.length; i++) {
      final questao = questoesOriginais[i];
      final id = questao['id']?.toString().trim();
      questoesAgrupadas['${id?.isNotEmpty == true ? id : 'posicao_$i'}'] =
          questao;
    }
    if (questoesAgrupadas.isEmpty) {
      for (var i = 0; i < gabarito.length; i++) {
        questoesAgrupadas['posicao_$i'] = <String, dynamic>{};
      }
    }

    for (final r in alunos) {
      final snapshot = resolverSnapshot(r);
      if (snapshot == null) continue;
      for (var i = 0; i < snapshot.length; i++) {
        final questao = snapshot[i];
        final id = questao['id']?.toString().trim();
        final chave = id?.isNotEmpty == true ? id! : 'posicao_$i';
        questoesAgrupadas.putIfAbsent(chave, () => questao);
      }
    }

    var numero = 1;
    for (final entrada in questoesAgrupadas.entries) {
      final chave = entrada.key;
      final questaoCanonical = entrada.value;
      final enunciado = questaoCanonical['enunciado']?.toString() ?? '';
      final alternativasOriginais = <String, String>{};
      final rawAlternativas =
          questaoCanonical['alternativas'] as List<dynamic>? ?? const [];
      for (final raw in rawAlternativas) {
        if (raw is Map) {
          final letra = raw['letra']?.toString() ?? '';
          final texto = raw['texto']?.toString() ?? '';
          if (letra.isNotEmpty) alternativasOriginais[letra] = texto;
        }
      }

      var totalAplicavel = 0;
      var acertos = 0;
      final contagem = <String, int>{for (final letra in letras) letra: 0};
      final gabaritosNaQuestao = <String>{};

      for (final r in alunos) {
        final snapshot = resolverSnapshot(r);
        if (snapshot == null) continue;

        for (var i = 0; i < snapshot.length; i++) {
          final questao = snapshot[i];
          final id = questao['id']?.toString().trim();
          final chaveAluno = id?.isNotEmpty == true ? id! : 'posicao_$i';
          if (chaveAluno != chave) continue;

          final gabaritoAluno = r.gabaritoCorreto ?? gabarito;
          if (i >= gabaritoAluno.length || i >= r.alternativasMarcadas.length) {
            continue;
          }

          final marcadaVersao = r.alternativasMarcadas[i].trim().toUpperCase();
          final corretaVersao = gabaritoAluno[i].trim().toUpperCase();
          final mappingVersaoParaOriginal = <String, String>{};
          final rawAlternativas =
              questao['alternativas'] as List<dynamic>? ?? const [];
          for (final raw in rawAlternativas) {
            if (raw is Map) {
              final letraVersao =
                  raw['letra']?.toString().trim().toUpperCase() ?? '';
              final letraOriginal =
                  raw['letraOriginal']?.toString().trim().toUpperCase() ??
                  letraVersao;
              if (letraVersao.isNotEmpty) {
                mappingVersaoParaOriginal[letraVersao] = letraOriginal;
              }
            }
          }
          final marcadaOriginal =
              mappingVersaoParaOriginal[marcadaVersao] ?? marcadaVersao;
          final corretaOriginal =
              mappingVersaoParaOriginal[corretaVersao] ?? corretaVersao;
          contagem[marcadaOriginal] = (contagem[marcadaOriginal] ?? 0) + 1;
          gabaritosNaQuestao.add(corretaOriginal);
          totalAplicavel++;
          if (marcadaOriginal == corretaOriginal) acertos++;
        }
      }

      final alternativas = letras.map((letra) {
        final quantidade = contagem[letra] ?? 0;
        return AlternativaDistribuicao(
          letra: letra,
          texto: alternativasOriginais[letra] ?? '',
          quantidade: quantidade,
          percentual: totalAplicavel == 0
              ? 0
              : (quantidade / totalAplicavel) * 100,
          correta: gabaritosNaQuestao.contains(letra),
        );
      }).toList();

      final gabaritosOrdenados = gabaritosNaQuestao.toList()..sort();
      porQuestao.add(
        ResultadoQuestao(
          numero: numero++,
          enunciado: enunciado,
          alternativaCorreta: gabaritosOrdenados.join(' / '),
          percentualAcerto: totalAplicavel == 0
              ? 0
              : (acertos / totalAplicavel) * 100,
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
          FaixaDistribuicao(
            faixa: faixasNota[i],
            quantidade: contagemFaixas[i],
          ),
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
        .map(
          (d) => FaixaDistribuicao.fromMap(Map<String, dynamic>.from(d as Map)),
        )
        .toList();

    final rawQuestoes = resumo['porQuestao'] as List<dynamic>? ?? [];
    final porQuestao = rawQuestoes
        .map(
          (q) => ResultadoQuestao.fromMap(Map<String, dynamic>.from(q as Map)),
        )
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
