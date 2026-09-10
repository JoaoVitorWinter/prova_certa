import 'dart:async';

import 'package:flutter/material.dart';

import 'provas_screen.dart';

class NovaProvaScreen extends StatefulWidget {
  const NovaProvaScreen({super.key});

  @override
  State<NovaProvaScreen> createState() => _NovaProvaScreenState();
}

class _NovaProvaScreenState extends State<NovaProvaScreen> {
  int _etapa = 0;
  String _nome = '';
  int _quantidadeQuestoes = 10;
  bool _embaralharQuestoes = false;
  bool _embaralharAlternativas = false;
  int _numeroVersoes = 1;
  final Set<int> _questoesSelecionadas = {};

  void _avancar() {
    if (_etapa < 2) {
      setState(() => _etapa++);
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const _CriandoProvaScreen()),
    );
  }

  void _voltar() {
    if (_etapa == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() => _etapa--);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _WizardHeader(etapa: _etapa, onBack: _voltar),
            Expanded(
              child: IndexedStack(
                index: _etapa,
                children: [
                  _DadosStep(
                    nome: _nome,
                    quantidadeQuestoes: _quantidadeQuestoes,
                    onNameChanged: (value) => _nome = value,
                    onQuantityChanged: (value) =>
                        setState(() => _quantidadeQuestoes = value),
                  ),
                  _QuestoesStep(
                    selecionadas: _questoesSelecionadas,
                    onToggle: (index) => setState(() {
                      if (_questoesSelecionadas.contains(index)) {
                        _questoesSelecionadas.remove(index);
                      } else {
                        _questoesSelecionadas.add(index);
                      }
                    }),
                  ),
                  _GerarStep(
                    nome: _nome,
                    quantidadeQuestoes: _quantidadeQuestoes,
                    questoesSelecionadas: _questoesSelecionadas.length,
                    embaralharQuestoes: _embaralharQuestoes,
                    embaralharAlternativas: _embaralharAlternativas,
                    numeroVersoes: _numeroVersoes,
                    onShuffleQuestionsChanged: (value) =>
                        setState(() => _embaralharQuestoes = value),
                    onShuffleAlternativesChanged: (value) =>
                        setState(() => _embaralharAlternativas = value),
                    onVersionsChanged: (value) =>
                        setState(() => _numeroVersoes = value),
                  ),
                ],
              ),
            ),
            _WizardFooter(etapa: _etapa, onContinue: _avancar),
          ],
        ),
      ),
    );
  }
}

class _WizardHeader extends StatelessWidget {
  final int etapa;
  final VoidCallback onBack;

  const _WizardHeader({required this.etapa, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 29),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE4E9F1))),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 17,
                  color: Color(0xFF4E47EF),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 22),
              const Text(
                'Nova Prova',
                style: TextStyle(
                  color: Color(0xFF101827),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 49,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            children: [
              _StepIndicator(
                number: 1,
                label: 'Dados',
                active: etapa >= 0,
                completed: etapa > 0,
              ),
              const _StepLine(),
              _StepIndicator(
                number: 2,
                label: 'Questões',
                active: etapa >= 1,
                completed: etapa > 1,
              ),
              const _StepLine(),
              _StepIndicator(
                number: 3,
                label: 'Gerar',
                active: etapa >= 2,
                completed: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int number;
  final String label;
  final bool active;
  final bool completed;

  const _StepIndicator({
    required this.number,
    required this.label,
    required this.active,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF5547EA) : const Color(0xFFF0F3F7),
          shape: BoxShape.circle,
        ),
        child: Text(
          completed ? '✓' : '$number',
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF9BA9BA),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(width: 7),
      Text(
        label,
        style: TextStyle(
          color: active ? const Color(0xFF4D43E8) : const Color(0xFF9BA9BA),
          fontSize: 11,
          fontWeight: active ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
    ],
  );
}

class _StepLine extends StatelessWidget {
  const _StepLine();

  @override
  Widget build(BuildContext context) => const Expanded(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Divider(color: Color(0xFFDCE2EA), thickness: 1),
    ),
  );
}

class _DadosStep extends StatelessWidget {
  final String nome;
  final int quantidadeQuestoes;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<int> onQuantityChanged;

  const _DadosStep({
    required this.nome,
    required this.quantidadeQuestoes,
    required this.onNameChanged,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(28, 16, 15, 25),
    children: [
      _FormCard(
        children: [
          const _FieldLabel('NOME DA PROVA'),
          TextField(
            onChanged: onNameChanged,
            decoration: _inputDecoration('Ex: 1ª Prova Bimestral — Citologia'),
          ),
          const SizedBox(height: 16),
          const _FieldLabel('TURMA'),
          DropdownButtonFormField<String>(
            value: '1º A — 1º Ano (38 alunos)',
            items: const [
              DropdownMenuItem(
                value: '1º A — 1º Ano (38 alunos)',
                child: Text('1º A — 1º Ano (38 alunos)'),
              ),
            ],
            onChanged: (_) {},
            decoration: _inputDecoration(''),
          ),
          const SizedBox(height: 16),
          const _FieldLabel('DATA DE APLICAÇÃO'),
          TextField(
            readOnly: true,
            onTap: () async {
              await showDatePicker(
                context: context,
                firstDate: DateTime(2024),
                lastDate: DateTime(2030),
                initialDate: DateTime(2026),
              );
            },
            decoration: _inputDecoration(
              'dd/mm/aaaa',
              suffixIcon: Icons.calendar_month_outlined,
            ),
          ),
          const SizedBox(height: 16),
          const _FieldLabel('NÚMERO DE QUESTÕES'),
          Row(
            children: [
              for (final quantidade in [5, 10, 15, 20]) ...[
                if (quantidade != 5) const SizedBox(width: 8),
                Expanded(
                  child: _ChoiceButton(
                    label: '$quantidade',
                    selected: quantidadeQuestoes == quantidade,
                    onTap: () => onQuantityChanged(quantidade),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    ],
  );
}

class _QuestoesStep extends StatelessWidget {
  final Set<int> selecionadas;
  final ValueChanged<int> onToggle;

  const _QuestoesStep({required this.selecionadas, required this.onToggle});

  static const questoes = [
    (
      'Qual organela é responsável pela produção de energia (ATP) nas células eucarióticas?',
      'Citologia',
      'Fácil',
      'Gabarito: C',
    ),
    (
      'A membrana plasmática é composta principalmente por uma bicamada de:',
      'Citologia',
      'Fácil',
      'Gabarito: B',
    ),
    (
      'O processo pelo qual as células realizam a divisão celular para formar células-filhas geneticamente...',
      'Divisão celular',
      'Fácil',
      'Gabarito: B',
    ),
    (
      'Na fotossíntese, qual gás é liberado como subproduto da fotólise da água?',
      'Fisiologia vegetal',
      'Médio',
      'Gabarito: D',
    ),
    (
      'As leis de Mendel foram estabelecidas com experimentos realizados com qual planta?',
      'Genética',
      'Fácil',
      'Gabarito: C',
    ),
  ];

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(22, 17, 22, 25),
    children: [
      const Text(
        'BANCO DE QUESTÕES — SELECIONE ATÉ 10',
        style: TextStyle(
          color: Color(0xFF52647C),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: .3,
        ),
      ),
      const SizedBox(height: 12),
      for (var index = 0; index < questoes.length; index++) ...[
        _QuestionCard(
          question: questoes[index],
          selected: selecionadas.contains(index),
          onTap: () => onToggle(index),
        ),
        if (index < questoes.length - 1) const SizedBox(height: 10),
      ],
    ],
  );
}

class _QuestionCard extends StatelessWidget {
  final (String, String, String, String) question;
  final bool selected;
  final VoidCallback onTap;

  const _QuestionCard({
    required this.question,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(15),
    child: Container(
      padding: const EdgeInsets.all(13),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 19,
            height: 19,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF5547EA)
                  : const Color(0xFFF5F8FB),
              border: Border.all(
                color: selected
                    ? const Color(0xFF5547EA)
                    : const Color(0xFFCBD8E5),
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            child: selected
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.$1,
                  style: const TextStyle(
                    color: Color(0xFF355173),
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 7,
                  runSpacing: 5,
                  children: [
                    _Tag(
                      question.$2,
                      const Color(0xFFE7E9FF),
                      const Color(0xFF443CE1),
                    ),
                    _Tag(
                      question.$3,
                      const Color(0xFFD4F8E7),
                      const Color(0xFF07865D),
                    ),
                    _Tag(
                      question.$4,
                      const Color(0xFFE6FAF0),
                      const Color(0xFF16825D),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _GerarStep extends StatelessWidget {
  final String nome;
  final int quantidadeQuestoes;
  final int questoesSelecionadas;
  final bool embaralharQuestoes;
  final bool embaralharAlternativas;
  final int numeroVersoes;
  final ValueChanged<bool> onShuffleQuestionsChanged;
  final ValueChanged<bool> onShuffleAlternativesChanged;
  final ValueChanged<int> onVersionsChanged;

  const _GerarStep({
    required this.nome,
    required this.quantidadeQuestoes,
    required this.questoesSelecionadas,
    required this.embaralharQuestoes,
    required this.embaralharAlternativas,
    required this.numeroVersoes,
    required this.onShuffleQuestionsChanged,
    required this.onShuffleAlternativesChanged,
    required this.onVersionsChanged,
  });

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(28, 16, 15, 25),
    children: [
      _FormCard(
        children: [
          const Text(
            'Configurações de geração',
            style: TextStyle(
              color: Color(0xFF101827),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _SwitchLine(
            title: 'Embaralhar questões',
            subtitle: 'Altera a ordem das questões entre versões',
            value: embaralharQuestoes,
            onChanged: onShuffleQuestionsChanged,
          ),
          _SwitchLine(
            title: 'Embaralhar alternativas',
            subtitle: 'Altera a ordem das alternativas A–E',
            value: embaralharAlternativas,
            onChanged: onShuffleAlternativesChanged,
          ),
          const SizedBox(height: 5),
          const _FieldLabel('NÚMERO DE VERSÕES'),
          Row(
            children: [
              for (final versoes in [1, 2, 4]) ...[
                if (versoes != 1) const SizedBox(width: 8),
                Expanded(
                  child: _ChoiceButton(
                    label: '$versoes ${versoes == 1 ? 'versão' : 'versões'}',
                    selected: numeroVersoes == versoes,
                    onTap: () => onVersionsChanged(versoes),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      const SizedBox(height: 15),
      _SummaryCard(
        nome: nome,
        quantidadeQuestoes: questoesSelecionadas == 0
            ? quantidadeQuestoes
            : questoesSelecionadas,
        numeroVersoes: numeroVersoes,
      ),
    ],
  );
}

class _SwitchLine extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchLine({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Color(0xFF101827), fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF91A0B5), fontSize: 10),
            ),
          ],
        ),
      ),
      Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.white,
        activeTrackColor: const Color(0xFF5547EA),
      ),
    ],
  );
}

class _SummaryCard extends StatelessWidget {
  final String nome;
  final int quantidadeQuestoes;
  final int numeroVersoes;

  const _SummaryCard({
    required this.nome,
    required this.quantidadeQuestoes,
    required this.numeroVersoes,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFEFF3FF),
      border: Border.all(color: const Color(0xFFC6D3FF)),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumo',
          style: TextStyle(
            color: Color(0xFF2437C2),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _SummaryRow('Nome', nome.isEmpty ? 'Não informado' : nome),
        _SummaryRow('Turma', '1º A'),
        _SummaryRow('Data', 'Não informada'),
        _SummaryRow('Questões selecionadas', '$quantidadeQuestoes'),
        _SummaryRow('Versões', '$numeroVersoes'),
      ],
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFC6D3FF))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF4C58C9), fontSize: 10),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF2638B7),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _WizardFooter extends StatelessWidget {
  final int etapa;
  final VoidCallback onContinue;

  const _WizardFooter({required this.etapa, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 12, 15, 23),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE4E9F1))),
      ),
      child: SizedBox(
        height: 46,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6040EB),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: Text(
            etapa == 2 ? 'Gerar prova' : 'Continuar',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _CriandoProvaScreen extends StatefulWidget {
  const _CriandoProvaScreen();

  @override
  State<_CriandoProvaScreen> createState() => _CriandoProvaScreenState();
}

class _CriandoProvaScreenState extends State<_CriandoProvaScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const ProvasScreen()),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 74,
                height: 74,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFD2F8E7),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.check, color: Colors.black, size: 35),
              ),
              const SizedBox(height: 18),
              const Text(
                'Prova criada!',
                style: TextStyle(
                  color: Color(0xFF101827),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Nova prova foi gerada com 10 questões.',
                style: TextStyle(color: Color(0xFF667A96), fontSize: 13),
              ),
              const SizedBox(height: 18),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFF5547EA),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final List<Widget> children;

  const _FormCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(15, 17, 15, 15),
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
      children: children,
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      label,
      style: const TextStyle(
        color: Color(0xFF52647C),
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: .4,
      ),
    ),
  );
}

InputDecoration _inputDecoration(String hint, {IconData? suffixIcon}) =>
    InputDecoration(
      hintText: hint,
      suffixIcon: suffixIcon == null
          ? null
          : Icon(suffixIcon, size: 16, color: const Color(0xFF101827)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFDCE2EA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFDCE2EA)),
      ),
      hintStyle: const TextStyle(color: Color(0xFF8292A9), fontSize: 12),
    );

class _ChoiceButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF5547EA) : const Color(0xFFF1F4F8),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF667A96),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _Tag(this.label, this.background, this.foreground);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: foreground,
        fontSize: 9,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
