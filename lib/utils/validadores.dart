class Validadores {
  Validadores._();

  static const tamanhoMinimoSenha = 8;
  static const tamanhoMaximoSenha = 128;

  static final _email = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}$',
  );
  static final _nome = RegExp(r"^[\p{L} .'-]+$", unicode: true);
  static final _ra = RegExp(r'^[A-Za-z0-9./-]+$');

  static String? email(String valor) {
    final email = valor.trim();
    if (email.isEmpty) return 'Informe o e-mail institucional.';
    if (email.length > 254 || !_email.hasMatch(email)) {
      return 'Informe um formato de e-mail válido.';
    }
    return null;
  }

  static String? senhaLogin(String valor) {
    if (valor.isEmpty) return 'Informe a senha de acesso.';
    return null;
  }

  static String? novaSenha(String valor) {
    if (valor.isEmpty) return 'Informe a senha de acesso.';
    if (valor.length < tamanhoMinimoSenha) {
      return 'A senha deve ter pelo menos $tamanhoMinimoSenha caracteres.';
    }
    if (valor.length > tamanhoMaximoSenha) {
      return 'A senha deve ter no máximo $tamanhoMaximoSenha caracteres.';
    }
    if (valor.trim() != valor) {
      return 'A senha não pode começar nem terminar com espaço.';
    }
    if (!RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(valor) ||
        !RegExp(r'\d').hasMatch(valor)) {
      return 'A senha deve conter letras e números.';
    }
    return null;
  }

  static String? confirmacaoSenha(String senha, String confirmacao) {
    if (confirmacao.isEmpty) return 'Confirme a senha de acesso.';
    if (senha != confirmacao) return 'As senhas informadas não coincidem.';
    return null;
  }

  static String? nomeCompleto(String valor) {
    final nome = valor.trim();
    if (nome.isEmpty) return 'Informe o nome completo.';
    if (nome.length < 3) return 'O nome deve ter pelo menos 3 caracteres.';
    if (nome.length > 100) return 'O nome deve ter no máximo 100 caracteres.';
    if (!_nome.hasMatch(nome)) {
      return 'O nome deve conter apenas letras, espaços, ponto, apóstrofo ou hífen.';
    }
    return null;
  }

  static String? instituicao(String valor, {bool obrigatoria = true}) {
    final instituicao = valor.trim();
    if (instituicao.isEmpty) {
      return obrigatoria ? 'Informe a instituição de ensino.' : null;
    }
    if (instituicao.length < 2) {
      return 'O nome da instituição deve ter pelo menos 2 caracteres.';
    }
    if (instituicao.length > 120) {
      return 'O nome da instituição deve ter no máximo 120 caracteres.';
    }
    return null;
  }

  static String? nomeAluno(String valor) {
    final nome = valor.trim();
    if (nome.isEmpty) return 'Informe o nome do aluno.';
    if (nome.length < 3) {
      return 'O nome do aluno deve ter pelo menos 3 caracteres.';
    }
    if (nome.length > 100) {
      return 'O nome do aluno deve ter no máximo 100 caracteres.';
    }
    if (!_nome.hasMatch(nome)) {
      return 'O nome do aluno deve conter apenas letras, espaços, apóstrofo ou hífen.';
    }
    return null;
  }

  static String? ra(String valor) {
    final ra = valor.trim();
    if (ra.isEmpty) return 'Informe o RA do aluno.';
    if (ra.length > 20) return 'O RA deve ter no máximo 20 caracteres.';
    if (!_ra.hasMatch(ra)) {
      return 'O RA deve conter apenas letras, números, ponto, hífen ou barra.';
    }
    return null;
  }

  static String? codigoRedefinicao(String valor) {
    if (valor.trim().isEmpty) {
      return 'Cole o link ou o código recebido por e-mail.';
    }
    if (extrairCodigoRedefinicao(valor) == null) {
      return 'O link ou código informado não é válido.';
    }
    return null;
  }

  static String? extrairCodigoRedefinicao(String valor) {
    final texto = valor.trim();
    if (texto.isEmpty) return null;

    final uri = Uri.tryParse(texto);
    if (uri != null && uri.hasScheme) {
      final codigo = uri.queryParameters['oobCode'];
      if (codigo != null && codigo.isNotEmpty) return codigo;

      final linkInterno = uri.queryParameters['link'];
      if (linkInterno != null) return extrairCodigoRedefinicao(linkInterno);

      return null;
    }

    if (RegExp(r'^[A-Za-z0-9_-]{10,}$').hasMatch(texto)) return texto;
    return null;
  }
}
