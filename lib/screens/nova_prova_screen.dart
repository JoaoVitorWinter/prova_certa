import 'package:flutter/material.dart';

import '../mocks/questoes_mock.dart';
import '../models/questao.dart';
import '../services/geracao_versoes_service.dart';

class NovaProvaScreen extends StatefulWidget {
  const NovaProvaScreen({super.key});

  @override
  State<NovaProvaScreen> createState() => _NovaProvaScreenState();
}

class _NovaProvaScreenState extends State<NovaProvaScreen> {
  int _etapa = 0;
  final TextEditingController _nomeController = TextEditingController();

  int _quantidadeQuestoes = 5;
  bool _embaralharQuestoes = false;
  bool _embaralharAlternativas = false;
  int _numeroVersoes = 1;

  final Set<String> _questoesSelecionadas = {};

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  List<Questao> get _questoesEscolhidas {
    return questoesMock
        .where((questao) => _questoesSelecionadas.contains(questao.id))
        .toList();
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  void _alternarQuestao(Questao questao) {
    setState(() {
      if (_questoesSelecionadas.contains(questao.id)) {
        _questoesSelecionadas.remove(questao.id);
      } else {
        if (_questoesSelecionadas.length >= _quantidadeQuestoes) {
          _mostrarMensagem(
            'Podes selecionar no máximo $_quantidadeQuestoes questões.',
          );
          return;
        }

        _questoesSelecionadas.add(questao.id);
      }
    });
  }

  void _avancar() {
    if (_etapa == 0) {
      if (_nomeController.text.trim().isEmpty) {
        _mostrarMensagem('Introduz o nome da prova.');
        return;
      }

      setState(() => _etapa = 1);
      return;
    }

    if (_etapa == 1) {
      if (_questoesSelecionadas.length != _quantidadeQuestoes) {
        _mostrarMensagem(
          'Seleciona exatamente $_quantidadeQuestoes questões.',
        );
        return;
      }

      setState(() => _etapa = 2);
      return;
    }

    _gerarProva();
  }

  void _voltar() {
    if (_etapa == 0) {
      Navigator.pop(context);
      return;
    }

    setState(() => _etapa--);
  }

  void _gerarProva() {
    try {
      final versoes = GeracaoVersoesService().gerarVersoes(
        questoes: _questoesEscolhidas,
        embaralharQuestoes: _embaralharQuestoes,
        embaralharAlternativas: _embaralharAlternativas,
        numeroVersoes: _numeroVersoes,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultadoGeracaoScreen(
            nomeProva: _nomeController.text.trim(),
            versoes: versoes,
            embaralharQuestoes: _embaralharQuestoes,
            embaralharAlternativas: _embaralharAlternativas,
          ),
        ),
      );
    } catch (e) {
      _mostrarMensagem('Não foi possível gerar a prova: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Column(
          children: [
            _Cabecalho(etapa: _etapa, onBack: _voltar),
            Expanded(
              child: IndexedStack(
                index: _etapa,
                children: [
                  _etapaDados(),
                  _etapaQuestoes(),
                  _etapaGerar(),
                ],
              ),
            ),
            _Rodape(
              etapa: _etapa,
              onContinue: _avancar,
            ),
          ],
        ),
      ),
    );
  }

  Widget _etapaDados() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Dados da prova',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF101827),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Define o nome e a quantidade de questões.',
          style: TextStyle(color: Color(0xFF667085)),
        ),
        const SizedBox(height: 22),
        _Cartao(
          children: [
            const _Rotulo('NOME DA PROVA'),
            TextField(
              controller: _nomeController,
              textCapitalization: TextCapitalization.sentences,
              decoration: _decoracao('Ex.: Prova de Biologia'),
            ),
            const SizedBox(height: 20),
            const _Rotulo('QUANTIDADE DE QUESTÕES'),
            DropdownButtonFormField<int>(
              value: _quantidadeQuestoes,
              decoration: _decoracao('Seleciona a quantidade'),
              items: [5, 10].map((quantidade) {
                return DropdownMenuItem<int>(
                  value: quantidade,
                  child: Text('$quantidade questões'),
                );
              }).toList(),
              onChanged: (valor) {
                if (valor == null) return;

                setState(() {
                  _quantidadeQuestoes = valor;

                  if (_questoesSelecionadas.length > valor) {
                    _questoesSelecionadas.clear();
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'O banco de demonstração contém 10 questões.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF667085),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _etapaQuestoes() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selecionar questões',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF101827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Selecionadas: ${_questoesSelecionadas.length} '
                'de $_quantidadeQuestoes',
                style: const TextStyle(color: Color(0xFF667085)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            itemCount: questoesMock.length,
            itemBuilder: (context, index) {
              final questao = questoesMock[index];
              final selecionada =
                  _questoesSelecionadas.contains(questao.id);

              return Card(
                color: selecionada ? const Color(0xFFEDEBFF) : Colors.white,
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: selecionada
                        ? const Color(0xFF6040EB)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: CheckboxListTile(
                  value: selecionada,
                  activeColor: const Color(0xFF6040EB),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    questao.enunciado,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${questao.disciplina} • ${questao.assunto} • '
                      '${questao.dificuldade}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  onChanged: (_) => _alternarQuestao(questao),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _etapaGerar() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Gerar versões',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF101827),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Escolhe como pretendes organizar as versões da prova.',
          style: TextStyle(color: Color(0xFF667085)),
        ),
        const SizedBox(height: 22),
        _Cartao(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Embaralhar questões',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Altera a ordem das perguntas em cada versão.',
              ),
              activeColor: const Color(0xFF6040EB),
              value: _embaralharQuestoes,
              onChanged: (valor) {
                setState(() => _embaralharQuestoes = valor);
              },
            ),
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Embaralhar alternativas',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Altera a ordem das alternativas e atualiza o gabarito.',
              ),
              activeColor: const Color(0xFF6040EB),
              value: _embaralharAlternativas,
              onChanged: (valor) {
                setState(() => _embaralharAlternativas = valor);
              },
            ),
            const SizedBox(height: 16),
            const _Rotulo('NÚMERO DE VERSÕES'),
            const SizedBox(height: 8),
            Row(
              children: [1, 2, 4].map((quantidade) {
                final selecionado = _numeroVersoes == quantidade;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => _numeroVersoes = quantidade);
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: selecionado
                            ? const Color(0xFF6040EB)
                            : Colors.white,
                        foregroundColor:
                            selecionado ? Colors.white : Colors.black87,
                        side: BorderSide(
                          color: selecionado
                              ? const Color(0xFF6040EB)
                              : const Color(0xFFDCE2EA),
                        ),
                      ),
                      child: Text(
                        '$quantidade ${quantidade == 1 ? 'versão' : 'versões'}',
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Cartao(
          children: [
            const Text(
              'Resumo da prova',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            _LinhaResumo(
              'Nome',
              _nomeController.text.trim(),
            ),
            _LinhaResumo(
              'Questões selecionadas',
              '$_quantidadeQuestoes',
            ),
            _LinhaResumo(
              'Versões a gerar',
              '$_numeroVersoes',
            ),
            _LinhaResumo(
              'Embaralhar questões',
              _embaralharQuestoes ? 'Sim' : 'Não',
            ),
            _LinhaResumo(
              'Embaralhar alternativas',
              _embaralharAlternativas ? 'Sim' : 'Não',
            ),
          ],
        ),
      ],
    );
  }
}

class ResultadoGeracaoScreen extends StatelessWidget {
  final String nomeProva;
  final List<VersaoProva> versoes;
  final bool embaralharQuestoes;
  final bool embaralharAlternativas;

  const ResultadoGeracaoScreen({
    super.key,
    required this.nomeProva,
    required this.versoes,
    required this.embaralharQuestoes,
    required this.embaralharAlternativas,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF101827),
        title: const Text('Versões geradas'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFF16A36A),
            size: 54,
          ),
          const SizedBox(height: 12),
          Text(
            nomeProva,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${versoes.length} versão(ões) gerada(s) com '
            '${versoes.first.questoes.length} questões.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF667085)),
          ),
          const SizedBox(height: 20),
          ...versoes.map((versao) {
            return Card(
              color: Colors.white,
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Versão ${versao.numero}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6040EB),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(versao.questoes.length, (index) {
                      final questao = versao.questoes[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${index + 1}. ${questao.enunciado}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ...questao.alternativas.map(
                              (alternativa) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 3),
                                child: Text(
                                  '${alternativa.letra}) ${alternativa.texto}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(),
                    const Text(
                      'Gabarito',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(
                        versao.gabarito.length,
                        (index) => Chip(
                          label: Text(
                            '${index + 1}: ${versao.gabarito[index]}',
                          ),
                          backgroundColor: const Color(0xFFEDEBFF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          const Text(
            'Nota: esta etapa gera e apresenta as versões no ecrã. '
            'Ainda não guarda a prova no Firestore nem cria um PDF.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF667085),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6040EB),
                foregroundColor: Colors.white,
              ),
              child: const Text('Voltar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  final int etapa;
  final VoidCallback onBack;

  const _Cabecalho({
    required this.etapa,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    const corAtiva = Color(0xFF6040EB);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: corAtiva,
              ),
              const SizedBox(width: 8),
              const Text(
                'Nova Prova',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF101827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Passo(numero: 1, texto: 'Dados', ativo: etapa >= 0),
              _LinhaPassos(ativo: etapa >= 1),
              _Passo(numero: 2, texto: 'Questões', ativo: etapa >= 1),
              _LinhaPassos(ativo: etapa >= 2),
              _Passo(numero: 3, texto: 'Gerar', ativo: etapa >= 2),
            ],
          ),
        ],
      ),
    );
  }
}

class _Passo extends StatelessWidget {
  final int numero;
  final String texto;
  final bool ativo;

  const _Passo({
    required this.numero,
    required this.texto,
    required this.ativo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor:
              ativo ? const Color(0xFF6040EB) : const Color(0xFFE5E7EB),
          child: Text(
            '$numero',
            style: TextStyle(
              color: ativo ? Colors.white : const Color(0xFF667085),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: TextStyle(
            fontSize: 11,
            color: ativo ? const Color(0xFF6040EB) : const Color(0xFF667085),
            fontWeight: ativo ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _LinhaPassos extends StatelessWidget {
  final bool ativo;

  const _LinhaPassos({required this.ativo});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 7),
        color: ativo ? const Color(0xFF6040EB) : const Color(0xFFE5E7EB),
      ),
    );
  }
}

class _Rodape extends StatelessWidget {
  final int etapa;
  final VoidCallback onContinue;

  const _Rodape({
    required this.etapa,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: onContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6040EB),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
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

class _Cartao extends StatelessWidget {
  final List<Widget> children;

  const _Cartao({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _Rotulo extends StatelessWidget {
  final String texto;

  const _Rotulo(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        texto,
        style: const TextStyle(
          color: Color(0xFF52647C),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _LinhaResumo extends StatelessWidget {
  final String titulo;
  final String valor;

  const _LinhaResumo(this.titulo, this.valor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                color: Color(0xFF667085),
                fontSize: 13,
              ),
            ),
          ),
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Color(0xFF101827),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _decoracao(String dica) {
  return InputDecoration(
    hintText: dica,
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 14,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFDCE2EA)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFDCE2EA)),
    ),
  );
}