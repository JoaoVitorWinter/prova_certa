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

    // Coordenadas recalibradas com a imagem enviada (698 x 636).
    // Centros das cinco colunas de círculos A, B, C, D e E.
    const centersX = <double>[0.374, 0.448, 0.523, 0.596, 0.670];

    // Centros aproximados da primeira e última linha da grelha.
    // A grelha mostrada tem 15 linhas. Para outras quantidades, os centros
    // são interpolados entre estes limites.
    const firstRowY = 0.326;
    const lastRowY = 0.956;

    final answers = <String?>[];
    final rowStep = quantidadeQuestoes == 1
        ? 0.0
        : (lastRowY - firstRowY) / (quantidadeQuestoes - 1);

    for (var q = 0; q < quantidadeQuestoes; q++) {
      final y = ((firstRowY + rowStep * q) * image.height).round();
      final darkness = <double>[];

      for (final xNorm in centersX) {
        final x = (xNorm * image.width).round();
        darkness.add(_circleFillScore(image, x, y));
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
        final luminance =
            0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b;
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
}
