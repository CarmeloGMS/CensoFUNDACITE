import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/app_theme.dart';
import '../state/providers.dart';
import '../widgets/brand_mark.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final TextEditingController _server;
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _showServer = false;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _server = TextEditingController(
      text: ref.read(appControllerProvider).serverUrl.isEmpty
          ? defaultServerUrl
          : ref.read(appControllerProvider).serverUrl,
    );
  }

  @override
  void dispose() {
    _server.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(appControllerProvider).login(
            username: _username.text,
            password: _password.text,
            server: _server.text,
          );
    } catch (error) {
      setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _message(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['detail'] != null) {
        return data['detail'].toString();
      }
      if (error.response?.statusCode == 401) {
        return 'Usuario o contraseña incorrectos.';
      }
      return 'No se pudo conectar. Verifique el servidor e intente de nuevo.';
    }
    final text = error.toString();
    return text.startsWith('Exception: ') ? text.substring(11) : text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(25, 28, 25, 24),
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minHeight: constraints.maxHeight - 52),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BrandMark(size: 64),
                  const SizedBox(height: 30),
                  Text(
                    'Censo\nCampesino',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: darkGreen,
                          height: 1.1,
                          fontSize: 36,
                        ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'La Guaira · Registro de campo',
                    style: TextStyle(color: mutedText, fontSize: 15),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [darkGreen, brandGreen, midGreen],
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.offline_bolt_rounded,
                            color: Color(0xFFB7F7D8), size: 25),
                        SizedBox(width: 13),
                        Expanded(
                          child: Text(
                            'Trabaje sin señal. Sus registros se guardan en este teléfono y se envían al volver la conexión.',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  TextField(
                    controller: _username,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    decoration: const InputDecoration(
                      labelText: 'Usuario',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 13),
                  TextField(
                    controller: _password,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _login(),
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(_obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(height: 11),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _showServer = !_showServer),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.tune_rounded, size: 18, color: brandGreen),
                          SizedBox(width: 8),
                          Text(
                            'Configurar servidor',
                            style: TextStyle(
                                color: brandGreen, fontWeight: FontWeight.w600),
                          ),
                          Spacer(),
                          Icon(Icons.expand_more, color: mutedText),
                        ],
                      ),
                    ),
                  ),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 180),
                    crossFadeState: _showServer
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: TextField(
                        controller: _server,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'URL del servidor',
                          hintText: defaultServerUrl,
                          prefixIcon: Icon(Icons.dns_outlined),
                        ),
                      ),
                    ),
                    secondChild: const SizedBox(width: double.infinity),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 4),
                    Text(_error!,
                        style: const TextStyle(
                            color: Color(0xFFE11D48), fontSize: 13)),
                  ],
                  const SizedBox(height: 13),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: _loading ? null : _login,
                      style: FilledButton.styleFrom(
                        backgroundColor: brandGreen,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Iniciar sesión'),
                                SizedBox(width: 9),
                                Icon(Icons.arrow_forward_rounded, size: 19),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Center(
                    child: Column(
                      children: [
                        Text(
                          'ESTADO LA GUAIRA  ·  MODO CAMPO',
                          style: TextStyle(
                              color: Color(0xFF9AA39D),
                              fontSize: 10,
                              letterSpacing: 1.25),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '© 2026 · Fundacite La Guaira\nDesarrollado por Carmelo Marcano',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: mutedText, fontSize: 10, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
