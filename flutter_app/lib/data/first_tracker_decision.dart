import '../models/legend_model.dart';
import '../models/page_model.dart';

/// The empty page a dormant account's first tracker should replace: the
/// first page (by position) with no legend. Cells need not be checked: the
/// flow only runs when the phone's full copy has no cell at all for the account.
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
/// [activated] is what the phone's full copy says (offline sync): `null`
/// means the phone has no full copy yet (first launch offline) and never
/// shows the flow.
/// [doneOnThisDevice] is the per-device, per-account flag set when the flow
/// was finished or skipped. The free limit is respected: at the limit, the
/// flow only runs if it can replace an empty page.
/// Whether a session's landing waits for its first sync: anyone the phone
/// already knows as active lands at once; so does an account just born on
/// this phone, whose empty copy already says « first tracker » (case 5) —
/// on a slow network, its creation may take a while (review, minor 9).
bool waitsForFirstSync({required bool hydrated, required bool? snapshotActivated, required bool newAccount}) =>
    !newAccount && (!hydrated || snapshotActivated != true);

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
