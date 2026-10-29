# Prova Certa

**Aplicativo para organização de turmas, avaliações e acompanhamento de resultados.**

## 1. Visão geral

O **Prova Certa** é um aplicativo desenvolvido em **Flutter e Dart**, voltado à gestão de avaliações escolares. A plataforma tem como objetivo facilitar a rotina dos professores, centralizando o gerenciamento de turmas, alunos, provas, correções e resultados em um ambiente digital organizado e intuitivo.

A aplicação utiliza o **Firebase Authentication** para autenticação dos usuários e o **Cloud Firestore** para armazenamento e gerenciamento dos dados em nuvem. Cada professor possui um ambiente individualizado, garantindo a organização, a privacidade e o isolamento das informações vinculadas à sua conta.

Entre suas funcionalidades estão o cadastro e gerenciamento de turmas e alunos, a importação de listas por arquivos CSV e XLSX, o fluxo de correção de avaliações, a visualização de resultados e a exportação de notas. O sistema também oferece um painel inicial com indicadores acadêmicos e acesso rápido às principais funcionalidades.

O Prova Certa busca proporcionar uma experiência prática e eficiente, contribuindo para a **digitalização dos processos avaliativos, a redução de tarefas manuais e o acompanhamento do desempenho dos alunos**.

## 2. Objetivo do projeto

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

## 3. Escopo

### 3.1. Funcionalidades implementadas com Firebase

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

### 3.2. Funcionalidades parciais ou experimentais

| Módulo | Estado atual | Limitação |
| --- | --- | --- |
| Gestão de provas | **Parcialmente implementado** | Permite criar, listar, alterar o status e excluir provas; a edição completa de uma prova já cadastrada não foi identificada. |
| Leitura das folhas de resposta | **Experimental** | Analisa fotografias e tenta identificar alternativas marcadas por processamento de imagem, exigindo alinhamento adequado e conferência manual. |
| Identificação dos alunos nas folhas | **Manual** | O professor seleciona o aluno correspondente à folha; não há reconhecimento automático do nome ou RA escrito. |
| Versões e embaralhamento de questões | **Parcial** | Existem estruturas para versões, mas a integração completa ao fluxo principal não foi identificada. |
| Algumas configurações | **Demonstrativo/parcial** | As telas podem estar disponíveis sem persistência ou aplicação integral das preferências. |

**Importante:** a detecção de alternativas nas folhas é experimental e depende da revisão do professor. A existência do leitor de imagem não significa que o aplicativo já realize correção totalmente automática e validada em diferentes condições de captura.

### 3.3. Fora do escopo implementado nesta versão

- reconhecimento robusto das marcações em diferentes modelos de folhas e condições de captura;
- identificação automática do aluno por nome ou RA manuscrito na folha;
- edição completa de provas já cadastradas, incluindo alterações de suas questões e configurações;
- integração completa da geração e distribuição de versões de prova;
- funcionamento totalmente offline e sincronização posterior;
- disponibilização do aplicativo como produto final em produção.

## 4. Requisitos funcionais (RF)

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

## 5. Requisitos não funcionais (RNF)

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

## 6. Telas e módulos do aplicativo

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

### 6.1. Fluxo principal de utilização

1. O professor cria uma conta ou entra com suas credenciais.
2. Após a validação da sessão e do perfil, acessa a **Home**.
3. Cadastra turmas e alunos manualmente ou importa uma lista CSV/XLSX.
4. Consulta os indicadores e navega entre **Turmas, Provas, Correção, Resultados e Perfil**.
5. Cadastra questões no banco e as seleciona para compor uma nova prova.
6. Salva a prova no Firestore e gera seu QR Code com as informações do gabarito.
7. No fluxo de correção, lê o QR Code, fotografa as folhas e revisa as respostas identificadas antes de confirmar.
8. O sistema calcula as notas e salva os resultados da correção no Firestore.
9. O professor visualiza as análises e pode exportar e compartilhar as informações em CSV.

## 7. Integração com o Firebase e banco de dados

### 7.1. Autenticação

O aplicativo usa **Firebase Authentication** para cadastro, login, sessão, logout e solicitação de recuperação de senha. A identidade do usuário autenticado é representada por um **UID**, utilizado como referência para seus dados no Firestore.

As senhas são gerenciadas pelo serviço de autenticação e **não devem ser armazenadas nos documentos do Cloud Firestore**.

### 7.2. Cloud Firestore

O Cloud Firestore armazena os dados persistentes em uma organização vinculada ao professor:

```text
usuarios/
  {uid}/                         perfil do professor
    turmas/
      {turmaId}/                 dados da turma
        alunos/
          {alunoId}              dados do aluno
    questoes/
      {questaoId}                 enunciado, alternativas e resposta correta
    provas/
      {provaId}/                 turma, status, questões, gabarito
                                 e resumoResultado
        resultados/
          {alunoId}              nota, acertos e respostas do aluno
```

### 7.3. Isolamento dos dados

O aplicativo foi estruturado para que cada professor acesse suas informações usando o próprio UID. As regras do Firestore devem validar a autenticação e a titularidade dos documentos, impedindo que um usuário leia ou modifique dados pertencentes a outro.

## 8. Tecnologias utilizadas

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

## 9. Organização do código

Estrutura geral do projeto:

```text
lib/
  main.dart                 inicialização e entrada do aplicativo
  firebase_options.dart     configuração das plataformas Firebase
  models/                  modelos de dados e serialização
  services/                autenticação, Firestore e regras de negócio
  screens/                 telas e fluxos da aplicação
  widgets/                 componentes reutilizáveis
  utils/                   validações auxiliares
  mocks/                   arquivos de dados de exemplo

test/                      testes automatizados

docs/                      documentação adicional
firestore.rules             regras de segurança do Cloud Firestore
firestore.indexes.json      índices utilizados nas consultas
firebase.json               configuração do Firebase
```

A organização separa a apresentação, o acesso aos serviços externos e as estruturas de dados, facilitando a manutenção e a evolução das funcionalidades do aplicativo.

## 10. Execução do projeto

### 10.1. Pré-requisitos

- Flutter SDK e Dart configurados conforme o `pubspec.yaml`;
- Android Studio/Android SDK ou ambiente compatível para execução;
- emulador Android ou dispositivo físico (ou navegador, para os fluxos compatíveis com Web);
- dependências do projeto instaladas;
- projeto Firebase configurado com **Authentication** e **Cloud Firestore**;
- arquivo `lib/firebase_options.dart` correspondente ao projeto Firebase.

Para as funcionalidades de câmera e leitura de QR Code, recomenda-se validar o funcionamento em um dispositivo compatível, com as permissões necessárias.

### 10.2. Execução pelo terminal

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

### 10.3. Análise e testes

```bash
flutter analyze
flutter test
```

Esses comandos verificam a análise estática e executam os testes Flutter existentes. A verificação integral da segurança e da persistência exige, adicionalmente, validar as regras e os fluxos de leitura/escrita no Firebase.

### 10.4. Geração do APK

Para criar um APK Android de release:

```bash
flutter build apk --release
```

Após a geração, o arquivo normalmente estará em:

```text
build/app/outputs/flutter-apk/app-release.apk
```

O APK precisa ser instalado em um dispositivo Android compatível. Para autenticação e acesso aos dados, a configuração do Firebase deve estar correta e a conexão de rede deve estar disponível.

## 11. Identificação e considerações finais

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
