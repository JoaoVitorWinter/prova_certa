class Alternativa {
  final String letra;
  final String texto;

  Alternativa({
    required this.letra,
    required this.texto,
  });

  Map<String, dynamic> toMap() {
    return {
      'letra': letra,
      'texto': texto,
    };
  }

  Map<String, dynamic> toFirestore() => toMap();

  factory Alternativa.fromMap(Map<String, dynamic> map) {
    return Alternativa(
      letra: map['letra'] as String? ?? '',
      texto: map['texto'] as String? ?? '',
    );
  }

  Alternativa copyWith({
    String? letra,
    String? texto,
  }) {
    return Alternativa(
      letra: letra ?? this.letra,
      texto: texto ?? this.texto,
    );
  }
}
