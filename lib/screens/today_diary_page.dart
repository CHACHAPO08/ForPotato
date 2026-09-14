import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';

class _PickedMedia {
  _PickedMedia({
    required this.bytes,
    required this.mimeType,
    required this.type,
  });

  final Uint8List bytes;
  final String mimeType;
  final MediaType type;
}

class TodayDiaryPage extends ConsumerStatefulWidget {
  const TodayDiaryPage({super.key});

  @override
  ConsumerState<TodayDiaryPage> createState() => _TodayDiaryPageState();
}

class _TodayDiaryPageState extends ConsumerState<TodayDiaryPage> {
  final _contentController = TextEditingController();
  final _picker = ImagePicker();
  final List<_PickedMedia> _pickedMedia = [];
  bool _saving = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _pickedMedia.add(
        _PickedMedia(
          bytes: bytes,
          mimeType: file.mimeType ?? 'image/jpeg',
          type: MediaType.photo,
        ),
      );
    });
  }

  Future<void> _pickVideo() async {
    final file = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 30),
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _pickedMedia.add(
        _PickedMedia(
          bytes: bytes,
          mimeType: file.mimeType ?? 'video/mp4',
          type: MediaType.video,
        ),
      );
    });
  }

  Future<void> _save() async {
    if (_contentController.text.trim().isEmpty && _pickedMedia.isEmpty) {
      return;
    }

    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    try {
      final entryId = await db
          .into(db.diaryEntries)
          .insert(
            DiaryEntriesCompanion.insert(
              date: DateTime.now(),
              content: _contentController.text.trim(),
            ),
          );

      for (final media in _pickedMedia) {
        await db
            .into(db.media)
            .insert(
              MediaCompanion.insert(
                entryId: entryId,
                data: media.bytes,
                mimeType: media.mimeType,
                type: media.type,
              ),
            );
      }

      if (!mounted) return;
      _contentController.clear();
      setState(() => _pickedMedia.clear());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('저장했습니다')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Today')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText: '오늘 하루는 어땠나요?',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              if (_pickedMedia.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _pickedMedia.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final media = _pickedMedia[index];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: media.type == MediaType.photo
                            ? Image.memory(
                                media.bytes,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 80,
                                height: 80,
                                color: Colors.black12,
                                child: const Icon(
                                  Icons.videocam,
                                  size: 32,
                                ),
                              ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () => _pickPhoto(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    tooltip: '사진 촬영',
                  ),
                  IconButton(
                    onPressed: () => _pickPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    tooltip: '앨범에서 선택',
                  ),
                  IconButton(
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.videocam),
                    tooltip: '짧은 동영상 촬영',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saving ? null : _save,
        child: _saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check),
      ),
    );
  }
}
