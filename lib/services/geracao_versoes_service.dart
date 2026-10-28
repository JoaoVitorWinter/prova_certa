
import 'dart:math';

import '../models/alternativa.dart';
import '../models/questao.dart';

class VersaoProva {
  final int numero;
  final List<Questao> questoes;
  final List<String> gabarito;

  const VersaoProva({
    required this.numero,
    required this.questoes,
    required this.gabarito,
  });

  Map<String, dynamic> toMap() {
    return {
      'numero': numero,
      'questoes': questoes.map((q) => q.toMap()).toList(),
      'gabarito': gabarito,
    };
  }
}

class GeracaoVersoesService {
  final Random _random;

  GeracaoVersoesService({Random? random})
      : _random = random ?? Random();

  List<VersaoProva> gerarVersoes({
    required List<Questao> questoes,
    required bool embaralharQuestoes,
    required bool embaralharAlternativas,
    required int numeroVersoes,
  }) {
    if (questoes.isEmpty) {
      throw ArgumentError('Selecione pelo menos uma questão.');
    }

    if (numeroVersoes < 1) {
      throw ArgumentError(
        'O número de versões deve ser maior que zero.',
      );
    }

    final List<VersaoProva> versoes = [];

    for (int numero = 1; numero <= numeroVersoes; numero++) {
      final List<Questao> questoesDaVersao =
          List<Questao>.from(questoes);

      if (embaralharQuestoes) {
        questoesDaVersao.shuffle(_random);
      }

      final List<Questao> questoesProcessadas = [];

      for (final Questao questao in questoesDaVersao) {
        if (!embaralharAlternativas) {
          questoesProcessadas.add(questao);
          continue;
        }

        final List<Alternativa> alternativas =
            List<Alternativa>.from(questao.alternativas);

        final int indiceCorreto = alternativas.indexWhere(
          (alternativa) =>
              alternativa.letra.toUpperCase() ==
              questao.correta.toUpperCase(),
        );

        if (indiceCorreto == -1) {
          throw StateError(
            'A questão ${questao.id} não possui '
            'uma alternativa correta válida.',
          );
        }

        alternativas.shuffle(_random);

        final List<Alternativa> novasAlternativas = [];
        String novaLetraCorreta = '';

        for (int i = 0; i < alternativas.length; i++) {
          final Alternativa alternativa = alternativas[i];
          final String novaLetra =
              String.fromCharCode(65 + i);

          if (alternativa.letra.toUpperCase() ==
              questao.correta.toUpperCase()) {
            novaLetraCorreta = novaLetra;
          }

          novasAlternativas.add(
            Alternativa(
              letra: novaLetra,
              texto: alternativa.texto,
            ),
          );
        }

        if (novaLetraCorreta.isEmpty) {
          throw StateError(
            'Não foi possível atualizar o gabarito '
            'da questão ${questao.id}.',
          );
        }

        final Questao questaoAtualizada = questao.copyWith(
          alternativas: novasAlternativas,
          correta: novaLetraCorreta,
        );

        questoesProcessadas.add(questaoAtualizada);
      }

      final List<String> gabarito = questoesProcessadas
          .map((questao) => questao.correta)
          .toList();

      versoes.add(
        VersaoProva(
          numero: numero,
          questoes: questoesProcessadas,
          gabarito: gabarito,
        ),
      );
    }

    return versoes;
  }
}
