# Prova Certa

## 1. Visão geral

O projeto Prova Certa é um protótipo de aplicativo mobile desenvolvido em Flutter para apoiar atividades de gestão escolar e avaliação acadêmica. A solução foi pensada para facilitar o trabalho do professor na organização de turmas, criação e acompanhamento de provas, além de simular o processo de correção de avaliações.

O projeto está em fase de protótipo front-end com dados mockados, ou seja, ele apresenta a interface e o fluxo funcional principal, mas ainda não possui integração real com backend, autenticação real, banco de dados ou processamento de OCR/QR em produção.

---

## 2. Objetivo do projeto

O objetivo principal do sistema é permitir que o professor:

- gerencie turmas e alunos;
- crie e visualize provas;
- acompanhe o status das avaliações;
- simule a correção por QR Code e leitura de folhas;
- visualize resultados e informações gerais do perfil do docente.

A ideia é reduzir a rotina manual e centralizar a organização de avaliações em uma interface intuitiva e bem estruturada.

---

## 3. Escopo delimitado

Este projeto abrange a implementação de uma interface funcional para apresentação do fluxo principal do aplicativo, com foco em UX/UI e navegação entre telas. O escopo inclui:

- telas de autenticação e início;
- dashboard inicial;
- gestão de turmas;
- visualização e filtro de provas;
- criação de nova prova;
- fluxo de correção mockado;
- telas de resultados e perfil;
- estrutura de navegação via barra inferior.

O escopo foi delimitado para um protótipo de alta fidelidade, sem persistência real, sem regras de negócio complexas e sem integração com serviços externos.

### O que não está incluso no momento

- autenticação real;
- banco de dados persistente;
- backend/API;
- leitura real de QR code em produção;
- OCR real de folhas de respostas;
- sincronização com dados reais de alunos e turmas;
- lógica de geração/armazenamento de provas em produção.

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
O sistema deve permitir iniciar o fluxo de correção de prova, simulando o uso de QR Code e leitura de folhas.

### RF08 - Resultado da correção
O sistema deve mostrar o resultado de uma avaliação corrigida com métricas simplificadas.

### RF09 - Visualização de resultados
O sistema deve disponibilizar uma tela com indicadores e estatísticas das avaliações.

### RF10 - Perfil do professor
O sistema deve apresentar dados do usuário e opções de configuração.

---

## 5. Requisitos não funcionais (RNF)

### RNF01 - Interface responsiva
A aplicação deve apresentar uma UI consistente e adaptável ao uso em dispositivos móveis.

### RNF02 - Navegação intuitiva
As telas devem possuir fluxo claro, com navegação simples entre menu principal, ações rápidas e subfluxos.

### RNF03 - Prototipação front-end
O projeto deve priorizar a experiência visual e a usabilidade para validação de fluxo, mesmo com dados simulados.

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
5. Simula a correção de prova com QR e folhas mockadas.
6. Visualiza o resultado da correção e demais informações.

---

## 7. Tecnologias utilizadas

- Flutter
- Dart
- Material Design
- Mobile Scanner (mockado para simular leitura de QR)
- Camera (preparada para integração futura)
- Estrutura de models, screens e mocks

---

## 8. Estrutura do projeto

```text
lib/
  main.dart
  mocks/
  models/
  screens/
  widgets/

test/
```

A estrutura segue organização por responsabilidade, separando dados mockados, modelos de domínio e telas da aplicação.

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

Se quiser, também pode usar o comando abaixo para verificar se o projeto está sem erros de análise:

```bash
flutter analyze
```

### Opção 3: executável

O projeto também pode ser executado diretamente pelo executável gerado para a entrega.

---

## 10. Link do vídeo

Adicionar aqui o link do vídeo de apresentação do projeto:

- [Link do vídeo da entrega](https://youtu.be/X_vYoKu1NKs)

---

## 11. Observações finais

Este aplicativo representa um protótipo funcional para validação de fluxo e apresentação de interface. Ele demonstra o uso de telas mockadas, navegação entre módulos e um simulador de correção de provas, sendo uma base sólida para evolução em projetos futuros com backend e automação real.

---

## 12. Identificação do projeto

- Nome: Prova Certa
- Tecnologias: Flutter + Dart
- Tipo: protótipo mobile front-end
- Estado atual: em desenvolvimento com dados mockados

---

"Prova Certa: organização, correção e acompanhamento de avaliações em um só lugar."
