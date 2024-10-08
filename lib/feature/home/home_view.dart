import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:otraku/extension/scroll_controller_extension.dart';
import 'package:otraku/feature/activity/activities_provider.dart';
import 'package:otraku/feature/activity/activities_view.dart';
import 'package:otraku/feature/activity/activity_model.dart';
import 'package:otraku/feature/collection/collection_entries_provider.dart';
import 'package:otraku/feature/collection/collection_floating_action.dart';
import 'package:otraku/feature/collection/collection_top_bar.dart';
import 'package:otraku/feature/discover/discover_filter_provider.dart';
import 'package:otraku/feature/discover/discover_floating_action.dart';
import 'package:otraku/feature/discover/discover_provider.dart';
import 'package:otraku/feature/discover/discover_top_bar.dart';
import 'package:otraku/feature/feed/feed_floating_action.dart';
import 'package:otraku/feature/feed/feed_top_bar.dart';
import 'package:otraku/feature/home/home_model.dart';
import 'package:otraku/feature/home/home_provider.dart';
import 'package:otraku/feature/settings/settings_provider.dart';
import 'package:otraku/feature/tag/tag_provider.dart';
import 'package:otraku/feature/user/user_providers.dart';
import 'package:otraku/feature/user/user_view.dart';
import 'package:otraku/util/paged_controller.dart';
import 'package:otraku/util/persistence.dart';
import 'package:otraku/feature/discover/discover_view.dart';
import 'package:otraku/feature/collection/collection_view.dart';
import 'package:otraku/util/routes.dart';
import 'package:otraku/widget/layout/adaptive_scaffold.dart';
import 'package:otraku/widget/layout/hiding_floating_action_button.dart';
import 'package:otraku/widget/layout/scroll_physics.dart';
import 'package:otraku/widget/layout/top_bar.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key, this.tab});

  final HomeTab? tab;

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView>
    with SingleTickerProviderStateMixin {
  final _id = Persistence().id!;
  late final _userTag = idUserTag(_id);
  late final _animeCollectionTag = (userId: _id, ofAnime: true);
  late final _mangaCollectionTag = (userId: _id, ofAnime: false);

  final _searchFocusNode = FocusNode();
  final _animeScrollCtrl = ScrollController();
  final _mangaScrollCtrl = ScrollController();
  late final _feedScrollCtrl = PagedController(
    loadMore: () => ref.read(activitiesProvider(homeFeedId).notifier).fetch(),
  );
  late final _discoverScrollCtrl = PagedController(
    loadMore: () => ref.read(discoverProvider.notifier).fetch(),
  );
  late final _tabCtrl = TabController(
    length: HomeTab.values.length,
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    _tabCtrl.index = Persistence().defaultHomeTab.index;
    if (widget.tab != null) _tabCtrl.index = widget.tab!.index;

    _tabCtrl.addListener(
      () => WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.go(Routes.home(HomeTab.values[_tabCtrl.index])),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant HomeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tab != null) _tabCtrl.index = widget.tab!.index;
  }

  @override
  void deactivate() {
    ref.invalidate(discoverProvider);
    ref.invalidate(discoverFilterProvider);
    ref.invalidate(activitiesProvider(homeFeedId));
    super.deactivate();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _animeScrollCtrl.dispose();
    _mangaScrollCtrl.dispose();
    _feedScrollCtrl.dispose();
    _discoverScrollCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(settingsProvider.select((_) => null));
    ref.watch(tagsProvider.select((_) => null));
    ref.watch(userProvider(_userTag).select((_) => null));

    if (_tabCtrl.index == HomeTab.feed.index) {
      ref.watch(activitiesProvider(homeFeedId).select((_) => null));
    } else if (_tabCtrl.index == HomeTab.discover.index) {
      ref.watch(discoverProvider.select((_) => null));
    }

    ref.watch(
        collectionEntriesProvider(_animeCollectionTag).select((_) => null));
    ref.watch(
        collectionEntriesProvider(_mangaCollectionTag).select((_) => null));

    final home = ref.watch(homeProvider);

    final primaryScrollCtrl = PrimaryScrollController.of(context);

    final topBar = TopBarAnimatedSwitcher(
      switch (_tabCtrl.index) {
        0 => const TopBar(
            key: Key('feedTopBar'),
            title: 'Feed',
            trailing: [
              FeedTopBarTrailingContent(),
            ],
          ),
        1 => TopBar(
            key: const Key('animeCollectionTopBar'),
            trailing: [
              CollectionTopBarTrailingContent(
                _animeCollectionTag,
                _searchFocusNode,
              ),
            ],
          ),
        2 => TopBar(
            key: const Key('mangaCollectionTopBar'),
            trailing: [
              CollectionTopBarTrailingContent(
                _mangaCollectionTag,
                _searchFocusNode,
              ),
            ],
          ),
        3 => TopBar(
            key: const Key('discoverTobBar'),
            trailing: [
              DiscoverTopBarTrailingContent(_searchFocusNode),
            ],
          ),
        _ => const EmptyTopBar() as PreferredSizeWidget,
      },
    );

    final navigationConfig = NavigationConfig(
      selected: _tabCtrl.index,
      onChanged: (i) => context.go(Routes.home(HomeTab.values[i])),
      items: {
        for (final tab in HomeTab.values) tab.label: _homeTabIconData(tab),
      },
      onSame: (i) {
        final tab = HomeTab.values[i];

        switch (tab) {
          case HomeTab.anime:
            if (_animeScrollCtrl.position.pixels > 0) {
              _animeScrollCtrl.scrollToTop();
            } else {
              _toggleSearchFocus();
            }
            return;
          case HomeTab.manga:
            if (_mangaScrollCtrl.position.pixels > 0) {
              _mangaScrollCtrl.scrollToTop();
            } else {
              _toggleSearchFocus();
            }
            return;
          case HomeTab.discover:
            if (_discoverScrollCtrl.position.pixels > 0) {
              _discoverScrollCtrl.scrollToTop();
            } else {
              _toggleSearchFocus();
            }
            return;
          case HomeTab.feed:
            _feedScrollCtrl.scrollToTop();
          case HomeTab.profile:
            primaryScrollCtrl.scrollToTop();
            return;
        }
      },
    );

    return AdaptiveScaffold(
      (context, compact) {
        final floatingAction = switch (_tabCtrl.index) {
          0 => HidingFloatingActionButton(
              key: const Key('feed'),
              scrollCtrl: _feedScrollCtrl,
              child: FeedFloatingAction(ref),
            ),
          1 => compact || !home.didExpandAnimeCollection
              ? HidingFloatingActionButton(
                  key: const Key('anime'),
                  scrollCtrl: _animeScrollCtrl,
                  child: CollectionFloatingAction(_animeCollectionTag),
                )
              : null,
          2 => compact || !home.didExpandMangaCollection
              ? HidingFloatingActionButton(
                  key: const Key('manga'),
                  scrollCtrl: _mangaScrollCtrl,
                  child: CollectionFloatingAction(_mangaCollectionTag),
                )
              : null,
          3 => compact
              ? HidingFloatingActionButton(
                  key: const Key('discover'),
                  scrollCtrl: _discoverScrollCtrl,
                  child: const DiscoverFloatingAction(),
                )
              : null,
          _ => null,
        };

        final child = TabBarView(
          controller: _tabCtrl,
          physics: const FastTabBarViewScrollPhysics(),
          children: [
            ActivitiesSubView(homeFeedId, _feedScrollCtrl),
            CollectionSubview(
              scrollCtrl: _animeScrollCtrl,
              tag: _animeCollectionTag,
              compact: compact,
              key: Key(true.toString()),
            ),
            CollectionSubview(
              scrollCtrl: _mangaScrollCtrl,
              tag: _mangaCollectionTag,
              compact: compact,
              key: Key(false.toString()),
            ),
            DiscoverSubview(_discoverScrollCtrl, compact),
            UserHomeView(
              _userTag,
              null,
              homeScrollCtrl: primaryScrollCtrl,
              removableTopPadding: topBar.preferredSize.height,
            ),
          ],
        );

        return switch (compact) {
          true => ScaffoldConfig(
              topBar: topBar,
              floatingAction: floatingAction,
              navigationConfig: navigationConfig,
              child: child,
            ),
          false => ScaffoldConfig(
              topBar: topBar,
              floatingAction: floatingAction,
              navigationConfig: navigationConfig,
              child: child,
            ),
        };
      },
    );
  }

  void _toggleSearchFocus() => _searchFocusNode.hasFocus
      ? _searchFocusNode.unfocus()
      : _searchFocusNode.requestFocus();

  IconData _homeTabIconData(HomeTab tab) => switch (tab) {
        HomeTab.feed => Ionicons.file_tray_outline,
        HomeTab.anime => Ionicons.film_outline,
        HomeTab.manga => Ionicons.book_outline,
        HomeTab.discover => Ionicons.compass_outline,
        HomeTab.profile => Ionicons.person_outline,
      };
}
