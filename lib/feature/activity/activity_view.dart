import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:otraku/util/routes.dart';
import 'package:otraku/util/theming.dart';
import 'package:otraku/extension/snack_bar_extension.dart';
import 'package:otraku/widget/layout/adaptive_scaffold.dart';
import 'package:otraku/widget/layout/constrained_view.dart';
import 'package:otraku/feature/activity/activities_provider.dart';
import 'package:otraku/feature/activity/activity_model.dart';
import 'package:otraku/feature/activity/activity_provider.dart';
import 'package:otraku/feature/activity/activity_card.dart';
import 'package:otraku/feature/activity/reply_card.dart';
import 'package:otraku/feature/composition/composition_model.dart';
import 'package:otraku/feature/composition/composition_view.dart';
import 'package:otraku/util/paged_controller.dart';
import 'package:otraku/util/persistence.dart';
import 'package:otraku/widget/layout/hiding_floating_action_button.dart';
import 'package:otraku/widget/layout/top_bar.dart';
import 'package:otraku/widget/cached_image.dart';
import 'package:otraku/widget/loaders.dart';
import 'package:otraku/widget/sheets.dart';

class ActivityView extends ConsumerStatefulWidget {
  const ActivityView(this.id, this.feedId);

  final int id;
  final int? feedId;

  @override
  ConsumerState<ActivityView> createState() => _ActivityViewState();
}

class _ActivityViewState extends ConsumerState<ActivityView> {
  late final _ctrl = PagedController(
    loadMore: () => ref.read(activityProvider(widget.id).notifier).fetch(),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activity = ref.watch(
      activityProvider(widget.id).select((s) => s.valueOrNull?.activity),
    );

    return AdaptiveScaffold(
      (context, compact) => ScaffoldConfig(
        topBar: TopBar(
          trailing: [if (activity != null) _TopBarContent(activity)],
        ),
        floatingAction: HidingFloatingActionButton(
          key: const Key('Reply'),
          scrollCtrl: _ctrl,
          child: FloatingActionButton(
            tooltip: 'New Reply',
            child: const Icon(Icons.edit_outlined),
            onPressed: () => showSheet(
              context,
              CompositionView(
                tag: ActivityReplyCompositionTag(
                  id: null,
                  activityId: widget.id,
                ),
                onSaved: (map) => ref
                    .read(activityProvider(widget.id).notifier)
                    .appendReply(map),
              ),
            ),
          ),
        ),
        child: Consumer(
          child: SliverRefreshControl(
            onRefresh: () => ref.invalidate(activityProvider(widget.id)),
          ),
          builder: (context, ref, refreshControl) {
            ref.listen<AsyncValue>(
              activityProvider(widget.id),
              (_, s) => s.whenOrNull(
                error: (error, _) =>
                    SnackBarExtension.show(context, error.toString()),
              ),
            );

            return ref.watch(activityProvider(widget.id)).unwrapPrevious().when(
                  loading: () => const Center(child: Loader()),
                  error: (_, __) => const Center(
                    child: Text('Failed to load activity'),
                  ),
                  data: (data) {
                    return ConstrainedView(
                      child: CustomScrollView(
                        physics: Theming.bouncyPhysics,
                        controller: _ctrl,
                        slivers: [
                          refreshControl!,
                          SliverToBoxAdapter(
                            child: ActivityCard(
                              withHeader: false,
                              activity: data.activity,
                              footer: ActivityFooter(
                                activity: data.activity,
                                toggleLike: () => _toggleLike(data.activity),
                                toggleSubscription: () =>
                                    _toggleSubscription(data.activity),
                                togglePin: () => _togglePin(data.activity),
                                remove: () => _remove(data.activity),
                                onEdited: _onEdited,
                                openReplies: null,
                              ),
                            ),
                          ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              childCount: data.replies.items.length,
                              (context, i) => ReplyCard(
                                activityId: widget.id,
                                reply: data.replies.items[i],
                                toggleLike: () => ref
                                    .read(activityProvider(widget.id).notifier)
                                    .toggleReplyLike(data.replies.items[i].id),
                              ),
                            ),
                          ),
                          SliverFooter(loading: data.replies.hasNext),
                        ],
                      ),
                    );
                  },
                );
          },
        ),
      ),
    );
  }

  Future<Object?> _toggleLike(Activity activity) {
    if (widget.feedId != null) {
      return ref
          .read(activitiesProvider(widget.feedId!).notifier)
          .toggleLike(activity);
    }

    return ref.read(activityProvider(widget.id).notifier).toggleLike();
  }

  Future<Object?> _toggleSubscription(Activity activity) {
    if (widget.feedId != null) {
      return ref
          .read(activitiesProvider(widget.feedId!).notifier)
          .toggleSubscription(activity);
    }

    return ref.read(activityProvider(widget.id).notifier).toggleSubscription();
  }

  Future<Object?> _togglePin(Activity activity) {
    if (widget.feedId != null) {
      return ref
          .read(activitiesProvider(widget.feedId!).notifier)
          .togglePin(activity);
    }

    return ref.read(activityProvider(widget.id).notifier).togglePin();
  }

  Future<Object?> _remove(Activity activity) {
    Navigator.pop(context);

    if (widget.feedId != null) {
      return ref
          .read(activitiesProvider(widget.feedId!).notifier)
          .remove(activity);
    }

    return ref.read(activityProvider(widget.id).notifier).remove();
  }

  void _onEdited(Map<String, dynamic> map) {
    final activity = Activity.maybe(
      map,
      Persistence().id!,
      Persistence().imageQuality,
    );

    if (activity == null) return;

    ref.read(activityProvider(widget.id).notifier).replace(activity);
    if (widget.feedId != null) {
      ref.read(activitiesProvider(widget.feedId!).notifier).replace(activity);
    }
  }
}

class _TopBarContent extends StatelessWidget {
  const _TopBarContent(this.activity);

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Flexible(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => context.push(
                Routes.user(activity.authorId, activity.authorAvatarUrl),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Hero(
                    tag: activity.authorId,
                    child: ClipRRect(
                      borderRadius: Theming.borderRadiusSmall,
                      child: CachedImage(
                        activity.authorAvatarUrl,
                        height: 40,
                        width: 40,
                      ),
                    ),
                  ),
                  const SizedBox(width: Theming.offset),
                  Flexible(
                    child: Text(
                      activity.authorName,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ...switch (activity) {
            MessageActivity message => [
                if (message.isPrivate)
                  const Padding(
                    padding: EdgeInsets.only(left: Theming.offset),
                    child: Icon(Ionicons.eye_off_outline),
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: Theming.offset),
                  child: Icon(Icons.arrow_right_alt),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.push(
                    Routes.user(
                      message.recipientId,
                      message.recipientAvatarUrl,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: Theming.borderRadiusSmall,
                    child: CachedImage(
                      message.recipientAvatarUrl,
                      height: 40,
                      width: 40,
                    ),
                  ),
                ),
              ],
            _ when activity.isPinned => const [
                Padding(
                  padding: EdgeInsets.only(left: Theming.offset),
                  child: Icon(Icons.push_pin_outlined),
                ),
              ],
            _ => const [],
          },
        ],
      ),
    );
  }
}
