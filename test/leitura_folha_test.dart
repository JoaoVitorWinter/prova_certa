import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:prova_certa/services/folha_respostas_layout.dart';
import 'package:prova_certa/services/leitura_folha_service.dart';

/// Gera uma "foto" sintética da folha de respostas: desenha a página
/// analiticamente (com a mesma geometria do PDF) e projeta com perspectiva,
/// iluminação desigual e ruído.
Uint8List _fotoSintetica({
  required int quantidade,
  required Map<int, List<int>> marcadas, // questão -> alternativas preenchidas
  required List<math.Point<double>> cantosPagina, // TL, TR, BL, BR em px
  int largura = 1080,
  int altura = 1440,
  bool semMarcadores = false,
  int semente = 1,
  double sombra = 0.35,
  Map<int, int> marcacaoFraca = const {},
}) {
  final layout = FolhaRespostasLayout(quantidade);
  // A4 em pt; o bloco começa a ~250 pt do topo, como no PDF real.
  const paginaL = 595.28, paginaA = 841.89;
  const blocoX = 42.52, blocoY = 250.0;

  final paraPagina = _homografia(cantosPagina, const [
    math.Point(0, 0),
    math.Point(paginaL, 0),
    math.Point(0, paginaA),
    math.Point(paginaL, paginaA),
  ]);

  final rnd = math.Random(semente);
  final qr = List.generate(45 * 45, (_) => rnd.nextBool());

  double tinta(double px, double py) {
    // Cabeçalho preto do topo da página.
    if (px > 42 && px < 553 && py > 42 && py < 92) return 0;
    // "QR code" aleatório.
    if (px > 460 && px < 552 && py > 105 && py < 197) {
      final i = ((px - 460) / 92 * 45).floor().clamp(0, 44);
      final j = ((py - 105) / 92 * 45).floor().clamp(0, 44);
      return qr[j * 45 + i] ? 0 : 1;
    }
    // Linhas de texto simuladas.
    if (px > 55 && px < 380 && ((py > 120 && py < 126) || (py > 150 && py < 156))) {
      return ((px / 4).floor() % 3 == 0) ? 1 : 0.1;
    }

    final x = px - blocoX, y = py - blocoY;
    if (x < 0 || y < 0 || x > FolhaRespostasLayout.largura || y > layout.altura) {
      return 1;
    }
    if (!semMarcadores) {
      for (final c in layout.centrosMarcadores) {
        if ((x - c.x).abs() <= 7 && (y - c.y).abs() <= 7) return 0;
      }
    }
    final esq = layout.tabelaEsquerda, topo = layout.tabelaTopo;
    final dir = esq + layout.larguraTabela, base = topo + layout.alturaTabela;
    if (x >= esq - .4 && x <= dir + .4 && y >= topo - .4 && y <= base + .4) {
      if ((x - esq).abs() < .4 || (x - dir).abs() < .4) return 0;
      if ((y - topo).abs() < .4 || (y - base).abs() < .4) return 0;
      for (var q = 0; q < quantidade; q++) {
        final ly = topo + FolhaRespostasLayout.alturaCabecalho +
            FolhaRespostasLayout.alturaLinha * q;
        if ((y - ly).abs() < .4) return 0;
      }
      for (var i = 0; i < 5; i++) {
        final lx = esq + FolhaRespostasLayout.larguraColunaQuestao +
            layout.larguraColunaAlternativa * i;
        if ((x - lx).abs() < .4) return 0;
      }
      for (var q = 0; q < quantidade; q++) {
        final cy = layout.centroYQuestao(q);
        if ((y - cy).abs() > 8) continue;
        for (var i = 0; i < 5; i++) {
          final cx = layout.centroXAlternativa(i);
          final d = math.sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy));
          if (d > 7.6) continue;
          if (marcadas[q]?.contains(i) == true && d < 6.8) return 0.08;
          if (marcacaoFraca[q] == i && d < 6.8) {
            // Só um risco diagonal fino.
            return ((x - cx) - (y - cy)).abs() < 1.2 ? 0.1 : 1;
          }
          if (d > 6.5) return 0; // contorno
        }
      }
      // Número da questão / letras do cabeçalho: um borrão pequeno.
      if (x < esq + FolhaRespostasLayout.larguraColunaQuestao &&
          y > topo + FolhaRespostasLayout.alturaCabecalho) {
        final q = ((y - topo - FolhaRespostasLayout.alturaCabecalho) /
                FolhaRespostasLayout.alturaLinha)
            .floor();
        final cy = layout.centroYQuestao(q);
        if ((x - esq - 25).abs() < 3 && (y - cy).abs() < 4) return 0.2;
      }
    }
    return 1;
  }

  final foto = img.Image(width: largura, height: altura);
  for (var py = 0; py < altura; py++) {
    for (var px = 0; px < largura; px++) {
      final p = paraPagina(px + .5, py + .5);
      double v;
      if (p.x < 0 || p.y < 0 || p.x > paginaL || p.y > paginaA) {
        v = 70; // mesa escura atrás da folha
      } else {
        v = 40 + 195 * tinta(p.x, p.y);
      }
      // Gradiente de iluminação (sombra de um lado) + ruído.
      v *= 1 - sombra * (px / largura) * (py / altura);
      v += (rnd.nextDouble() - .5) * 24;
      final c = v.clamp(0, 255).round();
      foto.setPixelRgb(px, py, c, c, (c * .95).round());
    }
  }
  return Uint8List.fromList(img.encodeJpg(foto, quality: 85));
}

/// Retorna a função que leva pontos de [origem] para [destino].
math.Point<double> Function(double, double) _homografia(
  List<math.Point<double>> origem,
  List<math.Point<double>> destino,
) {
  final a = List.generate(8, (_) => List<double>.filled(9, 0));
  for (var i = 0; i < 4; i++) {
    final x = origem[i].x, y = origem[i].y;
    final u = destino[i].x, v = destino[i].y;
    a[2 * i] = [x, y, 1, 0, 0, 0, -u * x, -u * y, u];
    a[2 * i + 1] = [0, 0, 0, x, y, 1, -v * x, -v * y, v];
  }
  for (var c = 0; c < 8; c++) {
    var p = c;
    for (var r = c + 1; r < 8; r++) {
      if (a[r][c].abs() > a[p][c].abs()) p = r;
    }
    final t = a[c];
    a[c] = a[p];
    a[p] = t;
    for (var r = 0; r < 8; r++) {
      if (r == c) continue;
      final f = a[r][c] / a[c][c];
      for (var k = c; k < 9; k++) {
        a[r][k] -= f * a[c][k];
      }
    }
  }
  final h = [for (var i = 0; i < 8; i++) a[i][8] / a[i][i], 1.0];
  return (x, y) {
    final w = h[6] * x + h[7] * y + h[8];
    return math.Point((h[0] * x + h[1] * y + h[2]) / w,
        (h[3] * x + h[4] * y + h[5]) / w);
  };
}

List<math.Point<double>> _retaCentralizada() => const [
      math.Point(60, 90),
      math.Point(1020, 90),
      math.Point(60, 1450 - 90),
      math.Point(1020, 1450 - 90),
    ];

void main() {
  final service = LeituraFolhaService();

  Map<int, List<int>> respostasDe(List<String> letras) => {
        for (var q = 0; q < letras.length; q++)
          q: [FolhaRespostasLayout.alternativas.indexOf(letras[q])],
      };

  group('LeituraFolhaService', () {
    for (final n in [5, 10, 15, 20]) {
      test('lê $n questões numa foto de frente', () {
        final gabarito = List.generate(
            n, (i) => FolhaRespostasLayout.alternativas[(i * 3 + 1) % 5]);
        final foto = _fotoSintetica(
          quantidade: n,
          marcadas: respostasDe(gabarito),
          cantosPagina: _retaCentralizada(),
          altura: 1450,
          semente: n,
        );
        expect(
          service.lerRespostas(bytesImagem: foto, quantidadeQuestoes: n),
          gabarito,
        );
      });
    }

    test('lê foto inclinada, rodada e com perspectiva', () {
      const n = 20;
      final gabarito = List.generate(
          n, (i) => FolhaRespostasLayout.alternativas[(i * 7 + 2) % 5]);
      final foto = _fotoSintetica(
        quantidade: n,
        marcadas: respostasDe(gabarito),
        // Topo mais estreito (perspectiva) e folha rodada ~6°.
        cantosPagina: const [
          math.Point(190, 120),
          math.Point(960, 200),
          math.Point(40, 1330),
          math.Point(1050, 1410),
        ],
        sombra: .5,
        semente: 42,
      );
      expect(
        service.lerRespostas(bytesImagem: foto, quantidadeQuestoes: n),
        gabarito,
      );
    });

    test('lê folha pequena na foto (fotografada de longe)', () {
      const n = 10;
      final gabarito = List.generate(
          n, (i) => FolhaRespostasLayout.alternativas[(i + 4) % 5]);
      final foto = _fotoSintetica(
        quantidade: n,
        marcadas: respostasDe(gabarito),
        cantosPagina: const [
          math.Point(300, 380),
          math.Point(780, 400),
          math.Point(290, 1060),
          math.Point(790, 1070),
        ],
        semente: 7,
      );
      expect(
        service.lerRespostas(bytesImagem: foto, quantidadeQuestoes: n),
        gabarito,
      );
    });

    test('devolve null para branco, marcação dupla e risco fraco', () {
      const n = 5;
      final foto = _fotoSintetica(
        quantidade: n,
        marcadas: {
          0: [0],
          1: [], // em branco
          2: [1, 3], // duas marcadas
          4: [4],
        },
        marcacaoFraca: {3: 2},
        cantosPagina: _retaCentralizada(),
        altura: 1450,
      );
      expect(
        service.lerRespostas(bytesImagem: foto, quantidadeQuestoes: n),
        ['A', null, null, null, 'E'],
      );
    });

    test('avisa quando os marcadores não aparecem', () {
      final foto = _fotoSintetica(
        quantidade: 5,
        marcadas: {0: [0]},
        cantosPagina: _retaCentralizada(),
        altura: 1450,
        semMarcadores: true,
      );
      expect(
        () => service.lerRespostas(bytesImagem: foto, quantidadeQuestoes: 5),
        throwsA(isA<LeituraFolhaException>()),
      );
    });

    test('rejeita quantidade inválida', () {
      expect(
        () => service.lerRespostas(
            bytesImagem: Uint8List(0), quantidadeQuestoes: 0),
        throwsArgumentError,
      );
    });
  });
}
