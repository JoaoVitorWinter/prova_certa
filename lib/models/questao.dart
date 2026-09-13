import 'alternativa.dart';

class Questao {
    final String id;
    final String enunciado;
    final List<Alternativa> alternativas;
    final String correta;
    final String assunto;
    final String dificuldade;
    final String disciplina;

    Questao({
        required this.id,
        required this.enunciado,
        required this.alternativas,
        required this.correta,
        required this.assunto,
        required this.dificuldade,
        required this.disciplina
    });
}
