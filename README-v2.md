<div align="center">

# 🚀 Prova Certa

**Aplicativo para organização de turmas, avaliações e acompanhamento de resultados.**

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Git](https://img.shields.io/badge/Git-F05032?style=for-the-badge&logo=git&logoColor=white)
![GitHub](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white)

![Status](https://img.shields.io/badge/status-em%20desenvolvimento-F5A623?style=flat-square)
![Documentação](https://img.shields.io/badge/documenta%C3%A7%C3%A3o-N3-3D348B?style=flat-square)
![Categoria](https://img.shields.io/badge/projeto-acad%C3%AAmico-7B4FA6?style=flat-square)

</div>

## 👥 Equipe

<!-- Substitua o campo abaixo pelos nomes completos dos integrantes antes da entrega. -->

| Nome completo |
| --- |
| *Carlos Henrique Lechner* |
| *Gabriel Fellipe Marquardt* |
| *João Vitor Winter* |
| *Kayky Rocha* |
| *Mateus Zeviani Rodrigues* |

## 📑 Sumário

- [1. Visão Geral](#1-visão-geral)
  - [1.1 Objetivo do Projeto](#11-objetivo-do-projeto)
  - [1.2 Escopo](#12-escopo)
- [2. Requisitos](#2-requisitos)
  - [2.1 Funcionais (RF)](#21-funcionais-rf)
  - [2.2 Não Funcionais (RNF)](#22-não-funcionais-rnf)
- [3. Telas do Sistema](#3-telas-do-sistema)
- [4. Modelo de Dados](#4-modelo-de-dados)
- [5. Stack Tecnológica](#5-stack-tecnológica)
- [6. Estrutura de Pastas](#6-estrutura-de-pastas)
- [7. Como Executar o Projeto](#7-como-executar-o-projeto)
- [8. Backlog de Atividades da N2](#8-backlog-de-atividades-da-n2)

---

## 1. Visão Geral

📌 **N1**

O **Prova Certa** é um aplicativo desenvolvido em **Flutter e Dart**, voltado à gestão de avaliações escolares. A plataforma tem como objetivo facilitar a rotina dos professores, centralizando o gerenciamento de turmas, alunos, provas, correções e resultados em um ambiente digital organizado e intuitivo.

A aplicação utiliza o **Firebase Authentication** para autenticação dos usuários e o **Cloud Firestore** para armazenamento e gerenciamento dos dados em nuvem. Cada professor possui um ambiente individualizado, garantindo a organização, a privacidade e o isolamento das informações vinculadas à sua conta.

Entre suas funcionalidades estão o cadastro e gerenciamento de turmas e alunos, a importação de listas por arquivos CSV e XLSX, o fluxo de correção de avaliações, a visualização de resultados e a exportação de notas. O sistema também oferece um painel inicial com indicadores acadêmicos e acesso rápido às principais funcionalidades.

O Prova Certa busca proporcionar uma experiência prática e eficiente, contribuindo para a **digitalização dos processos avaliativos, a redução de tarefas manuais e o acompanhamento do desempenho dos alunos**.

### 1.1 Objetivo do Projeto

O objetivo principal é facilitar a rotina do professor por meio de uma solução que permita:

- cadastrar-se, autenticar-se e gerenciar sua sessão;
- cadastrar, consultar, editar e excluir turmas e alunos;
- importar alunos por arquivos **CSV** e **XLSX**;
- consultar um painel com indicadores e correções recentes;
- cadastrar, consultar, editar e excluir questões do banco de questões;
- criar provas a partir das questões cadastradas, associando-as às turmas;
- consultar provas, acompanhar seus estados e gerenciá-las;
- gerar e ler o QR Code do gabarito das avaliações;
- capturar imagens das folhas de resposta e conferir as alternativas identificadas pelo leitor experimental;
- calcular, armazenar e consultar resultados de correções;
- analisar o desempenho por avaliação, questão e aluno;
- exportar e compartilhar resultados em arquivos CSV;
- consultar e atualizar as informações do perfil docente.

A finalidade é reduzir a dependência de registros manuais, melhorar a organização de avaliações e evoluir a precisão e a confiabilidade do processo de correção automatizada.

### 1.2 Escopo

#### 1.2.1. Funcionalidades implementadas com Firebase

- **Autenticação:** cadastro de usuário, login, manutenção da sessão, encerramento de sessão e solicitação de redefinição de senha por e-mail.
- **Perfil do professor:** criação, consulta e atualização das informações do usuário armazenadas no Firestore.
- **Turmas:** cadastro, listagem, consulta de detalhes, edição e exclusão, com persistência no Firestore.
- **Alunos:** cadastro, listagem, edição e exclusão de alunos associados a uma turma.
- **Importação de alunos:** leitura e processamento de arquivos CSV/XLSX, com validação de registros e tratamento de duplicidades.
- **Banco de questões:** cadastro, consulta, listagem, edição e exclusão de questões, com persistência no Firestore.
- **Provas:** criação, listagem, filtros por situação, alteração de status e exclusão de avaliações cadastradas, com persistência no Firestore.
- **Composição de provas:** seleção de questões existentes e armazenamento de suas referências e informações na prova.
- **QR Code:** geração e exibição do QR Code de uma prova cadastrada e leitura do código no fluxo de correção.
- **Dashboard:** apresentação de informações associadas aos dados do professor, como quantidade de alunos, correções e atividades recentes disponíveis.
- **Correções e resultados:** cálculo e persistência dos resultados gerados pelo fluxo de correção, com consultas por aluno e por questão.
- **Exportação:** geração de arquivos CSV de notas e análise por questão, com possibilidade de compartilhamento pelo dispositivo.
- **Segurança e navegação:** associação das informações ao UID autenticado, regras de acesso do Firestore e controle de acesso a telas por sessão.

#### 1.2.2. Funcionalidades parciais ou experimentais

| Módulo | Estado atual | Limitação |

| --- | --- | --- |

| Gestão de provas | **Parcialmente implementado** | Permite criar, listar, alterar o status e excluir provas; a edição completa de uma prova já cadastrada não foi identificada. |

| Leitura das folhas de resposta | **Experimental** | Analisa fotografias e tenta identificar alternativas marcadas por processamento de imagem, exigindo alinhamento adequado e conferência manual. |

| Identificação dos alunos nas folhas | **Manual** | O professor seleciona o aluno correspondente à folha; não há reconhecimento automático do nome ou RA escrito. |

| Versões e embaralhamento de questões | **Parcial** | Existem estruturas para versões, mas a integração completa ao fluxo principal não foi identificada. |

| Algumas configurações | **Demonstrativo/parcial** | As telas podem estar disponíveis sem persistência ou aplicação integral das preferências. |

**Importante:** a detecção de alternativas nas folhas é experimental e depende da revisão do professor. A existência do leitor de imagem não significa que o aplicativo já realize correção totalmente automática e validada em diferentes condições de captura.

#### 1.2.3. Fora do escopo implementado nesta versão

- reconhecimento robusto das marcações em diferentes modelos de folhas e condições de captura;
- identificação automática do aluno por nome ou RA manuscrito na folha;
- edição completa de provas já cadastradas, incluindo alterações de suas questões e configurações;
- integração completa da geração e distribuição de versões de prova;
- funcionamento totalmente offline e sincronização posterior;
- disponibilização do aplicativo como produto final em produção.

## 2. Requisitos

📌 **N1** — atualizados para refletir a integração com o Firebase e as funcionalidades atuais.

### 2.1 Funcionais (RF)

Os requisitos a seguir descrevem as funções previstas para a aplicação e indicam o estágio atual de atendimento.

| ID | Requisito | Estado |

| --- | --- | --- |

| **RF01** | O sistema deve permitir o **cadastro de professores**, utilizando e-mail e senha e criando o respectivo perfil no banco de dados. | Implementado |

| **RF02** | O sistema deve permitir **login, manutenção da sessão e logout** por meio do Firebase Authentication. | Implementado |

| **RF03** | O sistema deve permitir solicitar a **redefinição de senha por e-mail**. | Implementado |

| **RF04** | O sistema deve apresentar um **dashboard** com indicadores associados aos dados armazenados e atalhos para as funções principais. | Implementado |

| **RF05** | O sistema deve permitir **cadastrar, listar, consultar, editar e excluir turmas** do professor autenticado. | Implementado |

| **RF06** | O sistema deve permitir **cadastrar, listar, editar e excluir alunos** vinculados às turmas. | Implementado |

| **RF07** | O sistema deve permitir **importar alunos por arquivos CSV e XLSX**, validando os registros e tratando duplicidades. | Implementado |

| **RF08** | O sistema deve permitir **consultar e editar o perfil** do professor, persistindo as alterações no Firestore. | Implementado |

| **RF09** | O sistema deve permitir **cadastrar, listar, consultar, editar e excluir questões** no banco de questões. | Implementado |

| **RF10** | O sistema deve permitir **selecionar questões cadastradas** para compor uma prova. | Implementado |

| **RF11** | O sistema deve permitir **criar e armazenar provas** vinculadas às turmas, incluindo questões e gabarito. | Implementado |

| **RF12** | O sistema deve apresentar uma **lista de provas com filtros**, permitir a alteração de status e a exclusão de avaliações. | Implementado |

| **RF13** | O sistema deve permitir **editar integralmente uma prova existente**, incluindo seus dados e a composição de questões. | Não identificado na versão atual |

| **RF14** | O sistema deve permitir **gerar e exibir o QR Code** correspondente à prova e ao gabarito. | Implementado |

| **RF15** | O sistema deve oferecer a **leitura do QR Code do gabarito** como etapa da correção. | Implementado |

| **RF16** | O sistema deve permitir **capturar folhas de resposta e identificar possíveis marcações** para conferência do professor. | Experimental |

| **RF17** | O sistema deve permitir **associar a folha ao aluno**, conferir as respostas e finalizar a correção com alunos ausentes ou pendentes. | Implementado com conferência manual |

| **RF18** | O sistema deve **calcular notas e acertos**, gerar um resumo da correção e salvar os resultados no Firestore. | Implementado |

| **RF19** | O sistema deve apresentar **resultados por prova, questão e aluno**, incluindo médias, distribuição de notas e percentuais de acerto. | Implementado |

| **RF20** | O sistema deve **exportar e compartilhar notas e análises por questão em CSV**, compatível com planilhas. | Implementado |

| **RF21** | O sistema deve disponibilizar **navegação entre os módulos, proteção por sessão e telas complementares** do aplicativo. | Implementado; algumas configurações são demonstrativas |

### 2.2 Não Funcionais (RNF)

| ID | Requisito | Descrição |

| --- | --- | --- |

| **RNF01 — Usabilidade** | Interface intuitiva | A navegação e os formulários devem apresentar informações, ações e mensagens compreensíveis ao professor. |

| **RNF02 — Responsividade** | Adaptação visual | A interface deve se adaptar aos tamanhos de tela suportados, especialmente em dispositivos Android. |

| **RNF03 — Segurança de acesso** | Autenticação | As funcionalidades protegidas devem exigir sessão autenticada pelo Firebase Authentication. |

| **RNF04 — Isolamento de dados** | Autorização | Os registros devem estar vinculados a `usuarios/{uid}` e protegidos por regras que impeçam acesso entre usuários distintos. |

| **RNF05 — Persistência** | Banco de dados | Os módulos integrados devem gravar e recuperar informações no Cloud Firestore, sem depender exclusivamente do estado local. |

| **RNF06 — Integridade dos dados** | Validação | Os campos obrigatórios, relações entre entidades e registros importados devem ser validados, reduzindo duplicidades e inconsistências. |

| **RNF07 — Manutenibilidade** | Organização do código | O projeto deve manter a separação entre telas, modelos, serviços, componentes reutilizáveis e dados auxiliares. |

| **RNF08 — Evolutividade** | Expansão | A arquitetura deve permitir aprimorar o reconhecimento das folhas e integrar funcionalidades complementares. |

| **RNF09 — Compatibilidade** | Plataforma e arquivos | O aplicativo deve executar nas plataformas configuradas no Firebase e produzir arquivos CSV que possam ser abertos em programas de planilha. |

| **RNF10 — Tratamento de falhas** | Experiência do usuário | Falhas de autenticação, validação, rede e operações no banco devem ser tratadas e apresentadas com mensagens adequadas. |

| **RNF11 — Conectividade** | Operações remotas | As operações que consultam o Firebase dependem de conectividade adequada; não há garantia de funcionamento offline completo. |

| **RNF12 — Testabilidade** | Qualidade | O projeto deve permitir análise estática, execução de testes automatizados e validação das regras e dos fluxos de persistência. |

## 3. Telas do Sistema

📌 **N2**

| Tela ou módulo | Finalidade | Estado |

| --- | --- | --- |

| **Login** | Autenticar o professor por e-mail e senha. | Integrada ao Firebase Auth |

| **Cadastro** | Criar a conta e o perfil inicial do professor. | Integrada ao Firebase Auth/Firestore |

| **Recuperação de senha** | Solicitar envio do e-mail de redefinição. | Integrada ao Firebase Auth |

| **Home / Dashboard** | Mostrar atalhos, contadores e informações disponíveis do professor. | Integrada aos dados persistidos |

| **Turmas** | Consultar e gerenciar as turmas cadastradas. | Integrada ao Firestore |

| **Cadastro / edição de turma** | Criar ou atualizar as informações de uma turma. | Integrada ao Firestore |

| **Detalhes da turma** | Exibir dados da turma e alunos associados. | Integrada ao Firestore |

| **Cadastro / edição de aluno** | Manter os registros dos estudantes. | Integrada ao Firestore |

| **Importação de alunos** | Importar estudantes por arquivo CSV ou XLSX. | Integrada ao Firestore |

| **Provas** | Apresentar a lista e os filtros de avaliações e ações de gerenciamento. | Integrada ao Firestore |

| **Nova prova** | Criar uma prova, selecionar questões e salvar seus dados. | Integrada ao Firestore |

| **Banco de questões** | Consultar, cadastrar, editar e excluir questões. | Integrada ao Firestore |

| **Seleção de questões** | Escolher questões cadastradas para uma avaliação. | Integrada ao Firestore |

| **Correção de prova** | Iniciar e acompanhar a correção de uma avaliação. | Funcional, com etapa experimental de leitura |

| **QR Code da prova** | Gerar e exibir o código do gabarito da avaliação. | Implementado |

| **Leitura do QR Code** | Capturar e validar o código do gabarito. | Implementado |

| **Leitura de folhas** | Fotografar a folha, identificar possíveis respostas e permitir conferência. | Experimental |

| **Resultados** | Exibir resumos e detalhes por questão e aluno. | Integrada ao Firestore |

| **Exportação / compartilhamento** | Gerar e compartilhar arquivos CSV. | Funcional |

| **Perfil** | Consultar informações do docente. | Integrada ao Firestore |

| **Editar perfil** | Atualizar dados do professor. | Integrada ao Firestore |

| **Configurações / notificações / aparência / sobre** | Apresentar opções e informações complementares. | Algumas funções demonstrativas |

### 3.1 Fluxo Principal de Utilização

1\. O professor cria uma conta ou entra com suas credenciais.

2\. Após a validação da sessão e do perfil, acessa a **Home**.

3\. Cadastra turmas e alunos manualmente ou importa uma lista CSV/XLSX.

4\. Consulta os indicadores e navega entre **Turmas, Provas, Correção, Resultados e Perfil**.

5\. Cadastra questões no banco e as seleciona para compor uma nova prova.

6\. Salva a prova no Firestore e gera seu QR Code com as informações do gabarito.

7\. No fluxo de correção, lê o QR Code, fotografa as folhas e revisa as respostas identificadas antes de confirmar.

8\. O sistema calcula as notas e salva os resultados da correção no Firestore.

9\. O professor visualiza as análises e pode exportar e compartilhar as informações em CSV.

### 3.2 Capturas das Telas Principais

As imagens devem representar o aplicativo em execução e seguir a sequência de navegação apresentada na seção anterior. **Os prints não acompanharam os arquivos enviados**; por isso, os locais abaixo estão preparados sem criar referências quebradas no GitHub.

<!--
Após adicionar os arquivos reais em docs/telas/, descomente os blocos desejados:

![Tela de login](docs/telas/tela-login.png)
*Tela de login: autenticação do professor por e-mail e senha.*

![Tela inicial](docs/telas/tela-home.png)
*Tela inicial: indicadores e acesso aos módulos do aplicativo.*

![Tela de turmas](docs/telas/tela-turmas.png)
*Tela de turmas: consulta e gerenciamento das turmas cadastradas.*

![Tela do banco de questões](docs/telas/tela-questoes.png)
*Banco de questões: cadastro e consulta das questões do professor.*

![Tela de nova prova](docs/telas/tela-nova-prova.png)
*Nova prova: configuração e seleção de questões para a avaliação.*

![Tela de correção](docs/telas/tela-correcao.png)
*Correção: leitura de QR Code e conferência das respostas identificadas.*

![Tela de resultados](docs/telas/tela-resultados.png)
*Resultados: análise do desempenho por prova, questão e aluno.*

![Tela de perfil](docs/telas/tela-perfil.png)
*Perfil: consulta e atualização das informações do professor.*
-->

## 4. Modelo de Dados

📌 **N3**

O aplicativo usa o **Cloud Firestore**, que organiza as informações em documentos e coleções NoSQL. A estrutura é separada pelo **UID do professor**, permitindo que cada conta mantenha seus registros individualizados.

### 4.1 Integração com o Firebase e Organização das Coleções

#### 4.1.1 Autenticação

O aplicativo usa **Firebase Authentication** para cadastro, login, sessão, logout e solicitação de recuperação de senha. A identidade do usuário autenticado é representada por um **UID**, utilizado como referência para seus dados no Firestore.

As senhas são gerenciadas pelo serviço de autenticação e **não devem ser armazenadas nos documentos do Cloud Firestore**.

#### 4.1.2 Cloud Firestore

O Cloud Firestore armazena os dados persistentes em uma organização vinculada ao professor:

```text

usuarios/

  {uid}/                         perfil do professor

    turmas/

      {turmaId}/                 dados da turma

        alunos/

          {alunoId}              dados do aluno

    questoes/

      {questaoId}                 enunciado, alternativas e resposta correta

    provas/

      {provaId}/                 turma, status, questões, gabarito

                                 e resumoResultado

        resultados/

          {alunoId}              nota, acertos e respostas do aluno

```

#### 4.1.3 Isolamento dos Dados

O aplicativo foi estruturado para que cada professor acesse suas informações usando o próprio UID. As regras do Firestore devem validar a autenticação e a titularidade dos documentos, impedindo que um usuário leia ou modifique dados pertencentes a outro.

### 4.2 Exemplos de Documentos e Dicionário de Dados

Os exemplos abaixo representam os **campos usados pela aplicação**, com valores ilustrativos e sem dados pessoais reais. Eles foram montados a partir dos modelos e serviços Dart do projeto. Nos exemplos JSON, os valores de datas são exibidos como texto ISO 8601 para facilitar a leitura; **no Cloud Firestore, esses campos são armazenados como `Timestamp`**. O identificador entre chaves no caminho é o ID do documento, e pode ou não aparecer duplicado no corpo do documento conforme a operação de gravação.

#### 4.2.1 Professores (usuarios)

**Caminho:** `usuarios/{uid}`

```json
{
  "nome": "Maria Silva",
  "email": "professora@exemplo.com",
  "instituicao": "Escola Exemplo",
  "fotoUrl": null,
  "criadoEm": "2026-10-29T13:00:00Z",
  "atualizadoEm": "2026-10-29T13:00:00Z"
}
```

| Campo | Tipo | Descrição |
| --- | --- | --- |
| `nome` | String | Nome do professor. |
| `email` | String | E-mail de cadastro. |
| `instituicao` | String | Instituição informada no perfil. |
| `fotoUrl` | String ou null | Endereço da imagem de perfil, quando houver. |
| `criadoEm` | Timestamp | Data de criação do registro. |
| `atualizadoEm` | Timestamp | Data da última atualização. |

O **UID** é fornecido pelo Firebase Authentication e identifica o documento do professor. As senhas não são gravadas no Firestore.

#### 4.2.2 Turmas

**Caminho:** `usuarios/{uid}/turmas/{turmaId}`

```json
{
  "id": "turma-exemplo",
  "nome": "8º Ano A",
  "ano": "2026",
  "disciplina": "Matemática",
  "periodo": "Matutino",
  "quantidadeAlunos": 2,
  "criadoEm": "2026-10-29T13:00:00Z",
  "atualizadoEm": "2026-10-29T13:00:00Z"
}
```

| Campo | Tipo | Descrição |
| --- | --- | --- |
| `id` | String | Identificador da turma, também usado no caminho. |
| `nome` | String | Nome da turma. |
| `ano` | String | Ano de referência. |
| `disciplina` | String | Disciplina vinculada. |
| `periodo` | String | Período ou turno da turma. |
| `quantidadeAlunos` | Number (inteiro) | Quantidade de alunos associados. |
| `criadoEm` | Timestamp | Data da criação. |
| `atualizadoEm` | Timestamp | Data da última alteração. |

Os alunos são registrados em uma **subcoleção**, não em uma lista embutida no documento da turma.

#### 4.2.3 Alunos

**Caminho:** `usuarios/{uid}/turmas/{turmaId}/alunos/{alunoId}`

```json
{
  "nome": "Ana Costa",
  "ra": "000123",
  "criadoEm": "2026-10-29T13:00:00Z",
  "atualizadoEm": "2026-10-29T13:00:00Z"
}
```

| Campo | Tipo | Descrição |
| --- | --- | --- |
| `nome` | String | Nome do aluno. |
| `ra` | String | Registro acadêmico, preservando zeros à esquerda. |
| `criadoEm` | Timestamp | Data da criação. |
| `atualizadoEm` | Timestamp | Data da última alteração. |

O identificador do aluno é o ID do documento (`{alunoId}`), utilizado para as relações com a correção.

#### 4.2.4 Banco de Questões

**Caminho:** `usuarios/{uid}/questoes/{questaoId}`

```json
{
  "id": "questao-exemplo",
  "enunciado": "Quanto é 2 + 2?",
  "alternativas": [
    {
      "letra": "A",
      "texto": "3"
    },
    {
      "letra": "B",
      "texto": "4"
    },
    {
      "letra": "C",
      "texto": "5"
    },
    {
      "letra": "D",
      "texto": "6"
    }
  ],
  "correta": "B",
  "assunto": "Adição",
  "dificuldade": "Fácil",
  "disciplina": "Matemática",
  "criadoEm": "2026-10-29T13:00:00Z",
  "atualizadoEm": "2026-10-29T13:00:00Z"
}
```

| Campo | Tipo | Descrição |
| --- | --- | --- |
| `id` | String | Identificador da questão. |
| `enunciado` | String | Texto da questão. |
| `alternativas` | Array<Map> | Alternativas com os campos `letra` e `texto`. |
| `correta` | String | Letra da alternativa correta. |
| `assunto` | String | Tema da questão. |
| `dificuldade` | String | Nível de dificuldade. |
| `disciplina` | String | Disciplina associada. |
| `criadoEm` | Timestamp | Data da criação. |
| `atualizadoEm` | Timestamp | Data da última alteração. |

Cada alternativa é um **objeto embutido** no documento da questão, e não uma coleção independente.

#### 4.2.5 Provas

**Caminho:** `usuarios/{uid}/provas/{provaId}`

```json
{
  "id": "prova-exemplo",
  "nome": "Avaliação 1 - Matemática",
  "turmaId": "turma-exemplo",
  "turmaNome": "8º Ano A",
  "turmaAno": "2026",
  "turmaDisciplina": "Matemática",
  "turmaPeriodo": "Matutino",
  "dataAplicacao": "2026-10-30T12:00:00Z",
  "quantidadeQuestoes": 1,
  "status": "encerrada",
  "embaralharQuestoes": false,
  "embaralharAlternativas": false,
  "numeroVersoes": 1,
  "questoesIds": [
    "questao-exemplo"
  ],
  "questoesSnapshot": [
    {
      "id": "questao-exemplo",
      "enunciado": "Quanto é 2 + 2?",
      "alternativas": [
        {
          "letra": "A",
          "texto": "3"
        },
        {
          "letra": "B",
          "texto": "4"
        },
        {
          "letra": "C",
          "texto": "5"
        },
        {
          "letra": "D",
          "texto": "6"
        }
      ],
      "correta": "B",
      "assunto": "Adição",
      "dificuldade": "Fácil",
      "disciplina": "Matemática",
      "criadoEm": "2026-10-29T13:00:00.000",
      "atualizadoEm": "2026-10-29T13:00:00.000"
    }
  ],
  "gabaritoOficial": [
    "B"
  ],
  "resumoResultado": {
    "media": 10.0,
    "minimo": 10.0,
    "maximo": 10.0,
    "totalFolhasCorrigidas": 1,
    "distribuicao": [
      {
        "faixa": "8-10",
        "quantidade": 1
      }
    ],
    "porQuestao": [
      {
        "numero": 1,
        "alternativaCorreta": "B",
        "percentualAcerto": 100.0,
        "alternativas": [
          {
            "letra": "B",
            "quantidade": 1,
            "percentual": 100.0,
            "correta": true
          }
        ]
      }
    ]
  },
  "criadoEm": "2026-10-29T13:00:00Z",
  "atualizadoEm": "2026-10-29T13:00:00Z"
}
```

| Campo | Tipo | Descrição |
| --- | --- | --- |
| `id` | String | Identificador da prova. |
| `nome` | String | Título da avaliação. |
| `turmaId` | String | Turma à qual a prova pertence. |
| `turmaNome / turmaAno / turmaDisciplina / turmaPeriodo` | String | Informações descritivas da turma associada. |
| `dataAplicacao` | Timestamp | Data planejada para a avaliação. |
| `quantidadeQuestoes` | Number (inteiro) | Quantidade total de questões. |
| `status` | String | Estado da prova, como `rascunho`. |
| `embaralharQuestoes / embaralharAlternativas` | Boolean | Configurações de embaralhamento. |
| `numeroVersoes` | Number (inteiro) | Número de versões previsto. |
| `questoesIds` | Array<String> | Referências aos documentos do banco de questões. |
| `questoesSnapshot` | Array<Map> | Cópia dos dados das questões associados à prova. |
| `gabaritoOficial` | Array<String> (opcional) | Alternativa correta de cada questão. |
| `resumoResultado` | Map (opcional) | Estatísticas agregadas da correção. |
| `criadoEm / atualizadoEm` | Timestamp | Datas de criação e atualização. |

Os campos opcionais `gabaritoOficial` e `resumoResultado` podem estar ausentes até que o fluxo correspondente seja executado. O resumo inclui média, notas mínima e máxima, distribuição, número de folhas corrigidas e dados por questão.

#### 4.2.6 Resultados por Aluno

**Caminho:** `usuarios/{uid}/provas/{provaId}/resultados/{alunoId}`

```json
{
  "alunoId": "aluno-exemplo",
  "alunoNome": "Ana Costa",
  "alunoRa": "000123",
  "nota": 10.0,
  "acertos": 1,
  "totalQuestoes": 1,
  "alternativasMarcadas": [
    "B"
  ],
  "provaId": "prova-exemplo",
  "turmaId": "turma-exemplo",
  "corrigidoEm": "2026-10-29T13:00:00Z"
}
```

| Campo | Tipo | Descrição |
| --- | --- | --- |
| `alunoId` | String | Identificador do aluno. |
| `alunoNome` | String | Nome do aluno no momento da correção. |
| `alunoRa` | String | Registro acadêmico do aluno. |
| `nota` | Number (decimal) | Nota atribuída. |
| `acertos` | Number (inteiro) | Quantidade de questões corretas. |
| `totalQuestoes` | Number (inteiro) | Quantidade de questões corrigidas. |
| `alternativasMarcadas` | Array<String> | Respostas registradas para cada questão. |
| `provaId` | String (opcional) | Identificador da prova. |
| `turmaId` | String (opcional) | Identificador da turma. |
| `corrigidoEm` | Timestamp | Data da correção. |

### 4.3 Relações e Segurança

- Um **professor** possui turmas, questões e provas na própria estrutura `usuarios/{uid}`.
- Cada **turma** possui sua subcoleção de alunos.
- Uma **prova** referencia a turma e as questões utilizadas e pode guardar um resumo das correções.
- Cada **resultado** é armazenado na subcoleção da prova, usando o ID do aluno.
- As regras em `firestore.rules` restringem o acesso conforme a autenticação e a titularidade do professor.

A modelagem conceitual adicional já se encontra em `docs/firestore-modelagem.md` e `docs/ERD.pdf` no projeto analisado.

## 5. Stack Tecnológica

📌 **N1**

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=flat-square&logo=firebase&logoColor=black)

| Tecnologia / pacote | Aplicação |

| --- | --- |

| **Flutter** | Desenvolvimento da interface multiplataforma. |

| **Dart** | Linguagem de programação do aplicativo. |

| **Material Design** | Componentes e padrões visuais da interface. |

| **Firebase Authentication** | Cadastro, login, sessão e recuperação de senha. |

| **Cloud Firestore** | Persistência de dados do professor, turmas, alunos, questões, provas e resultados. |

| **file_picker** | Seleção de arquivos para importação. |

| **csv / archive / xml** | Leitura e processamento de CSV/XLSX e geração de arquivos CSV. |

| **mobile_scanner** | Leitura do QR Code do gabarito. |

| **qr_flutter** | Geração e exibição do QR Code das provas. |

| **camera / image** | Captura e análise experimental das marcações nas folhas. |

| **share_plus** | Compartilhamento dos arquivos exportados. |

## 6. Estrutura de Pastas

📌 **N1**

Estrutura geral do projeto:

```text

lib/

  main.dart                 inicialização e entrada do aplicativo

  firebase_options.dart     configuração das plataformas Firebase

  models/                  modelos de dados e serialização

  services/                autenticação, Firestore e regras de negócio

  screens/                 telas e fluxos da aplicação

  widgets/                 componentes reutilizáveis

  utils/                   validações auxiliares

  mocks/                   arquivos de dados de exemplo

test/                      testes automatizados

docs/                      documentação adicional

firestore.rules             regras de segurança do Cloud Firestore

firestore.indexes.json      índices utilizados nas consultas

firebase.json               configuração do Firebase

```

A organização separa a apresentação, o acesso aos serviços externos e as estruturas de dados, facilitando a manutenção e a evolução das funcionalidades do aplicativo.

Para atender ao modelo de documentação da disciplina, recomenda-se organizar as capturas e os arquivos de apoio em `docs/telas/`, `docs/modelo-dados/` e `docs/backlog/`, criando as subpastas que ainda não existirem.

## 7. Como Executar o Projeto

📌 **N1**

### 7.1 Clonar o Repositório

```bash
git clone <URL-DO-REPOSITORIO>
cd prova_certa
```

> Substitua `<URL-DO-REPOSITORIO>` pelo endereço real do GitHub e ajuste o nome da pasta caso seja diferente.

### 7.2 Pré-requisitos

- Flutter SDK e Dart configurados conforme o `pubspec.yaml`;
- Android Studio/Android SDK ou ambiente compatível para execução;
- emulador Android ou dispositivo físico (ou navegador, para os fluxos compatíveis com Web);
- dependências do projeto instaladas;
- projeto Firebase configurado com **Authentication** e **Cloud Firestore**;
- arquivo `lib/firebase_options.dart` correspondente ao projeto Firebase.

Para as funcionalidades de câmera e leitura de QR Code, recomenda-se validar o funcionamento em um dispositivo compatível, com as permissões necessárias.

### 7.3 Execução pelo Terminal

Na pasta raiz do projeto:

```bash

flutter pub get

flutter run

```

Para selecionar explicitamente um dispositivo disponível:

```bash

flutter devices

flutter run -d <id-do-dispositivo>

```

### 7.4 Análise e Testes

```bash

flutter analyze

flutter test

```

Esses comandos verificam a análise estática e executam os testes Flutter existentes. A verificação integral da segurança e da persistência exige, adicionalmente, validar as regras e os fluxos de leitura/escrita no Firebase.

### 7.5 Geração do APK

Para criar um APK Android de release:

```bash

flutter build apk --release

```

Após a geração, o arquivo normalmente estará em:

```text

build/app/outputs/flutter-apk/app-release.apk

```

O APK precisa ser instalado em um dispositivo Android compatível. Para autenticação e acesso aos dados, a configuração do Firebase deve estar correta e a conexão de rede deve estar disponível.

## 8. Backlog de Atividades da N2

📌 **N2**

Esta seção deve registrar **as tarefas efetivamente realizadas na N2**, organizadas por integrante, com prazo e situação. Como os arquivos enviados não informam a relação completa da equipe nem o histórico consolidado do backlog da N2, os campos permanecem identificados para preenchimento com os registros reais do grupo.

<!-- Repita o bloco para cada integrante, preenchendo com as tarefas reais da N2. -->

### *Mateus Zeviani Rodrigues*

| Tarefa | Prazo | Status |
| --- | --- | --- |
| Modelar as entidades e os relacionamentos do banco de dados (Usuário, Turma, Aluno, Prova, Questão, Alternativa e Resultado) e documentar a estrutura. | 30/10 | Concluído |
| Implementar a autenticação com Firebase Authentication, incluindo login, manutenção da sessão, logout e recuperação de senha. | 30/10 | Concluído |
| Implementar a tela de cadastro de professores com validação dos campos, criação da conta e armazenamento do perfil no Firestore. | 30/10 | Concluído |
| Integrar o cadastro e a consulta de turmas e alunos ao Cloud Firestore, garantindo a persistência dos registros. | 30/10 | Concluído |
| Implementar a importação de alunos por arquivos CSV e XLSX, com validação de RA e identificação de registros duplicados. | 30/10 | Concluído |
| Atualizar a Home e o perfil para apresentar informações reais do professor autenticado e a quantidade de alunos cadastrados. | 30/10 | Concluído |
| Validar as alterações por testes automatizados e organizar os commits na branch `feat/firebase-integration`. | 30/10 | Concluído |
| Atualizar o README do projeto, revisando escopo, RF/RNF, telas e integração com o Firebase. | 30/10 | Concluído |
| Revisar Pull Requests de integrantes da equipe, analisando código, organização e aderência aos requisitos. | 30/10 | Concluído |
| Revisar o Pull Request e integrar as alterações ao projeto da equipe. | 30/10 | Concluído |

---

## Identificação e Considerações Finais

- **Nome:** Prova Certa
- **Categoria:** projeto acadêmico / aplicativo de apoio à avaliação escolar
- **Linguagem e framework:** Dart e Flutter
- **Autenticação:** Firebase Authentication
- **Banco de dados:** Cloud Firestore (NoSQL)
- **Plataforma principal:** Android, com configuração Firebase também para Web
- **Estado atual:** em desenvolvimento, com persistência de provas e questões e leitura experimental das folhas
- **Atualização da documentação:** 29 de outubro de 2026

O **Prova Certa** já possui uma base funcional para gerenciar usuários, turmas, alunos, questões, provas e resultados com persistência em nuvem. O foco das próximas etapas é aprimorar o reconhecimento das folhas de resposta, concluir a edição de provas e ampliar os testes para consolidar o fluxo de avaliações.

---

*Prova Certa: organização, correção e acompanhamento de avaliações em um só lugar.*

<div align="center">

*README do projeto acadêmico Prova Certa — disciplina de Desenvolvimento de Dispositivos Móveis.*

</div>
