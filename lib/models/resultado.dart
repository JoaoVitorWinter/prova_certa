import 'aluno.dart';
import 'prova.dart';

class FaixaDistribuicao {
  final String faixa;
  final int quantidade;

  FaixaDistribuicao({required this.faixa, required this.quantidade});
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
}

class ResultadoAluno {
  final Aluno aluno;
  final double nota;
  final int acertos;
  final List<String> alternativasMarcadas;

  ResultadoAluno({
    required this.aluno,
    required this.nota,
    required this.acertos,
    required this.alternativasMarcadas,
  });
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
}
