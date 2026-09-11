import '../models/alternativa.dart';
import '../models/questao.dart';

final List<Questao> questoesMock = [
    Questao(
        id: 'q1',
        enunciado:
            'Qual organela é responsável pela produção de energia (ATP) '
            'nas células eucarióticas?',
        alternativas: [
            Alternativa(letra: 'A', texto: 'Ribossomo'),
            Alternativa(letra: 'B', texto: 'Complexo de Golgi'),
            Alternativa(letra: 'C', texto: 'Mitocôndria'),
            Alternativa(letra: 'D', texto: 'Lisossomo'),
            Alternativa(letra: 'E', texto: 'Retículo endoplasmático liso'),
        ],
        correta: 'C',
        assunto: 'Citologia',
        dificuldade: 'Fácil',
        disciplina: 'Biologia',
    ),

    Questao(
        id: 'q2',
        enunciado:
            'A membrana plasmática é composta principalmente por uma bicamada de:',
        alternativas: [
            Alternativa(letra: 'A', texto: 'Proteínas e carboidratos'),
            Alternativa(letra: 'B', texto: 'Fosfolipídios e proteínas'),
            Alternativa(letra: 'C', texto: 'Ácidos nucleicos e lipídios'),
            Alternativa(letra: 'D', texto: 'Colesterol e glicogênio'),
            Alternativa(letra: 'E', texto: 'Aminoácidos e água'),
        ],
        correta: 'B',
        assunto: 'Citologia',
        dificuldade: 'Fácil',
        disciplina: 'Biologia',
    ),

    Questao(
        id: 'q3',
        enunciado:
            'O processo pelo qual as células realizam a divisão celular para '
            'formar células-filha geneticamente idênticas é chamado de:',
        alternativas: [
            Alternativa(letra: 'A', texto: 'Meiose'),
            Alternativa(letra: 'B', texto: 'Mitose'),
            Alternativa(letra: 'C', texto: 'Amitose'),
            Alternativa(letra: 'D', texto: 'Reprodução assexuada'),
            Alternativa(letra: 'E', texto: 'Gametogênese'),
        ],
        correta: 'B',
        assunto: 'Divisão celular',
        dificuldade: 'Fácil',
        disciplina: 'Biologia',
    ),

    Questao(
        id: 'q4',
        enunciado:
            'Na fotossíntese, qual gás é liberado como subproduto da fotólise da água?',
        alternativas: [
            Alternativa(letra: 'A', texto: 'Dióxido de carbono (CO₂)'),
            Alternativa(letra: 'B', texto: 'Nitrogênio (N₂)'),
            Alternativa(letra: 'C', texto: 'Hidrogênio (H₂)'),
            Alternativa(letra: 'D', texto: 'Oxigênio (O₂)'),
            Alternativa(letra: 'E', texto: 'Vapor d\'água (H₂O)'),
        ],
        correta: 'D',
        assunto: 'Fisiologia vegetal',
        dificuldade: 'Médio',
        disciplina: 'Biologia',
    ),

    Questao(
        id: 'q5',
        enunciado:
            'As leis de Mendel foram estabelecidas com experimentos realizados '
            'com qual planta?',
        alternativas: [
            Alternativa(letra: 'A', texto: 'Milho'),
            Alternativa(letra: 'B', texto: 'Trigo'),
            Alternativa(letra: 'C', texto: 'Ervilha'),
            Alternativa(letra: 'D', texto: 'Feijão'),
            Alternativa(letra: 'E', texto: 'Soja'),
        ],
        correta: 'C',
        assunto: 'Genética',
        dificuldade: 'Fácil',
        disciplina: 'Biologia',
    ),

    Questao(
        id: 'q6',
        enunciado:
            'A mutação que altera a sequência de bases do DNA sem alterar o '
            'aminoácido produzido é denominada:',
        alternativas: [
            Alternativa(letra: 'A', texto: 'Mutação silenciosa'),
            Alternativa(letra: 'B', texto: 'Mutação nonsense'),
            Alternativa(letra: 'C', texto: 'Mutação frameshift'),
            Alternativa(letra: 'D', texto: 'Deleção'),
            Alternativa(letra: 'E', texto: 'Translocação'),
        ],
        correta: 'A',
        assunto: 'Genética molecular',
        dificuldade: 'Difícil',
        disciplina: 'Biologia',
    ),

    Questao(
        id: 'q7',
        enunciado: 'Qual é o papel dos ribossomos na célula?',
        alternativas: [
            Alternativa(letra: 'A', texto: 'Digestão intracelular'),
            Alternativa(letra: 'B', texto: 'Síntese de proteínas'),
            Alternativa(letra: 'C', texto: 'Armazenamento de energia'),
            Alternativa(letra: 'D', texto: 'Controle do ciclo celular'),
            Alternativa(letra: 'E', texto: 'Transporte de substâncias'),
        ],
        correta: 'B',
        assunto: 'Citologia',
        dificuldade: 'Fácil',
        disciplina: 'Biologia',
    ),

    Questao(
        id: 'q8',
        enunciado:
            'Na cadeia alimentar, os organismos que convertem matéria inorgânica '
            'em orgânica são chamados de:',
        alternativas: [
            Alternativa(letra: 'A', texto: 'Consumidores primários'),
            Alternativa(letra: 'B', texto: 'Decompositores'),
            Alternativa(letra: 'C', texto: 'Produtores'),
            Alternativa(letra: 'D', texto: 'Consumidores secundários'),
            Alternativa(letra: 'E', texto: 'Carnívoros'),
        ],
        correta: 'C',
        assunto: 'Ecologia',
        dificuldade: 'Fácil',
        disciplina: 'Biologia',
    ),

    Questao(
        id: 'q9',
        enunciado: 'O processo de replicação do DNA ocorre na fase:',
        alternativas: [
            Alternativa(letra: 'A', texto: 'Prófase'),
            Alternativa(letra: 'B', texto: 'Metáfase'),
            Alternativa(letra: 'C', texto: 'Anáfase'),
            Alternativa(letra: 'D', texto: 'Interfase (fase S)'),
            Alternativa(letra: 'E', texto: 'Telófase'),
        ],
        correta: 'D',
        assunto: 'Divisão celular',
        dificuldade: 'Médio',
        disciplina: 'Biologia',
    ),

    Questao(
        id: 'q10',
        enunciado:
            'Qual hormônio é responsável pela regulação dos níveis de glicose no '
            'sangue, estimulando sua captação pelas células?',
        alternativas: [
            Alternativa(letra: 'A', texto: 'Glucagon'),
            Alternativa(letra: 'B', texto: 'Adrenalina'),
            Alternativa(letra: 'C', texto: 'Insulina'),
            Alternativa(letra: 'D', texto: 'Cortisol'),
            Alternativa(letra: 'E', texto: 'Tiroxina'),
        ],
        correta: 'C',
        assunto: 'Fisiologia humana',
        dificuldade: 'Médio',
        disciplina: 'Biologia',
    ),
];
