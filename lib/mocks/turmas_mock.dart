import '../models/aluno.dart';
import '../models/turma.dart';

final aluno = Aluno(
    id: '1',
    nome: 'Ana',
    ra: '323245',
);

final aluno2 = Aluno(
    id: '2',
    nome: 'Mateus',
    ra: '654321',
);

final aluno3 = Aluno(
    id: '3',
    nome: 'Thais',
    ra: '024579',
);

final aluno4 = Aluno(
    id: '4',
    nome: 'Felipe',
    ra: '848413',
);

final aluno5 = Aluno(
    id: '5',
    nome: 'Maria',
    ra: '961112',
);

final turma = Turma(
    id: '1',
    nome: '1° A',
    ano: '1º Ano',
    disciplina: 'Matemática',
    periodo: 'Manhã',
    alunos: [aluno, aluno2, aluno3, aluno4, aluno5],
);

final turma2 = Turma(
    id: '2',
    nome: '2° B',
    ano: '2º Ano',
    disciplina: 'Português',
    periodo: 'Tarde',
    alunos: [aluno, aluno2],
);

final turma3 = Turma(
    id: '3',
    nome: '3° C',
    ano: '3º Ano',
    disciplina: 'Química',
    periodo: 'Manhã',
    alunos: [aluno3, aluno4, aluno5],
);

final turmasMock = [
  turma,
  turma2,
  turma3,
];