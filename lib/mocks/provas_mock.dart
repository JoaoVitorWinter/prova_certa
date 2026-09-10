import '../models/prova.dart';
import 'turmas_mock.dart';

final provasMock = [
  Prova(
    id: '1',
    nome: '1ª Prova Bimestral — Citologia',
    turma: turma,
    dataAplicacao: DateTime(2026, 8, 15),
    quantidadeQuestoes: 10,
    questoes: const [],
    status: ProvaStatus.encerrada,
  ),
  Prova(
    id: '2',
    nome: '2ª Prova Bimestral — Genética',
    turma: turma,
    dataAplicacao: DateTime(2026, 9, 20),
    quantidadeQuestoes: 10,
    questoes: const [],
    status: ProvaStatus.ativa,
  ),
  Prova(
    id: '3',
    nome: 'Simulado ENEM — Biologia',
    turma: turma2,
    dataAplicacao: DateTime(2026, 10, 5),
    quantidadeQuestoes: 15,
    questoes: const [],
    status: ProvaStatus.rascunho,
  ),
  Prova(
    id: '4',
    nome: '1ª Prova Bimestral — Ecologia',
    turma: turma3,
    dataAplicacao: DateTime(2026, 8, 22),
    quantidadeQuestoes: 12,
    questoes: const [],
    status: ProvaStatus.encerrada,
  ),
];
