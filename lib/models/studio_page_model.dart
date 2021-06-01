import 'package:otraku/models/explorable_model.dart';

class StudioPageModel {
  final categories = <String>[];
  final groups = <List<ExplorableModel>>[];
  bool _hasNextPage = true;
  int _nextPage = 1;

  bool get hasNextPage => _hasNextPage;

  int get nextPage => _nextPage;

  int get mediaCount {
    int count = 0;
    for (final group in groups) count += group.length;
    return count;
  }

  List<ExplorableModel> get joined {
    final all = <ExplorableModel>[];
    for (final group in groups) all.addAll(group);
    return all;
  }

  void append(
    List<String> moreCategories,
    List<List<ExplorableModel>> moreMedia,
    bool hasNext,
  ) {
    if (categories.isNotEmpty && categories.last == moreCategories.first) {
      moreCategories.removeAt(0);
      groups.last.addAll(moreMedia.removeAt(0));
    }

    categories.addAll(moreCategories);
    groups.addAll(moreMedia);

    _nextPage++;
    _hasNextPage = hasNext;
  }

  void clear() {
    categories.clear();
    groups.clear();
    _hasNextPage = true;
    _nextPage = 1;
  }
}
