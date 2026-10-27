# Prova Certa

## 1. Visão geral

O projeto Prova Certa é um protótipo de aplicativo mobile desenvolvido em Flutter para apoiar atividades de gestão escolar e avaliação acadêmica. A solução foi pensada para facilitar o trabalho do professor na organização de turmas, criação e acompanhamento de provas, além de simular o processo de correção de avaliações.

O aplicativo usa Firebase: a autenticação é feita pelo Firebase Authentication e os dados do professor (perfil, turmas, alunos e resultados das correções) ficam no Cloud Firestore, isolados por usuário. Algumas partes continuam demonstrativas: a lista de provas e o banco de questões usam dados mockados, e a leitura das folhas de resposta é simulada.

---

## 2. Objetivo do projeto

O objetivo principal do sistema é permitir que o professor:

- gerencie turmas e alunos;
- crie e visualize provas;
- acompanhe o status das avaliações;
- corrija provas lendo o gabarito por QR Code e as folhas de resposta;
- acompanhe os resultados por turma, por questão e por aluno;
- exporte as notas para planilha (CSV, abre no Excel) e compartilhe o arquivo;
- visualize informações gerais do perfil do docente.

A ideia é reduzir a rotina manual e centralizar a organização de avaliações em uma interface intuitiva e bem estruturada.

---

## 3. Escopo delimitado

Este projeto abrange a implementação de uma interface funcional para apresentação do fluxo principal do aplicativo, com foco em UX/UI e navegação entre telas. O escopo inclui:

- telas de autenticação e início;
- dashboard inicial;
- gestão de turmas;
- visualização e filtro de provas;
- criação de nova prova;
- fluxo de correção com leitura do gabarito por QR Code e leitura simulada das folhas;
- resultados reais por prova, por questão e por aluno, salvos no Firestore;
- exportação das notas e da análise por questão em CSV, com compartilhamento;
- telas de perfil;
- estrutura de navegação via barra inferior.

### O que não está incluso no momento

- OCR real das folhas de resposta (a leitura das folhas é simulada: cada aluno da turma recebe um conjunto de respostas estável);
- geração do QR Code do gabarito dentro do app;
- persistência das provas e do banco de questões no Firestore (ainda usam dados mockados).

---

## 4. Requisitos funcionais (RF)

### RF01 - Login
O sistema deve possuir uma tela de login para iniciar o uso do aplicativo.

### RF02 - Dashboard inicial
O sistema deve exibir uma tela inicial com ações rápidas e resumo de atividades relacionadas a avaliações.

### RF03 - Gestão de turmas
O sistema deve permitir visualizar turmas ativas e acessar o detalhe de cada turma.

### RF04 - Cadastro de turma
O sistema deve permitir a criação de uma nova turma com dados mockados.

### RF05 - Gestão de provas
O sistema deve exibir uma lista de provas com possibilidade de filtro por categoria/estado.

### RF06 - Criação de prova
O sistema deve permitir criar uma nova prova em fluxo de etapas, com dados básicos e etapas de configuração.

### RF07 - Correção de prova
O sistema deve permitir corrigir uma prova: ler o gabarito pelo QR Code e ler uma folha de resposta para cada aluno da turma, podendo finalizar mesmo com alunos ausentes.

### RF08 - Resultado da correção
Ao finalizar, o sistema deve calcular a nota de cada aluno, salvar os resultados no Firestore e mostrar o resumo da correção com a média da turma.

### RF09 - Visualização de resultados
O sistema deve disponibilizar uma tela com os resultados reais de cada prova corrigida: média, menor e maior nota e distribuição das notas (visão geral), percentual de acerto e alternativas marcadas em cada questão (por questão) e nota, acertos e respostas de cada aluno (por aluno).

### RF10 - Perfil do professor
O sistema deve apresentar dados do usuário e opções de configuração.

### RF11 - Exportação de notas
O sistema deve gerar arquivos CSV com as notas dos alunos e com a análise por questão, prontos para abrir no Excel (separador `;` e acentuação preservada), e abrir o compartilhamento do aparelho (WhatsApp, e-mail, Drive etc.).

### RF12 - Dashboard
A tela inicial deve exibir dados reais: quantidade de provas corrigidas, folhas corrigidas, total de alunos e as correções mais recentes com a média de cada uma.

---

## 5. Requisitos não funcionais (RNF)

### RNF01 - Interface responsiva
A aplicação deve apresentar uma UI consistente e adaptável ao uso em dispositivos móveis.

### RNF02 - Navegação intuitiva
As telas devem possuir fluxo claro, com navegação simples entre menu principal, ações rápidas e subfluxos.

### RNF03 - Persistência e isolamento
Os dados devem ser gravados no Cloud Firestore dentro de `usuarios/{uid}`, e as regras de segurança (`firestore.rules`) devem impedir que um professor acesse os dados de outro.

### RNF04 - Organização de código
Os arquivos devem seguir uma estrutura modular em Flutter, separando telas, modelos e mocks.

### RNF05 - Manutenção
A estrutura do projeto deve facilitar futuras alterações, adições de telas e integração com backend real.

---

## 6. Telas principais

O projeto contempla as principais telas abaixo:

- Login
- Home
- Turmas
- Detalhes da turma
- Provas
- Nova prova
- Correção de prova
- QR do gabarito
- Leitura de folhas
- Resultados
- Perfil
- Configurações e detalhes do app

### Fluxo principal

1. Usuário acessa a tela de login.
2. Entra na home do app.
3. Navega entre início, provas, corrigir, resultados e turmas.
4. Cria ou acessa avaliações.
5. Corrige uma prova: lê o QR Code do gabarito e uma folha por aluno.
6. Visualiza os resultados (geral, por questão e por aluno) e exporta as notas em CSV.

---

## 7. Tecnologias utilizadas

- Flutter
- Dart
- Material Design
- Firebase Authentication e Cloud Firestore
- Mobile Scanner (leitura do QR Code do gabarito)
- Camera e image (leitor de folhas, preparado para OCR)
- csv, path_provider e share_plus (exportação e compartilhamento das notas)
- Estrutura de models, services, screens e mocks

---

## 8. Estrutura do projeto

```text
lib/
  main.dart
  firebase_options.dart
  mocks/      dados demonstrativos (provas e questões)
  models/     entidades e conversão para o Firestore
  screens/    telas
  services/   autenticação, turmas, resultados e exportação
  widgets/

test/
```

A estrutura segue organização por responsabilidade, separando dados mockados, modelos de domínio, serviços de acesso a dados e telas da aplicação.

### Onde ficam os resultados no Firestore

```text
usuarios/{uid}/provas/{provaId}                        resumoResultado (média, distribuição, por questão) e gabaritoOficial
usuarios/{uid}/provas/{provaId}/resultados/{alunoId}   nota, acertos e alternativas marcadas pelo aluno
```

---

## 9. Instruções para rodar o projeto

### Opção 1: VS Code

1. Abra a pasta do projeto no VS Code.
2. Certifique-se de que o Flutter SDK está instalado e configurado corretamente.
3. Verifique se um emulador ou dispositivo físico está conectado.
4. No VS Code, clique em:
   - Run
   - Start Debugging
5. O projeto será compilado e executado no emulador/dispositivo selecionado.

### Opção 2: terminal

No terminal, dentro da pasta do projeto, execute:

```bash
flutter pub get
flutter run
```

Para verificar se o projeto está sem erros de análise e rodar os testes automatizados:

```bash
flutter analyze
flutter test
```

### Opção 3: executável

O projeto também pode ser executado diretamente pelo executável gerado para a entrega (.\build\app\outputs\flutter-apk\app-release.apk).

Para gerar o APK é preciso ter o Android SDK instalado (pelo Android Studio). Depois, rode:

```bash
flutter build apk --release
```

---

## 10. Link do vídeo

Adicionar aqui o link do vídeo de apresentação do projeto:

- [Link do vídeo da entrega](https://youtu.be/X_vYoKu1NKs)

---

## 11. Observações finais

O aplicativo já integra autenticação, turmas, alunos, correção e resultados com o Firebase, e permite exportar as notas. Os próximos passos são persistir provas e questões no Firestore, gerar o QR Code do gabarito no próprio app e trocar a leitura simulada das folhas por reconhecimento real das marcações.

---

## 12. Identificação do projeto

- Nome: Prova Certa
- Tecnologias: Flutter + Dart
- Tipo: aplicativo mobile com Firebase
- Estado atual: em desenvolvimento; provas, questões e leitura das folhas ainda são demonstrativas

---

"Prova Certa: organização, correção e acompanhamento de avaliações em um só lugar."
