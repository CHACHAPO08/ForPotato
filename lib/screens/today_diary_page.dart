import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';
import '../main.dart' show CuteColors;
import '../providers/database_provider.dart';
import 'camera_capture_page.dart';

/// One selectable option in the mood picker row. Display-only for now — see
/// `_TodayDiaryPageState._selectedMood` for why this isn't persisted yet.
class _MoodOption {
  const _MoodOption(this.label, this.emoji, this.color);

  final String label;
  final String emoji;
  final Color color;
}

const _moodOptions = [
  _MoodOption('최고', '🤩', CuteColors.moodBest),
  _MoodOption('좋음', '🙂', CuteColors.moodGood),
  _MoodOption('보통', '😐', CuteColors.moodOkay),
  _MoodOption('별로', '😕', CuteColors.moodMeh),
  _MoodOption('힘듦', '😢', CuteColors.moodBad),
];

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

  /// Locally-selected mood for the entry being edited. This is a purely
  /// visual/UI addition for the cute design pass — the `mood` column on
  /// `DiaryEntries` exists but wiring persistence up is out of scope here,
  /// so this state resets on every `_startEditing()` call and is never
  /// sent to `upsertEntry`.
  String? _selectedMood;
  EntryWithMedia? _existingEntry;
  _Mode _mode = _Mode.loading;
  bool _saving = false;

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('저장했습니다')));
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
            icon: const Icon(Icons.edit, color: CuteColors.accent),
            tooltip: '수정',
          ),
          IconButton(
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline, color: CuteColors.accent),
            tooltip: '삭제',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (entry.entry.content.isNotEmpty)
                      Text(entry.entry.content),
                    if (entry.tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final tag in entry.tags)
                            Chip(label: Text('#$tag')),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (entry.media.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final media in entry.media)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
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
                              color: CuteColors.accent.withValues(alpha: 0.12),
                              child: const Icon(
                                Icons.videocam,
                                size: 32,
                                color: CuteColors.accent,
                              ),
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
              _buildMoodPicker(context),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText: '오늘 하루는 어땠나요?',
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
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
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
                                    color: CuteColors.accent.withValues(
                                      alpha: 0.12,
                                    ),
                                    child: const Icon(
                                      Icons.videocam,
                                      size: 32,
                                      color: CuteColors.accent,
                                    ),
                                  ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _pickedMedia.removeAt(index)),
                              child: const CircleAvatar(
                                radius: 10,
                                backgroundColor: CuteColors.textMain,
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
                  prefixIcon: Icon(Icons.tag, color: CuteColors.accent),
                  isDense: true,
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: _addTag,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _MediaActionButton(
                    icon: Icons.camera_alt,
                    label: '카메라',
                    tooltip: '카메라로 촬영 (사진/최대 10초 영상)',
                    onPressed: _openCamera,
                  ),
                  _MediaActionButton(
                    icon: Icons.photo_library,
                    label: '앨범',
                    tooltip: '앨범에서 선택',
                    onPressed: () => _pickPhoto(ImageSource.gallery),
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
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.check),
      ),
    );
  }

  /// Row of 5 selectable mood buttons (최고/좋음/보통/별로/힘듦). Purely local
  /// UI state for now — see the `_selectedMood` field doc comment.
  Widget _buildMoodPicker(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        for (final option in _moodOptions)
          _MoodChoice(
            option: option,
            selected: _selectedMood == option.label,
            onTap: () => setState(() {
              _selectedMood = _selectedMood == option.label
                  ? null
                  : option.label;
            }),
          ),
      ],
    );
  }
}

class _MoodChoice extends StatelessWidget {
  const _MoodChoice({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _MoodOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? option.color : option.color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? option.color : Colors.transparent,
            width: 2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: option.color.withValues(alpha: 0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(option.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 2),
            Text(
              option.label,
              style: GoogleFonts.gowunDodum(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                color: CuteColors.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaActionButton extends StatelessWidget {
  const _MediaActionButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: CuteColors.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: CuteColors.accent, size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.gowunDodum(
                  color: CuteColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
