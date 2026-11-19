import 'questao.dart';

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
      'questoes': questoes.map((questao) => questao.toMap()).toList(),
      'gabarito': gabarito,
    };
  }

  factory VersaoProva.fromMap(Map<String, dynamic> map) {
    final rawQuestoes = map['questoes'] as List<dynamic>? ?? [];
    final rawGabarito = map['gabarito'] as List<dynamic>? ?? [];

    return VersaoProva(
      numero: (map['numero'] as num?)?.toInt() ?? 1,
      questoes: rawQuestoes
          .whereType<Map>()
          .map((questao) =>
              Questao.fromMap(Map<String, dynamic>.from(questao)))
          .toList(),
      gabarito: rawGabarito.map((resposta) => resposta.toString()).toList(),
    );
  }
}
