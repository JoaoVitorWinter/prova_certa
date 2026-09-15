import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nomeController;
  late final TextEditingController _emailController;
  late final TextEditingController _escolaController;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: 'Ana Paula Santos');
    _emailController = TextEditingController(text: 'ana.santos@escola.edu.br');
    _escolaController = TextEditingController(text: 'E.E. Prof. Antônio Lemos');
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _escolaController.dispose();
    super.dispose();
  }

  void _salvar() {
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alterações salvas no protótipo.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: _settingsAppBar(context, 'Editar perfil'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(23, 20, 23, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5D48F2), Color(0xFF7B2EEB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Text(
                      'AP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -5,
                    bottom: -5,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE7EAF0)),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Color(0xFF6542ED),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _ProfileField(
              label: 'NOME COMPLETO',
              controller: _nomeController,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 17),
            _ProfileField(
              label: 'E-MAIL INSTITUCIONAL',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 17),
            _ProfileField(
              label: 'ESCOLA',
              controller: _escolaController,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF713CEB),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Salvar alterações',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  const _ProfileField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF58677D),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: .2,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          decoration: _fieldDecoration(),
        ),
      ],
    );
  }
}

InputDecoration _fieldDecoration() {
  return InputDecoration(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: Color(0xFFE0E3E8)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: Color(0xFFE0E3E8)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: Color(0xFF713CEB), width: 1.5),
    ),
  );
}

PreferredSizeWidget _settingsAppBar(BuildContext context, String title) {
  return AppBar(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.white,
    elevation: 0,
    scrolledUnderElevation: 0,
    leading: IconButton(
      onPressed: () => Navigator.pop(context),
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
      color: const Color(0xFF111827),
    ),
    titleSpacing: 0,
    title: Text(
      title,
      style: const TextStyle(
        color: Color(0xFF111827),
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
    bottom: const PreferredSize(
      preferredSize: Size.fromHeight(1),
      child: Divider(height: 1, color: Color(0xFFE4E9F1)),
    ),
  );
}
