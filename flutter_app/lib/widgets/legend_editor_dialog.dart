import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cells_provider.dart';
import '../providers/language_provider.dart';
import '../providers/legends_provider.dart';
import '../theme/app_theme.dart';
import 'app_dialog.dart';
import 'marquee_text.dart';
import 'confirm_dialog.dart';

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
  final _scrollController = ScrollController();
  String _selectedColor = AppTheme.defaultPalette[0][0];
  // Track selection by position: "row,col" (e.g. "0,3" or "custom,2")
  String _selectedPos = '0,0';
  List<dynamic> _legends = [];
  int? _draggingIndex;
  // When non-null, we're picking a color for this legend index
  int? _recolorIndex;
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

  @override
  void dispose() {
    _labelController.dispose();
    _scrollController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageProvider>();
    final legends = _legends;

    return AppDialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Opacity(
              opacity: _recolorIndex != null ? 0.3 : 1.0,
              child: Text(
                lang.t('tracker.legend'),
                style: AppFonts.pixel(fontSize: 16, color: AppColors.title),
              ),
            ),
            const SizedBox(height: 16),

            // Existing legends (tiles handle their own dimming)
            if (legends.isEmpty)
              Opacity(
                opacity: _recolorIndex != null ? 0.3 : 1.0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    lang.t('tracker.noLegends'),
                    style:
                        AppFonts.dot(fontSize: 13, color: AppColors.textMuted),
                  ),
                ),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: List.generate(legends.length, (i) {
                      return _DraggableLegendTile(
                        index: i,
                        legend: legends[i],
                        isDragging: _draggingIndex == i,
                        dimmed: _recolorIndex != null && _recolorIndex != i,
                        highlighted: _recolorIndex == i,
                        parseHex: _parseHex,
                        onDragStarted: () => setState(() => _draggingIndex = i),
                        onDragEnd: () => setState(() => _draggingIndex = null),
                        onAccept: (fromIndex) => _onReorder(fromIndex, i),
                        onColorTap: () => setState(() {
                          _recolorIndex = _recolorIndex == i ? null : i;
                        }),
                        onEditLabel: (newLabel) async {
                          await _prov.updateLegend(legends[i].id, label: newLabel);
                          _refresh();
                        },
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
                ),
              ),

            const SizedBox(height: 16),
            Opacity(
              opacity: _recolorIndex != null ? 0.3 : 1.0,
              child: CustomPaint(
                size: const Size(double.infinity, 1),
                painter: _DashedHLinePainter(color: AppColors.sectionBorder),
              ),
            ),
            const SizedBox(height: 16),

            // Recolor hint
            if (_recolorIndex != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  lang.t('tracker.pickColor'),
                  style: AppFonts.pixel(fontSize: 10, color: AppColors.accent),
                ),
              ),

            // Color palette picker
            _buildPalettePicker(),

            const SizedBox(height: 12),

            // Add new legend (max 12)
            if (legends.length < 12 && _recolorIndex == null)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _labelController,
                      maxLength: 30,
                      style: AppFonts.dot(
                        fontSize: 13,
                        color: AppColors.inputText,
                      ),
                      decoration: InputDecoration(
                        hintText: lang.t('tracker.legendPlaceholder'),
                        counterText: '',
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
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients) {
                          _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                          );
                        }
                      });
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
                          fontSize: 11,
                          color: AppColors.btnAddText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Close / Cancel button
            GestureDetector(
              onTap: () {
                if (_recolorIndex != null) {
                  setState(() => _recolorIndex = null);
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: Opacity(
                opacity: _recolorIndex != null ? 0.5 : 1.0,
                child: Text(
                  _recolorIndex != null
                      ? lang.t('common.cancel')
                      : lang.t('settings.back'),
                  style: AppFonts.pixel(
                    fontSize: 12,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPaletteColorTap(String hex, String pos) async {
    if (_recolorIndex != null) {
      // Apply color to the legend and recolor matching cells
      final legend = _legends[_recolorIndex!];
      final oldColor = legend.color as String;
      setState(() {
        _recolorIndex = null;
      });
      await _prov.updateLegend(legend.id, color: hex);
      if (oldColor != hex) {
        await context.read<CellsProvider>().recolorCells({oldColor: hex});
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
    final isSelected = _selectedPos == pos && _recolorIndex == null;
    return GestureDetector(
      onTap: () => _onPaletteColorTap(hex, pos),
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _parseHex(hex),
          border: isSelected
              ? Border.all(color: AppColors.accent, width: 2.5)
              : Border.all(color: AppColors.dotBorder, width: 0.5),
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
                    'Cancel',
                    style: AppFonts.pixel(fontSize: 11, color: AppColors.textMuted),
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
                      'OK',
                      style: AppFonts.pixel(fontSize: 11, color: AppColors.btnAddText),
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
class _DraggableLegendTile extends StatefulWidget {
  final int index;
  final dynamic legend;
  final bool isDragging;
  final bool dimmed;
  final bool highlighted;
  final Color Function(String) parseHex;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnd;
  final void Function(int fromIndex) onAccept;
  final VoidCallback onColorTap;
  final void Function(String newLabel) onEditLabel;
  final VoidCallback onDelete;

  const _DraggableLegendTile({
    required this.index,
    required this.legend,
    required this.isDragging,
    this.dimmed = false,
    this.highlighted = false,
    required this.parseHex,
    required this.onDragStarted,
    required this.onDragEnd,
    required this.onAccept,
    required this.onColorTap,
    required this.onEditLabel,
    required this.onDelete,
  });

  @override
  State<_DraggableLegendTile> createState() => _DraggableLegendTileState();
}

class _DraggableLegendTileState extends State<_DraggableLegendTile> {
  bool _editing = false;
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.legend.label);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _editing) {
        _submitEdit();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _DraggableLegendTile old) {
    super.didUpdateWidget(old);
    if (old.legend.label != widget.legend.label && !_editing) {
      _controller.text = widget.legend.label;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _submitEdit() {
    final newLabel = _controller.text.trim();
    if (newLabel.isNotEmpty && newLabel != widget.legend.label) {
      widget.onEditLabel(newLabel);
    }
    setState(() => _editing = false);
  }

  Widget _buildContent({bool ghost = false}) {
    final dimmed = widget.dimmed && !ghost;
    final highlighted = widget.highlighted && !ghost;
    return Opacity(
      opacity: dimmed ? 0.3 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: ghost ? AppColors.dotEmpty : AppColors.inputBg,
          border: Border.all(
            color: highlighted
                ? AppColors.accent
                : ghost ? AppColors.dotBorder : AppColors.inputBorder,
            width: highlighted ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Opacity(
          opacity: ghost ? 0.3 : 1.0,
          child: Row(
            children: [
              Icon(Icons.drag_handle, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: ghost ? null : widget.onColorTap,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                color: widget.parseHex(widget.legend.color),
              ),
            ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _editing && !ghost
                  ? TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: true,
                      maxLength: 30,
                      style: AppFonts.dot(fontSize: 13, color: AppColors.text),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        counterText: '',
                      ),
                      onSubmitted: (_) => _submitEdit(),
                    )
                  : GestureDetector(
                      onTap: ghost ? null : () => setState(() => _editing = true),
                      child: MarqueeText(
                        text: widget.legend.label,
                        style: AppFonts.dot(fontSize: 13, color: AppColors.text),
                      ),
                    ),
            ),
            if (!ghost)
              GestureDetector(
                onTap: widget.onDelete,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: AppColors.btnResetText,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != widget.index,
      onAcceptWithDetails: (details) => widget.onAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        final isOver = candidateData.isNotEmpty;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOver)
              Container(
                height: 2,
                color: AppColors.accent,
                margin: const EdgeInsets.only(bottom: 2),
              ),
            LongPressDraggable<int>(
              data: widget.index,
              onDragStarted: widget.onDragStarted,
              onDragEnd: (_) => widget.onDragEnd(),
              feedback: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: _buildContent(),
                ),
              ),
              childWhenDragging: _buildContent(ghost: true),
              child: _buildContent(),
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
