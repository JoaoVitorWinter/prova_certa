// test/rules_test.js - Teste automatizado de regras de segurança do Firestore
// Para executar com Firebase Emulator (usando JDK 21+):
// $env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-25.0.4.7-hotspot"; $env:PATH = "$env:JAVA_HOME\bin;$env:PATH"; firebase emulators:exec --project demo-prova-certa --only firestore "node test/rules_test.js"

const assert = require('assert');

// Gera token JWT de mentira (alg: none) aceito nativamente pelo Firestore Emulator
function createEmulatorToken(userId, email) {
  const header = Buffer.from(JSON.stringify({ alg: 'none', typ: 'JWT' })).toString('base64url');
  const payload = Buffer.from(JSON.stringify({
    iss: 'https://securetoken.google.com/demo-prova-certa',
    aud: 'demo-prova-certa',
    auth_time: Math.floor(Date.now() / 1000),
    user_id: userId,
    sub: userId,
    email: email || `${userId}@escola.edu.br`,
    email_verified: true,
    firebase: { sign_in_provider: 'password' }
  })).toString('base64url');
  return `${header}.${payload}.`;
}

const BASE_URL = 'http://localhost:8080/v1/projects/demo-prova-certa/databases/(default)/documents';

async function firestoreRequest(path, method = 'GET', body = null, token = null) {
  const headers = { 'Content-Type': 'application/json' };
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }
  const url = `${BASE_URL}/${path}`;
  const response = await fetch(url, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined
  });
  let data = null;
  try {
    data = await response.json();
  } catch (_) {}
  return { status: response.status, data };
}

async function runTests() {
  console.log('========================================================');
  console.log('   SUÍTE DE TESTES DE REGRAS DE SEGURANÇA FIRESTORE     ');
  console.log('========================================================\n');
  
  const tokenAna = createEmulatorToken('prof_ana_1', 'ana@escola.edu.br');
  const tokenBruno = createEmulatorToken('prof_bruno_2', 'bruno@escola.edu.br');

  let passed = 0;
  let failed = 0;

  async function check(desc, fn) {
    try {
      await fn();
      console.log(`  [PASS] ${desc}`);
      passed++;
    } catch (e) {
      console.error(`  [FAIL] ${desc}: ${e.message}`);
      failed++;
    }
  }

  console.log('--- 1. USUÁRIO NÃO AUTENTICADO ---');
  await check('Usuário anônimo NÃO PODE ler /usuarios/prof_ana_1', async () => {
    const res = await firestoreRequest('usuarios/prof_ana_1', 'GET', null, null);
    assert.strictEqual(res.status, 403, `Esperado 403, obtido ${res.status}`);
  });

  await check('Usuário anônimo NÃO PODE criar /usuarios/prof_ana_1', async () => {
    const body = { fields: { nome: { stringValue: 'Invasor' }, email: { stringValue: 'hack@escola.com' } } };
    const res = await firestoreRequest('usuarios/prof_ana_1', 'PATCH', body, null);
    assert.strictEqual(res.status, 403, `Esperado 403, obtido ${res.status}`);
  });

  console.log('\n--- 2. PROFESSOR ACESSANDO SEUS PRÓPRIOS DADOS ---');
  await check('Professora Ana PODE criar seu perfil /usuarios/prof_ana_1', async () => {
    const body = {
      fields: {
        nome: { stringValue: 'Ana Paula Santos' },
        email: { stringValue: 'ana@escola.edu.br' },
        instituicao: { stringValue: 'E.E. Prof. Antônio Lemos' }
      }
    };
    const res = await firestoreRequest('usuarios/prof_ana_1', 'PATCH', body, tokenAna);
    assert.strictEqual(res.status, 200, `Esperado 200, obtido ${res.status}: ${JSON.stringify(res.data)}`);
  });

  await check('Professora Ana PODE ler seu próprio perfil', async () => {
    const res = await firestoreRequest('usuarios/prof_ana_1', 'GET', null, tokenAna);
    assert.strictEqual(res.status, 200, `Esperado 200, obtido ${res.status}`);
  });

  await check('Professora Ana PODE atualizar seu próprio perfil', async () => {
    const body = {
      fields: {
        nome: { stringValue: 'Ana Paula Santos Silva' },
        email: { stringValue: 'ana@escola.edu.br' },
        instituicao: { stringValue: 'Colégio Estadual Modelo' }
      }
    };
    const res = await firestoreRequest('usuarios/prof_ana_1', 'PATCH', body, tokenAna);
    assert.strictEqual(res.status, 200, `Esperado 200, obtido ${res.status}`);
  });

  console.log('\n--- 3. ISOLAMENTO MULTI-TENANT (PROFESSOR A vs PROFESSOR B) ---');
  await check('Professor Bruno NÃO PODE ler o perfil da Professora Ana', async () => {
    const res = await firestoreRequest('usuarios/prof_ana_1', 'GET', null, tokenBruno);
    assert.strictEqual(res.status, 403, `Esperado 403, obtido ${res.status}`);
  });

  await check('Professor Bruno NÃO PODE alterar o perfil da Professora Ana', async () => {
    const body = { fields: { nome: { stringValue: 'Hacked by Bruno' } } };
    const res = await firestoreRequest('usuarios/prof_ana_1', 'PATCH', body, tokenBruno);
    assert.strictEqual(res.status, 403, `Esperado 403, obtido ${res.status}`);
  });

  await check('Professor Bruno NÃO PODE excluir o perfil da Professora Ana', async () => {
    const res = await firestoreRequest('usuarios/prof_ana_1', 'DELETE', null, tokenBruno);
    assert.strictEqual(res.status, 403, `Esperado 403, obtido ${res.status}`);
  });

  console.log('\n--- 4. VALIDAÇÃO DE CAMPOS E DADOS INVÁLIDOS NO PERFIL ---');
  await check('Professora Ana NÃO PODE incluir campo "senha" no perfil', async () => {
    const body = {
      fields: {
        nome: { stringValue: 'Ana Paula' },
        email: { stringValue: 'ana@escola.edu.br' },
        senha: { stringValue: '123456' } // PROIBIDO
      }
    };
    const res = await firestoreRequest('usuarios/prof_ana_1', 'PATCH', body, tokenAna);
    assert.strictEqual(res.status, 403, `Esperado 403, obtido ${res.status}`);
  });

  await check('Professora Ana NÃO PODE incluir campos desconhecidos (hasOnly)', async () => {
    const body = {
      fields: {
        nome: { stringValue: 'Ana Paula' },
        email: { stringValue: 'ana@escola.edu.br' },
        campo_inexistente: { stringValue: 'valor' } // PROIBIDO
      }
    };
    const res = await firestoreRequest('usuarios/prof_ana_1', 'PATCH', body, tokenAna);
    assert.strictEqual(res.status, 403, `Esperado 403, obtido ${res.status}`);
  });

  console.log('\n--- 5. SUBCOLEÇÃO: TURMAS ---');
  await check('Professora Ana PODE criar turma em /usuarios/prof_ana_1/turmas/t1', async () => {
    const body = {
      fields: {
        nome: { stringValue: '1º A' },
        ano: { stringValue: '1º Ano' },
        disciplina: { stringValue: 'Biologia' },
        periodo: { stringValue: 'Manhã' },
        quantidadeAlunos: { integerValue: '0' }
      }
    };
    const res = await firestoreRequest('usuarios/prof_ana_1/turmas/t1', 'PATCH', body, tokenAna);
    assert.strictEqual(res.status, 200, `Esperado 200, obtido ${res.status}`);
  });

  await check('Professora Ana PODE atualizar quantidadeAlunos com incremento numérico', async () => {
    const body = {
      fields: {
        nome: { stringValue: '1º A' },
        ano: { stringValue: '1º Ano' },
        disciplina: { stringValue: 'Biologia' },
        periodo: { stringValue: 'Manhã' },
        quantidadeAlunos: { integerValue: '1' } // Simula FieldValue.increment(1)
      }
    };
    const res = await firestoreRequest('usuarios/prof_ana_1/turmas/t1', 'PATCH', body, tokenAna);
    assert.strictEqual(res.status, 200, `Esperado 200, obtido ${res.status}`);
  });

  await check('Professora Ana NÃO PODE salvar lista de alunos embutida no doc da turma', async () => {
    const body = {
      fields: {
        nome: { stringValue: '1º B' },
        ano: { stringValue: '1º Ano' },
        disciplina: { stringValue: 'Biologia' },
        periodo: { stringValue: 'Tarde' },
        alunos: { arrayValue: { values: [{ stringValue: 'aluno1' }] } } // PROIBIDO
      }
    };
    const res = await firestoreRequest('usuarios/prof_ana_1/turmas/t2', 'PATCH', body, tokenAna);
    assert.strictEqual(res.status, 403, `Esperado 403, obtido ${res.status}`);
  });

  await check('Professor Bruno NÃO PODE ler as turmas da Professora Ana', async () => {
    const res = await firestoreRequest('usuarios/prof_ana_1/turmas/t1', 'GET', null, tokenBruno);
    assert.strictEqual(res.status, 403, `Esperado 403, obtido ${res.status}`);
  });

  await check('Professor Bruno NÃO PODE excluir a turma da Professora Ana', async () => {
    const res = await firestoreRequest('usuarios/prof_ana_1/turmas/t1', 'DELETE', null, tokenBruno);
    assert.strictEqual(res.status, 403, `Esperado 403, obtido ${res.status}`);
  });

  console.log('\n--- 6. SUBCOLEÇÃO: ALUNOS DA TURMA ---');
  await check('Professora Ana PODE adicionar aluno em /usuarios/prof_ana_1/turmas/t1/alunos/a1', async () => {
    const body = {
      fields: {
        nome: { stringValue: 'Lucas Silva' },
        ra: { stringValue: '001234' } // Preservando String
      }
    };
    const res = await firestoreRequest('usuarios/prof_ana_1/turmas/t1/alunos/a1', 'PATCH', body, tokenAna);
    assert.strictEqual(res.status, 200, `Esperado 200, obtido ${res.status}`);
  });

  await check('Aluno SEM RA ou com RA vazio é REJEITADO', async () => {
    const body = {
      fields: {
        nome: { stringValue: 'Aluno Sem RA' },
        ra: { stringValue: '' } // Inválido (vazio)
      }
    };
    const res = await firestoreRequest('usuarios/prof_ana_1/turmas/t1/alunos/a_invalido', 'PATCH', body, tokenAna);
    assert.strictEqual(res.status, 403, `Esperado 403, obtido ${res.status}`);
  });

  await check('Professor Bruno NÃO PODE ler os alunos da turma da Professora Ana', async () => {
    const res = await firestoreRequest('usuarios/prof_ana_1/turmas/t1/alunos/a1', 'GET', null, tokenBruno);
    assert.strictEqual(res.status, 403, `Esperado 403, obtido ${res.status}`);
  });

  console.log('\n--- 7. SUBCOLEÇÃO: QUESTÕES (BANCO DO PROFESSOR) ---');
  await check('Professora Ana PODE criar questão com 4 alternativas', async () => {
    const body = {
      fields: {
        enunciado: { stringValue: 'O que é mitocôndria?' },
        correta: { stringValue: 'A' },
        assunto: { stringValue: 'Citologia' },
        dificuldade: { stringValue: 'Fácil' },
        disciplina: { stringValue: 'Biologia' },
        alternativas: {
          arrayValue: {
            values: [
              { mapValue: { fields: { letra: { stringValue: 'A' }, texto: { stringValue: 'Respiração celular' } } } },
              { mapValue: { fields: { letra: { stringValue: 'B' }, texto: { stringValue: 'Fotossíntese' } } } },
              { mapValue: { fields: { letra: { stringValue: 'C' }, texto: { stringValue: 'Divisão' } } } },
              { mapValue: { fields: { letra: { stringValue: 'D' }, texto: { stringValue: 'Síntese proteica' } } } }
            ]
          }
        }
      }
    };
    const res = await firestoreRequest('usuarios/prof_ana_1/questoes/q1', 'PATCH', body, tokenAna);
    assert.strictEqual(res.status, 200, `Esperado 200, obtido ${res.status}`);
  });

  await check('Questão com MENOS de 2 alternativas é REJEITADA', async () => {
    const body = {
      fields: {
        enunciado: { stringValue: 'Questão com apenas 1 alternativa' },
        correta: { stringValue: 'A' },
        assunto: { stringValue: 'Geral' },
        dificuldade: { stringValue: 'Fácil' },
        disciplina: { stringValue: 'Biologia' },
        alternativas: {
          arrayValue: {
            values: [
              { mapValue: { fields: { letra: { stringValue: 'A' }, texto: { stringValue: 'Única' } } } }
            ]
          }
        }
      }
    };
    const res = await firestoreRequest('usuarios/prof_ana_1/questoes/q_invalida', 'PATCH', body, tokenAna);
    assert.strictEqual(res.status, 403, `Esperado 403, obtido ${res.status}`);
  });

  await check('Professor Bruno NÃO PODE ler as questões da Professora Ana', async () => {
    const res = await firestoreRequest('usuarios/prof_ana_1/questoes/q1', 'GET', null, tokenBruno);
    assert.strictEqual(res.status, 403, `Esperado 403, obtido ${res.status}`);
  });

  console.log('\n--- 8. SUBCOLEÇÃO: PROVAS ---');
  await check('Professora Ana PODE criar Prova com status válido (ativa)', async () => {
    const body = {
      fields: {
        nome: { stringValue: '1ª Prova Bimestral' },
        turmaId: { stringValue: 't1' },
        status: { stringValue: 'ativa' },
        quantidadeQuestoes: { integerValue: '10' }
      }
    };
    const res = await firestoreRequest('usuarios/prof_ana_1/provas/p1', 'PATCH', body, tokenAna);
    assert.strictEqual(res.status, 200, `Esperado 200, obtido ${res.status}`);
  });

  await check('Prova com STATUS INVÁLIDO ("cancelada") é REJEITADA', async () => {
    const body = {
      fields: {
        nome: { stringValue: 'Prova Status Inválido' },
        turmaId: { stringValue: 't1' },
        status: { stringValue: 'cancelada' }, // Inválido (deve ser rascunho, ativa ou encerrada)
        quantidadeQuestoes: { integerValue: '10' }
      }
    };
    const res = await firestoreRequest('usuarios/prof_ana_1/provas/p_invalida', 'PATCH', body, tokenAna);
    assert.strictEqual(res.status, 403, `Esperado 403, obtido ${res.status}`);
  });

  await check('Professor Bruno NÃO PODE ler as provas da Professora Ana', async () => {
    const res = await firestoreRequest('usuarios/prof_ana_1/provas/p1', 'GET', null, tokenBruno);
    assert.strictEqual(res.status, 403, `Esperado 403, obtido ${res.status}`);
  });

  console.log('\n--- 9. SUBCOLEÇÃO: RESULTADOS ---');
  await check('Professora Ana PODE registrar resultado do aluno na prova', async () => {
    const body = {
      fields: {
        alunoId: { stringValue: 'a1' },
        alunoNome: { stringValue: 'Lucas Silva' },
        alunoRa: { stringValue: '001234' },
        nota: { doubleValue: 9.5 },
        acertos: { integerValue: '9' },
        totalQuestoes: { integerValue: '10' },
        alternativasMarcadas: { arrayValue: { values: [{ stringValue: 'A' }, { stringValue: 'B' }] } }
      }
    };
    const res = await firestoreRequest('usuarios/prof_ana_1/provas/p1/resultados/a1', 'PATCH', body, tokenAna);
    assert.strictEqual(res.status, 200, `Esperado 200, obtido ${res.status}`);
  });

  await check('Professor Bruno NÃO PODE ler resultados da prova da Ana', async () => {
    const res = await firestoreRequest('usuarios/prof_ana_1/provas/p1/resultados/a1', 'GET', null, tokenBruno);
    assert.strictEqual(res.status, 403, `Esperado 403, obtido ${res.status}`);
  });

  await check('Professor Bruno NÃO PODE excluir resultados da prova da Ana', async () => {
    const res = await firestoreRequest('usuarios/prof_ana_1/provas/p1/resultados/a1', 'DELETE', null, tokenBruno);
    assert.strictEqual(res.status, 403, `Esperado 403, obtido ${res.status}`);
  });

  console.log(`\n========================================================`);
  console.log(`  RESULTADO DAS REGRAS: ${passed} PASSARAM, ${failed} FALHARAM`);
  console.log(`========================================================`);
  if (failed > 0) process.exit(1);
}

runTests().catch(err => {
  console.error('Erro na execução dos testes:', err);
  process.exit(1);
});
