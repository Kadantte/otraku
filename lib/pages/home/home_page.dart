import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:otraku/controllers/collection_controller.dart';
import 'package:otraku/pages/home/explore_page.dart';
import 'package:otraku/pages/home/collection_page.dart';
import 'package:otraku/pages/home/feed_page.dart';
import 'package:otraku/pages/home/user_page.dart';
import 'package:otraku/utils/background_handler.dart';
import 'package:otraku/utils/client.dart';
import 'package:otraku/utils/config.dart';
import 'package:otraku/widgets/navigation/custom_drawer.dart';
import 'package:otraku/widgets/navigation/nav_bar.dart';
import 'package:otraku/widgets/overlays/dialogs.dart';

class HomePage extends StatelessWidget {
  static const ROUTE = '/home';

  static const FEED = 0;
  static const ANIME_LIST = 1;
  static const MANGA_LIST = 2;
  static const EXPLORE = 3;
  static const PROFILE = 4;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const FeedTab(),
      CollectionTab(
        ofAnime: true,
        id: Client.viewerId!,
        collectionTag: CollectionController.ANIME,
        key: UniqueKey(),
      ),
      CollectionTab(
        ofAnime: false,
        id: Client.viewerId!,
        collectionTag: CollectionController.MANGA,
        key: UniqueKey(),
      ),
      const ExploreTab(),
      UserTab(Client.viewerId!, null),
    ];

    const drawers = [
      null,
      const CollectionDrawer(CollectionController.ANIME),
      const CollectionDrawer(CollectionController.MANGA),
      const ExploreDrawer(),
      null,
    ];

    BackgroundHandler.checkLaunchedByNotification(context);

    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: ValueListenableBuilder<int>(
        valueListenable: Config.index,
        builder: (_, index, __) => Scaffold(
          extendBody: true,
          drawerScrimColor: Theme.of(context).primaryColor.withAlpha(150),
          bottomNavigationBar: NavBar(
            options: {
              'Feed': Ionicons.file_tray_outline,
              'Anime': Ionicons.film_outline,
              'Manga': Ionicons.bookmark_outline,
              'Explore': Ionicons.compass_outline,
              'Profile': Ionicons.person_outline,
            },
            onChanged: (page) => Config.setIndex(page),
            initial: index,
          ),
          drawer: drawers[index],
          body: SafeArea(
            bottom: false,
            child: AnimatedSwitcher(
              duration: Config.TAB_SWITCH_DURATION,
              child: tabs[index],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _onWillPop(BuildContext ctx) async {
    bool ok = false;

    await showPopUp(
      ctx,
      ConfirmationDialog(
        title: 'Exit?',
        mainAction: 'Yes',
        secondaryAction: 'Never',
        onConfirm: () => ok = true,
      ),
    );

    return ok;
  }
}
