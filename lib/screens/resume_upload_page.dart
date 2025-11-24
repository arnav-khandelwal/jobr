import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:swipe_app/services/resume_service.dart';
import 'package:swipe_app/widgets/bottom_navbar.dart';

class ResumeUploadPage extends StatefulWidget {
  const ResumeUploadPage({super.key});

  @override
  State<ResumeUploadPage> createState() => _ResumeUploadPageState();
}

class _ResumeUploadPageState extends State<ResumeUploadPage> {
  PlatformFile? _pickedFile;
  bool _uploading = false;
  Map<String, dynamic>? _parsed;
  String? _error;
  int _navIndex = 3; // Resume tab index
  bool _snippetExpanded = false; // controls expansion of raw snippet

  Future<void> _pickFile() async {
    setState(() {
      _error = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: kIsWeb, // need bytes on web
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (!(file.extension?.toLowerCase() == 'pdf')) {
          setState(() => _error = 'Please select a PDF file.');
          return;
        }
        setState(() => _pickedFile = file);
      }
    } catch (e) {
      setState(() => _error = 'File selection failed: $e');
    }
  }

  Future<void> _upload() async {
    if (_pickedFile == null) return;
    setState(() {
      _uploading = true;
      _error = null;
      _parsed = null;
    });
    try {
      final fileName = _pickedFile!.name;
      Map<String, dynamic> parsed;
      if (kIsWeb) {
        final bytes = _pickedFile!.bytes;
        if (bytes == null)
          throw ResumeException('Missing bytes for web upload');
        parsed = await ResumeService.instance.parseResume(
          bytes: bytes,
          fileName: fileName,
        );
      } else {
        final path = _pickedFile!.path;
        if (path == null) throw ResumeException('Missing file path');
        parsed = await ResumeService.instance.parseResume(
          file: File(path),
          fileName: fileName,
        );
      }
      setState(() => _parsed = parsed);
    } on ResumeException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Upload failed: $e');
    } finally {
      setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF1E293B);
    final accentColor = const Color(0xFF6366F1);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Resume Parser',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: themeColor,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Upload Card
              Card(
                elevation: 2,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.upload_file,
                              color: accentColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Upload Resume',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Upload your PDF resume to extract key information automatically',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // File picker area
                      if (_pickedFile == null)
                        InkWell(
                          onTap: _uploading ? null : _pickFile,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: accentColor.withOpacity(0.3),
                                style: BorderStyle.solid,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: accentColor.withOpacity(0.05),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 48,
                                  color: accentColor,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to choose PDF file',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: accentColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'PDF files only',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.05),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.picture_as_pdf,
                                  color: Colors.green,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _pickedFile!.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'PDF • Ready to upload',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Color(0xFF64748B),
                                ),
                                onPressed: _uploading
                                    ? null
                                    : () => setState(() {
                                        _pickedFile = null;
                                        _parsed = null;
                                        _error = null;
                                      }),
                              ),
                            ],
                          ),
                        ),

                      if (_pickedFile != null) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            icon: _uploading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.auto_awesome),
                            onPressed: _uploading ? null : _upload,
                            label: Text(
                              _uploading ? 'Parsing Resume...' : 'Parse Resume',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Error display
              if (_error != null) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.red.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade600),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Results section
              if (_parsed != null) ...[
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Extracted Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final double maxWidth = constraints.maxWidth;
                            final bool twoColumns = maxWidth > 600; // adaptive
                            final List<String> orderedKeys = [
                              'name',
                              'email',
                              'phone',
                              'skills',
                              'education',
                              'experience',
                              ..._parsed!.keys.where(
                                (k) => ![
                                  'name',
                                  'email',
                                  'phone',
                                  'skills',
                                  'education',
                                  'experience',
                                  'raw_text_snippet',
                                ].contains(k),
                              ),
                            ];

                            List<Widget> tiles = [];
                            for (final key in orderedKeys) {
                              if (!_parsed!.containsKey(key)) continue;
                              if (key == 'raw_text_snippet') continue;
                              final value = _parsed![key];
                              Widget content;
                              if (key == 'skills' && value is List) {
                                content = Wrap(
                                  spacing: 6,
                                  runSpacing: -4,
                                  children: value
                                      .take(20)
                                      .map<Widget>(
                                        (s) => Chip(
                                          label: Text(
                                            s.toString(),
                                            style: const TextStyle(
                                              fontSize: 11,
                                            ),
                                          ),
                                          backgroundColor: const Color(
                                            0xFFEFF6FF,
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFFBFDBFE),
                                          ),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      )
                                      .toList(),
                                );
                              } else if ((key == 'education' ||
                                      key == 'experience') &&
                                  value is List) {
                                final list = value
                                    .where(
                                      (l) => l.toString().trim().isNotEmpty,
                                    )
                                    .take(12)
                                    .toList();
                                content = Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: list
                                      .map(
                                        (l) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 4,
                                          ),
                                          child: Text(
                                            '• ${l.toString()}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF1E293B),
                                              height: 1.3,
                                            ),
                                            softWrap: true,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                );
                              } else {
                                content = Text(
                                  value == null ||
                                          (value is String &&
                                              value.trim().isEmpty)
                                      ? 'Not found'
                                      : value is List
                                      ? value.join(', ')
                                      : value.toString(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        value == null ||
                                            (value is String &&
                                                value.trim().isEmpty)
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF1E293B),
                                    fontWeight: FontWeight.w500,
                                    height: 1.25,
                                  ),
                                );
                              }
                              tiles.add(
                                Container(
                                  width: twoColumns
                                      ? (maxWidth - 12) / 2
                                      : maxWidth,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        key.replaceAll('_', ' ').toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF64748B),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      content,
                                    ],
                                  ),
                                ),
                              );
                            }
                            return Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: tiles,
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        if (_parsed!.containsKey('raw_text_snippet') &&
                            _parsed!['raw_text_snippet'] != null &&
                            _parsed!['raw_text_snippet']
                                .toString()
                                .trim()
                                .isNotEmpty)
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    12,
                                    12,
                                    0,
                                  ),
                                  child: Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'RAW TEXT PREVIEW',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF64748B),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => setState(() {
                                          _snippetExpanded = !_snippetExpanded;
                                        }),
                                        icon: Icon(
                                          _snippetExpanded
                                              ? Icons.expand_less
                                              : Icons.expand_more,
                                          size: 18,
                                        ),
                                        label: Text(
                                          _snippetExpanded
                                              ? 'Collapse'
                                              : 'Expand',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                AnimatedCrossFade(
                                  firstChild: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      4,
                                      12,
                                      12,
                                    ),
                                    child: Text(
                                      _parsed!['raw_text_snippet']
                                          .toString()
                                          .replaceAll('\r', ''),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF1E293B),
                                        height: 1.35,
                                      ),
                                      maxLines: 6,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  secondChild: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      4,
                                      12,
                                      12,
                                    ),
                                    child: SelectableText(
                                      _parsed!['raw_text_snippet']
                                          .toString()
                                          .replaceAll('\r', ''),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF1E293B),
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                  crossFadeState: _snippetExpanded
                                      ? CrossFadeState.showSecond
                                      : CrossFadeState.showFirst,
                                  duration: const Duration(milliseconds: 250),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _navIndex,
        onTap: (index) {
          if (index != _navIndex) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
