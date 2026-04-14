import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/legend_model.dart';
import '../providers/cells_provider.dart';
import '../providers/language_provider.dart';
import '../providers/legends_provider.dart';
import '../theme/app_theme.dart';
import 'app_dialog.dart';
import 'legend_editor_dialog.dart';
import 'swipe_nav.dart';

class CellEditorDialog extends StatefulWidget {
  final int month;
  final int day;
  final int year;

  const CellEditorDialog({
    super.key,
    required this.month,
    required this.day,
    required this.year,
  });

  static Future<void> show(
    BuildContext context, {
    required int month,
    required int day,
    required int year,
  }) {
    final legends = context.read<LegendsProvider>().legends;
    if (legends.isEmpty) {
      final lang = context.read<LanguageProvider>();
      final pageId = context.read<CellsProvider>().currentPageId;
      return showDialog(
        context: context,
        builder: (ctx) => AppDialog(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  lang.t('tracker.addLegendsHint'),
                  style: AppFonts.dot(fontSize: 14, color: AppColors.text),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.of(ctx).pop();
                    if (pageId != null) {
                      LegendEditorDialog.show(context, pageId: pageId);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.btnAdd,
                      border: Border.all(color: AppColors.btnAddBorder),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      lang.t('tracker.editLegends'),
                      style: AppFonts.pixel(fontSize: 12, color: AppColors.btnAddText),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return showDialog(
      context: context,
      builder: (_) => CellEditorDialog(month: month, day: day, year: year),
    );
  }

  @override
  State<CellEditorDialog> createState() => _CellEditorDialogState();
}

class _CellEditorDialogState extends State<CellEditorDialog> {
  late int _month;
  late int _day;
  final _commentController = TextEditingController();
  String? _selectedColor;
  String? _selectedLegendId;
  bool _hasCell = false;
  bool _editingComment = false;

  static const List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _month = widget.month;
    _day = widget.day;
    _loadCellData();
  }

  void _loadCellData() {
    final cells = context.read<CellsProvider>();
    final cell = cells.getCell(_month, _day);
    if (cell != null) {
      _selectedColor = cell.color;
      _selectedLegendId = null;
      _commentController.text = cell.comment ?? '';
      _hasCell = true;
      _editingComment = false;
    } else {
      _selectedColor = null;
      _selectedLegendId = null;
      _commentController.text = '';
      _hasCell = false;
      _editingComment = false;
    }
  }

  void _navigateDay(int delta) {
    setState(() {
      _day += delta;
      if (_day < 1) {
        _month -= 1;
        if (_month < 1) _month = 12;
        _day = 31;
      } else if (_day > 31) {
        _month += 1;
        if (_month > 12) _month = 1;
        _day = 1;
      }
      _loadCellData();
    });
  }

  Color _parseHex(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  String? _legendLabelForColor(String color, List<LegendModel> legends) {
    try {
      return legends.firstWhere((l) => l.color == color).label;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageProvider>();
    final legends = context.watch<LegendsProvider>().legends;

    return AppDialog(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Date navigation
            _buildDateNav(),
            const SizedBox(height: 8),

            if (_hasCell)
              _buildViewMode(lang, legends)
            else
              _buildEditMode(lang, legends),
          ],
        ),
      ),
    );
  }

  Widget _buildDateNav() {
    return SwipeNav(
      arrowSize: 16,
      arrowColor: AppColors.accent,
      onPrev: () => _navigateDay(-1),
      onNext: () => _navigateDay(1),
      center: Text(
        '$_day ${_monthNames[_month - 1]} ${widget.year}',
        style: AppFonts.pixel(fontSize: 14, color: AppColors.title),
      ),
    );
  }

  /// View mode: cell exists — show color, legend label, comment (editable), delete button
  Widget _buildViewMode(LanguageProvider lang, List<LegendModel> legends) {
    final legendLabel = _legendLabelForColor(_selectedColor!, legends);
    final comment = _commentController.text;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Color + legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _parseHex(_selectedColor!),
              ),
            ),
            if (legendLabel != null) ...[
              const SizedBox(width: 10),
              Text(
                legendLabel,
                style: AppFonts.dot(fontSize: 14, color: AppColors.text),
              ),
            ],
          ],
        ),

        const SizedBox(height: 12),

        // Comment: view or edit
        if (_editingComment) ...[
          TextField(
            controller: _commentController,
            autofocus: true,
            maxLength: 200,
            maxLines: 2,
            style: AppFonts.dot(fontSize: 13, color: AppColors.inputText),
            decoration: InputDecoration(
              hintText: '${lang.t('common.comment')}...',
              hintStyle: AppFonts.dot(fontSize: 13, color: AppColors.textMuted),
              counterStyle: AppFonts.dot(fontSize: 10, color: AppColors.textMuted),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  // Reload original comment
                  final cells = context.read<CellsProvider>();
                  final cell = cells.getCell(_month, _day);
                  _commentController.text = cell?.comment ?? '';
                  setState(() => _editingComment = false);
                },
                child: Text(
                  lang.t('common.cancel'),
                  style: AppFonts.pixel(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () async {
                  final cells = context.read<CellsProvider>();
                  final newComment = _commentController.text.trim();
                  await cells.setCell(
                    _month, _day, _selectedColor!,
                    comment: newComment.isNotEmpty ? newComment : null,
                  );
                  setState(() => _editingComment = false);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.btnAdd,
                    border: Border.all(color: AppColors.btnAddBorder),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    lang.t('common.ok'),
                    style: AppFonts.pixel(fontSize: 12, color: AppColors.btnAddText),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          // Show comment block with edit icon, or small "add" button if no comment
          if (comment.isNotEmpty)
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.dotBorder, width: 0.5),
                  ),
                  child: Text(
                    comment,
                    style: AppFonts.dot(fontSize: 12, color: AppColors.subtitle),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _editingComment = true),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.edit_outlined, size: 13, color: AppColors.textMuted),
                  ),
                ),
              ],
            )
          else
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _editingComment = true),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      lang.t('common.comment'),
                      style: AppFonts.dot(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text(
                    lang.t('settings.back'),
                    style: AppFonts.pixel(fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () async {
                  final cells = context.read<CellsProvider>();
                  await cells.deleteCell(_month, _day);
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.btnReset,
                    border: Border.all(color: AppColors.btnResetBorder),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_outline, size: 14, color: AppColors.btnResetText),
                      const SizedBox(width: 6),
                      Text(
                        lang.t('common.delete'),
                        style: AppFonts.pixel(
                          fontSize: 12,
                          color: AppColors.btnResetText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Edit mode: cell is empty — select legend, add comment, confirm
  Widget _buildEditMode(LanguageProvider lang, List<LegendModel> legends) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Legend selection
        ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: legends.map((legend) {
                  return _buildLegendRow(legend);
                }).toList(),
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Comment field
        TextField(
          controller: _commentController,
          maxLength: 200,
          maxLines: 2,
          style: AppFonts.dot(fontSize: 13, color: AppColors.inputText),
          decoration: InputDecoration(
            hintText: '${lang.t('common.comment')}...',
            hintStyle: AppFonts.dot(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
            counterStyle: AppFonts.dot(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Text(
                lang.t('common.cancel'),
                style: AppFonts.pixel(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 20),
            GestureDetector(
              onTap: _selectedColor == null
                  ? null
                  : () async {
                      final cells = context.read<CellsProvider>();
                      final comment = _commentController.text.trim();
                      await cells.setCell(
                        _month,
                        _day,
                        _selectedColor!,
                        comment: comment.isNotEmpty ? comment : null,
                      );
                      if (context.mounted) Navigator.of(context).pop();
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _selectedColor != null
                      ? AppColors.btnAdd
                      : AppColors.dotEmpty,
                  border: Border.all(
                    color: _selectedColor != null
                        ? AppColors.btnAddBorder
                        : AppColors.dotBorder,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  lang.t('common.ok'),
                  style: AppFonts.pixel(
                    fontSize: 12,
                    color: _selectedColor != null
                        ? AppColors.btnAddText
                        : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendRow(LegendModel legend) {
    final selected = _selectedLegendId == legend.id;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = legend.color;
          _selectedLegendId = legend.id;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.screen : Colors.transparent,
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.screenBorder,
            width: selected ? 1.5 : 0.5,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _parseHex(legend.color),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                legend.label,
                style: AppFonts.dot(fontSize: 13, color: AppColors.text),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
