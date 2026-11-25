class Alternativa {
  final String letra;
  final String texto;
  final String? letraOriginal;

  Alternativa({required this.letra, required this.texto, this.letraOriginal});

  Map<String, dynamic> toMap() {
    return {
      'letra': letra,
      'texto': texto,
      if (letraOriginal != null) 'letraOriginal': letraOriginal,
    };
  }

  Map<String, dynamic> toFirestore() => toMap();

  factory Alternativa.fromMap(Map<String, dynamic> map) {
    return Alternativa(
      letra: map['letra'] as String? ?? '',
      texto: map['texto'] as String? ?? '',
      letraOriginal: map['letraOriginal']?.toString(),
    );
  }

  Alternativa copyWith({String? letra, String? texto, String? letraOriginal}) {
    return Alternativa(
      letra: letra ?? this.letra,
      texto: texto ?? this.texto,
      letraOriginal: letraOriginal ?? this.letraOriginal,
    );
  }
}
