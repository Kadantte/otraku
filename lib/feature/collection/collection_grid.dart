import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:otraku/feature/collection/collection_models.dart';
import 'package:otraku/feature/edit/edit_view.dart';
import 'package:otraku/feature/media/media_route_tile.dart';
import 'package:otraku/util/theming.dart';
import 'package:otraku/extension/snack_bar_extension.dart';
import 'package:otraku/widget/cached_image.dart';
import 'package:otraku/util/debounce.dart';
import 'package:otraku/widget/grid/sliver_grid_delegates.dart';
import 'package:otraku/widget/sheets.dart';

class CollectionGrid extends StatelessWidget {
  const CollectionGrid({required this.items, required this.onProgressUpdated});

  final List<Entry> items;
  final Future<String?> Function(Entry)? onProgressUpdated;

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithMinWidthAndExtraHeight(
        minWidth: 100,
        extraHeight: 70,
        rawHWRatio: Theming.coverHtoWRatio,
      ),
      delegate: SliverChildBuilderDelegate(
        childCount: items.length,
        (context, i) => Card(
          child: MediaRouteTile(
            id: items[i].mediaId,
            imageUrl: items[i].imageUrl,
            child: Column(
              children: [
                Expanded(
                  child: Hero(
                    tag: items[i].mediaId,
                    child: ClipRRect(
                      borderRadius: Theming.borderRadiusSmall,
                      child: Container(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        child: CachedImage(items[i].imageUrl),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 5, right: 5, top: 5),
                  child: SizedBox(
                    height: 35,
                    child: Text(
                      items[i].titles[0],
                      overflow: TextOverflow.fade,
                      maxLines: 2,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
                _IncrementButton(items[i], onProgressUpdated),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IncrementButton extends StatefulWidget {
  const _IncrementButton(this.item, this.onProgressUpdated);

  final Entry item;
  final Future<String?> Function(Entry)? onProgressUpdated;

  @override
  State<_IncrementButton> createState() => _IncrementButtonState();
}

class _IncrementButtonState extends State<_IncrementButton> {
  final _debounce = Debounce();
  int? _lastProgress;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    if (item.progress == item.progressMax) {
      return Tooltip(
        message: 'Progress',
        child: SizedBox(
          height: 30,
          child: Center(
            child: Text(
              item.progress.toString(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ),
      );
    }

    final overridenTextColor =
        item.nextEpisode != null && item.progress + 1 < item.nextEpisode!
            ? Theme.of(context).colorScheme.error
            : null;

    if (widget.onProgressUpdated == null) {
      return Tooltip(
        message: 'Progress',
        child: SizedBox(
          height: 30,
          child: Center(
            child: Text(
              '${item.progress}/${item.progressMax ?? "?"}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: overridenTextColor,
                  ),
            ),
          ),
        ),
      );
    }

    return TextButton(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 30),
        padding: const EdgeInsets.symmetric(horizontal: 5),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: overridenTextColor,
      ),
      onPressed: () {
        if (item.progressMax != null &&
            item.progress >= item.progressMax! - 1) {
          _debounce.cancel();
          _resetProgress();

          showSheet(context, EditView((id: item.mediaId, setComplete: true)));
          return;
        }

        _debounce.cancel();
        _lastProgress ??= item.progress;
        setState(() => item.progress++);

        _debounce.run(() async {
          final err = await widget.onProgressUpdated!(item);
          if (err == null) {
            _lastProgress = null;
            return;
          }

          _resetProgress();
          if (context.mounted) {
            SnackBarExtension.show(context, 'Failed updating progress: $err');
          }
        });
      },
      child: Tooltip(
        message: 'Increment Progress',
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${item.progress}/${item.progressMax ?? "?"}',
              style: const TextStyle(fontSize: Theming.fontSmall),
            ),
            const SizedBox(width: 3),
            const Icon(Ionicons.add_outline, size: Theming.iconSmall),
          ],
        ),
      ),
    );
  }

  void _resetProgress() {
    if (_lastProgress == null) return;

    setState(() => widget.item.progress = _lastProgress!);
    _lastProgress = null;
  }
}