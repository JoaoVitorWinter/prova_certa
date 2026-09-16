import 'package:flutter/material.dart';

import '../mocks/provas_mock.dart';
import '../models/prova.dart';
import '../widgets/app_bottom_navigation.dart';
import 'gabarito_qr_screen.dart';
import 'home_screen.dart';
import 'provas_screen.dart';
import 'resultados_screen.dart';
import 'turmas_screen.dart';

class CorrigirProvaScreen extends StatefulWidget {
  const CorrigirProvaScreen({super.key});

  @override
  State<CorrigirProvaScreen> createState() => _CorrigirProvaScreenState();
}

class _CorrigirProvaScreenState extends State<CorrigirProvaScreen> {
  Prova? _provaSelecionada;

  List<Prova> get _provasParaCorrigir {
    return provasMock
        .where((prova) => prova.status == ProvaStatus.encerrada)
        .toList();
  }

  @override
  void initState() {
    super.initState();

    final provas = _provasParaCorrigir;

    if (provas.isNotEmpty) {
      _provaSelecionada = provas.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(13, 14, 13, 20),
                child: Column(
                  children: [
                    _buildSelecaoProva(),
                    const SizedBox(height: 18),
                    _buildComoFunciona(),
                  ],
                ),
              ),
            ),
            _buildBottomButton(),
            AppBottomNavigation(
              currentItem: AppNavigationItem.corrigir,
              onInicio: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              ),
              onProvas: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProvasScreen()),
              ),
              onResultados: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ResultadosScreen(),
                ),
              ),
              onTurmas: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const TurmasScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 58,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 17),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE4E9F1))),
      ),
      alignment: Alignment.centerLeft,
      child: const Text(
        'Corrigir Prova',
        style: TextStyle(
          color: Color(0xFF101827),
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSelecaoProva() {
    final provas = _provasParaCorrigir;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecionar prova',
            style: TextStyle(
              color: Color(0xFF172033),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),

          ...provas.map(
            (prova) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ProvaOption(
                prova: prova,
                selected: _provaSelecionada?.id == prova.id,
                onTap: () {
                  setState(() {
                    _provaSelecionada = prova;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComoFunciona() {
    final passos = [
      'Leia o QR code do gabarito da prova',
      'Escaneie cada folha de resposta do aluno',
      'O sistema corrige automaticamente e exibe a nota',
      'Ao finalizar, veja os resultados completos',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        border: Border.all(color: const Color(0xFFC9D4FF)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Como funciona',
            style: TextStyle(
              color: Color(0xFF4F43B8),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(
            passos.length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFF5547EA),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      passos[index],
                      style: const TextStyle(
                        color: Color(0xFF59667B),
                        fontSize: 10,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    final habilitado = _provaSelecionada != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 10),
      color: Colors.white,
      child: SizedBox(
        height: 40,
        child: ElevatedButton(
          onPressed: habilitado
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          GabaritoQrScreen(prova: _provaSelecionada!),
                    ),
                  );
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6345E8),
            disabledBackgroundColor: const Color(0xFFD8D9E2),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Iniciar correção',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _ProvaOption extends StatelessWidget {
  final Prova prova;
  final bool selected;
  final VoidCallback onTap;

  const _ProvaOption({
    required this.prova,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEEF0FF) : const Color(0xFFF8F9FB),
          border: Border.all(
            color: selected ? const Color(0xFF5146EE) : const Color(0xFFEEF0F4),
            width: selected ? 1.2 : 1,
          ),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xFF5146EE)
                      : const Color(0xFFD1D7E0),
                  width: 1.3,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF5146EE),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prova.nome,
                    style: const TextStyle(
                      color: Color(0xFF1A2435),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${prova.turma.nome} • ${_formatDate(prova.dataAplicacao)}',
                    style: const TextStyle(
                      color: Color(0xFF8895A7),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$year-$month-$day';
  }
}
