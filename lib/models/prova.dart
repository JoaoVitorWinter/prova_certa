import 'turma.dart';

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
  });
}
