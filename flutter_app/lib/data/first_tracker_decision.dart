import '../models/legend_model.dart';
import '../models/page_model.dart';

/// The empty page a dormant account's first tracker should replace: the
/// first page (by position) with no legend. Cells need not be checked: the
/// flow only runs when the server reports no cell at all for the account.
String? replaceablePageId(
  List<PageModel> pages,
  List<LegendModel> Function(String pageId) legendsFor,
) {
  final sorted = [...pages]..sort((a, b) => a.position.compareTo(b.position));
  for (final p in sorted) {
    if (legendsFor(p.id).isEmpty) return p.id;
  }
  return null;
}

/// Whether to show the first-tracker flow instead of the usual landing.
///
/// [activated] is the server's answer for this session: `null` means no
/// answer (offline, or a backend older than 1.2.0) and never shows the flow.
/// [doneOnThisDevice] is the per-device, per-account flag set when the flow
/// was finished or skipped. The free limit is respected: at the limit, the
/// flow only runs if it can replace an empty page.
bool shouldShowFirstTracker({
  required bool? activated,
  required bool doneOnThisDevice,
  required int pageCount,
  required int maxTrackers,
  required bool hasReplaceablePage,
}) {
  if (activated != false) return false;
  if (doneOnThisDevice) return false;
  return pageCount < maxTrackers || hasReplaceablePage;
}
