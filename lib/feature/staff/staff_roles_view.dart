import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otraku/model/relation.dart';
import 'package:otraku/widget/grids/relation_grid.dart';
import 'package:otraku/widget/paged_view.dart';
import 'package:otraku/feature/staff/staff_provider.dart';

class StaffRolesSubview extends StatelessWidget {
  const StaffRolesSubview({
    required this.id,
    required this.scrollCtrl,
  });

  final int id;
  final ScrollController scrollCtrl;

  @override
  Widget build(BuildContext context) {
    return PagedView<Relation>(
      scrollCtrl: scrollCtrl,
      onRefresh: (invalidate) => invalidate(staffRelationsProvider(id)),
      provider: staffRelationsProvider(id).select(
        (s) => s.unwrapPrevious().whenData((data) => data.roles),
      ),
      onData: (data) => SingleRelationGrid(data.items),
    );
  }
}
