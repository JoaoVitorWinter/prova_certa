
# Modelagem do Banco de Dados — Prova Certa

O Prova Certa utiliza o Cloud Firestore, um banco de dados NoSQL do Firebase.

Os dados são organizados por professor, utilizando o UID do Firebase Authentication como identificador.

## Diagrama de Entidades e Relacionamentos

```mermaid
erDiagram
    USUARIO ||--o{ TURMA : gerencia
    USUARIO ||--o{ QUESTAO : cadastra
    USUARIO ||--o{ PROVA : cria
    TURMA ||--o{ ALUNO : possui
    TURMA ||--o{ PROVA : recebe
    PROVA }o--o{ QUESTAO : utiliza
    QUESTAO ||--|{ ALTERNATIVA : contem
    PROVA ||--o{ RESULTADO : gera
    ALUNO ||--o{ RESULTADO : recebe

    USUARIO {
        string id PK
        string nome
        string email
        string instituicao
    }

    TURMA {
        string id PK
        string nome
        string ano
        string disciplina
        string periodo
        int quantidadeAlunos
    }

    ALUNO {
        string id PK
        string nome
        string ra
    }

    QUESTAO {
        string id PK
        string enunciado
        string assunto
        string dificuldade
        string correta
    }

    ALTERNATIVA {
        string letra
        string texto
    }

    PROVA {
        string id PK
        string turmaId FK
        string nome
        string status
        date dataAplicacao
        int quantidadeQuestoes
    }

    RESULTADO {
        string id PK
        string alunoId FK
        string provaId FK
        float nota
        int acertos
        int totalQuestoes
    }
```

## Organização dos dados

- **Usuários:** informações dos professores.
- **Turmas:** turmas cadastradas por cada professor.
- **Alunos:** estudantes vinculados às turmas.
- **Questões:** questões cadastradas pelo professor.
- **Alternativas:** opções de resposta armazenadas nas questões.
- **Provas:** avaliações associadas às turmas.
- **Resultados:** desempenho dos alunos nas avaliações.

## Estrutura no Firestore

```text
usuarios/{usuarioId}
  ├── turmas/{turmaId}
  │   └── alunos/{alunoId}
  ├── questoes/{questaoId}
  └── provas/{provaId}
      └── resultados/{alunoId}
```

As alternativas são armazenadas diretamente nos documentos das questões, enquanto provas e resultados mantêm as referências necessárias às turmas e aos alunos.

O diagrama representa os relacionamentos conceituais, pois o Firestore não utiliza chaves estrangeiras como um banco relacional.
