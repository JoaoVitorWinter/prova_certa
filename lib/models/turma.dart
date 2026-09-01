import 'aluno.dart';

class Turma {
    final String id;
    final String nome;
    final String ano;
    final String disciplina;
    final String periodo;
    final List<Aluno> alunos;

    Turma({
        required this.id,
        required this.nome,
        required this.ano,
        required this.disciplina,
        required this.periodo,
        required this.alunos
    });
}