import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';
  bool _error = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    final auth = context.read<AuthProvider>();
    final success = await auth.login(_username, _password);
    if (!mounted) return;
    if (success) {
      // 2FA PIN desactivado temporalmente
      await _finalizeLogin();
    } else {
      setState(() {
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 300,
                  child: TextFormField(
                    textAlign: TextAlign.center,
                    maxLength: 20,
                    decoration: const InputDecoration(
                      labelText: 'Usuario',
                      floatingLabelAlignment: FloatingLabelAlignment.center,
                      alignLabelWithHint: true,
                      counterText: '',
                    ),
                    onSaved: (v) => _username = v ?? '',
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 300,
                  child: TextFormField(
                    textAlign: TextAlign.center,
                    maxLength: 20,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      floatingLabelAlignment: FloatingLabelAlignment.center,
                      alignLabelWithHint: true,
                      counterText: '',
                    ),
                    obscureText: true,
                    onSaved: (v) => _password = v ?? '',
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Requerido' : null,
                  ),
                ),
                if (_error)
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: Text(
                      'Credenciales incorrectas',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Ingresar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _finalizeLogin() async {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }
}
