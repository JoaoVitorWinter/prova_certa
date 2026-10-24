import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prova_certa/models/alternativa.dart';
import 'package:prova_certa/models/aluno.dart';
import 'package:prova_certa/models/prova.dart';
import 'package:prova_certa/models/questao.dart';
import 'package:prova_certa/models/resultado.dart';
import 'package:prova_certa/models/turma.dart';
import 'package:prova_certa/models/usuario.dart';

void main() {
  group('Serialização de Modelos Firestore - Prova Certa', () {
    test('1. Usuario: serialização e omissão estrita de senhas', () {
      final dataCriacao = DateTime(2026, 3, 10, 8, 30);
      final usuario = Usuario(
        id: 'user_123',
        nome: 'Prof. Carlos Eduardo',
        email: 'carlos.eduardo@escola.edu.br',
        instituicao: 'Colégio Estadual Modelo',
        fotoUrl: 'https://exemplo.com/avatar.jpg',
        criadoEm: dataCriacao,
      );

      final mapFirestore = usuario.toFirestore();

      // Validação de segurança: nunca deve conter campos de senha
      expect(mapFirestore.containsKey('senha'), isFalse);
      expect(mapFirestore.containsKey('password'), isFalse);
      expect(mapFirestore.containsKey('hash'), isFalse);

      expect(mapFirestore['nome'], equals('Prof. Carlos Eduardo'));
      expect(mapFirestore['email'], equals('carlos.eduardo@escola.edu.br'));
      expect(mapFirestore['instituicao'], equals('Colégio Estadual Modelo'));
      expect(mapFirestore['fotoUrl'], equals('https://exemplo.com/avatar.jpg'));
      expect(mapFirestore['criadoEm'], isA<Timestamp>());

      // Deserialização
      final usuarioRecriado = Usuario.fromMap(mapFirestore, id: 'user_123');
      expect(usuarioRecriado.id, equals('user_123'));
      expect(usuarioRecriado.nome, equals('Prof. Carlos Eduardo'));
      expect(usuarioRecriado.email, equals('carlos.eduardo@escola.edu.br'));
      expect(usuarioRecriado.criadoEm, equals(dataCriacao));
    });

    test('2. Alternativa: serialização simples de letra e texto', () {
      final alt = Alternativa(letra: 'A', texto: 'Mitocôndria');
      final map = alt.toFirestore();

      expect(map['letra'], equals('A'));
      expect(map['texto'], equals('Mitocôndria'));

      final altRecriada = Alternativa.fromMap(map);
      expect(altRecriada.letra, equals('A'));
      expect(altRecriada.texto, equals('Mitocôndria'));
    });

    test('3. Aluno: preservação de RA com zeros à esquerda como String', () {
      final dataCriacao = DateTime(2026, 2, 1, 10, 0);
      final aluno = Aluno(
        id: 'aluno_007',
        nome: 'Mariana Souza',
        ra: '007842', // RA com zeros à esquerda
        criadoEm: dataCriacao,
      );

      final map = aluno.toFirestore();
      expect(map['nome'], equals('Mariana Souza'));
      expect(map['ra'], isA<String>());
      expect(map['ra'], equals('007842')); // Deve preservar zeros!

      final alunoRecriado = Aluno.fromMap(map, id: 'aluno_007');
      expect(alunoRecriado.id, equals('aluno_007'));
      expect(alunoRecriado.nome, equals('Mariana Souza'));
      expect(alunoRecriado.ra, equals('007842'));
    });

    test('4. Questao: alternativas embutidas como lista de mapas', () {
      final questao = Questao(
        id: 'q_citologia_1',
        enunciado: 'Qual organela produz ATP nas células?',
        alternativas: [
          Alternativa(letra: 'A', texto: 'Complexo de Golgi'),
          Alternativa(letra: 'B', texto: 'Ribossomo'),
          Alternativa(letra: 'C', texto: 'Mitocôndria'),
          Alternativa(letra: 'D', texto: 'Lisossomo'),
        ],
        correta: 'C',
        assunto: 'Citologia',
        dificuldade: 'Fácil',
        disciplina: 'Biologia',
        criadoEm: DateTime(2026, 1, 15),
      );

      final map = questao.toFirestore();
      expect(map['enunciado'], contains('organela produz ATP'));
      expect(map['correta'], equals('C'));
      expect(map['alternativas'], isA<List>());
      expect((map['alternativas'] as List).length, equals(4));

      final questaoRecriada = Questao.fromMap(map, id: 'q_citologia_1');
      expect(questaoRecriada.id, equals('q_citologia_1'));
      expect(questaoRecriada.alternativas.length, equals(4));
      expect(questaoRecriada.alternativas[2].letra, equals('C'));
      expect(questaoRecriada.alternativas[2].texto, equals('Mitocôndria'));
    });

    test('5. Turma: preserva Turma.alunos em memória, mas OMITE alunos no documento Firestore', () {
      final aluno1 = Aluno(id: 'a1', nome: 'Aluno 1', ra: '001');
      final aluno2 = Aluno(id: 'a2', nome: 'Aluno 2', ra: '002');

      final turma = Turma(
        id: 'turma_3a',
        nome: '3º Ano A',
        ano: '3º Ano',
        disciplina: 'Biologia',
        periodo: 'Manhã',
        alunos: [aluno1, aluno2], // Em memória para compatibilidade com as telas
      );

      // Em memória, a lista de alunos permanece acessível
      expect(turma.alunos.length, equals(2));
      expect(turma.totalAlunos, equals(2));

      final map = turma.toFirestore();

      // REQUISITO CRÍTICO: Não salvar a lista de alunos no documento da turma
      expect(map.containsKey('alunos'), isFalse);
      expect(map['quantidadeAlunos'], equals(2));
      expect(map['nome'], equals('3º Ano A'));
      expect(map['disciplina'], equals('Biologia'));

      // Deserialização sem alunos passa a lista vazia (a ser carregada da subcoleção)
      final turmaCarregada = Turma.fromMap(map, id: 'turma_3a');
      expect(turmaCarregada.alunos, isEmpty);
      expect(turmaCarregada.quantidadeAlunos, equals(2));
      expect(turmaCarregada.totalAlunos, equals(2));

      // Se injetar alunos vindos da subcoleção:
      final turmaComAlunos = Turma.fromMap(map, id: 'turma_3a', alunos: [aluno1, aluno2]);
      expect(turmaComAlunos.alunos.length, equals(2));
    });

    test('6. Prova: serialização segura de turma, snapshot tipado de questoes e status', () {
      final turma = Turma(
        id: 'turma_10',
        nome: '1º A',
        ano: '1º Ano',
        disciplina: 'Biologia',
        periodo: 'Manhã',
        alunos: const [],
      );

      final q1 = Questao(
        id: 'q1',
        enunciado: 'Enunciado Q1',
        alternativas: [
          Alternativa(letra: 'A', texto: 'Alt A'),
          Alternativa(letra: 'B', texto: 'Alt B'),
        ],
        correta: 'A',
        assunto: 'Genética',
        dificuldade: 'Média',
        disciplina: 'Biologia',
      );

      final prova = Prova(
        id: 'prova_bimestral_1',
        nome: '1ª Avaliação Bimestral',
        turma: turma,
        dataAplicacao: DateTime(2026, 4, 15, 9, 0),
        quantidadeQuestoes: 1,
        questoes: [q1, 'q_id_externo'], // Tipos mistos seguros
        status: ProvaStatus.ativa,
        embaralharQuestoes: true,
        embaralharAlternativas: true,
        numeroVersoes: 2,
        gabaritoOficial: ['A'],
      );

      final map = prova.toFirestore();

      // Verifica campos desnormalizados da turma
      expect(map['turmaId'], equals('turma_10'));
      expect(map['turmaNome'], equals('1º A'));
      expect(map['status'], equals('ativa'));

      // Verifica que questoesIds e questoesSnapshot foram tipados e extraídos corretamente
      final ids = map['questoesIds'] as List<String>;
      expect(ids, contains('q1'));
      expect(ids, contains('q_id_externo'));

      final snapshot = map['questoesSnapshot'] as List<Map<String, dynamic>>;
      expect(snapshot.length, equals(1)); // Somente a Questão gerou snapshot de conteúdo
      expect(snapshot.first['enunciado'], equals('Enunciado Q1'));

      // Deserialização da prova
      final provaRecriada = Prova.fromMap(map, id: 'prova_bimestral_1');
      expect(provaRecriada.id, equals('prova_bimestral_1'));
      expect(provaRecriada.turma.id, equals('turma_10'));
      expect(provaRecriada.turma.nome, equals('1º A'));
      expect(provaRecriada.status, equals(ProvaStatus.ativa));
      expect(provaRecriada.questoes.length, equals(1));
      expect((provaRecriada.questoes.first as Questao).enunciado, equals('Enunciado Q1'));
      expect(provaRecriada.gabaritoOficial, equals(['A']));
    });

    test('7. Resultados: separação entre resultado individual do aluno e resumo agregado', () {
      final aluno = Aluno(id: 'aluno_33', nome: 'Lucas Ribeiro', ra: '098765');
      final dataCorrecao = DateTime(2026, 4, 16, 14, 0);

      final resultadoAluno = ResultadoAluno(
        id: 'aluno_33',
        aluno: aluno,
        nota: 8.5,
        acertos: 8,
        alternativasMarcadas: ['A', 'B', 'C', 'D', 'A', 'B', 'C', 'D', 'A', 'B'],
        provaId: 'prova_bimestral_1',
        turmaId: 'turma_10',
        corrigidoEm: dataCorrecao,
      );

      // 7.1 Resultado individual do aluno (subcoleção /resultados/{alunoId})
      final mapAluno = resultadoAluno.toFirestore();
      expect(mapAluno['alunoId'], equals('aluno_33'));
      expect(mapAluno['alunoNome'], equals('Lucas Ribeiro'));
      expect(mapAluno['alunoRa'], equals('098765'));
      expect(mapAluno['nota'], equals(8.5));
      expect(mapAluno['acertos'], equals(8));
      expect(mapAluno['totalQuestoes'], equals(10));
      expect((mapAluno['alternativasMarcadas'] as List).length, equals(10));

      final recriadoAluno = ResultadoAluno.fromMap(mapAluno, id: 'aluno_33');
      expect(recriadoAluno.aluno.nome, equals('Lucas Ribeiro'));
      expect(recriadoAluno.nota, equals(8.5));
      expect(recriadoAluno.aluno.ra, equals('098765'));

      // 7.2 Resumo agregado da prova (campo resumoResultado no doc da prova)
      final resumoAgregado = ResultadoProva(
        prova: Prova(
          id: 'p1',
          nome: 'Prova 1',
          turma: Turma(id: 't1', nome: 'T1', ano: '1', disciplina: 'D', periodo: 'M', alunos: const []),
          dataAplicacao: DateTime.now(),
          quantidadeQuestoes: 10,
          questoes: const [],
          status: ProvaStatus.encerrada,
        ),
        media: 7.8,
        minimo: 4.0,
        maximo: 10.0,
        distribuicao: [
          FaixaDistribuicao(faixa: '6-8', quantidade: 5),
          FaixaDistribuicao(faixa: '8-10', quantidade: 12),
        ],
        porQuestao: [
          ResultadoQuestao(
            numero: 1,
            alternativaCorreta: 'C',
            percentualAcerto: 85.0,
            alternativas: [
              AlternativaDistribuicao(letra: 'C', quantidade: 17, percentual: 85.0, correta: true),
            ],
          ),
        ],
        porAluno: [resultadoAluno],
      );

      final mapResumo = resumoAgregado.toFirestoreResumo();
      expect(mapResumo['media'], equals(7.8));
      expect(mapResumo['minimo'], equals(4.0));
      expect(mapResumo['maximo'], equals(10.0));
      expect(mapResumo['totalFolhasCorrigidas'], equals(1));
      expect((mapResumo['distribuicao'] as List).length, equals(2));
      expect((mapResumo['porQuestao'] as List).length, equals(1));
    });
  });
}
