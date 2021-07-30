import 'package:flutter/material.dart';
import 'package:otraku/widgets/navigation/app_bars.dart';

class FavouriteButton extends StatefulWidget {
  final int favourites;
  final bool isFavourite;
  final double shrinkPercentage;
  final Future<bool> Function() onTap;

  FavouriteButton({
    required this.favourites,
    required this.isFavourite,
    required this.shrinkPercentage,
    required this.onTap,
  });

  @override
  _FavouriteButtonState createState() => _FavouriteButtonState();
}

class _FavouriteButtonState extends State<FavouriteButton> {
  late bool _isFavourite;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.shrinkPercentage < 0.5) ...[
          Opacity(
            opacity: 1 - widget.shrinkPercentage * 2,
            child: Text(widget.favourites.toString()),
          ),
        ],
        AppBarIcon(
          tooltip: _isFavourite ? 'UnFavourite' : 'Favourite',
          icon: _isFavourite ? Icons.favorite : Icons.favorite_border,
          onTap: () =>
              widget.onTap().then((val) => setState(() => _isFavourite = val)),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _isFavourite = widget.isFavourite;
  }
}
