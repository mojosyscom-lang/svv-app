import 'package:flutter/material.dart';
import '../data/superadmin_user_service.dart';

class NewUserPage extends StatefulWidget {
  const NewUserPage({super.key});

  @override
  State<NewUserPage> createState() => _NewUserPageState();
}

class _NewUserPageState extends State<NewUserPage> {
  final SuperadminUserService _service = SuperadminUserService();
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();

  String _role = 'staff';
  bool _isSaving = false;
  late Future<Map<String, dynamic>> _accessFuture;

  @override
  void initState() {
    super.initState();
    _accessFuture = _service.getMyAccess();
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _service.createUser(
        email: _emailController.text,
        password: _passwordController.text,
        username: _usernameController.text,
        displayName: _displayNameController.text,
        role: _role,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User created successfully')),
      );
      Navigator.pop(context);
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
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New User'),
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
          final isSuperadmin = access['isSuperadmin'] == true;

          if (!isSuperadmin) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Only superadmin can create users.'),
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
                          'Create User',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _field(
                          controller: _emailController,
                          label: 'Email',
                          validator: (value) {
                            final text = (value ?? '').trim();
                            if (text.isEmpty) return 'Required';
                            if (!text.contains('@')) return 'Enter valid email';
                            return null;
                          },
                        ),
                        _field(
                          controller: _usernameController,
                          label: 'Username',
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) return 'Required';
                            return null;
                          },
                        ),
                        _field(
                          controller: _displayNameController,
                          label: 'Display Name',
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) return 'Required';
                            return null;
                          },
                        ),
                        _field(
                          controller: _passwordController,
                          label: 'Password',
                          obscure: true,
                          validator: (value) {
                            final text = value ?? '';
                            if (text.isEmpty) return 'Required';
                            if (text.length < 6) {
                              return 'Minimum 6 characters';
                            }
                            return null;
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DropdownButtonFormField<String>(
                            value: _role,
                            decoration: const InputDecoration(
                              labelText: 'Role',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'staff',
                                child: Text('staff'),
                              ),
                              DropdownMenuItem(
                                value: 'owner',
                                child: Text('owner'),
                              ),
                              DropdownMenuItem(
                                value: 'superadmin',
                                child: Text('superadmin'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _role = value;
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _createUser,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.person_add_alt_1),
                            label: Text(_isSaving ? 'Creating...' : 'Create User'),
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