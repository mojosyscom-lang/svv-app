import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompanyAssetStorageService {
  CompanyAssetStorageService();

  final SupabaseClient _client = Supabase.instance.client;

  static const String bucketName = 'company-assets';

  Future<String?> pickAndUploadAsset({
    required String companyId,
    required String assetType,
    String? oldPublicUrl,
    List<String>? allowedExtensions,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions:
          allowedExtensions ??
          const ['png', 'jpg', 'jpeg', 'webp', 'svg', 'pdf'],
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.single;
    final Uint8List? bytes = file.bytes;
    if (bytes == null) {
      throw Exception('Could not read selected file bytes.');
    }

    final originalName = (file.name).trim();
    final safeName = _sanitizeFileName(originalName.isEmpty ? 'file' : originalName);
    final extension = _extensionFromName(safeName);
    final millis = DateTime.now().millisecondsSinceEpoch;

    final objectPath = '$companyId/$assetType/${millis}_$safeName';

    await _client.storage.from(bucketName).uploadBinary(
      objectPath,
      bytes,
      fileOptions: FileOptions(
        upsert: false,
        cacheControl: '3600',
        contentType: _contentTypeFromExtension(extension),
      ),
    );

    final publicUrl = _client.storage.from(bucketName).getPublicUrl(objectPath);

    final oldPath = _extractStoragePathFromPublicUrl(oldPublicUrl);
    if (oldPath != null && oldPath.isNotEmpty && oldPath != objectPath) {
      try {
        await _client.storage.from(bucketName).remove([oldPath]);
      } catch (_) {
        // ignore old file cleanup failure
      }
    }

    return publicUrl;
  }

  String _sanitizeFileName(String input) {
    return input
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '');
  }

  String _extensionFromName(String name) {
    final dot = name.lastIndexOf('.');
    if (dot == -1 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toLowerCase().trim();
  }

  String _contentTypeFromExtension(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'svg':
        return 'image/svg+xml';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  String? _extractStoragePathFromPublicUrl(String? publicUrl) {
    final raw = (publicUrl ?? '').trim();
    if (raw.isEmpty) return null;

    final marker = '/storage/v1/object/public/$bucketName/';
    final index = raw.indexOf(marker);
    if (index == -1) return null;

    final path = raw.substring(index + marker.length);
    if (path.isEmpty) return null;

    return Uri.decodeFull(path);
  }
}