import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../database/database.dart';
import '../main.dart' show CuteColors;
import '../providers/database_provider.dart';
import 'camera_capture_page.dart';

/// One selectable option in the mood picker row. Display-only for now — see
/// `_EntryEditPageState._selectedMood` for why this isn't persisted yet.
class _MoodOption {
  const _MoodOption(this.label, this.emoji, this.color);

  final String label;
  final String emoji;
  final Color color;
}

const _markerEmojiLabels = {'❤️': '하트', '⭐': '별', '⚪': '동그라미'};

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

/// Create-or-edit form for a single diary entry (title/content/tags/photos).
///
/// A day can hold several entries now, so this always operates on one
/// specific entry: pass [existing] to edit it, or omit it to create a new
/// entry for [date].
class EntryEditPage extends ConsumerStatefulWidget {
  const EntryEditPage({super.key, required this.date, this.existing});

  final DateTime date;
  final EntryWithMedia? existing;

  @override
  ConsumerState<EntryEditPage> createState() => _EntryEditPageState();
}

class _EntryEditPageState extends ConsumerState<EntryEditPage> {
  late final _titleController = TextEditingController(
    text: widget.existing?.entry.title ?? '',
  );
  late final _contentController = TextEditingController(
    text: widget.existing?.entry.content ?? '',
  );
  final _tagInputController = TextEditingController();
  final _picker = ImagePicker();

  late final List<_PickedMedia> _pickedMedia = [
    for (final m in widget.existing?.media ?? const <MediaData>[])
      _PickedMedia(bytes: m.data, mimeType: m.mimeType, type: m.type),
  ];
  late final List<String> _tags = [...?widget.existing?.tags];

  /// Purely local/visual for now — the `mood` column on `DiaryEntries`
  /// exists but wiring persistence up is out of scope here.
  String? _selectedMood;

  /// The emoji this entry contributes to its day's Calendar marker. `null`
  /// means "default" (a plain circle on the calendar).
  late String? _selectedEmoji = widget.existing?.entry.emoji;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  void _addTag(String raw) {
    final name = raw.trim();
    _tagInputController.clear();
    if (name.isEmpty || _tags.contains(name)) return;
    setState(() => _tags.add(name));
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
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty && content.isEmpty && _pickedMedia.isEmpty) {
      return;
    }

    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    try {
      await db.upsertEntry(
        existingId: widget.existing?.entry.id,
        date: widget.date,
        title: title,
        content: content,
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
        emoji: _selectedEmoji,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing != null ? '글 수정' : '새 글 작성'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(false),
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
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(hintText: '제목'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _buildMoodPicker(context),
              const SizedBox(height: 12),
              _buildEmojiPicker(context),
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

  /// Row for choosing this entry's Calendar-day marker emoji: a default
  /// plain circle, or one of [markerEmojiOptions] (❤️/⭐/⚪).
  Widget _buildEmojiPicker(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        _EmojiChoice(
          display: '⚫',
          label: '기본',
          selected: _selectedEmoji == null,
          onTap: () => setState(() => _selectedEmoji = null),
        ),
        for (final emoji in markerEmojiOptions)
          _EmojiChoice(
            display: emoji,
            label: _markerEmojiLabels[emoji] ?? emoji,
            selected: _selectedEmoji == emoji,
            onTap: () => setState(
              () => _selectedEmoji = _selectedEmoji == emoji ? null : emoji,
            ),
          ),
      ],
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

class _EmojiChoice extends StatelessWidget {
  const _EmojiChoice({
    required this.display,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String display;
  final String label;
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
          color: selected
              ? CuteColors.accent.withValues(alpha: 0.25)
              : CuteColors.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? CuteColors.accent : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(display, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 2),
            Text(
              label,
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
