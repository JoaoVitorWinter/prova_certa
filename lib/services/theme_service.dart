import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço responsável por gerenciar a preferência de tema (Claro, Escuro ou Sistema),
/// notificando ouvintes para reconstrução global da interface e persistindo a
/// escolha localmente via `shared_preferences` (sem persistência no Firestore).
class ThemeService extends ChangeNotifier {
  static const String chavePreferenciaTema = 'app_theme_mode';

  static ThemeService? _instancia;

  /// Retorna a instância singleton compartilhada do serviço.
  static ThemeService get instancia => _instancia ??= ThemeService();

  final SharedPreferences? prefs;
  ThemeMode _themeMode;

  ThemeService({
    this.prefs,
    ThemeMode initialMode = ThemeMode.light,
  }) : _themeMode = initialMode;

  /// Modo de tema atualmente ativo no aplicativo.
  ThemeMode get themeMode => _themeMode;

  /// Nome amigável do tema selecionado para exibição na interface.
  String get temaAtualNome {
    switch (_themeMode) {
      case ThemeMode.dark:
        return 'Escuro';
      case ThemeMode.system:
        return 'Sistema';
      case ThemeMode.light:
        return 'Claro';
    }
  }

  bool get isEscuro => _themeMode == ThemeMode.dark;
  bool get isClaro => _themeMode == ThemeMode.light;
  bool get isSistema => _themeMode == ThemeMode.system;

  /// Carrega a preferência persistida localmente.
  /// Caso não haja valor salvo ou ocorra erro, mantém o padrão (`ThemeMode.light`).
  Future<void> inicializar() async {
    try {
      final sp = prefs ?? await SharedPreferences.getInstance();
      final salvo = sp.getString(chavePreferenciaTema);
      if (salvo == 'escuro') {
        _themeMode = ThemeMode.dark;
      } else if (salvo == 'sistema') {
        _themeMode = ThemeMode.system;
      } else {
        _themeMode = ThemeMode.light;
      }
      notifyListeners();
    } catch (_) {
      // Falhas no armazenamento local preservam o modo padrão
    }
  }

  /// Define o [ThemeMode] e persiste a preferência localmente.
  Future<void> definirThemeMode(ThemeMode modo) async {
    if (_themeMode == modo) return;
    _themeMode = modo;
    notifyListeners();

    try {
      final sp = prefs ?? await SharedPreferences.getInstance();
      String valor;
      switch (modo) {
        case ThemeMode.dark:
          valor = 'escuro';
          break;
        case ThemeMode.system:
          valor = 'sistema';
          break;
        case ThemeMode.light:
          valor = 'claro';
          break;
      }
      await sp.setString(chavePreferenciaTema, valor);
    } catch (_) {
      // Ignora falhas isoladas de escrita em disco
    }
  }

  /// Define o tema a partir do nome textual ('Claro', 'Escuro', 'Sistema').
  Future<void> definirTema(String nome) async {
    switch (nome.trim().toLowerCase()) {
      case 'escuro':
        await definirThemeMode(ThemeMode.dark);
        break;
      case 'sistema':
      case 'usar padrão do sistema':
        await definirThemeMode(ThemeMode.system);
        break;
      case 'claro':
      default:
        await definirThemeMode(ThemeMode.light);
        break;
    }
  }

  /// Utilitário exclusivo para testes automatizados.
  @visibleForTesting
  static void resetarInstanciaParaTestes([ThemeService? novaInstancia]) {
    _instancia = novaInstancia;
  }
}
