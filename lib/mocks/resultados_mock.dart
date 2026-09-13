import '../models/resultado.dart';
import 'provas_mock.dart';
import 'turmas_mock.dart';

ResultadoQuestao _questao(int numero, String correta, Map<String, int> contagens) {
  final total = contagens.values.fold<int>(0, (soma, valor) => soma + valor);

  final alternativas = contagens.entries
      .map(
        (entry) => AlternativaDistribuicao(
          letra: entry.key,
          quantidade: entry.value,
          percentual: total == 0 ? 0 : (entry.value / total) * 100,
          correta: entry.key == correta,
        ),
      )
      .toList();

  final acertos = contagens[correta] ?? 0;

  return ResultadoQuestao(
    numero: numero,
    alternativaCorreta: correta,
    percentualAcerto: total == 0 ? 0 : (acertos / total) * 100,
    alternativas: alternativas,
  );
}

final resultadoProva1 = ResultadoProva(
  prova: provasMock[0],
  media: 7.2,
  minimo: 3.0,
  maximo: 10.0,
  distribuicao: [
    FaixaDistribuicao(faixa: '0-2', quantidade: 0),
    FaixaDistribuicao(faixa: '2-4', quantidade: 1),
    FaixaDistribuicao(faixa: '4-6', quantidade: 0),
    FaixaDistribuicao(faixa: '6-8', quantidade: 1),
    FaixaDistribuicao(faixa: '8-10', quantidade: 3),
  ],
  porAluno: [
    ResultadoAluno(
      aluno: aluno,
      nota: 10.0,
      acertos: 10,
      alternativasMarcadas: ['A', 'B', 'C', 'A', 'D', 'B', 'A', 'C', 'A', 'B'],
    ),
    ResultadoAluno(
      aluno: aluno2,
      nota: 8.5,
      acertos: 8,
      alternativasMarcadas: ['A', 'B', 'C', 'A', 'D', 'B', 'A', 'C', 'D', 'B'],
    ),
    ResultadoAluno(
      aluno: aluno3,
      nota: 8.0,
      acertos: 8,
      alternativasMarcadas: ['A', 'B', 'D', 'A', 'D', 'B', 'A', 'C', 'A', 'B'],
    ),
    ResultadoAluno(
      aluno: aluno4,
      nota: 6.5,
      acertos: 7,
      alternativasMarcadas: ['A', 'C', 'C', 'A', 'D', 'A', 'A', 'C', 'A', 'D'],
    ),
    ResultadoAluno(
      aluno: aluno5,
      nota: 3.0,
      acertos: 3,
      alternativasMarcadas: ['B', 'C', 'D', 'B', 'A', 'A', 'B', 'D', 'C', 'B'],
    ),
  ],
  porQuestao: [
    _questao(1, 'A', {'A': 4, 'B': 1, 'C': 0, 'D': 0}),
    _questao(2, 'B', {'A': 1, 'B': 3, 'C': 1, 'D': 0}),
    _questao(3, 'C', {'A': 0, 'B': 0, 'C': 2, 'D': 3}),
    _questao(4, 'A', {'A': 3, 'B': 2, 'C': 0, 'D': 0}),
    _questao(5, 'D', {'A': 1, 'B': 0, 'C': 0, 'D': 4}),
    _questao(6, 'B', {'A': 2, 'B': 3, 'C': 0, 'D': 0}),
    _questao(7, 'A', {'A': 4, 'B': 1, 'C': 0, 'D': 0}),
    _questao(8, 'C', {'A': 0, 'B': 0, 'C': 4, 'D': 1}),
    _questao(9, 'A', {'A': 3, 'B': 0, 'C': 1, 'D': 1}),
    _questao(10, 'B', {'A': 1, 'B': 4, 'C': 0, 'D': 0}),
  ],
);

final resultadoProva2 = ResultadoProva(
  prova: provasMock[3],
  media: 6.0,
  minimo: 4.0,
  maximo: 8.0,
  distribuicao: [
    FaixaDistribuicao(faixa: '0-2', quantidade: 0),
    FaixaDistribuicao(faixa: '2-4', quantidade: 0),
    FaixaDistribuicao(faixa: '4-6', quantidade: 1),
    FaixaDistribuicao(faixa: '6-8', quantidade: 1),
    FaixaDistribuicao(faixa: '8-10', quantidade: 1),
  ],
  porAluno: [
    ResultadoAluno(
      aluno: aluno3,
      nota: 8.0,
      acertos: 10,
      alternativasMarcadas: [
        'A', 'B', 'C', 'A', 'D', 'B', 'A', 'C', 'A', 'B', 'C', 'A',
      ],
    ),
    ResultadoAluno(
      aluno: aluno4,
      nota: 6.0,
      acertos: 7,
      alternativasMarcadas: [
        'A', 'C', 'C', 'A', 'D', 'A', 'A', 'C', 'A', 'D', 'B', 'A',
      ],
    ),
    ResultadoAluno(
      aluno: aluno5,
      nota: 4.0,
      acertos: 5,
      alternativasMarcadas: [
        'B', 'C', 'D', 'B', 'A', 'A', 'B', 'D', 'C', 'B', 'D', 'C',
      ],
    ),
  ],
  porQuestao: [
    _questao(1, 'A', {'A': 2, 'B': 1, 'C': 0, 'D': 0}),
    _questao(2, 'B', {'A': 1, 'B': 2, 'C': 0, 'D': 0}),
    _questao(3, 'C', {'A': 0, 'B': 0, 'C': 2, 'D': 1}),
    _questao(4, 'A', {'A': 2, 'B': 0, 'C': 1, 'D': 0}),
    _questao(5, 'D', {'A': 0, 'B': 1, 'C': 0, 'D': 2}),
    _questao(6, 'A', {'A': 3, 'B': 0, 'C': 0, 'D': 0}),
    _questao(7, 'A', {'A': 2, 'B': 1, 'C': 0, 'D': 0}),
    _questao(8, 'C', {'A': 0, 'B': 1, 'C': 2, 'D': 0}),
    _questao(9, 'A', {'A': 1, 'B': 0, 'C': 1, 'D': 1}),
    _questao(10, 'D', {'A': 0, 'B': 1, 'C': 0, 'D': 2}),
    _questao(11, 'B', {'A': 0, 'B': 3, 'C': 0, 'D': 0}),
    _questao(12, 'C', {'A': 1, 'B': 0, 'C': 2, 'D': 0}),
  ],
);

final resultadosMock = [resultadoProva1, resultadoProva2];
