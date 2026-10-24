import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prova_certa/models/aluno.dart';
import 'package:prova_certa/models/turma.dart';
import 'package:prova_certa/screens/nova_turma_screen.dart';
import 'package:prova_certa/screens/turma_detalhes_screen.dart';
import 'package:prova_certa/screens/turmas_screen.dart';
import 'package:prova_certa/services/turma_service.dart';

/// Implementação em memória do TurmaService para testes automatizados rápidos e isolados
class FakeTurmaService extends TurmaService {
  String _simulatedUserId;
  bool shouldThrowOnStream;
  String? streamErrorMessage;
  int _counter = 0;

  // Banco de dados em memória: userId -> (turmaId -> Turma)
  final Map<String, Map<String, Turma>> _turmasDb = {};
  // Banco de dados em memória: userId -> (turmaId -> (alunoId -> Aluno))
  final Map<String, Map<String, Map<String, Aluno>>> _alunosDb = {};

  final StreamController<List<Turma>> _turmasStreamController =
      StreamController<List<Turma>>.broadcast();

  final Map<String, StreamController<List<Aluno>>> _alunosStreamControllers = {};

  FakeTurmaService({
    String initialUserId = 'prof_default_1',
    this.shouldThrowOnStream = false,
    this.streamErrorMessage,
  }) : _simulatedUserId = initialUserId;

  void trocarUsuario(String novoUserId) {
    _simulatedUserId = novoUserId;
    _notificarTurmas();
  }

  @override
  String get currentUserId => _simulatedUserId;

  void _notificarTurmas() {
    final turmas = (_turmasDb[_simulatedUserId]?.values.toList() ?? [])
      ..sort((a, b) => a.nome.compareTo(b.nome));
    _turmasStreamController.add(List.unmodifiable(turmas));
  }

  void _notificarAlunos(String turmaId) {
    final controller = _alunosStreamControllers[turmaId];
    if (controller != null && !controller.isClosed) {
      final alunos =
          (_alunosDb[_simulatedUserId]?[turmaId]?.values.toList() ?? [])
            ..sort((a, b) => a.nome.compareTo(b.nome));
      controller.add(List.unmodifiable(alunos));
    }
  }

  @override
  Stream<List<Turma>> monitorarTurmas({String? userId}) {
    if (shouldThrowOnStream) {
      return Stream.error(
        streamErrorMessage ?? 'Falha de conexão com Firestore.',
      );
    }
    final uid = userId ?? _simulatedUserId;
    final initialTurmas = (_turmasDb[uid]?.values.toList() ?? [])
      ..sort((a, b) => a.nome.compareTo(b.nome));

    return Stream<List<Turma>>.multi((controller) {
      controller.add(initialTurmas);
      final sub = _turmasStreamController.stream.listen(
        controller.add,
        onError: controller.addError,
      );
      controller.onCancel = () => sub.cancel();
    });
  }

  @override
  Future<List<Turma>> listarTurmas({String? userId}) async {
    final uid = userId ?? _simulatedUserId;
    return _turmasDb[uid]?.values.toList() ?? [];
  }

  @override
  Stream<Turma?> monitorarTurma(String turmaId, {String? userId}) {
    final uid = userId ?? _simulatedUserId;
    return monitorarTurmas(userId: uid).map((turmas) {
      final matches = turmas.where((t) => t.id == turmaId);
      return matches.isNotEmpty ? matches.first : null;
    });
  }

  @override
  Future<Turma?> buscarTurma(String turmaId, {String? userId}) async {
    final uid = userId ?? _simulatedUserId;
    return _turmasDb[uid]?[turmaId];
  }

  @override
  Future<Turma> criarTurma({
    required String nome,
    required String ano,
    required String disciplina,
    required String periodo,
    String? userId,
  }) async {
    final nomeLimpo = nome.trim();
    final anoLimpo = ano.trim();
    final disciplinaLimpa = disciplina.trim();
    final periodoLimpo = periodo.trim();

    if (nomeLimpo.isEmpty) {
      throw ArgumentError('O nome da turma é obrigatório.');
    }
    if (anoLimpo.isEmpty) {
      throw ArgumentError('O ano da turma é obrigatório.');
    }
    if (disciplinaLimpa.isEmpty) {
      throw ArgumentError('A disciplina da turma é obrigatória.');
    }
    if (periodoLimpo.isEmpty) {
      throw ArgumentError('O período/turno da turma é obrigatório.');
    }

    final uid = userId ?? _simulatedUserId;
    final id = 'turma_${++_counter}_${DateTime.now().microsecondsSinceEpoch}';

    final novaTurma = Turma(
      id: id,
      nome: nomeLimpo,
      ano: anoLimpo,
      disciplina: disciplinaLimpa,
      periodo: periodoLimpo,
      alunos: const [],
      quantidadeAlunos: 0,
      criadoEm: DateTime.now(),
      atualizadoEm: DateTime.now(),
    );

    _turmasDb.putIfAbsent(uid, () => {})[id] = novaTurma;
    _alunosDb.putIfAbsent(uid, () => {}).putIfAbsent(id, () => {});

    _notificarTurmas();
    return novaTurma;
  }

  @override
  Future<void> atualizarTurma({
    required String turmaId,
    required String nome,
    required String ano,
    required String disciplina,
    required String periodo,
    String? userId,
  }) async {
    final nomeLimpo = nome.trim();
    final anoLimpo = ano.trim();
    final disciplinaLimpa = disciplina.trim();
    final periodoLimpo = periodo.trim();

    if (nomeLimpo.isEmpty) {
      throw ArgumentError('O nome da turma é obrigatório.');
    }
    if (anoLimpo.isEmpty) {
      throw ArgumentError('O ano da turma é obrigatório.');
    }
    if (disciplinaLimpa.isEmpty) {
      throw ArgumentError('A disciplina da turma é obrigatória.');
    }
    if (periodoLimpo.isEmpty) {
      throw ArgumentError('O período/turno da turma é obrigatório.');
    }

    final uid = userId ?? _simulatedUserId;
    final turmaAtual = _turmasDb[uid]?[turmaId];
    if (turmaAtual == null) {
      throw Exception('Turma não encontrada.');
    }

    final atualizada = turmaAtual.copyWith(
      nome: nomeLimpo,
      ano: anoLimpo,
      disciplina: disciplinaLimpa,
      periodo: periodoLimpo,
      atualizadoEm: DateTime.now(),
    );

    _turmasDb[uid]![turmaId] = atualizada;
    _notificarTurmas();
  }

  @override
  Stream<List<Aluno>> monitorarAlunos({
    required String turmaId,
    String? userId,
  }) {
    final uid = userId ?? _simulatedUserId;
    final controller = _alunosStreamControllers.putIfAbsent(
      turmaId,
      () => StreamController<List<Aluno>>.broadcast(),
    );

    final initialAlunos = (_alunosDb[uid]?[turmaId]?.values.toList() ?? [])
      ..sort((a, b) => a.nome.compareTo(b.nome));

    return Stream<List<Aluno>>.multi((multiController) {
      multiController.add(initialAlunos);
      final sub = controller.stream.listen(
        multiController.add,
        onError: multiController.addError,
      );
      multiController.onCancel = () => sub.cancel();
    });
  }

  @override
  Future<List<Aluno>> listarAlunos({
    required String turmaId,
    String? userId,
  }) async {
    final uid = userId ?? _simulatedUserId;
    return _alunosDb[uid]?[turmaId]?.values.toList() ?? [];
  }

  @override
  Future<Aluno> cadastrarAluno({
    required String turmaId,
    required String nome,
    required String ra,
    String? userId,
  }) async {
    final nomeLimpo = nome.trim();
    final raLimpo = ra.trim();

    if (nomeLimpo.isEmpty) {
      throw ArgumentError('O nome do aluno é obrigatório.');
    }
    if (raLimpo.isEmpty) {
      throw ArgumentError('O RA do aluno é obrigatório.');
    }

    final uid = userId ?? _simulatedUserId;
    final turma = _turmasDb[uid]?[turmaId];
    if (turma == null) {
      throw Exception('Turma não encontrada para cadastro de aluno.');
    }

    final alunosTurma =
        _alunosDb.putIfAbsent(uid, () => {}).putIfAbsent(turmaId, () => {});

    // Prevenção de RA duplicado na mesma turma
    final raExiste = alunosTurma.values.any((a) => a.ra == raLimpo);
    if (raExiste) {
      throw Exception(
        'Já existe um aluno cadastrado com o RA "$raLimpo" nesta turma.',
      );
    }

    final alunoId = 'aluno_${++_counter}_${DateTime.now().microsecondsSinceEpoch}';
    final novoAluno = Aluno(
      id: alunoId,
      nome: nomeLimpo,
      ra: raLimpo,
      criadoEm: DateTime.now(),
      atualizadoEm: DateTime.now(),
    );

    alunosTurma[alunoId] = novoAluno;

    // Atualização atômica simulada do contador de alunos na turma
    final novaQtd = (turma.quantidadeAlunos ?? 0) + 1;
    _turmasDb[uid]![turmaId] = turma.copyWith(
      quantidadeAlunos: novaQtd,
      atualizadoEm: DateTime.now(),
    );

    _notificarAlunos(turmaId);
    _notificarTurmas();

    return novoAluno;
  }

  @override
  Future<void> editarAluno({
    required String turmaId,
    required String alunoId,
    required String nome,
    required String ra,
    String? userId,
  }) async {
    final nomeLimpo = nome.trim();
    final raLimpo = ra.trim();

    if (nomeLimpo.isEmpty) {
      throw ArgumentError('O nome do aluno é obrigatório.');
    }
    if (raLimpo.isEmpty) {
      throw ArgumentError('O RA do aluno é obrigatório.');
    }

    final uid = userId ?? _simulatedUserId;
    final alunosTurma = _alunosDb[uid]?[turmaId];
    if (alunosTurma == null || !alunosTurma.containsKey(alunoId)) {
      throw Exception('Aluno não encontrado.');
    }

    // Prevenção de duplicação de RA com outro aluno da turma
    final raExisteEmOutro = alunosTurma.values
        .any((a) => a.id != alunoId && a.ra == raLimpo);
    if (raExisteEmOutro) {
      throw Exception(
        'Já existe outro aluno cadastrado com o RA "$raLimpo" nesta turma.',
      );
    }

    final alunoAtual = alunosTurma[alunoId]!;
    alunosTurma[alunoId] = alunoAtual.copyWith(
      nome: nomeLimpo,
      ra: raLimpo,
      atualizadoEm: DateTime.now(),
    );

    _notificarAlunos(turmaId);
  }

  @override
  Future<void> removerAluno({
    required String turmaId,
    required String alunoId,
    String? userId,
  }) async {
    final uid = userId ?? _simulatedUserId;
    final turma = _turmasDb[uid]?[turmaId];
    final alunosTurma = _alunosDb[uid]?[turmaId];

    if (turma != null && alunosTurma != null && alunosTurma.containsKey(alunoId)) {
      alunosTurma.remove(alunoId);

      // Previne contagem negativa
      final qtdAtual = turma.quantidadeAlunos ?? 0;
      final novaQtd = qtdAtual > 0 ? qtdAtual - 1 : 0;

      _turmasDb[uid]![turmaId] = turma.copyWith(
        quantidadeAlunos: novaQtd,
        atualizadoEm: DateTime.now(),
      );

      _notificarAlunos(turmaId);
      _notificarTurmas();
    }
  }

  @override
  Future<int> importarAlunosLote({
    required String turmaId,
    required List<Aluno> alunos,
    String? userId,
  }) async {
    if (alunos.isEmpty) return 0;
    final uid = userId ?? _simulatedUserId;
    final turma = _turmasDb[uid]?[turmaId];
    if (turma == null) throw Exception('Turma não encontrada.');

    final alunosTurma =
        _alunosDb.putIfAbsent(uid, () => {}).putIfAbsent(turmaId, () => {});

    final rasExistentes = alunosTurma.values.map((a) => a.ra).toSet();

    // Filtra exclusivamente os novos que não constam na turma
    final novos = alunos
        .where((a) => !rasExistentes.contains(a.ra.trim()))
        .toList();

    if (novos.isEmpty) return 0;

    for (final aluno in novos) {
      final safeRa =
          aluno.ra.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final docId = 'aluno_$safeRa';
      alunosTurma[docId] = Aluno(
        id: docId,
        nome: aluno.nome.trim(),
        ra: aluno.ra.trim(),
        criadoEm: DateTime.now(),
        atualizadoEm: DateTime.now(),
      );
    }

    final novaQtd = (turma.quantidadeAlunos ?? 0) + novos.length;
    _turmasDb[uid]![turmaId] = turma.copyWith(
      quantidadeAlunos: novaQtd,
      atualizadoEm: DateTime.now(),
    );

    _notificarAlunos(turmaId);
    _notificarTurmas();

    return novos.length;
  }
}

void main() {
  group('Etapa 3 - TurmaService (Persistência, Unicidade de RA e Contadores)', () {
    late FakeTurmaService service;

    setUp(() {
      service = FakeTurmaService(initialUserId: 'prof_carlos');
    });

    test('1. Criação e consulta de turma vinculada ao professor', () async {
      final turma = await service.criarTurma(
        nome: '3º Ano A',
        ano: '3º Ano',
        disciplina: 'Física',
        periodo: 'Manhã',
      );

      expect(turma.id, isNotEmpty);
      expect(turma.nome, equals('3º Ano A'));
      expect(turma.quantidadeAlunos, equals(0));

      final turmas = await service.listarTurmas();
      expect(turmas.length, equals(1));
      expect(turmas.first.nome, equals('3º Ano A'));
    });

    test('2. Edição de dados cadastrais da turma', () async {
      final turma = await service.criarTurma(
        nome: '2º B',
        ano: '2º Ano',
        disciplina: 'Química',
        periodo: 'Tarde',
      );

      await service.atualizarTurma(
        turmaId: turma.id,
        nome: '2º Ano B - Avançado',
        ano: '2º Ano',
        disciplina: 'Química Orgânica',
        periodo: 'Noite',
      );

      final consultada = await service.buscarTurma(turma.id);
      expect(consultada?.nome, equals('2º Ano B - Avançado'));
      expect(consultada?.disciplina, equals('Química Orgânica'));
      expect(consultada?.periodo, equals('Noite'));
    });

    test('3. Isolamento multi-tenant por usuário (prof_carlos vs prof_maria)', () async {
      await service.criarTurma(
        nome: 'Turma do Carlos',
        ano: '1º Ano',
        disciplina: 'História',
        periodo: 'Manhã',
      );

      // Troca para Maria
      service.trocarUsuario('prof_maria');

      final turmasMaria = await service.listarTurmas();
      expect(turmasMaria, isEmpty);

      await service.criarTurma(
        nome: 'Turma da Maria',
        ano: '1º Ano',
        disciplina: 'Geografia',
        periodo: 'Tarde',
      );

      final turmasMariaAposCriar = await service.listarTurmas();
      expect(turmasMariaAposCriar.length, equals(1));
      expect(turmasMariaAposCriar.first.nome, equals('Turma da Maria'));

      // Volta para Carlos
      service.trocarUsuario('prof_carlos');
      final turmasCarlos = await service.listarTurmas();
      expect(turmasCarlos.length, equals(1));
      expect(turmasCarlos.first.nome, equals('Turma do Carlos'));
    });

    test('4. Cadastro de aluno com RA String preservando zeros e contador atômico', () async {
      final turma = await service.criarTurma(
        nome: '1º A',
        ano: '1º Ano',
        disciplina: 'Matemática',
        periodo: 'Manhã',
      );

      final aluno = await service.cadastrarAluno(
        turmaId: turma.id,
        nome: 'Beatriz Lima',
        ra: '007890', // Zeros à esquerda devem ser preservados
      );

      expect(aluno.ra, equals('007890'));
      expect(aluno.ra, isA<String>());

      final turmaAtualizada = await service.buscarTurma(turma.id);
      expect(turmaAtualizada?.quantidadeAlunos, equals(1));
      expect(turmaAtualizada?.totalAlunos, equals(1));
    });

    test('5. Prevenção estrita de RA duplicado dentro da mesma turma', () async {
      final turma = await service.criarTurma(
        nome: '1º B',
        ano: '1º Ano',
        disciplina: 'Biologia',
        periodo: 'Manhã',
      );

      await service.cadastrarAluno(
        turmaId: turma.id,
        nome: 'Lucas Silva',
        ra: '001234',
      );

      // Tentativa de cadastrar outro aluno com o mesmo RA deve falhar
      expect(
        () => service.cadastrarAluno(
          turmaId: turma.id,
          nome: 'Outro Aluno',
          ra: '001234',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'mensagem',
            contains('Já existe um aluno cadastrado com o RA "001234"'),
          ),
        ),
      );

      // O contador deve permanecer em 1
      final turmaCheck = await service.buscarTurma(turma.id);
      expect(turmaCheck?.quantidadeAlunos, equals(1));
    });

    test('6. Mesmo RA em turmas diferentes é permitido (escopo isolado por turma)', () async {
      final turma1 = await service.criarTurma(
        nome: 'Turma 1',
        ano: '1º Ano',
        disciplina: 'Inglês',
        periodo: 'Manhã',
      );
      final turma2 = await service.criarTurma(
        nome: 'Turma 2',
        ano: '2º Ano',
        disciplina: 'Espanhol',
        periodo: 'Tarde',
      );

      await service.cadastrarAluno(
        turmaId: turma1.id,
        nome: 'Aluno A',
        ra: '009999',
      );

      // Mesmo RA em turma diferente não deve disparar erro
      final alunoT2 = await service.cadastrarAluno(
        turmaId: turma2.id,
        nome: 'Aluno A em outra turma',
        ra: '009999',
      );

      expect(alunoT2.ra, equals('009999'));
    });

    test('7. Edição de aluno e prevenção de colisão de RA', () async {
      final turma = await service.criarTurma(
        nome: 'Turma X',
        ano: '3º Ano',
        disciplina: 'Literatura',
        periodo: 'Manhã',
      );

      final a1 = await service.cadastrarAluno(
        turmaId: turma.id,
        nome: 'Mariana',
        ra: '001',
      );
      await service.cadastrarAluno(
        turmaId: turma.id,
        nome: 'Carlos',
        ra: '002',
      );

      // Editar a1 mantendo seu próprio RA 001 é permitido
      await service.editarAluno(
        turmaId: turma.id,
        alunoId: a1.id,
        nome: 'Mariana Ferreira',
        ra: '001',
      );

      // Editar a1 tentando mudar para o RA 002 (já em uso por a2) deve falhar
      expect(
        service.editarAluno(
          turmaId: turma.id,
          alunoId: a1.id,
          nome: 'Mariana Ferreira',
          ra: '002',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('8. Remoção de aluno com decremento seguro e prevenção de contagem negativa', () async {
      final turma = await service.criarTurma(
        nome: 'Turma Y',
        ano: '1º Ano',
        disciplina: 'Artes',
        periodo: 'Tarde',
      );

      final aluno = await service.cadastrarAluno(
        turmaId: turma.id,
        nome: 'Aluno Teste',
        ra: '12345',
      );

      var turmaAposCadastro = await service.buscarTurma(turma.id);
      expect(turmaAposCadastro?.quantidadeAlunos, equals(1));

      // Remove aluno
      await service.removerAluno(turmaId: turma.id, alunoId: aluno.id);

      var turmaAposRemocao = await service.buscarTurma(turma.id);
      expect(turmaAposRemocao?.quantidadeAlunos, equals(0));

      // Remoção repetida não deve negativar
      await service.removerAluno(turmaId: turma.id, alunoId: aluno.id);
      var turmaCheck = await service.buscarTurma(turma.id);
      expect(turmaCheck?.quantidadeAlunos, equals(0));
    });
  });

  group('Etapa 3 - Interface de Usuário (TurmasScreen, NovaTurmaScreen, TurmaDetalhesScreen)', () {
    testWidgets('TurmasScreen: exibe estado vazio quando não há turmas cadastradas',
        (tester) async {
      final fakeService = FakeTurmaService();

      await tester.pumpWidget(
        MaterialApp(
          home: TurmasScreen(turmaService: fakeService),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma turma cadastrada'), findsOneWidget);
      expect(find.text('Criar turma'), findsOneWidget);
      expect(find.text('0'), findsNWidgets(2)); // Turmas ativas: 0, Total alunos: 0
    });

    testWidgets('TurmasScreen: exibe mensagem de erro quando Firestore falha (sem fallback a mocks)',
        (tester) async {
      final fakeService = FakeTurmaService(
        shouldThrowOnStream: true,
        streamErrorMessage: 'Erro de permissão no Firestore',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TurmasScreen(turmaService: fakeService),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível carregar as turmas.'), findsOneWidget);
      expect(find.text('Erro de permissão no Firestore'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
      // Garante que mocks não foram exibidos
      expect(find.text('1º A'), findsNothing);
    });

    testWidgets('TurmasScreen: lista turmas reais e exibe contadores consistentes',
        (tester) async {
      final fakeService = FakeTurmaService();
      final t1 = await fakeService.criarTurma(
        nome: '3º A',
        ano: '3º Ano',
        disciplina: 'Física',
        periodo: 'Manhã',
      );
      await fakeService.cadastrarAluno(
        turmaId: t1.id,
        nome: 'Aluno 1',
        ra: '001',
      );
      await fakeService.cadastrarAluno(
        turmaId: t1.id,
        nome: 'Aluno 2',
        ra: '002',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TurmasScreen(turmaService: fakeService),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('3º A — 3º Ano'), findsOneWidget);
      expect(find.text('Física · Manhã'), findsOneWidget);
      expect(find.text('2 alunos cadastrados'), findsOneWidget);
      expect(find.text('1'), findsOneWidget); // 1 turma ativa
      expect(find.text('2'), findsOneWidget); // 2 alunos no total
    });

    testWidgets('NovaTurmaScreen: valida campos obrigatórios e cria turma no serviço',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeService = FakeTurmaService();

      await tester.pumpWidget(
        MaterialApp(
          home: NovaTurmaScreen(turmaService: fakeService),
        ),
      );
      await tester.pumpAndSettle();

      final botaoCriar = find.widgetWithText(ElevatedButton, 'Criar turma');
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(tester.widget<ElevatedButton>(botaoCriar).enabled, isFalse);

      // Preenche os campos
      await tester.enterText(find.byType(TextField).at(0), '1º Ano C');
      await tester.enterText(find.byType(TextField).at(1), '1º Ano');
      await tester.enterText(find.byType(TextField).at(2), 'Filosofia');
      await tester.pump();

      expect(tester.widget<ElevatedButton>(botaoCriar).enabled, isTrue);

      await tester.tap(botaoCriar);
      await tester.pumpAndSettle();

      final turmas = await fakeService.listarTurmas();
      expect(turmas.length, equals(1));
      expect(turmas.first.nome, equals('1º Ano C'));
      expect(turmas.first.disciplina, equals('Filosofia'));
    });

    testWidgets('TurmaDetalhesScreen: exibe lista de alunos e cadastra novo aluno manualmente',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeService = FakeTurmaService();
      final turma = await fakeService.criarTurma(
        nome: '2º B',
        ano: '2º Ano',
        disciplina: 'Sociologia',
        periodo: 'Tarde',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TurmaDetalhesScreen(
            turma: turma,
            turmaService: fakeService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Estado inicial sem alunos
      expect(find.text('Nenhum aluno cadastrado nesta turma'), findsOneWidget);

      // Toca em "Cadastrar primeiro aluno"
      await tester.tap(find.text('Cadastrar primeiro aluno'));
      await tester.pumpAndSettle();

      // Preenche modal de cadastro
      expect(find.text('Novo aluno'), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(0), 'Mariana Rios');
      await tester.enterText(find.byType(TextField).at(1), '008765');
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Cadastrar aluno'));
      await tester.pumpAndSettle();

      // Verifica exibição do aluno na lista da turma
      expect(find.text('Mariana Rios'), findsOneWidget);
      expect(find.text('RA: 008765'), findsOneWidget);
      expect(find.textContaining('1 alunos'), findsOneWidget);
    });
  });
}
