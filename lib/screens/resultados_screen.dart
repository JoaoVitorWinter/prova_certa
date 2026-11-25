import 'package:flutter/material.dart';

import '../models/resultado.dart';
import '../services/exportacao_service.dart';
import '../services/resultado_service.dart';
import '../widgets/app_bottom_navigation.dart';
import 'home_screen.dart';
import 'provas_screen.dart';
import 'turmas_screen.dart';
import 'corrigir_prova_screen.dart';

enum _ResultadosTab { visaoGeral, porQuestao, alunos }

enum _TipoExportacao { notas, questoes }

class ResultadosScreen extends StatefulWidget {
  final ResultadoService? resultadoService;

  // Prova que já abre selecionada (ex.: vindo da tela de correção concluída).
  final String? provaIdInicial;

  // Correção que não pôde ser gravada no Firestore; exibida só nesta sessão.
  final ResultadoProva? resultadoNaoSalvo;

  const ResultadosScreen({
    super.key,
    this.resultadoService,
    this.provaIdInicial,
    this.resultadoNaoSalvo,
  });

  @override
  State<ResultadosScreen> createState() => _ResultadosScreenState();
}

class _ResultadosScreenState extends State<ResultadosScreen> {
  late final Stream<List<ResultadoProva>> _resultadosStream;
  String? _provaSelecionadaId;
  _ResultadosTab _tab = _ResultadosTab.visaoGeral;
  bool _exportando = false;

  @override
  void initState() {
    super.initState();
    _provaSelecionadaId = widget.provaIdInicial;
    _resultadosStream = (widget.resultadoService ?? ResultadoService())
        .monitorarResultados();
  }

  List<ResultadoProva> _comResultadoLocal(List<ResultadoProva> salvos) {
    final local = widget.resultadoNaoSalvo;
    if (local == null) return salvos;
    return [local, ...salvos.where((r) => r.prova.id != local.prova.id)];
  }

  Future<void> _exportar(
    BuildContext context,
    ResultadoProva resultado,
    _TipoExportacao tipo,
  ) async {
    if (_exportando) return;

    if (resultado.porAluno.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não há notas para exportar nesta prova.'),
        ),
      );
      return;
    }

    setState(() => _exportando = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final notas = tipo == _TipoExportacao.notas;
      await ExportacaoService.exportar(
        conteudo: notas
            ? ExportacaoService.gerarCsvNotas(resultado)
            : ExportacaoService.gerarCsvQuestoes(resultado),
        nomeArquivo: ExportacaoService.nomeArquivo(
          notas ? 'notas' : 'analise_questoes',
          resultado,
        ),
        assunto:
            '${notas ? 'Notas' : 'Análise por questão'} — '
            '${resultado.prova.nome}',
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Não foi possível exportar o arquivo: $e')),
      );
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Resultados',
              style: TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            Text(
              'Provas corrigidas',
              style: TextStyle(
                color: Color(0xFF5146EE),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: StreamBuilder<List<ResultadoProva>>(
                stream: _resultadosStream,
                builder: (context, snapshot) {
                  final resultados = _comResultadoLocal(
                    snapshot.data ?? const [],
                  );

                  if (resultados.isEmpty) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF5146EE),
                        ),
                      );
                    }
                    return _EstadoVazio(
                      erro: snapshot.hasError,
                      onCorrigir: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CorrigirProvaScreen(),
                        ),
                      ),
                    );
                  }

                  var selecionado = resultados.indexWhere(
                    (r) => r.prova.id == _provaSelecionadaId,
                  );
                  if (selecionado < 0) selecionado = 0;
                  final resultado = resultados[selecionado];

                  return ListView(
                    padding: const EdgeInsets.all(14),
                    children: [
                      _ProvaSelector(
                        resultados: resultados,
                        selecionado: selecionado,
                        onSelecionado: (index) => setState(
                          () =>
                              _provaSelecionadaId = resultados[index].prova.id,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _TabsBar(
                        selecionada: _tab,
                        onSelecionada: (tab) => setState(() => _tab = tab),
                      ),
                      const SizedBox(height: 14),
                      switch (_tab) {
                        _ResultadosTab.visaoGeral => _VisaoGeralTab(
                          resultado: resultado,
                        ),
                        _ResultadosTab.porQuestao => _PorQuestaoTab(
                          resultado: resultado,
                        ),
                        _ResultadosTab.alunos => _AlunosTab(
                          resultado: resultado,
                        ),
                      },
                      const SizedBox(height: 14),
                      _ExportarCard(
                        exportando: _exportando,
                        onExportar: (tipo) =>
                            _exportar(context, resultado, tipo),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          AppBottomNavigation(
            currentItem: AppNavigationItem.resultados,
            onInicio: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
            onProvas: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProvasScreen()),
              );
            },
            onCorrigir: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const CorrigirProvaScreen(),
                ),
              );
            },
            onTurmas: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const TurmasScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EstadoVazio extends StatelessWidget {
  final bool erro;
  final VoidCallback onCorrigir;

  const _EstadoVazio({required this.erro, required this.onCorrigir});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                color: Color(0xFF4A58F4),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              erro
                  ? 'Não foi possível carregar os resultados'
                  : 'Nenhuma prova corrigida ainda',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              erro
                  ? 'Verifique sua conexão e se você está conectado à sua conta.'
                  : 'Corrija uma prova para ver a média da turma, '
                        'o desempenho por questão e as notas de cada aluno.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF8A99AE), fontSize: 12),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onCorrigir,
              icon: const Icon(Icons.document_scanner_outlined, size: 18),
              label: const Text('Corrigir prova'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5647E8),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProvaSelector extends StatelessWidget {
  final List<ResultadoProva> resultados;
  final int selecionado;
  final ValueChanged<int> onSelecionado;

  const _ProvaSelector({
    required this.resultados,
    required this.selecionado,
    required this.onSelecionado,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: resultados.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final resultado = resultados[index];
          final selected = index == selecionado;

          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onSelecionado(index),
            child: Container(
              width: 190,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF5547EA) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D1B2740),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    resultado.prova.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF101827),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    resultado.prova.turma.nome,
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFFDCD7FF)
                          : const Color(0xFF8A99AE),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TabsBar extends StatelessWidget {
  final _ResultadosTab selecionada;
  final ValueChanged<_ResultadosTab> onSelecionada;

  const _TabsBar({required this.selecionada, required this.onSelecionada});

  @override
  Widget build(BuildContext context) {
    const abas = [
      (tab: _ResultadosTab.visaoGeral, label: 'Visão Geral'),
      (tab: _ResultadosTab.porQuestao, label: 'Por Questão'),
      (tab: _ResultadosTab.alunos, label: 'Alunos'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE4E9F1))),
      ),
      child: Row(
        children: abas.map((aba) {
          final selected = aba.tab == selecionada;

          return Expanded(
            child: InkWell(
              onTap: () => onSelecionada(aba.tab),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    Text(
                      aba.label,
                      style: TextStyle(
                        fontSize: 13,
                        color: selected
                            ? const Color(0xFF101827)
                            : const Color(0xFF8A99AE),
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 3,
                      width: 28,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF5547EA)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _VisaoGeralTab extends StatelessWidget {
  final ResultadoProva resultado;

  const _VisaoGeralTab({required this.resultado});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                valor: resultado.media.toStringAsFixed(1),
                titulo: 'Média',
                cor: const Color(0xFF3A68D3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                valor: resultado.minimo.toStringAsFixed(1),
                titulo: 'Mínimo',
                cor: const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                valor: resultado.maximo.toStringAsFixed(1),
                titulo: 'Máximo',
                cor: const Color(0xFF00A879),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D1B2740),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Distribuição de notas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF101827),
                ),
              ),
              const SizedBox(height: 18),
              _DistribuicaoChart(distribuicao: resultado.distribuicao),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String valor;
  final String titulo;
  final Color cor;

  const _StatCard({
    required this.valor,
    required this.titulo,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D1B2740),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            valor,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _DistribuicaoChart extends StatelessWidget {
  final List<FaixaDistribuicao> distribuicao;

  const _DistribuicaoChart({required this.distribuicao});

  static const _cores = [
    Color(0xFFDC2626),
    Color(0xFFE8790C),
    Color(0xFFF5A623),
    Color(0xFF0891B2),
    Color(0xFF00A879),
  ];

  @override
  Widget build(BuildContext context) {
    final maiorValor = distribuicao
        .map((faixa) => faixa.quantidade)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final escala = maiorValor == 0 ? 1 : maiorValor;

    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(distribuicao.length, (index) {
          final faixa = distribuicao[index];
          final altura = faixa.quantidade == 0
              ? 0.0
              : (faixa.quantidade / escala) * 90;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${faixa.quantidade}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: altura,
                    decoration: BoxDecoration(
                      color: _cores[index % _cores.length],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(height: 1, color: const Color(0xFFE4E9F1)),
                  const SizedBox(height: 8),
                  Text(
                    faixa.faixa,
                    style: const TextStyle(
                      color: Color(0xFF8A99AE),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _PorQuestaoTab extends StatelessWidget {
  final ResultadoProva resultado;

  const _PorQuestaoTab({required this.resultado});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: resultado.porQuestao
          .map(
            (questao) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _QuestaoCard(questao: questao),
            ),
          )
          .toList(),
    );
  }
}

class _QuestaoCard extends StatelessWidget {
  final ResultadoQuestao questao;

  const _QuestaoCard({required this.questao});

  ({String label, Color background, Color foreground}) get _acertoStyle {
    if (questao.percentualAcerto >= 70) {
      return (
        label: '${questao.percentualAcerto.round()}% de acerto',
        background: const Color(0xFFCFF7E3),
        foreground: const Color(0xFF087454),
      );
    }

    if (questao.percentualAcerto >= 40) {
      return (
        label: '${questao.percentualAcerto.round()}% de acerto',
        background: const Color(0xFFFFF0C5),
        foreground: const Color(0xFFB65D2E),
      );
    }

    return (
      label: '${questao.percentualAcerto.round()}% de acerto',
      background: const Color(0xFFFEE2E2),
      foreground: const Color(0xFFDC2626),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = _acertoStyle;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D1B2740),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Questão ${questao.numero}',
                  style: const TextStyle(
                    color: Color(0xFF101827),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: style.background,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  style.label,
                  style: TextStyle(
                    color: style.foreground,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...questao.alternativas.map(
            (alternativa) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _AlternativaBar(alternativa: alternativa),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlternativaBar extends StatelessWidget {
  final AlternativaDistribuicao alternativa;

  const _AlternativaBar({required this.alternativa});

  @override
  Widget build(BuildContext context) {
    final cor = alternativa.correta
        ? const Color(0xFF00A879)
        : const Color(0xFF94A3B8);

    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: alternativa.correta
                ? const Color(0xFFD1FAE5)
                : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: Text(
            alternativa.letra,
            style: TextStyle(
              color: alternativa.correta
                  ? const Color(0xFF059669)
                  : const Color(0xFF64748B),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: alternativa.percentual / 100,
                minHeight: 6,
                backgroundColor: const Color(0xFFE9EDF4),
                color: cor,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 62,
          child: Text(
            '${alternativa.quantidade} · ${alternativa.percentual.round()}%',
            textAlign: TextAlign.end,
            style: const TextStyle(color: Color(0xFF8A99AE), fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _AlunosTab extends StatelessWidget {
  final ResultadoProva resultado;

  const _AlunosTab({required this.resultado});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D1B2740),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Notas dos alunos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${resultado.porAluno.length} alunos',
                  style: const TextStyle(color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: resultado.porAluno.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return _ResultadoAlunoItem(
                resultado: resultado.porAluno[index],
                gabarito: [
                  for (final q in resultado.porQuestao) q.alternativaCorreta,
                ],
                index: index,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ResultadoAlunoItem extends StatelessWidget {
  final ResultadoAluno resultado;
  final List<String> gabarito;
  final int index;

  const _ResultadoAlunoItem({
    required this.resultado,
    required this.gabarito,
    required this.index,
  });

  void _abrirDetalhe(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          _DetalheAlunoSheet(resultado: resultado, gabarito: gabarito),
    );
  }

  ({Color background, Color foreground}) get _notaStyle {
    if (resultado.nota >= 7) {
      return (
        background: const Color(0xFFD1FAE5),
        foreground: const Color(0xFF059669),
      );
    }

    if (resultado.nota >= 5) {
      return (
        background: const Color(0xFFFFF0C5),
        foreground: const Color(0xFFB65D2E),
      );
    }

    return (
      background: const Color(0xFFFEE2E2),
      foreground: const Color(0xFFDC2626),
    );
  }

  static const _cores = [
    Color(0xFF5844E8),
    Color(0xFF9333EA),
    Color(0xFF059669),
    Color(0xFF0891B2),
    Color(0xFFEF2D2D),
    Color(0xFFE8790C),
  ];

  String get _iniciais {
    final partes = resultado.aluno.nome.trim().split(' ');

    if (partes.length == 1) {
      return partes.first[0].toUpperCase();
    }

    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final notaStyle = _notaStyle;

    return InkWell(
      onTap: () => _abrirDetalhe(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _cores[index % _cores.length],
              child: Text(
                _iniciais,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resultado.aluno.nome,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'RA: ${resultado.aluno.ra} · '
                    '${resultado.acertos}/${gabarito.length} acertos',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: notaStyle.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                resultado.nota.toStringAsFixed(1),
                style: TextStyle(
                  color: notaStyle.foreground,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetalheAlunoSheet extends StatelessWidget {
  final ResultadoAluno resultado;
  final List<String> gabarito;

  const _DetalheAlunoSheet({required this.resultado, required this.gabarito});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              resultado.aluno.nome,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              'RA ${resultado.aluno.ra} · nota ${resultado.nota.toStringAsFixed(1)} · '
              '${resultado.acertos}/${gabarito.length} acertos',
              style: const TextStyle(color: Color(0xFF8A99AE), fontSize: 12),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(gabarito.length, (i) {
                final marcada = i < resultado.alternativasMarcadas.length
                    ? resultado.alternativasMarcadas[i]
                    : '?';
                final correta = marcada == gabarito[i];

                return Container(
                  width: 62,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: correta
                        ? const Color(0xFFD8F3E8)
                        : const Color(0xFFFDE4E5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Q${i + 1}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        marcada,
                        style: TextStyle(
                          color: correta
                              ? const Color(0xFF12815E)
                              : const Color(0xFFBF404A),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!correta)
                        Text(
                          'certa: ${gabarito[i]}',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 9,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportarCard extends StatelessWidget {
  final ValueChanged<_TipoExportacao> onExportar;
  final bool exportando;

  const _ExportarCard({required this.onExportar, this.exportando = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D1B2740),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Exportar resultados',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              if (exportando)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _ExportItem(
            icon: Icons.grid_on_rounded,
            iconColor: const Color(0xFF00A978),
            iconBackground: const Color(0xFFD9F8E9),
            titulo: 'Notas dos alunos (.csv)',
            subtitulo: 'Nome, RA, nota e alternativas marcadas',
            onTap: () => onExportar(_TipoExportacao.notas),
          ),
          const SizedBox(height: 10),
          _ExportItem(
            icon: Icons.bar_chart_rounded,
            iconColor: const Color(0xFF4A58F4),
            iconBackground: const Color(0xFFEAF0FF),
            titulo: 'Análise por questão (.csv)',
            subtitulo: 'Alternativas mais escolhidas por questão',
            onTap: () => onExportar(_TipoExportacao.questoes),
          ),
        ],
      ),
    );
  }
}

class _ExportItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  const _ExportItem({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FB),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF101827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      color: Color(0xFF8A99AE),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }
}
