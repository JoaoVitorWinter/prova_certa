import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'folha_respostas_layout.dart';

/// Erro de leitura com mensagem pronta para mostrar ao professor.
class LeituraFolhaException implements Exception {
  final String mensagem;

  const LeituraFolhaException(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Lê as marcações de uma fotografia da folha de respostas gerada pelo app.
///
/// Fluxo:
/// 1. converte a foto para tons de cinza e binariza com limiar adaptativo
///    (tolera sombras e iluminação desigual);
/// 2. localiza os quatro quadrados pretos dos cantos do bloco de respostas;
/// 3. calcula uma homografia entre o layout impresso
///    ([FolhaRespostasLayout]) e a foto, corrigindo enquadramento, rotação
///    e perspectiva;
/// 4. mede quanto de cada bolha está preenchido.
///
/// Questões sem marcação, com marcação fraca ou com mais de uma alternativa
/// marcada voltam como `null`, para conferência manual.
class LeituraFolhaService {
  static const List<String> alternativas = FolhaRespostasLayout.alternativas;

  /// Fração mínima do interior da bolha que precisa estar escura.
  static const double limiarMarcada = 0.40;

  /// Abaixo disto a bolha é considerada em branco (acima, mas abaixo de
  /// [limiarMarcada], é uma marcação duvidosa).
  static const double limiarDuvida = 0.20;

  static const int _ladoMaximo = 1600;

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
      throw const LeituraFolhaException('Não foi possível abrir a fotografia.');
    }

    var image = img.bakeOrientation(decoded);
    if (image.width < 300 || image.height < 300) {
      throw const LeituraFolhaException(
        'Imagem pequena demais. Fotografe a folha inteira com boa iluminação.',
      );
    }

    final maiorLado = math.max(image.width, image.height);
    if (maiorLado > _ladoMaximo) {
      final escala = _ladoMaximo / maiorLado;
      image = img.copyResize(
        image,
        width: (image.width * escala).round(),
        height: (image.height * escala).round(),
        interpolation: img.Interpolation.average,
      );
    }

    final imagem = _ImagemBinaria.de(image);
    final layout = FolhaRespostasLayout(quantidadeQuestoes);
    final marcadores = _localizarMarcadores(imagem, layout);
    if (marcadores == null) {
      throw const LeituraFolhaException(
        'Não foi possível localizar os 4 quadrados pretos dos cantos da '
        'grade de respostas. Fotografe a folha inteira, de frente, sem '
        'sombras fortes e com os quatro cantos visíveis.',
      );
    }

    final homografia = _Homografia.calcular(layout.centrosMarcadores, marcadores);
    if (homografia == null) {
      throw const LeituraFolhaException(
        'A folha está muito inclinada. Fotografe-a de frente.',
      );
    }

    final respostas = <String?>[];
    for (var q = 0; q < quantidadeQuestoes; q++) {
      final notas = <double>[
        for (var i = 0; i < alternativas.length; i++)
          _preenchimentoBolha(
            imagem,
            homografia,
            layout.centroXAlternativa(i),
            layout.centroYQuestao(q),
          ),
      ];
      respostas.add(_decidir(notas));
    }
    return respostas;
  }

  String? _decidir(List<double> notas) {
    var melhor = 0;
    for (var i = 1; i < notas.length; i++) {
      if (notas[i] > notas[melhor]) melhor = i;
    }
    final segunda = [
      for (var i = 0; i < notas.length; i++)
        if (i != melhor) notas[i],
    ].reduce(math.max);

    if (notas[melhor] < limiarMarcada) return null; // branco ou duvidosa
    if (segunda >= limiarMarcada) return null; // mais de uma marcada
    if (notas[melhor] - segunda < limiarDuvida) return null; // pouco contraste
    return alternativas[melhor];
  }

  /// Fração de pixels escuros no miolo da bolha (sem o contorno impresso).
  double _preenchimentoBolha(
    _ImagemBinaria imagem,
    _Homografia h,
    double xPt,
    double yPt,
  ) {
    final centro = h.aplicar(xPt, yPt);
    if (!centro.x.isFinite || !centro.y.isFinite) {
      throw const LeituraFolhaException(
        'Não foi possível alinhar a grade de respostas. Fotografe a folha de frente.',
      );
    }
    const raioPt = FolhaRespostasLayout.diametroBolha / 2;
    final rx = h.aplicar(xPt + raioPt, yPt).distanceTo(centro);
    final ry = h.aplicar(xPt, yPt + raioPt).distanceTo(centro);
    // Amostra só ~55% do raio para não contar a linha do círculo.
    final raio = math.max(1.5, 0.55 * (rx + ry) / 2);

    final cx = centro.x;
    final cy = centro.y;
    final x0 = (cx - raio).floor();
    final x1 = (cx + raio).ceil();
    final y0 = (cy - raio).floor();
    final y1 = (cy + raio).ceil();
    if (x0 < 0 || y0 < 0 || x1 >= imagem.largura || y1 >= imagem.altura) {
      throw const LeituraFolhaException(
        'Parte da grade de respostas ficou fora da foto. Enquadre a folha inteira.',
      );
    }

    var total = 0;
    var escuros = 0;
    final r2 = raio * raio;
    for (var y = y0; y <= y1; y++) {
      for (var x = x0; x <= x1; x++) {
        final dx = x - cx;
        final dy = y - cy;
        if (dx * dx + dy * dy > r2) continue;
        total++;
        if (imagem.escuro(x, y)) escuros++;
      }
    }
    return total == 0 ? 0 : escuros / total;
  }

  /// Procura, entre as manchas escuras e compactas da imagem, os quatro
  /// marcadores. Escolhe o maior quadrilátero cujos cantos têm tamanho
  /// compatível entre si e com a proporção esperada do bloco.
  List<math.Point<double>>? _localizarMarcadores(
    _ImagemBinaria imagem,
    FolhaRespostasLayout layout,
  ) {
    final menorLado = math.min(imagem.largura, imagem.altura);
    final ladoMin = math.max(4, menorLado * 0.006);
    final ladoMax = menorLado * 0.09;

    final candidatos = imagem
        .componentes(areaMinima: (ladoMin * ladoMin).round())
        .where((c) {
          final lado = math.sqrt(c.area);
          if (lado < ladoMin || lado > ladoMax) return false;
          final proporcao = c.larguraCaixa / c.alturaCaixa;
          if (proporcao < 0.6 || proporcao > 1.67) return false;
          // Quadrado cheio: >= 0.5 mesmo rodado 45°. Letras e contornos ficam
          // abaixo disso.
          return c.preenchimento >= 0.55;
        })
        .toList()
      ..sort((a, b) => b.area.compareTo(a.area));

    final lista = candidatos.length > 40 ? candidatos.sublist(0, 40) : candidatos;
    if (lista.length < 4) return null;

    final larguraEsperada =
        FolhaRespostasLayout.largura - FolhaRespostasLayout.tamanhoMarcador;
    final alturaEsperada = layout.altura - FolhaRespostasLayout.tamanhoMarcador;
    final proporcaoEsperada = alturaEsperada / larguraEsperada;
    const ladoMarcador = FolhaRespostasLayout.tamanhoMarcador;

    // Primeiro filtro: geometria plausível (tamanhos e proporção).
    final quadrilateros = <(double, List<math.Point<double>>)>[];
    final n = lista.length;
    for (var a = 0; a < n - 3; a++) {
      for (var b = a + 1; b < n - 2; b++) {
        for (var c = b + 1; c < n - 1; c++) {
          for (var d = c + 1; d < n; d++) {
            final grupo = [lista[a], lista[b], lista[c], lista[d]];
            final lados = grupo.map((g) => math.sqrt(g.area)).toList();
            final menor = lados.reduce(math.min);
            final maior = lados.reduce(math.max);
            if (maior / menor > 1.8) continue;

            final cantos = _ordenarCantos(grupo.map((g) => g.centro).toList());
            if (cantos == null) continue;
            final tl = cantos[0], tr = cantos[1], bl = cantos[2], br = cantos[3];

            final horizontal = (tl.distanceTo(tr) + bl.distanceTo(br)) / 2;
            final vertical = (tl.distanceTo(bl) + tr.distanceTo(br)) / 2;
            if (horizontal <= 0 || vertical <= 0) continue;

            final proporcao = (vertical / horizontal) / proporcaoEsperada;
            if (proporcao < 0.7 || proporcao > 1.43) continue;

            final escala = horizontal / larguraEsperada; // px por pt
            final ladoMedio = lados.reduce((x, y) => x + y) / 4;
            final relacaoTamanho = ladoMedio / (ladoMarcador * escala);
            if (relacaoTamanho < 0.6 || relacaoTamanho > 1.6) continue;

            quadrilateros.add((_areaQuadrilatero(tl, tr, br, bl), cantos));
          }
        }
      }
    }
    if (quadrilateros.isEmpty) return null;
    quadrilateros.sort((x, y) => y.$1.compareTo(x.$1));

    // Segundo filtro: confirma que a tabela impressa está onde o
    // quadrilátero diz que estaria. Elimina combinações acidentais de
    // manchas (QR code, texto, bolhas preenchidas).
    List<math.Point<double>>? melhor;
    var melhorNota = 0.55;
    for (final (_, cantos) in quadrilateros.take(400)) {
      final h = _Homografia.calcular(layout.centrosMarcadores, cantos);
      if (h == null) continue;
      final nota = _notaGrade(imagem, h, layout);
      if (nota > melhorNota) {
        melhorNota = nota;
        melhor = cantos;
      }
    }
    return melhor;
  }

  /// Fração das amostras sobre as linhas da tabela que estão escuras, menos a
  /// fração escura na faixa branca entre os marcadores e a tabela.
  double _notaGrade(
    _ImagemBinaria imagem,
    _Homografia h,
    FolhaRespostasLayout layout,
  ) {
    final esq = layout.tabelaEsquerda;
    final dir = esq + layout.larguraTabela;
    final topo = layout.tabelaTopo;
    final base = topo + layout.alturaTabela;

    // Tolerância: ~0.9 pt em pixels.
    final escala = h.aplicar(1, 0).distanceTo(h.aplicar(0, 0));
    if (!escala.isFinite || escala <= 0) return 0;
    final tol = (0.9 * escala).round().clamp(1, 4);

    bool escuroPerto(double x, double y) {
      final p = h.aplicar(x, y);
      if (!p.x.isFinite || !p.y.isFinite) return false;
      final cx = p.x.round(), cy = p.y.round();
      for (var dy = -tol; dy <= tol; dy++) {
        for (var dx = -tol; dx <= tol; dx++) {
          final px = cx + dx, py = cy + dy;
          if (px < 0 || py < 0 || px >= imagem.largura || py >= imagem.altura) {
            continue;
          }
          if (imagem.escuro(px, py)) return true;
        }
      }
      return false;
    }

    bool escuroNoPonto(double x, double y) {
      final p = h.aplicar(x, y);
      if (!p.x.isFinite || !p.y.isFinite) return false;
      final px = p.x.round(), py = p.y.round();
      if (px < 0 || py < 0 || px >= imagem.largura || py >= imagem.altura) {
        return false;
      }
      return imagem.escuro(px, py);
    }

    var acertos = 0;
    var amostras = 0;
    void linha(double x0, double y0, double x1, double y1, int passos) {
      for (var i = 1; i < passos; i++) {
        final t = i / passos;
        amostras++;
        if (escuroPerto(x0 + (x1 - x0) * t, y0 + (y1 - y0) * t)) acertos++;
      }
    }

    linha(esq, topo, dir, topo, 40);
    linha(esq, base, dir, base, 40);
    linha(esq, topo, esq, base, 30);
    linha(dir, topo, dir, base, 30);
    for (var i = 0; i < FolhaRespostasLayout.alternativas.length; i++) {
      final x = esq +
          FolhaRespostasLayout.larguraColunaQuestao +
          layout.larguraColunaAlternativa * i;
      linha(x, topo, x, base, 16);
    }
    final positivo = amostras == 0 ? 0.0 : acertos / amostras;

    // Faixa branca entre a borda dos marcadores e a tabela.
    const faixa =
        (FolhaRespostasLayout.tamanhoMarcador + FolhaRespostasLayout.margemInterna) / 2;
    var escurosFaixa = 0;
    var amostrasFaixa = 0;
    void faixaBranca(double x0, double y0, double x1, double y1) {
      for (var i = 1; i < 30; i++) {
        final t = i / 30;
        amostrasFaixa++;
        if (escuroNoPonto(x0 + (x1 - x0) * t, y0 + (y1 - y0) * t)) {
          escurosFaixa++;
        }
      }
    }

    final largura = FolhaRespostasLayout.largura;
    final altura = layout.altura;
    faixaBranca(faixa, faixa, largura - faixa, faixa);
    faixaBranca(faixa, altura - faixa, largura - faixa, altura - faixa);
    faixaBranca(faixa, faixa, faixa, altura - faixa);
    faixaBranca(largura - faixa, faixa, largura - faixa, altura - faixa);
    final negativo = escurosFaixa / amostrasFaixa;

    return positivo - negativo;
  }

  /// Ordena em [sup. esq., sup. dir., inf. esq., inf. dir.] e verifica se o
  /// quadrilátero é convexo.
  List<math.Point<double>>? _ordenarCantos(List<math.Point<double>> pontos) {
    final porY = [...pontos]..sort((a, b) => a.y.compareTo(b.y));
    final topo = porY.sublist(0, 2)..sort((a, b) => a.x.compareTo(b.x));
    final base = porY.sublist(2)..sort((a, b) => a.x.compareTo(b.x));
    final tl = topo[0], tr = topo[1], bl = base[0], br = base[1];

    final ciclo = [tl, tr, br, bl];
    double? sinal;
    for (var i = 0; i < 4; i++) {
      final p0 = ciclo[i];
      final p1 = ciclo[(i + 1) % 4];
      final p2 = ciclo[(i + 2) % 4];
      final cruz =
          (p1.x - p0.x) * (p2.y - p1.y) - (p1.y - p0.y) * (p2.x - p1.x);
      if (cruz == 0) return null;
      sinal ??= cruz.sign;
      if (cruz.sign != sinal) return null;
    }
    return [tl, tr, bl, br];
  }

  double _areaQuadrilatero(
    math.Point<double> a,
    math.Point<double> b,
    math.Point<double> c,
    math.Point<double> d,
  ) {
    final pts = [a, b, c, d];
    var soma = 0.0;
    for (var i = 0; i < 4; i++) {
      final p = pts[i];
      final q = pts[(i + 1) % 4];
      soma += p.x * q.y - q.x * p.y;
    }
    return soma.abs() / 2;
  }
}

class _Componente {
  int area = 0;
  int minX;
  int maxX;
  int minY;
  int maxY;
  double somaX = 0;
  double somaY = 0;

  _Componente(int x, int y) : minX = x, maxX = x, minY = y, maxY = y;

  int get larguraCaixa => maxX - minX + 1;
  int get alturaCaixa => maxY - minY + 1;
  double get preenchimento => area / (larguraCaixa * alturaCaixa);
  math.Point<double> get centro => math.Point(somaX / area, somaY / area);
}

/// Imagem em tons de cinza binarizada com limiar adaptativo (média local
/// calculada por imagem integral).
class _ImagemBinaria {
  final int largura;
  final int altura;
  final Uint8List _escuro;

  _ImagemBinaria._(this.largura, this.altura, this._escuro);

  factory _ImagemBinaria.de(img.Image image) {
    final w = image.width;
    final h = image.height;
    final cinza = Uint8List(w * h);
    var i = 0;
    for (final p in image) {
      final max = p.maxChannelValue;
      final lum = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b) * 255 / max;
      cinza[p.y * w + p.x] = lum.clamp(0, 255).round();
      i++;
    }
    assert(i == w * h);

    // Imagem integral para médias locais.
    final w1 = w + 1;
    final integral = Uint32List(w1 * (h + 1));
    for (var y = 0; y < h; y++) {
      var somaLinha = 0;
      for (var x = 0; x < w; x++) {
        somaLinha += cinza[y * w + x];
        integral[(y + 1) * w1 + x + 1] = integral[y * w1 + x + 1] + somaLinha;
      }
    }

    final raio = math.max(7, math.min(w, h) ~/ 16);
    final escuro = Uint8List(w * h);
    for (var y = 0; y < h; y++) {
      final ya = math.max(0, y - raio);
      final yb = math.min(h, y + raio + 1);
      for (var x = 0; x < w; x++) {
        final xa = math.max(0, x - raio);
        final xb = math.min(w, x + raio + 1);
        final soma = integral[yb * w1 + xb] -
            integral[ya * w1 + xb] -
            integral[yb * w1 + xa] +
            integral[ya * w1 + xa];
        final media = soma / ((xb - xa) * (yb - ya));
        final v = cinza[y * w + x];
        if (v < media * 0.78 && media - v > 18) escuro[y * w + x] = 1;
      }
    }
    return _ImagemBinaria._(w, h, escuro);
  }

  bool escuro(int x, int y) => _escuro[y * largura + x] == 1;

  /// Componentes conexos (vizinhança 4) de pixels escuros.
  List<_Componente> componentes({required int areaMinima}) {
    final visitado = Uint8List(largura * altura);
    final pilha = <int>[];
    final resultado = <_Componente>[];

    for (var inicio = 0; inicio < _escuro.length; inicio++) {
      if (_escuro[inicio] == 0 || visitado[inicio] == 1) continue;
      final comp = _Componente(inicio % largura, inicio ~/ largura);
      visitado[inicio] = 1;
      pilha.add(inicio);
      while (pilha.isNotEmpty) {
        final idx = pilha.removeLast();
        final x = idx % largura;
        final y = idx ~/ largura;
        comp
          ..area += 1
          ..somaX += x
          ..somaY += y;
        if (x < comp.minX) comp.minX = x;
        if (x > comp.maxX) comp.maxX = x;
        if (y < comp.minY) comp.minY = y;
        if (y > comp.maxY) comp.maxY = y;

        if (x > 0) _empilhar(idx - 1, visitado, pilha);
        if (x < largura - 1) _empilhar(idx + 1, visitado, pilha);
        if (y > 0) _empilhar(idx - largura, visitado, pilha);
        if (y < altura - 1) _empilhar(idx + largura, visitado, pilha);
      }
      if (comp.area >= areaMinima) resultado.add(comp);
    }
    return resultado;
  }

  void _empilhar(int idx, Uint8List visitado, List<int> pilha) {
    if (_escuro[idx] == 1 && visitado[idx] == 0) {
      visitado[idx] = 1;
      pilha.add(idx);
    }
  }
}

/// Transformação projetiva do plano do layout (pt) para a foto (px).
class _Homografia {
  final List<double> h; // 3x3, h[8] = 1

  _Homografia._(this.h);

  static _Homografia? calcular(
    List<math.Point<double>> origem,
    List<math.Point<double>> destino,
  ) {
    // Sistema 8x8: para cada par (x,y)->(u,v)
    // u = (h0 x + h1 y + h2) / (h6 x + h7 y + 1)
    // v = (h3 x + h4 y + h5) / (h6 x + h7 y + 1)
    final a = List.generate(8, (_) => List<double>.filled(9, 0));
    for (var i = 0; i < 4; i++) {
      final x = origem[i].x, y = origem[i].y;
      final u = destino[i].x, v = destino[i].y;
      a[2 * i] = [x, y, 1, 0, 0, 0, -u * x, -u * y, u];
      a[2 * i + 1] = [0, 0, 0, x, y, 1, -v * x, -v * y, v];
    }
    for (var col = 0; col < 8; col++) {
      var pivo = col;
      for (var r = col + 1; r < 8; r++) {
        if (a[r][col].abs() > a[pivo][col].abs()) pivo = r;
      }
      if (a[pivo][col].abs() < 1e-12) return null;
      final tmp = a[col];
      a[col] = a[pivo];
      a[pivo] = tmp;
      for (var r = 0; r < 8; r++) {
        if (r == col) continue;
        final f = a[r][col] / a[col][col];
        if (f == 0) continue;
        for (var k = col; k < 9; k++) {
          a[r][k] -= f * a[col][k];
        }
      }
    }
    final sol = [for (var i = 0; i < 8; i++) a[i][8] / a[i][i], 1.0];
    return _Homografia._(sol);
  }

  math.Point<double> aplicar(double x, double y) {
    final w = h[6] * x + h[7] * y + h[8];
    return math.Point(
      (h[0] * x + h[1] * y + h[2]) / w,
      (h[3] * x + h[4] * y + h[5]) / w,
    );
  }
}
