import 'package:flutter/material.dart';
import 'package:otraku/pages/pushable/media_item_page.dart';

class MediaIndexer extends StatelessWidget {
  final int mediaId;
  final Widget child;

  MediaIndexer({@required this.mediaId, @required this.child});

  static void pushMedia(BuildContext context, int mediaId, {Object tag}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => MediaItemPage(id: mediaId, tag: tag),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => MediaIndexer.pushMedia(context, mediaId, tag: mediaId),
      child: child,
    );
  }
}
