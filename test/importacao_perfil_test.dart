import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prova_certa/models/aluno.dart';
import 'package:prova_certa/screens/importar_alunos_screen.dart';
import 'package:prova_certa/screens/profile_screen.dart';
import 'package:prova_certa/services/importacao_alunos_service.dart';

import 'turmas_alunos_test.dart';

/// Utilitário para gerar arquivo XLSX em memória válido (OfficeOpenXML ZIP)
Uint8List criarXlsxMock({
  required List<String> cabecalhos,
  required List<List<String>> dados,
}) {
  final archive = Archive();
  final sharedStrings = <String>[];

  // Adiciona strings compartilhadas
  for (final h in cabecalhos) {
    sharedStrings.add(h);
  }
  for (final row in dados) {
    for (final cell in row) {
      sharedStrings.add(cell);
    }
  }

  final sstXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  ${sharedStrings.map((s) => '<si><t>$s</t></si>').join()}
</sst>''';
  archive.addFile(
    ArchiveFile('xl/sharedStrings.xml', sstXml.length, utf8.encode(sstXml)),
  );

  // Constrói sheet1.xml
  final rowsXml = StringBuffer();
  int stringIndex = 0;

  // Linha 1: Cabeçalhos
  rowsXml.write('<row r="1">');
  for (int c = 0; c < cabecalhos.length; c++) {
    final colLetter = String.fromCharCode(65 + c);
    rowsXml.write('<c r="${colLetter}1" t="s"><v>${stringIndex++}</v></c>');
  }
  rowsXml.write('</row>');

  // Linhas de dados
  for (int r = 0; r < dados.length; r++) {
    final rowNum = r + 2;
    rowsXml.write('<row r="$rowNum">');
    for (int c = 0; c < dados[r].length; c++) {
      final colLetter = String.fromCharCode(65 + c);
      rowsXml.write(
        '<c r="$colLetter$rowNum" t="s"><v>${stringIndex++}</v></c>',
      );
    }
    rowsXml.write('</row>');
  }

  final sheetXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <sheetData>
    $rowsXml
  </sheetData>
</worksheet>''';
  archive.addFile(
    ArchiveFile(
      'xl/worksheets/sheet1.xml',
      sheetXml.length,
      utf8.encode(sheetXml),
    ),
  );

  final bytes = ZipEncoder().encode(archive);
  return Uint8List.fromList(bytes);
}

Uint8List criarCsvMock(String csv) => Uint8List.fromList(utf8.encode(csv));

void main() {
  group('Etapa 4 — Validações da Importação de Alunos (CSV / XLSX)', () {
    test('1. Importação de CSV válido (com delimitador ponto e vírgula e vírgula)',
        () async {
      // Teste com ';'
      final csvPontoVirgula = '''
RA;Nome
00123;Beatriz Lima
00124;Carlos Eduardo
''';
      final res1 = await ImportacaoAlunosService.analisarArquivo(
        bytes: criarCsvMock(csvPontoVirgula),
        nomeArquivo: 'alunos.csv',
        rasExistentesNaTurma: {},
      );

      expect(res1.temErroGeral, isFalse);
      expect(res1.totalValidos, equals(2));
      expect(res1.alunosValidos[0].ra, equals('00123'));
      expect(res1.alunosValidos[0].nome, equals('Beatriz Lima'));
      expect(res1.alunosValidos[1].ra, equals('00124'));
      expect(res1.alunosValidos[1].nome, equals('Carlos Eduardo'));

      // Teste com ',' e campos entre aspas
      final csvVirgula = '''
"RA","Nome"
"00125","Silva, Lucas"
"00126","Souza, Mariana"
''';
      final res2 = await ImportacaoAlunosService.analisarArquivo(
        bytes: criarCsvMock(csvVirgula),
        nomeArquivo: 'alunos_virgula.csv',
        rasExistentesNaTurma: {},
      );

      expect(res2.temErroGeral, isFalse);
      expect(res2.totalValidos, equals(2));
      expect(res2.alunosValidos[0].ra, equals('00125'));
      expect(res2.alunosValidos[0].nome, equals('Silva, Lucas'));
    });

    test('2. Importação de XLSX válido (leitura da primeira planilha)',
        () async {
      final xlsxBytes = criarXlsxMock(
        cabecalhos: ['RA', 'Nome'],
        dados: [
          ['009871', 'Ana Paula Santos'],
          ['009872', 'Bruno Carvalho'],
        ],
      );

      final res = await ImportacaoAlunosService.analisarArquivo(
        bytes: xlsxBytes,
        nomeArquivo: 'turma.xlsx',
        rasExistentesNaTurma: {},
      );

      expect(res.temErroGeral, isFalse);
      expect(res.totalValidos, equals(2));
      expect(res.alunosValidos[0].ra, equals('009871'));
      expect(res.alunosValidos[0].nome, equals('Ana Paula Santos'));
      expect(res.alunosValidos[1].ra, equals('009872'));
      expect(res.alunosValidos[1].nome, equals('Bruno Carvalho'));
    });

    test('3. Colunas RA e Nome em ordem invertida (Nome primeiro, RA depois)',
        () async {
      final csvInvertido = '''
Nome;RA
João Victor;004411
Larissa Ramos;004412
''';
      final res = await ImportacaoAlunosService.analisarArquivo(
        bytes: criarCsvMock(csvInvertido),
        nomeArquivo: 'ordem_invertida.csv',
        rasExistentesNaTurma: {},
      );

      expect(res.temErroGeral, isFalse);
      expect(res.totalValidos, equals(2));
      expect(res.alunosValidos[0].nome, equals('João Victor'));
      expect(res.alunosValidos[0].ra, equals('004411'));
      expect(res.alunosValidos[1].nome, equals('Larissa Ramos'));
      expect(res.alunosValidos[1].ra, equals('004412'));
    });

    test('4. Ausência de coluna obrigatória dispara erro geral claro', () async {
      final csvSemRa = '''
Nome;Email;Idade
Gabriel;gabriel@escola.com;16
''';
      final res = await ImportacaoAlunosService.analisarArquivo(
        bytes: criarCsvMock(csvSemRa),
        nomeArquivo: 'sem_ra.csv',
        rasExistentesNaTurma: {},
      );

      expect(res.temErroGeral, isTrue);
      expect(res.totalValidos, equals(0));
      expect(
        res.erroGeral,
        contains('As colunas obrigatórias "RA" e "Nome" não foram encontradas'),
      );
    });

    test('5. Linhas com campos vazios (ignora linhas em branco e rejeita incompletas)',
        () async {
      final csvCamposVazios = '''
RA;Nome

001;Aluno Valido
002;
;Aluno Sem RA

003;Outro Valido
''';
      final res = await ImportacaoAlunosService.analisarArquivo(
        bytes: criarCsvMock(csvCamposVazios),
        nomeArquivo: 'vazios.csv',
        rasExistentesNaTurma: {},
      );

      expect(res.temErroGeral, isFalse);
      expect(res.totalValidos, equals(2)); // 001 e 003
      expect(res.totalInvalidos, equals(2)); // 002 e sem RA
      expect(res.avisos.any((a) => a.contains('Nome em branco')), isTrue);
      expect(res.avisos.any((a) => a.contains('RA em branco')), isTrue);
    });

    test('6. RA duplicado dentro do próprio arquivo é identificado e rejeitado',
        () async {
      final csvDuplicadoArquivo = '''
RA;Nome
00123;Primeira Ocorrencia
00123;Segunda Ocorrencia Duplicada
00124;Outro Aluno
''';
      final res = await ImportacaoAlunosService.analisarArquivo(
        bytes: criarCsvMock(csvDuplicadoArquivo),
        nomeArquivo: 'dup_arquivo.csv',
        rasExistentesNaTurma: {},
      );

      expect(res.temErroGeral, isFalse);
      expect(res.totalValidos, equals(2)); // 1ª ocorrencia 00123 e 00124
      expect(res.totalDuplicadosArquivo, equals(1));
      expect(
        res.avisos.any((a) => a.contains('duplicado no arquivo')),
        isTrue,
      );
    });

    test('7. RA já cadastrado na turma é identificado e não sobrescreve',
        () async {
      final csvExistente = '''
RA;Nome
001;Aluno Já na Turma
002;Aluno Novo
''';
      // Simula que '001' já está na turma
      final res = await ImportacaoAlunosService.analisarArquivo(
        bytes: criarCsvMock(csvExistente),
        nomeArquivo: 'existente.csv',
        rasExistentesNaTurma: {'001'},
      );

      expect(res.temErroGeral, isFalse);
      expect(res.totalValidos, equals(1)); // apenas 002
      expect(res.totalDuplicadosTurma, equals(1));
      expect(
        res.avisos.any((a) => a.contains('já cadastrado nesta turma')),
        isTrue,
      );
    });

    test('8. Preservação estrita de zeros à esquerda no RA como String', () async {
      final csvZeros = '''
RA,Nome
000789,Agente James
000001,Primeiro Aluno
''';
      final res = await ImportacaoAlunosService.analisarArquivo(
        bytes: criarCsvMock(csvZeros),
        nomeArquivo: 'zeros.csv',
        rasExistentesNaTurma: {},
      );

      expect(res.alunosValidos[0].ra, equals('000789'));
      expect(res.alunosValidos[1].ra, equals('000001'));
      expect(res.alunosValidos[0].ra.startsWith('000'), isTrue);
    });

    test('9. Importação na turma correta (isolamento por turma)', () async {
      final service = FakeTurmaService();
      final t1 = await service.criarTurma(
        nome: '1º A',
        ano: '1º',
        disciplina: 'Física',
        periodo: 'Manhã',
      );
      final t2 = await service.criarTurma(
        nome: '1º B',
        ano: '1º',
        disciplina: 'Química',
        periodo: 'Tarde',
      );

      final alunosImportar = [
        Aluno(id: '', nome: 'Aluno T1', ra: '991'),
        Aluno(id: '', nome: 'Aluno T1 - 2', ra: '992'),
      ];

      final total = await service.importarAlunosLote(
        turmaId: t1.id,
        alunos: alunosImportar,
      );

      expect(total, equals(2));

      // Verifica que T1 recebeu os alunos
      final alunosT1 = await service.listarAlunos(turmaId: t1.id);
      expect(alunosT1.length, equals(2));

      // Verifica que T2 permanece vazia
      final alunosT2 = await service.listarAlunos(turmaId: t2.id);
      expect(alunosT2, isEmpty);
    });

    test('10. Consistência do contador quantidadeAlunos na turma', () async {
      final service = FakeTurmaService();
      final turma = await service.criarTurma(
        nome: '3º A',
        ano: '3º',
        disciplina: 'Matemática',
        periodo: 'Manhã',
      );

      // Cadastra 1 aluno manual
      await service.cadastrarAluno(
        turmaId: turma.id,
        nome: 'Manual',
        ra: '001',
      );
      var turmaCheck = await service.buscarTurma(turma.id);
      expect(turmaCheck?.quantidadeAlunos, equals(1));

      // Importa 3 alunos válidos
      final novos = [
        Aluno(id: '', nome: 'Imp 1', ra: '002'),
        Aluno(id: '', nome: 'Imp 2', ra: '003'),
        Aluno(id: '', nome: 'Imp 3', ra: '004'),
      ];
      final importados = await service.importarAlunosLote(
        turmaId: turma.id,
        alunos: novos,
      );
      expect(importados, equals(3));

      turmaCheck = await service.buscarTurma(turma.id);
      expect(turmaCheck?.quantidadeAlunos, equals(4));
    });

    test('11. Falha parcial e repetição da importação sem duplicações', () async {
      final service = FakeTurmaService();
      final turma = await service.criarTurma(
        nome: 'Turma Resiliência',
        ano: '1º',
        disciplina: 'História',
        periodo: 'Manhã',
      );

      final lote = [
        Aluno(id: '', nome: 'Aluno A', ra: 'RA_A'),
        Aluno(id: '', nome: 'Aluno B', ra: 'RA_B'),
      ];

      // Primeira importação
      final inseridos1 = await service.importarAlunosLote(
        turmaId: turma.id,
        alunos: lote,
      );
      expect(inseridos1, equals(2));

      var tSnap = await service.buscarTurma(turma.id);
      expect(tSnap?.quantidadeAlunos, equals(2));

      // Repetição exata da importação (simula retry após queda de rede)
      final inseridos2 = await service.importarAlunosLote(
        turmaId: turma.id,
        alunos: lote,
      );
      // Nenhum aluno deve ser duplicado e o contador não deve ser incrementado
      expect(inseridos2, equals(0));

      tSnap = await service.buscarTurma(turma.id);
      expect(tSnap?.quantidadeAlunos, equals(2));

      final todosAlunos = await service.listarAlunos(turmaId: turma.id);
      expect(todosAlunos.length, equals(2));
    });
  });

  group('Etapa 4 — Tela de Perfil e Modal de Importação', () {
    testWidgets('12. Atualização reativa do contador de turmas no perfil',
        (tester) async {
      final service = FakeTurmaService();

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(turmaService: service),
        ),
      );
      await tester.pumpAndSettle();

      // Inicialmente 0 turmas no card de Turmas
      expect(find.text('0'), findsOneWidget);
      // Provas (4) e questões (10) permanecem mockadas
      expect(find.text('4'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);

      // Cria uma turma no serviço
      await service.criarTurma(
        nome: '1º A',
        ano: '1º',
        disciplina: 'Biologia',
        periodo: 'Manhã',
      );
      await tester.pumpAndSettle();

      // Indicador atualiza automaticamente para 1
      expect(find.text('1'), findsOneWidget);

      // Cria segunda turma
      await service.criarTurma(
        nome: '2º B',
        ano: '2º',
        disciplina: 'Física',
        periodo: 'Tarde',
      );
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('Modal ImportarAlunosModal: exibe pré-visualização e importa com sucesso',
        (tester) async {
      final service = FakeTurmaService();
      final turma = await service.criarTurma(
        nome: 'Turma Modal',
        ano: '1º',
        disciplina: 'Inglês',
        periodo: 'Manhã',
      );

      final csvData = criarCsvMock('''
RA;Nome
001;Lucas Silva
002;Mariana Rios
001;Lucas Duplicado
''');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImportarAlunosModal(
              turmaId: turma.id,
              turmaService: service,
              initialBytes: csvData,
              initialFileName: 'alunos_teste.csv',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Confere estatísticas na pré-visualização
      expect(find.text('alunos_teste.csv'), findsOneWidget);
      expect(find.text('Válidos'), findsOneWidget);
      expect(find.text('Duplicados'), findsOneWidget);

      // Botão com quantidade válida
      final btnImportar = find.widgetWithText(
        ElevatedButton,
        'Importar 2 alunos',
      );
      expect(btnImportar, findsOneWidget);

      await tester.tap(btnImportar);
      await tester.pumpAndSettle();

      // Confere que foram salvos no serviço
      final alunos = await service.listarAlunos(turmaId: turma.id);
      expect(alunos.length, equals(2));
      expect(alunos[0].ra, equals('001'));
      expect(alunos[1].ra, equals('002'));
    });
  });
}
