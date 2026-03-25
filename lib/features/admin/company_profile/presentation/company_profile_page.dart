import 'package:flutter/material.dart';
import '../data/company_asset_storage_service.dart';
import '../data/company_profile_service.dart';

class CompanyProfilePage extends StatefulWidget {
  const CompanyProfilePage({super.key});

  @override
  State<CompanyProfilePage> createState() => _CompanyProfilePageState();
}

class _CompanyProfilePageState extends State<CompanyProfilePage> {
  final CompanyProfileService _service = CompanyProfileService();
  final CompanyAssetStorageService _assetStorageService =
      CompanyAssetStorageService();

  late Future<void> _loadFuture;

  String? _companyId;
  bool _isUploadingLogo = false;
  bool _isUploadingBankQr = false;
  bool _isUploadingPrintBg = false;

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

  bool _canView = false;
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

    _canView = access['canView'] == true;
    _canEdit = access['canEdit'] == true;
    _companyId = (profile['company_id'] ?? '').toString().trim();

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

  Future<void> _uploadAsset({
    required String assetType,
    required TextEditingController controller,
    required List<String> allowedExtensions,
    required void Function(bool value) setUploading,
  }) async {
    if (!_canEdit) return;

    final companyId = (_companyId ?? '').trim();
    if (companyId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company ID not found. Please reload page.')),
      );
      return;
    }

    setState(() {
      setUploading(true);
    });

    try {
      final publicUrl = await _assetStorageService.pickAndUploadAsset(
        companyId: companyId,
        assetType: assetType,
        oldPublicUrl: controller.text,
        allowedExtensions: allowedExtensions,
      );

      if (publicUrl == null || publicUrl.trim().isEmpty) {
        return;
      }

      controller.text = publicUrl;

      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Asset uploaded successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          setUploading(false);
        });
      }
    }
  }

  Widget _imagePreview({
    required String label,
    required TextEditingController controller,
    double height = 120,
  }) {
    final url = controller.text.trim();
    if (url.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text('$label preview: no file selected'),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label preview'),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              height: height,
              color: Colors.black12,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) {
                  return const Center(
                    child: Text('Preview unavailable'),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _uploadButton({
    required String label,
    required bool isUploading,
    required VoidCallback? onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: isUploading ? null : onPressed,
          icon: isUploading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload_file),
          label: Text(isUploading ? 'Uploading...' : label),
        ),
      ),
    );
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

          if (!_canView) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('You are not allowed to view Company Profile.'),
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
                                ? 'Editable only for superadmin'
                                : 'Read-only access',
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
                          _uploadButton(
                            label: 'Upload Logo',
                            isUploading: _isUploadingLogo,
                            onPressed: _canEdit
                                ? () => _uploadAsset(
                                      assetType: 'logo',
                                      controller: _logoUrlController,
                                      allowedExtensions: const [
                                        'png',
                                        'jpg',
                                        'jpeg',
                                        'webp',
                                        'svg',
                                      ],
                                      setUploading: (value) {
                                        _isUploadingLogo = value;
                                      },
                                    )
                                : null,
                          ),
                          _imagePreview(
                            label: 'Logo',
                            controller: _logoUrlController,
                            height: 120,
                          ),
                          _field(
                            controller: _bankQrUrlController,
                            label: 'Bank QR Code URL',
                            maxLines: 3,
                          ),
                          _uploadButton(
                            label: 'Upload Bank QR',
                            isUploading: _isUploadingBankQr,
                            onPressed: _canEdit
                                ? () => _uploadAsset(
                                      assetType: 'bank_qr',
                                      controller: _bankQrUrlController,
                                      allowedExtensions: const [
                                        'png',
                                        'jpg',
                                        'jpeg',
                                        'webp',
                                        'svg',
                                      ],
                                      setUploading: (value) {
                                        _isUploadingBankQr = value;
                                      },
                                    )
                                : null,
                          ),
                          _imagePreview(
                            label: 'Bank QR',
                            controller: _bankQrUrlController,
                            height: 160,
                          ),
                          _field(
                            controller: _printBgUrlController,
                            label: 'Print Background URL',
                            maxLines: 3,
                          ),
                          _uploadButton(
                            label: 'Upload Print Background',
                            isUploading: _isUploadingPrintBg,
                            onPressed: _canEdit
                                ? () => _uploadAsset(
                                      assetType: 'print_bg',
                                      controller: _printBgUrlController,
                                      allowedExtensions: const [
                                        'png',
                                        'jpg',
                                        'jpeg',
                                        'webp',
                                      ],
                                      setUploading: (value) {
                                        _isUploadingPrintBg = value;
                                      },
                                    )
                                : null,
                          ),
                          _imagePreview(
                            label: 'Print Background',
                            controller: _printBgUrlController,
                            height: 140,
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