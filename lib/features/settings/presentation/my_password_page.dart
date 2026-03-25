import 'package:flutter/material.dart';
import '../data/my_password_service.dart';

class MyPasswordPage extends StatefulWidget {
  const MyPasswordPage({super.key});

  @override
  State<MyPasswordPage> createState() => _MyPasswordPageState();
}

class _MyPasswordPageState extends State<MyPasswordPage> {
  final MyPasswordService _service = MyPasswordService();
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isSaving = false;
  late Future<Map<String, dynamic>> _accessFuture;

  @override
  void initState() {
    super.initState();
    _accessFuture = _service.getMyAccess();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _service.changeMyPassword(
        newPassword: _passwordController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your password was updated')),
      );
      _passwordController.clear();
      _confirmController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          final text = value ?? '';
          if (text.isEmpty) return 'Required';
          if (text.length < 6) return 'Minimum 6 characters';
          if (label == 'Confirm Password' && text != _passwordController.text) {
            return 'Passwords do not match';
          }
          return null;
        },
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Password'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _accessFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Failed to load access: ${snapshot.error}'),
              ),
            );
          }

          final access = snapshot.data ?? const <String, dynamic>{};
          final canChange = access['canChangeOwnPassword'] == true;

          if (!canChange) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Only owner and superadmin can change their own password here.',
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Change My Password',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _field(
                          controller: _passwordController,
                          label: 'New Password',
                        ),
                        _field(
                          controller: _confirmController,
                          label: 'Confirm Password',
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _save,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.lock_reset),
                            label: Text(_isSaving ? 'Saving...' : 'Update Password'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}