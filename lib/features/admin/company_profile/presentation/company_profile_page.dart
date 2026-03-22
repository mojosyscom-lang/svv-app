import 'package:flutter/material.dart';
import '../data/company_profile_service.dart';

class CompanyProfilePage extends StatefulWidget {
  const CompanyProfilePage({super.key});

  @override
  State<CompanyProfilePage> createState() => _CompanyProfilePageState();
}

class _CompanyProfilePageState extends State<CompanyProfilePage> {
  final CompanyProfileService _service = CompanyProfileService();

  late Future<void> _loadFuture;

  final _formKey = GlobalKey<FormState>();

  final _companyNameController = TextEditingController();
  final _shortDescController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gstinController = TextEditingController();
  final _placeController = TextEditingController();
  final _invFormatController = TextEditingController();
  final _termsController = TextEditingController();
  final _termsInvoiceController = TextEditingController();
  final _installTermsController = TextEditingController();
  final _logoUrlController = TextEditingController();
  final _bankQrUrlController = TextEditingController();
  final _printBgUrlController = TextEditingController();

  bool _canEdit = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  Future<void> _load() async {
    final access = await _service.getMyAccess();
    final profile = await _service.fetchCompanyProfile();

    _canEdit = access['canEdit'] == true;

    _companyNameController.text = (profile['company_name'] ?? '').toString();
    _shortDescController.text = (profile['short_desc'] ?? '').toString();
    _addressController.text = (profile['address'] ?? '').toString();
    _phoneController.text = (profile['phone'] ?? '').toString();
    _gstinController.text = (profile['gstin'] ?? '').toString();
    _placeController.text = (profile['place_of_supply'] ?? '').toString();
    _invFormatController.text = (profile['inv_format'] ?? '').toString();
    _termsController.text = (profile['terms'] ?? '').toString();
    _termsInvoiceController.text = (profile['terms_invoice'] ?? '').toString();
    _installTermsController.text = (profile['install_terms'] ?? '').toString();
    _logoUrlController.text = (profile['logo_url'] ?? '').toString();
    _bankQrUrlController.text = (profile['bank_qr_url'] ?? '').toString();
    _printBgUrlController.text = (profile['print_bg_url'] ?? '').toString();
  }

  Future<void> _reload() async {
    setState(() {
      _loadFuture = _load();
    });
    await _loadFuture;
  }

  Future<void> _save() async {
    if (!_canEdit) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _service.saveCompanyProfile(
        companyName: _companyNameController.text,
        address: _addressController.text,
        phone: _phoneController.text,
        gstin: _gstinController.text,
        placeOfSupply: _placeController.text,
        terms: _termsController.text,
        termsInvoice: _termsInvoiceController.text,
        shortDesc: _shortDescController.text,
        logoUrl: _logoUrlController.text,
        bankQrUrl: _bankQrUrlController.text,
        printBgUrl: _printBgUrlController.text,
        invFormat: _invFormatController.text,
        installTerms: _installTermsController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company Profile Saved')),
      );
      await _reload();
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
    int maxLines = 1,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        enabled: _canEdit,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _shortDescController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _gstinController.dispose();
    _placeController.dispose();
    _invFormatController.dispose();
    _termsController.dispose();
    _termsInvoiceController.dispose();
    _installTermsController.dispose();
    _logoUrlController.dispose();
    _bankQrUrlController.dispose();
    _printBgUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Profile'),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Failed to load company profile: ${snapshot.error}'),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
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
                            'Company Profile',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _canEdit
                                ? 'Editable for owner and superadmin'
                                : 'Read-only for your role',
                          ),
                          const SizedBox(height: 16),
                          _field(
                            controller: _companyNameController,
                            label: 'Company Name',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                          _field(
                            controller: _shortDescController,
                            label: 'Short Description',
                            hint: 'LED Wall Rentals',
                          ),
                          _field(
                            controller: _addressController,
                            label: 'Address',
                            maxLines: 3,
                          ),
                          _field(
                            controller: _phoneController,
                            label: 'Phone',
                          ),
                          _field(
                            controller: _gstinController,
                            label: 'GSTIN',
                          ),
                          _field(
                            controller: _placeController,
                            label: 'Place of Supply',
                            hint: 'Gujarat',
                          ),
                          _field(
                            controller: _invFormatController,
                            label: 'Invoice Number Format (middle prefix)',
                            hint: 'Example: 2026/',
                          ),
                          _field(
                            controller: _termsController,
                            label: 'Terms (For Quotation)',
                            maxLines: 4,
                          ),
                          _field(
                            controller: _termsInvoiceController,
                            label: 'Terms (For Invoice)',
                            maxLines: 4,
                          ),
                          _field(
                            controller: _installTermsController,
                            label: 'Installation Terms & Conditions',
                            maxLines: 5,
                          ),
                          _field(
                            controller: _logoUrlController,
                            label: 'Logo URL',
                            maxLines: 3,
                          ),
                          _field(
                            controller: _bankQrUrlController,
                            label: 'Bank QR Code URL',
                            maxLines: 3,
                          ),
                          _field(
                            controller: _printBgUrlController,
                            label: 'Print Background URL',
                            maxLines: 3,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: (!_canEdit || _isSaving) ? null : _save,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.save),
                              label: Text(_isSaving ? 'Saving...' : 'Save Company Profile'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}