import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../formatters/domain_error_messages.dart';
import '../widgets/brand_mark.dart';

final class SignInScreen extends StatefulWidget {
  const SignInScreen({
    super.key,
    required this.title,
    required this.role,
    required this.state,
    required this.onLogin,
    required this.onRetry,
  });
  final String title;
  final Role role;
  final AuthState state;
  final void Function(String, String) onLogin;
  final VoidCallback onRetry;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

final class _SignInScreenState extends State<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.state.busy || !_form.currentState!.validate()) return;
    final password = _password.text;
    _password.clear();
    widget.onLogin(_username.text.trim(), password);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final error = state.error;
    final message = error is WrongApplication
        ? widget.role == Role.staff
              ? 'Backoffice je za osoblje salona.'
              : 'Mobilna aplikacija je za klijente salona.'
        : error == null
        ? null
        : errorMessage(error);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: BrandMark(size: 76)),
                    const SizedBox(height: 20),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _username,
                      enabled: !state.busy,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Korisničko ime',
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Unesi korisničko ime.'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      enabled: !state.busy,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: const InputDecoration(labelText: 'Lozinka'),
                      onFieldSubmitted: (_) => _submit(),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Unesi lozinku.'
                          : null,
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        message,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: state.busy ? null : _submit,
                      child: const Text('Prijavi se'),
                    ),
                    if (state.busy) const LinearProgressIndicator(),
                    if (state.restoreFailed)
                      TextButton(
                        onPressed: widget.onRetry,
                        child: const Text('Pokušaj obnovu prijave'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
