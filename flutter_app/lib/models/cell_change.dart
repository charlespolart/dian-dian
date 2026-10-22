/// The last cell this device changed, for the grid's pop. Never a change
/// from another device, a bootstrap or a recolor.
class CellChange {
  final String pageId;
  final int year;
  final int month;
  final int day;
  /// The new colour; on an erase, the colour that was there.
  final String? color;
  final bool erased;
  /// Grows at every change, so two taps on the same cell are two pops.
  final int seq;

  const CellChange({
    required this.pageId,
    required this.year,
    required this.month,
    required this.day,
    required this.color,
    required this.erased,
    required this.seq,
  });
}
