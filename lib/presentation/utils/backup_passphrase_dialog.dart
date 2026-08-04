import 'package:flutter/material.dart';

import '../../domain/backup_gateways.dart';

enum BackupPassphrasePurpose {
  export,
  import,
}

Future<String?> showBackupPassphraseDialog(
  BuildContext context, {
  required BackupPassphrasePurpose purpose,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _BackupPassphraseDialog(purpose: purpose),
  );
}

class _BackupPassphraseDialog extends StatefulWidget {
  final BackupPassphrasePurpose purpose;

  const _BackupPassphraseDialog({required this.purpose});

  @override
  State<_BackupPassphraseDialog> createState() =>
      _BackupPassphraseDialogState();
}

class _BackupPassphraseDialogState extends State<_BackupPassphraseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passphraseController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _obscureText = true;

  bool get _isExport => widget.purpose == BackupPassphrasePurpose.export;

  @override
  void dispose() {
    _passphraseController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isExport ? 'Protege tu respaldo' : 'Abre tu respaldo',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isExport
                    ? 'Esta contraseña cifra el archivo. Zentra no la guarda '
                        'y no puede recuperarla.'
                    : 'Ingresa la contraseña usada al exportar. Para un '
                        'respaldo antiguo sin cifrar, déjala vacía.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('backup-passphrase'),
                controller: _passphraseController,
                obscureText: _obscureText,
                autofocus: true,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: _isExport
                    ? const [AutofillHints.newPassword]
                    : const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: 'Contraseña del respaldo',
                  suffixIcon: IconButton(
                    tooltip: _obscureText
                        ? 'Mostrar contraseña'
                        : 'Ocultar contraseña',
                    onPressed: () {
                      setState(() => _obscureText = !_obscureText);
                    },
                    icon: Icon(
                      _obscureText
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  if (!_isExport) return null;
                  if ((value ?? '').length <
                      BackupSecurity.minimumPassphraseLength) {
                    return 'Usa al menos '
                        '${BackupSecurity.minimumPassphraseLength} caracteres';
                  }
                  return null;
                },
              ),
              if (_isExport) ...[
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('backup-passphrase-confirmation'),
                  controller: _confirmationController,
                  obscureText: _obscureText,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: const InputDecoration(
                    labelText: 'Confirma la contraseña',
                  ),
                  validator: (value) {
                    if (value != _passphraseController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _submit(),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isExport ? 'Cifrar y exportar' : 'Continuar'),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop(_passphraseController.text);
  }
}
