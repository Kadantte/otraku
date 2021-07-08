import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ionicons/ionicons.dart';
import 'package:otraku/controllers/media_controller.dart';
import 'package:otraku/utils/config.dart';
import 'package:otraku/pages/media/overview_tab.dart';
import 'package:otraku/pages/media/relations_tab.dart';
import 'package:otraku/pages/media/social_tab.dart';
import 'package:otraku/widgets/navigation/nav_bar.dart';
import 'package:otraku/pages/media/media_header.dart';

class MediaPage extends StatelessWidget {
  static const ROUTE = '/media';

  final int id;
  final String? coverUrl;

  MediaPage(this.id, this.coverUrl);

  @override
  Widget build(BuildContext context) {
    final placeHolder = const SliverToBoxAdapter(child: SizedBox());
    final coverWidth = MediaQuery.of(context).size.width < 430.0
        ? MediaQuery.of(context).size.width * 0.35
        : 150.0;
    final coverHeight = coverWidth / 0.7;
    final bannerHeight =
        coverHeight * 0.6 + Config.MATERIAL_TAP_TARGET_SIZE + 10;
    final headerHeight = bannerHeight + coverHeight * 0.6;
    final pageTop = headerHeight - Config.MATERIAL_TAP_TARGET_SIZE;

    return GetBuilder<MediaController>(
      tag: id.toString(),
      builder: (media) => Scaffold(
        extendBody: true,
        bottomNavigationBar: NavBar(
          options: {
            'Overview': Ionicons.book_outline,
            'Relations': Icons.emoji_people_outlined,
            'Social': Icons.rate_review_outlined,
          },
          initial: media.tab,
          onChanged: (index) => media.tab = index,
        ),
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: Config.PHYSICS,
            controller: media.scrollCtrl,
            slivers: [
              MediaHeader(
                media: media,
                imageUrl: coverUrl,
                coverWidth: coverWidth,
                coverHeight: coverHeight,
                bannerHeight: bannerHeight,
                height: headerHeight,
              ),
              if (media.model != null) ...[
                Obx(
                  () => media.tab == MediaController.RELATIONS
                      ? RelationControls(media, () => media.scrollTo(pageTop))
                      : placeHolder,
                ),
                Obx(() {
                  if (media.tab == MediaController.OVERVIEW)
                    return OverviewTab(media.model!.overview);
                  else if (media.tab == MediaController.RELATIONS)
                    return RelationsTab(media);
                  else
                    return SocialTab(media);
                }),
              ],
              SliverToBoxAdapter(
                child: SizedBox(height: NavBar.offset(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
