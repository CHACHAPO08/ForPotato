import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';
import '../theme/analog_theme.dart';
import 'camera_capture_page.dart';

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

enum _Mode { loading, empty, viewing, editing }

class TodayDiaryPage extends ConsumerStatefulWidget {
  const TodayDiaryPage({super.key, this.date});

  /// The diary date this page composes/edits an entry for.
  /// Defaults to today when not provided (the bottom-nav "Today" tab).
  final DateTime? date;

  @override
  ConsumerState<TodayDiaryPage> createState() => _TodayDiaryPageState();
}

class _TodayDiaryPageState extends ConsumerState<TodayDiaryPage> {
  late final DateTime _targetDate = widget.date ?? DateTime.now();
  final _contentController = TextEditingController();
  final _tagInputController = TextEditingController();
  final _picker = ImagePicker();
  List<_PickedMedia> _pickedMedia = [];
  List<String> _tags = [];
  EntryWithMedia? _existingEntry;
  _Mode _mode = _Mode.loading;
  bool _saving = false;

  /// Mood selected in the editor. Local UI state only - not yet persisted to
  /// the database (the `mood` column exists but isn't wired up).
  String? _selectedMood;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    final existing = await db.entryForDate(_targetDate);
    if (!mounted) return;
    setState(() {
      _existingEntry = existing;
      _mode = existing != null ? _Mode.viewing : _Mode.empty;
    });
  }

  void _startEditing() {
    final existing = _existingEntry;
    _contentController.text = existing?.entry.content ?? '';
    _pickedMedia = [
      if (existing != null)
        for (final m in existing.media)
          _PickedMedia(bytes: m.data, mimeType: m.mimeType, type: m.type),
    ];
    _tags = [if (existing != null) ...existing.tags];
    _selectedMood = null;
    setState(() => _mode = _Mode.editing);
  }

  void _addTag(String raw) {
    final name = raw.trim();
    _tagInputController.clear();
    if (name.isEmpty || _tags.contains(name)) return;
    setState(() => _tags.add(name));
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tagInputController.dispose();
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

  /// Setlog/인스타그램 스토리 스타일의 독자적인 카메라 화면(CameraCapturePage)을 열어
  /// 사진 또는 최대 10초 영상을 촬영하고, 그 결과를 첨부 목록에 추가한다.
  Future<void> _openCamera() async {
    final result = await Navigator.of(context).push<CameraCaptureResult>(
      MaterialPageRoute(
        builder: (_) => const CameraCapturePage(maxVideoSeconds: 10),
        fullscreenDialog: true,
      ),
    );
    if (result == null) return;
    setState(() {
      _pickedMedia.add(
        _PickedMedia(
          bytes: result.bytes,
          mimeType: result.mimeType,
          type: result.type,
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
      await db.upsertEntry(
        existingId: _existingEntry?.entry.id,
        date: _targetDate,
        content: _contentController.text.trim(),
        mediaRows: [
          for (final m in _pickedMedia)
            MediaCompanion.insert(
              entryId: 0, // overwritten by upsertEntry
              data: m.bytes,
              mimeType: m.mimeType,
              type: m.type,
            ),
        ],
        tagNames: _tags,
      );

      final refreshed = await db.entryForDate(_targetDate);
      if (!mounted) return;
      setState(() {
        _existingEntry = refreshed;
        _mode = _Mode.viewing;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('저장했습니다')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final entry = _existingEntry;
    if (entry == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제하시겠습니까?'),
        content: const Text('삭제한 글은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final db = ref.read(databaseProvider);
    await db.deleteEntry(entry.entry.id);
    if (!mounted) return;
    setState(() {
      _existingEntry = null;
      _mode = _Mode.empty;
    });
  }

  String get _title {
    final isToday = widget.date == null;
    return isToday ? 'Today' : DateFormat('yyyy.MM.dd').format(_targetDate);
  }

  @override
  Widget build(BuildContext context) {
    switch (_mode) {
      case _Mode.loading:
        return Scaffold(
          appBar: AppBar(title: Text(_title)),
          body: const Center(child: CircularProgressIndicator()),
        );
      case _Mode.empty:
        return Scaffold(
          appBar: AppBar(title: Text(_title)),
          body: const Center(child: Text('아직 작성한 글이 없습니다')),
          floatingActionButton: FloatingActionButton(
            onPressed: _startEditing,
            child: const Icon(Icons.add),
          ),
        );
      case _Mode.viewing:
        return _buildViewing(context);
      case _Mode.editing:
        return _buildEditing(context);
    }
  }

  Widget _buildViewing(BuildContext context) {
    final entry = _existingEntry!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            onPressed: _startEditing,
            icon: const Icon(Icons.edit),
            tooltip: '수정',
          ),
          IconButton(
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline),
            tooltip: '삭제',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (entry.entry.content.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(entry.entry.content),
                ),
              ),
            if (entry.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in entry.tags) Chip(label: Text('#$tag')),
                ],
              ),
            ],
            if (entry.media.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 12,
                children: [
                  for (final (index, media) in entry.media.indexed)
                    PolaroidThumbnail(
                      size: 120,
                      index: index,
                      child: media.type == MediaType.photo
                          ? Image.memory(
                              media.data,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 120,
                              height: 120,
                              color: Colors.black12,
                              child: const Icon(Icons.videocam, size: 32),
                            ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEditing(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        leading: IconButton(
          onPressed: () => setState(
            () => _mode = _existingEntry != null ? _Mode.viewing : _Mode.empty,
          ),
          icon: const Icon(Icons.close),
          tooltip: '취소',
        ),
      ),
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
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _pickedMedia.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final media = _pickedMedia[index];
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          PolaroidThumbnail(
                            size: 80,
                            index: index,
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
                                    child: const Icon(Icons.videocam, size: 32),
                                  ),
                          ),
                          Positioned(
                            top: -4,
                            right: -4,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _pickedMedia.removeAt(index)),
                              child: const CircleAvatar(
                                radius: 10,
                                backgroundColor: AnalogColors.textPrimary,
                                child: Icon(
                                  Icons.close,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _buildMoodPicker(),
              const SizedBox(height: 12),
              if (_tags.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tag in _tags)
                      Chip(
                        label: Text('#$tag'),
                        onDeleted: () => setState(() => _tags.remove(tag)),
                      ),
                  ],
                ),
              const SizedBox(height: 8),
              TextField(
                controller: _tagInputController,
                decoration: const InputDecoration(
                  hintText: '태그 입력 후 Enter (예: 여행)',
                  prefixIcon: Icon(Icons.tag),
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: _addTag,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: _openCamera,
                    icon: const Icon(Icons.camera_alt),
                    tooltip: '카메라로 촬영 (사진/최대 10초 영상)',
                  ),
                  IconButton(
                    onPressed: () => _pickPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    tooltip: '앨범에서 선택',
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

  /// Row of 5 mood "stamps" (최고/좋음/보통/별로/힘듦). Local widget state only
  /// - see [_selectedMood]; not persisted to the database yet.
  Widget _buildMoodPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('오늘의 기분', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final mood in kMoodOptions)
              _MoodStamp(
                mood: mood,
                selected: _selectedMood == mood.label,
                onTap: () => setState(
                  () => _selectedMood = _selectedMood == mood.label
                      ? null
                      : mood.label,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// A small square "paper stamp" style mood swatch used by the mood picker.
class _MoodStamp extends StatelessWidget {
  const _MoodStamp({
    required this.mood,
    required this.selected,
    required this.onTap,
  });

  final MoodOption mood;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: mood.color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: selected ? AnalogColors.accent : Colors.transparent,
                width: 3,
              ),
              boxShadow: selected
                  ? const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: selected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
          const SizedBox(height: 4),
          Text(
            mood.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: selected
                  ? AnalogColors.accent
                  : AnalogColors.textSecondary,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
