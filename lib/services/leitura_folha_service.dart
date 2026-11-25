import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Leitor experimental calibrado para a imagem de folha enviada.
///
/// A folha deve aparecer inteira, direita e aproximadamente centrada na foto.
/// Esta versão usa proporções relativas ao enquadramento, por isso ainda pode
/// falhar se a fotografia tiver margens/cortes diferentes. Sempre confirmar
/// as respostas antes de guardar a nota.
class LeituraFolhaService {
  static const List<String> alternativas = ['A', 'B', 'C', 'D', 'E'];

  List<String?> lerRespostas({
    required Uint8List bytesImagem,
    required int quantidadeQuestoes,
  }) {
    if (quantidadeQuestoes < 1) {
      throw ArgumentError.value(
        quantidadeQuestoes,
        'quantidadeQuestoes',
        'Deve ser pelo menos 1.',
      );
    }

    final decoded = img.decodeImage(bytesImagem);
    if (decoded == null) {
      throw const FormatException('Não foi possível abrir a fotografia.');
    }

    final image = img.bakeOrientation(decoded);
    if (image.width < 300 || image.height < 400) {
      throw const FormatException(
        'Imagem pequena demais. Fotografe a folha inteira com boa iluminação.',
      );
    }

    // Nova folha A4 em retrato: duas colunas de até 10 questões.
    // Q1-10 ficam à esquerda; Q11-20 à direita.
    const leftCentersX = <double>[0.178, 0.249, 0.321, 0.392, 0.463];
    const rightCentersX = <double>[0.615, 0.686, 0.757, 0.828, 0.899];
    const firstRowY = 0.315;
    const lastRowY = 0.555;
    final rowsPorColuna = (quantidadeQuestoes / 2).ceil();
    final answers = <String?>[];

    for (var q = 0; q < quantidadeQuestoes; q++) {
      final isSecondColumn = q >= rowsPorColuna;
      final rowIndex = isSecondColumn ? q - rowsPorColuna : q;
      final y = rowsPorColuna == 1
          ? (firstRowY * image.height).round()
          : ((firstRowY +
                        (lastRowY - firstRowY) *
                            rowIndex /
                            (rowsPorColuna - 1)) *
                    image.height)
                .round();
      final centersX = isSecondColumn ? rightCentersX : leftCentersX;
      final darkness = <double>[];

      for (final xNorm in centersX) {
        darkness.add(_melhorScoreNaVizinhanca(image, xNorm, y));
      }

      final ranked = List<double>.from(darkness)..sort();
      final highest = ranked.last;
      final secondHighest = ranked[ranked.length - 2];

      // Requer preenchimento escuro e diferença suficiente para a segunda
      // alternativa. Caso contrário, devolve null para revisão manual.
      if (highest < 0.28 || highest - secondHighest < 0.10) {
        answers.add(null);
      } else {
        answers.add(alternativas[darkness.indexOf(highest)]);
      }
    }

    return answers;
  }

  double _circleFillScore(img.Image image, int centerX, int centerY) {
    // Mede sobretudo o interior do círculo, sem apanhar demasiada grelha.
    final radius = math.max(2, (image.width * 0.010).round());
    var count = 0;
    var darkPixels = 0;
    var luminanceSum = 0.0;

    for (var y = centerY - radius; y <= centerY + radius; y++) {
      if (y < 0 || y >= image.height) continue;

      for (var x = centerX - radius; x <= centerX + radius; x++) {
        if (x < 0 || x >= image.width) continue;

        final dx = x - centerX;
        final dy = y - centerY;
        // Usa uma região circular para reduzir a influência das linhas da tabela.
        if (dx * dx + dy * dy > radius * radius) continue;

        final pixel = image.getPixel(x, y);
        final luminance = 0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b;
        luminanceSum += luminance;
        if (luminance < 90) darkPixels++;
        count++;
      }
    }

    if (count == 0) return 0;

    final darkRatio = darkPixels / count;
    final averageLuminance = luminanceSum / count;
    final darkness = (255 - averageLuminance) / 255;

    return (darkRatio * 0.75 + darkness * 0.25).clamp(0.0, 1.0);
  }

  double _melhorScoreNaVizinhanca(img.Image image, double xNorm, int y) {
    var melhor = 0.0;
    final deslocamentoY = math.max(3, (image.height * 0.012).round());
    final deslocamentoX = math.max(3, (image.width * 0.012).round());
    final centroX = (xNorm * image.width).round();

    for (var dy = -deslocamentoY; dy <= deslocamentoY; dy += 3) {
      for (var dx = -deslocamentoX; dx <= deslocamentoX; dx += 3) {
        final score = _circleFillScore(image, centroX + dx, y + dy);
        if (score > melhor) melhor = score;
      }
    }
    return melhor;
  }
}
