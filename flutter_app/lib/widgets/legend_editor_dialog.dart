import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cells_provider.dart';
import '../providers/language_provider.dart';
import '../providers/legends_provider.dart';
import '../theme/app_theme.dart';
import 'app_dialog.dart';
import 'marquee_text.dart';
import 'confirm_dialog.dart';
import 'utf16_length_limit.dart';

/// Dialog for managing legends: list, add, delete, reorder.
class LegendEditorDialog extends StatefulWidget {
  final String pageId;

  const LegendEditorDialog({super.key, required this.pageId});

  static Future<void> show(BuildContext context, {required String pageId}) {
    return showDialog(
      context: context,
      builder: (_) => LegendEditorDialog(pageId: pageId),
    );
  }

  @override
  State<LegendEditorDialog> createState() => _LegendEditorDialogState();
}

class _LegendEditorDialogState extends State<LegendEditorDialog> {
  final _labelController = TextEditingController();
  final _editLabelController = TextEditingController();
  String _selectedColor = AppTheme.defaultPalette[0][0];
  // Track selection by position: "row,col" (e.g. "0,3" or "custom,2")
  String _selectedPos = '0,0';
  List<dynamic> _legends = [];
  int? _draggingIndex;
  // Legend being edited (label + color on one screen); null = the list.
  int? _editIndex;
  late List<List<String>> _palette;

  @override
  void initState() {
    super.initState();
    _legends = List.of(context.read<LegendsProvider>().legends);
    // Deep copy the default palette so edits don't affect the original
    _palette = AppTheme.defaultPalette.map((row) => List<String>.from(row)).toList();
  }

  Color _parseHex(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  LegendsProvider get _prov => context.read<LegendsProvider>();

  dynamic get _editing => _editIndex == null ? null : _legends[_editIndex!];

  @override
  void dispose() {
    _labelController.dispose();
    _editLabelController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() => _legends = List.of(_prov.legends));
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final item = _legends.removeAt(oldIndex);
      _legends.insert(newIndex, item);
    });
    final ids = _legends.map((l) => l.id as String).toList();
    _prov.reorderLegends(ids);
  }

  void _openEdit(int i) {
    _editLabelController.text = _legends[i].label as String;
    setState(() => _editIndex = i);
  }

  /// Back to the list; the label is saved if it changed and is not blank.
  Future<void> _closeEdit() async {
    final legend = _editing;
    if (legend == null) return;
    final label = _editLabelController.text.trim();
    setState(() => _editIndex = null);
    if (label.isNotEmpty && label != legend.label) {
      await _prov.updateLegend(legend.id as String, label: label);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageProvider>();
    final editing = _editIndex != null;
    return AppDialog(
      footer: editing ? _buildEditFooter(lang) : _buildListFooter(lang),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: editing ? _buildEdit(lang) : _buildList(lang),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Edit one legend: its label and its color, nothing else on screen
  // ---------------------------------------------------------------------------

  Widget _buildEdit(LanguageProvider lang) {
    final legend = _editing;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          lang.t('tracker.editLegends'),
          style: AppFonts.pixel(fontSize: 16, color: AppColors.title),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _parseHex(legend.color as String),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                key: const Key('legend.editLabel'),
                controller: _editLabelController,
                inputFormatters: const [Utf16LengthLimit(30)],
                style: AppFonts.dot(fontSize: 13, color: AppColors.inputText),
                decoration: InputDecoration(
                  hintText: lang.t('tracker.legendPlaceholder'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                onSubmitted: (_) => _closeEdit(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomPaint(
          size: const Size(double.infinity, 1),
          painter: _DashedHLinePainter(color: AppColors.sectionBorder),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            lang.t('tracker.pickColor'),
            style: AppFonts.pixel(fontSize: 10, color: AppColors.accent),
          ),
        ),
        _buildPalettePicker(),
      ],
    );
  }

  Widget _buildEditFooter(LanguageProvider lang) {
    return Center(
      child: Semantics(
        button: true,
        child: GestureDetector(
          onTap: _closeEdit,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // The list: reorder, open one, delete, add
  // ---------------------------------------------------------------------------

  Widget _buildList(LanguageProvider lang) {
    final legends = _legends;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          lang.t('tracker.legend'),
          style: AppFonts.pixel(fontSize: 16, color: AppColors.title),
        ),
        const SizedBox(height: 16),

        if (legends.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              lang.t('tracker.noLegends'),
              style: AppFonts.dot(fontSize: 13, color: AppColors.textMuted),
            ),
          )
        else
          Column(
            children: List.generate(legends.length, (i) {
                  return _DraggableLegendTile(
                    index: i,
                    legend: legends[i],
                    isDragging: _draggingIndex == i,
                    parseHex: _parseHex,
                    onDragStarted: () => setState(() => _draggingIndex = i),
                    onDragEnd: () => setState(() => _draggingIndex = null),
                    onAccept: (fromIndex) => _onReorder(fromIndex, i),
                    onTap: () => _openEdit(i),
                    onDelete: () async {
                      final confirmed = await ConfirmDialog.show(
                        context,
                        title: lang.t('common.delete'),
                        message: lang.t('tracker.deleteLegendConfirm'),
                        confirmLabel: lang.t('common.delete'),
                        cancelLabel: lang.t('common.cancel'),
                        destructive: true,
                      );
                      if (confirmed == true && mounted) {
                        await _prov.deleteLegend(legends[i].id);
                        _refresh();
                      }
                    },
                  );
                }),
          ),

        const SizedBox(height: 16),
        CustomPaint(
          size: const Size(double.infinity, 1),
          painter: _DashedHLinePainter(color: AppColors.sectionBorder),
        ),
        const SizedBox(height: 16),

        // Color of the legend to add
        _buildPalettePicker(),

        const SizedBox(height: 12),

        // Add new legend (max 12)
        if (legends.length < 12)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: TextField(
                    controller: _labelController,
                    inputFormatters: const [Utf16LengthLimit(30)],
                    style: AppFonts.dot(
                      fontSize: 13,
                      color: AppColors.inputText,
                    ),
                    decoration: InputDecoration(
                      hintText: lang.t('tracker.legendPlaceholder'),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    final label = _labelController.text.trim();
                    if (label.isEmpty) return;
                    await _prov.createLegend(_selectedColor, label);
                    _labelController.clear();
                    _refresh();
                  },
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.btnAdd,
                      border: Border.all(color: AppColors.btnAddBorder),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      lang.t('common.add'),
                      style: AppFonts.pixel(
                        fontSize: 12,
                        color: AppColors.btnAddText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildListFooter(LanguageProvider lang) {
    return Center(
      child: Semantics(
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              lang.t('settings.back'),
              style: AppFonts.pixel(fontSize: 12, color: AppColors.accent),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Palette
  // ---------------------------------------------------------------------------

  void _onPaletteColorTap(String hex, String pos) async {
    final legend = _editing;
    if (legend != null) {
      // Recolor the edited legend and its cells; stay on the editor.
      final oldColor = legend.color as String;
      final cells = context.read<CellsProvider>();
      await _prov.updateLegend(legend.id as String, color: hex);
      if (oldColor != hex) {
        await cells.recolorCells({oldColor: hex});
      }
      _refresh();
    } else {
      setState(() {
        _selectedColor = hex;
        _selectedPos = pos;
      });
    }
  }

  Widget _buildColorDot(String hex, String pos, {VoidCallback? onLongPress}) {
    final editing = _editing;
    final isSelected = editing != null ? editing.color == hex : _selectedPos == pos;
    // Selection = an accent ring separated from the dot by a shell-colored
    // gap, so it reads on dark blues and purples as well as on pastels.
    // Unselected dots keep the same footprint (transparent ring).
    return GestureDetector(
      key: Key('palette.$pos'),
      onTap: () => _onPaletteColorTap(hex, pos),
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1),
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.shell,
          border: Border.all(
            color: isSelected ? AppColors.accent : Colors.transparent,
            width: 2,
          ),
        ),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _parseHex(hex),
            border: Border.all(color: AppColors.dotBorder, width: 0.5),
          ),
        ),
      ),
    );
  }

  void _editPaletteColor(int rowIdx, int colIdx) {
    showDialog(
      context: context,
      builder: (_) => _ColorPickerDialog(
        initialColor: _parseHex(_palette[rowIdx][colIdx]),
        onColorSelected: (hex) {
          setState(() {
            _palette[rowIdx][colIdx] = hex;
            _selectedColor = hex;
            _selectedPos = '$rowIdx,$colIdx';
          });
        },
      ),
    );
  }

  Widget _buildPalettePicker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(_palette.length, (rowIdx) {
          final row = _palette[rowIdx];
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(row.length, (colIdx) {
                return _buildColorDot(
                  row[colIdx],
                  '$rowIdx,$colIdx',
                  onLongPress: () => _editPaletteColor(rowIdx, colIdx),
                );
              }),
            ),
          );
        }),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app, size: 10, color: AppColors.textMuted),
            const SizedBox(width: 3),
            Text(
              'long press to edit',
              style: AppFonts.dot(fontSize: 9, color: AppColors.textMuted),
            ),
          ],
        ),
      ],
    );
  }
}

/// Color picker dialog with hex and RGB input.
class _ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final void Function(String hex) onColorSelected;

  const _ColorPickerDialog({
    required this.initialColor,
    required this.onColorSelected,
  });

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late TextEditingController _hexController;
  late TextEditingController _rController;
  late TextEditingController _gController;
  late TextEditingController _bController;
  late double _hue;
  late double _saturation;
  late double _value;
  bool _updatingFields = false;

  @override
  void initState() {
    super.initState();
    final hsv = HSVColor.fromColor(widget.initialColor);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;
    _hexController = TextEditingController(text: _colorToHex(_currentColor));
    _rController = TextEditingController(text: '${(_currentColor.r * 255).round()}');
    _gController = TextEditingController(text: '${(_currentColor.g * 255).round()}');
    _bController = TextEditingController(text: '${(_currentColor.b * 255).round()}');
  }

  Color get _currentColor =>
      HSVColor.fromAHSV(1, _hue, _saturation, _value).toColor();

  @override
  void dispose() {
    _hexController.dispose();
    _rController.dispose();
    _gController.dispose();
    _bController.dispose();
    super.dispose();
  }

  String _colorToHex(Color c) {
    final r = (c.r * 255).round();
    final g = (c.g * 255).round();
    final b = (c.b * 255).round();
    return '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
  }

  void _syncFields() {
    _updatingFields = true;
    final c = _currentColor;
    _hexController.text = _colorToHex(c);
    _rController.text = '${(c.r * 255).round()}';
    _gController.text = '${(c.g * 255).round()}';
    _bController.text = '${(c.b * 255).round()}';
    _updatingFields = false;
  }

  void _setFromColor(Color color) {
    final hsv = HSVColor.fromColor(color);
    setState(() {
      _hue = hsv.hue;
      _saturation = hsv.saturation;
      _value = hsv.value;
      _syncFields();
    });
  }

  void _onHexChanged(String text) {
    if (_updatingFields) return;
    final hex = text.replaceFirst('#', '').trim();
    if (hex.length != 6) return;
    final val = int.tryParse(hex, radix: 16);
    if (val == null) return;
    _setFromColor(Color(0xFF000000 | val));
  }

  void _onRgbChanged() {
    if (_updatingFields) return;
    final r = int.tryParse(_rController.text);
    final g = int.tryParse(_gController.text);
    final b = int.tryParse(_bController.text);
    if (r != null && g != null && b != null &&
        r >= 0 && r <= 255 && g >= 0 && g <= 255 && b >= 0 && b <= 255) {
      _setFromColor(Color.fromARGB(255, r, g, b));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Preview + title
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentColor,
                    border: Border.all(color: AppColors.shellBorder, width: 1.5),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Color Picker',
                  style: AppFonts.pixel(fontSize: 14, color: AppColors.title),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // SV picker area
            SizedBox(
              height: 150,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onPanDown: (d) => _onSVPick(d.localPosition, constraints),
                    onPanUpdate: (d) => _onSVPick(d.localPosition, constraints),
                    child: CustomPaint(
                      size: Size(constraints.maxWidth, 150),
                      painter: _SVPainter(hue: _hue),
                      child: Stack(
                        children: [
                          Positioned(
                            left: (_saturation * constraints.maxWidth - 8)
                                .clamp(0, constraints.maxWidth - 16),
                            top: ((1 - _value) * 150 - 8).clamp(0, 134),
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: const [
                                  BoxShadow(blurRadius: 2, color: Colors.black26),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // Hue slider
            SizedBox(
              height: 20,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onPanDown: (d) => _onHuePick(d.localPosition.dx, constraints.maxWidth),
                    onPanUpdate: (d) => _onHuePick(d.localPosition.dx, constraints.maxWidth),
                    child: CustomPaint(
                      size: Size(constraints.maxWidth, 20),
                      painter: _HuePainter(),
                      child: Stack(
                        children: [
                          Positioned(
                            left: (_hue / 360 * constraints.maxWidth - 4)
                                .clamp(0, constraints.maxWidth - 8),
                            top: 2,
                            child: Container(
                              width: 8,
                              height: 16,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: const [
                                  BoxShadow(blurRadius: 2, color: Colors.black26),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Hex input
            Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text('HEX', style: AppFonts.pixel(fontSize: 9, color: AppColors.textMuted)),
                ),
                Expanded(
                  child: TextField(
                    controller: _hexController,
                    style: AppFonts.dot(fontSize: 13, color: AppColors.inputText),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      isDense: true,
                    ),
                    onChanged: _onHexChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // RGB inputs
            Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text('RGB', style: AppFonts.pixel(fontSize: 9, color: AppColors.textMuted)),
                ),
                _rgbField(_rController, 'R'),
                const SizedBox(width: 4),
                _rgbField(_gController, 'G'),
                const SizedBox(width: 4),
                _rgbField(_bController, 'B'),
              ],
            ),
            const SizedBox(height: 16),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Text(
                    context.read<LanguageProvider>().t('common.cancel'),
                    style: AppFonts.pixel(fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    widget.onColorSelected(_colorToHex(_currentColor));
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.btnAdd,
                      border: Border.all(color: AppColors.btnAddBorder),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      context.read<LanguageProvider>().t('common.ok'),
                      style: AppFonts.pixel(fontSize: 12, color: AppColors.btnAddText),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onSVPick(Offset pos, BoxConstraints constraints) {
    setState(() {
      _saturation = (pos.dx / constraints.maxWidth).clamp(0, 1);
      _value = (1 - pos.dy / 150).clamp(0, 1);
      _syncFields();
    });
  }

  void _onHuePick(double dx, double width) {
    setState(() {
      _hue = (dx / width * 360).clamp(0, 360);
      _syncFields();
    });
  }

  Widget _rgbField(TextEditingController controller, String label) {
    return Expanded(
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: AppFonts.dot(fontSize: 13, color: AppColors.inputText),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          isDense: true,
          hintText: label,
          hintStyle: AppFonts.dot(fontSize: 13, color: AppColors.textMuted),
        ),
        onChanged: (_) => _onRgbChanged(),
      ),
    );
  }
}

/// Paints the saturation/value gradient for a given hue.
class _SVPainter extends CustomPainter {
  final double hue;
  _SVPainter({required this.hue});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // White to hue (horizontal)
    final hueColor = HSVColor.fromAHSV(1, hue, 1, 1).toColor();
    final horizontal = LinearGradient(
      colors: [Colors.white, hueColor],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = horizontal);

    // Transparent to black (vertical)
    final vertical = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.transparent, Colors.black],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = vertical);
  }

  @override
  bool shouldRepaint(_SVPainter old) => old.hue != hue;
}

/// Paints the hue rainbow bar.
class _HuePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final colors = List.generate(7, (i) {
      return HSVColor.fromAHSV(1, i * 60.0, 1, 1).toColor();
    });
    final gradient = LinearGradient(colors: colors).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()..shader = gradient,
    );
  }

  @override
  bool shouldRepaint(_HuePainter old) => false;
}

/// A single legend tile that supports drag-to-reorder and inline label editing.
/// One legend row: drag handle, dot, label, delete. Reorders like the
/// tracker list: drag the handle (a small "≡" chip follows the finger), the
/// row under it highlights, the dragged row greys out. Tapping the dot +
/// label opens the legend's editor (label + color).
class _DraggableLegendTile extends StatelessWidget {
  final int index;
  final dynamic legend;
  final bool isDragging;
  final Color Function(String) parseHex;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnd;
  final void Function(int fromIndex) onAccept;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DraggableLegendTile({
    required this.index,
    required this.legend,
    required this.isDragging,
    required this.parseHex,
    required this.onDragStarted,
    required this.onDragEnd,
    required this.onAccept,
    required this.onTap,
    required this.onDelete,
  });

  /// What follows the finger: the same chip as the tracker list.
  Widget _chip() => Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.shell,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.accent),
          ),
          child: Text('≡', style: TextStyle(fontSize: 14, height: 1, color: AppColors.accent)),
        ),
      );

  /// Three hit zones: the handle (drag at once), the dot + label (tap =
  /// open the editor), the cross (delete). Each zone carries its own
  /// padding, so a touch near the handle or the cross never opens the editor.
  Widget _buildContent(BuildContext context) {
    final ghost = isDragging;
    const handle = Padding(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: SizedBox(width: 20, height: 20),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: ghost ? AppColors.dotEmpty : AppColors.inputBg,
        border: Border.all(color: ghost ? AppColors.dotBorder : AppColors.inputBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Opacity(
        opacity: ghost ? 0.3 : 1.0,
        child: Row(
          children: [
            // The handle drags at once; it stays mounted while its row is
            // the ghost (swapping it out mid-drag would never end the drag).
            Draggable<int>(
              data: index,
              onDragStarted: onDragStarted,
              onDragEnd: (_) => onDragEnd(),
              feedback: _chip(),
              childWhenDragging: handle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Icon(Icons.drag_handle, size: 20, color: AppColors.textMuted),
              ),
            ),
            Expanded(
              child: Semantics(
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: ghost ? null : onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: parseHex(legend.color),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: MarqueeText(
                            text: legend.label,
                            style: AppFonts.dot(fontSize: 13, color: AppColors.text),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Semantics(
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: ghost ? null : onDelete,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 10, 10, 10),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: AppColors.btnResetText,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != index,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        final isOver = candidateData.isNotEmpty;
        return Stack(
          children: [
            _buildContent(context),
            // Drop highlight over the row under the finger (same as the
            // tracker list), inside the row's bottom margin.
            if (isOver)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: 4,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DashedHLinePainter extends CustomPainter {
  final Color color;
  _DashedHLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;
    double x = 0;
    const dash = 4.0;
    const gap = 3.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset((x + dash).clamp(0, size.width), 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedHLinePainter old) => old.color != color;
}
