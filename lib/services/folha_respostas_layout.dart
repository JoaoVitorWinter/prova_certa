import 'dart:math' as math;

/// Geometria única da grade de respostas.
///
/// É usada tanto pelo gerador do PDF quanto pelo leitor da fotografia, para
/// que as posições das bolhas impressas e das bolhas lidas nunca divirjam.
///
/// Todas as medidas estão em pontos tipográficos (1/72 pol.) e são relativas
/// ao canto superior esquerdo do bloco de respostas. Os quatro quadrados
/// pretos nos cantos do bloco servem de referência para o leitor corrigir
/// enquadramento, rotação e perspectiva da foto.
class FolhaRespostasLayout {
  static const List<String> alternativas = ['A', 'B', 'C', 'D', 'E'];

  static const double largura = 510;
  static const double tamanhoMarcador = 14;

  /// Distância da borda do bloco até a tabela. Deixa um espaço em branco
  /// entre os marcadores e as linhas da tabela para que não se fundam na foto.
  static const double margemInterna = 24;
  static const double larguraColunaQuestao = 50;
  static const double alturaCabecalho = 22;
  static const double alturaLinha = 21;
  static const double diametroBolha = 14;

  final int quantidadeQuestoes;

  const FolhaRespostasLayout(this.quantidadeQuestoes)
      : assert(quantidadeQuestoes > 0);

  double get altura =>
      margemInterna * 2 + alturaCabecalho + alturaLinha * quantidadeQuestoes;

  double get tabelaEsquerda => margemInterna;
  double get tabelaTopo => margemInterna;
  double get larguraTabela => largura - 2 * margemInterna;
  double get alturaTabela =>
      alturaCabecalho + alturaLinha * quantidadeQuestoes;

  double get larguraColunaAlternativa =>
      (larguraTabela - larguraColunaQuestao) / alternativas.length;

  double centroXAlternativa(int indice) =>
      tabelaEsquerda +
      larguraColunaQuestao +
      larguraColunaAlternativa * (indice + 0.5);

  double centroYQuestao(int indice) =>
      tabelaTopo + alturaCabecalho + alturaLinha * (indice + 0.5);

  /// Centros dos marcadores: superior esquerdo, superior direito,
  /// inferior esquerdo e inferior direito.
  List<math.Point<double>> get centrosMarcadores {
    const meio = tamanhoMarcador / 2;
    return [
      const math.Point(meio, meio),
      const math.Point(largura - meio, meio),
      math.Point(meio, altura - meio),
      math.Point(largura - meio, altura - meio),
    ];
  }
}
