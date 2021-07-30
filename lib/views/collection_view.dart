import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ionicons/ionicons.dart';
import 'package:otraku/controllers/collection_controller.dart';
import 'package:otraku/widgets/bottom_drawer.dart';
import 'package:otraku/widgets/layouts/media_list.dart';
import 'package:otraku/widgets/navigation/action_button.dart';
import 'package:otraku/widgets/navigation/control_header.dart';
import 'package:otraku/widgets/navigation/nav_bar.dart';
import 'package:otraku/widgets/navigation/headline_header.dart';
import 'package:otraku/widgets/overlays/sheets.dart';

import '../utils/client.dart';

class CollectionView extends StatelessWidget {
  final int id;
  final bool ofAnime;
  final String ctrlTag;

  CollectionView({
    required this.id,
    required this.ofAnime,
    required this.ctrlTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: CollectionActionButton(ctrlTag),
      body: SafeArea(
        child: HomeCollectionView(
          id: id,
          ofAnime: ofAnime,
          collectionTag: ctrlTag,
          key: null,
        ),
      ),
    );
  }
}

class HomeCollectionView extends StatelessWidget {
  final int id;
  final bool ofAnime;
  final String collectionTag;

  HomeCollectionView({
    required this.id,
    required this.ofAnime,
    required this.collectionTag,
    required key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        controller:
            Get.find<CollectionController>(tag: collectionTag).scrollCtrl,
        slivers: [
          HeadlineHeader(
            '${ofAnime ? 'Anime' : 'Manga'} List',
            id != Client.viewerId,
          ),
          CollectionControlHeader(collectionTag),
          MediaList(collectionTag),
          SliverToBoxAdapter(
            child: SizedBox(height: NavBar.offset(context)),
          ),
        ],
      );
}

class CollectionActionButton extends StatelessWidget {
  final String collectionTag;
  const CollectionActionButton(this.collectionTag);

  @override
  Widget build(BuildContext context) {
    return ActionButton(
      tooltip: 'Lists',
      icon: Ionicons.menu_outline,
      scrollCtrl: Get.find<CollectionController>(tag: collectionTag).scrollCtrl,
      onTap: () => Sheet.show(
        ctx: context,
        sheet: CollectionBottomDrawer(context, collectionTag),
        barrierColour: Theme.of(context).primaryColor.withAlpha(150),
        isScrollControlled: true,
      ),
    );
  }
}
