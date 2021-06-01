import 'package:get/get.dart';
import 'package:otraku/enums/list_sort.dart';
import 'package:otraku/enums/list_status.dart';
import 'package:otraku/enums/score_format.dart';
import 'package:otraku/utils/convert.dart';
import 'package:otraku/models/collection_list_model.dart';
import 'package:otraku/models/entry_model.dart';
import 'package:otraku/models/list_entry_model.dart';
import 'package:otraku/utils/filterable.dart';
import 'package:otraku/utils/client.dart';
import 'package:otraku/utils/scroll_x_controller.dart';

class Collection extends ScrollxController implements Filterable {
  // ***************************************************************************
  // CONSTANTS
  // ***************************************************************************

  static const _collectionQuery = r'''
    query Collection($userId: Int, $type: MediaType) {
      MediaListCollection(userId: $userId, type: $type) {
        lists {
          name
          isCustomList
          isSplitCompletedList
          status
          entries {
            mediaId
            status
            score
            progress
            progressVolumes
            repeat
            notes
            startedAt {year month day}
            completedAt {year month day}
            updatedAt
            createdAt
            media {
              title {userPreferred}
              format
              status(version: 2)
              startDate {year month day}
              endDate {year month day}
              episodes
              chapters
              volumes
              coverImage {large}
              nextAiringEpisode {timeUntilAiring episode}
              genres
            }
          }
        }
        user {
          mediaListOptions {
            rowOrder
            scoreFormat
            animeList {sectionOrder customLists splitCompletedSectionByFormat}
            mangaList {sectionOrder customLists splitCompletedSectionByFormat}
          }
        }
      }
    }
  ''';

  static const _updateEntryMutation = r'''
    mutation UpdateEntry($mediaId: Int, $status: MediaListStatus,
        $score: Float, $progress: Int, $progressVolumes: Int, $repeat: Int,
        $private: Boolean, $notes: String, $hiddenFromStatusLists: Boolean,
        $customLists: [String], $startedAt: FuzzyDateInput, $completedAt: FuzzyDateInput,
        $advancedScores: [Float]) {
      SaveMediaListEntry(mediaId: $mediaId, status: $status,
        score: $score, progress: $progress, progressVolumes: $progressVolumes,
        repeat: $repeat, private: $private, notes: $notes,
        hiddenFromStatusLists: $hiddenFromStatusLists, customLists: $customLists,
        startedAt: $startedAt, completedAt: $completedAt, advancedScores: $advancedScores) {
          mediaId
          status
          score
          progress
          progressVolumes
          repeat
          notes
          startedAt {year month day}
          completedAt {year month day}
          updatedAt
          createdAt
          media {
            title {userPreferred}
            format
            status(version: 2)
            startDate {year month day}
            endDate {year month day}
            episodes
            chapters
            volumes
            coverImage {large}
            nextAiringEpisode {timeUntilAiring episode}
            genres
          }
        }
    }
  ''';

  static const _updateProgressMutation = r'''
    mutation UpdateProgress($mediaId: Int, $progress: Int) {
      SaveMediaListEntry(mediaId: $mediaId, progress: $progress) {progress}
    }
  ''';

  static const _removeEntryMutation = r'''
    mutation RemoveEntry($entryId: Int) {DeleteMediaListEntry(id: $entryId) {deleted}}
  ''';

  static const ANIME = 'anime';
  static const MANGA = 'manga';

  // ***************************************************************************
  // DATA
  // ***************************************************************************

  final int userId;
  final bool ofAnime;
  final _lists = <CollectionListModel>[];
  final _entries = <ListEntryModel>[].obs;
  final _listIndex = 0.obs;
  final _filters = <String, dynamic>{};
  final _isLoading = false.obs;
  final _customListNames = <String>[];
  ScoreFormat? _scoreFormat;

  Collection(this.userId, this.ofAnime);

  // ***************************************************************************
  // GETTERS & SETTERS
  // ***************************************************************************

  @override
  bool get hasNextPage => false;
  bool get isLoading => _isLoading();
  int get listIndex => _listIndex();
  ScoreFormat? get scoreFormat => _scoreFormat;
  List<String> get customListNames => [..._customListNames];
  List<ListEntryModel> get entries => _entries();
  String get currentName => _lists[_listIndex()].name;
  ListStatus? get listStatus => _lists[_listIndex()].status;
  int get currentCount => _lists[_listIndex()].entries.length;
  bool get isEmpty => _entries.isEmpty;
  bool get isFullyEmpty => _lists.isEmpty;

  set listIndex(int value) {
    if (value < 0 || value >= _lists.length || value == _listIndex()) return;
    _listIndex.value = value;
    scrollTo(0);
    update();
    filter();
  }

  void sort() {
    for (final list in _lists) list.sort(_filters[Filterable.SORT]);
    scrollTo(0);
    filter();
  }

  int get totalEntryCount {
    int c = 0;
    for (final list in _lists)
      if (list.status != null) c += list.entries.length;
    return c;
  }

  List<String> get names {
    final n = <String>[];
    for (final list in _lists) n.add(list.name);
    return n;
  }

  List<int> get allEntryCounts {
    final c = <int>[];
    for (final list in _lists) c.add(list.entries.length);
    return c;
  }

  // ***************************************************************************
  // FETCHING
  // ***************************************************************************

  Future<void> fetch() async {
    _isLoading.value = true;
    Map<String, dynamic>? data = await Client.request(
      _collectionQuery,
      {
        'userId': userId,
        'type': ofAnime ? 'ANIME' : 'MANGA',
      },
      popOnErr: userId != Client.viewerId,
    );

    if (data == null) {
      _isLoading.value = false;
      return null;
    }

    data = data['MediaListCollection'];

    final metaData = ofAnime
        ? data!['user']['mediaListOptions']['animeList']
        : data!['user']['mediaListOptions']['mangaList'];
    final bool splitCompleted =
        metaData['splitCompletedSectionByFormat'] ?? false;

    _scoreFormat = Convert.strToEnum(
          data['user']['mediaListOptions']['scoreFormat'],
          ScoreFormat.values,
        ) ??
        ScoreFormat.POINT_10_DECIMAL;

    _filters[Filterable.SORT] = ListSortHelper.getEnum(
      data['user']['mediaListOptions']['rowOrder'],
    );

    _customListNames.clear();
    _customListNames.addAll(List.from(metaData['customLists']));

    _lists.clear();
    for (final String section in metaData['sectionOrder']) {
      final index = (data['lists'] as List<dynamic>)
          .indexWhere((listData) => listData['name'] == section);

      if (index == -1) continue;

      final l = (data['lists'] as List<dynamic>).removeAt(index);

      _lists.add(CollectionListModel(l, splitCompleted)
        ..sort(_filters[Filterable.SORT]));
    }

    for (final l in data['lists'])
      _lists.add(CollectionListModel(l, splitCompleted)
        ..sort(_filters[Filterable.SORT]));

    _listIndex.value = 0;
    update();
    filter();
    _isLoading.value = false;
  }

  @override
  Future<void> fetchPage() async {}

  Future<void> updateEntry(EntryModel oldEntry, EntryModel newEntry) async {
    // Update database item
    final oldCustomLists = oldEntry.customLists.entries
        .where((e) => e.value)
        .map((e) => e.key.toLowerCase())
        .toList();
    final newCustomLists = newEntry.customLists.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    final data = await Client.request(_updateEntryMutation, newEntry.toMap());
    if (data == null) return;

    final entry = ListEntryModel(data['SaveMediaListEntry']);

    for (int i = 0; i < newCustomLists.length; i++)
      newCustomLists[i] = newCustomLists[i].toLowerCase();

    // Remove from old status list
    if (!oldEntry.hiddenFromStatusLists)
      for (final list in _lists)
        if (oldEntry.status != null &&
            oldEntry.status == list.status &&
            (list.splitCompletedListFormat == null ||
                list.splitCompletedListFormat == entry.format)) {
          list.removeByMediaId(entry.mediaId);
          break;
        }

    // Remove from old custom lists
    if (oldCustomLists.isNotEmpty)
      for (final list in _lists)
        for (int i = 0; i < oldCustomLists.length; i++)
          if (oldCustomLists[i] == list.name.toLowerCase()) {
            list.removeByMediaId(entry.mediaId);
            oldCustomLists.removeAt(i);
            break;
          }

    // Add to new status list
    if (!newEntry.hiddenFromStatusLists) {
      bool added = false;
      for (final list in _lists)
        if (newEntry.status == list.status &&
            (list.splitCompletedListFormat == null ||
                list.splitCompletedListFormat == entry.format)) {
          list.insertSorted(entry, _filters[Filterable.SORT]);
          added = true;
          break;
        }
      if (!added) {
        fetch();
        return;
      }
    }

    // Add to new custom lists
    if (newCustomLists.isNotEmpty) {
      for (final list in _lists)
        for (int i = 0; i < newCustomLists.length; i++)
          if (newCustomLists[i] == list.name.toLowerCase()) {
            list.insertSorted(entry, _filters[Filterable.SORT]);
            newCustomLists.removeAt(i);
            break;
          }
      if (newCustomLists.isNotEmpty) {
        fetch();
        return;
      }
    }

    // Remove empty lists
    for (int i = 0; i < _lists.length; i++)
      if (_lists[i].entries.isEmpty) {
        if (i <= _listIndex.value) _listIndex.value--;
        _lists.removeAt(i--);
      }

    filter();
  }

  Future<void> updateProgress(ListEntryModel e) async {
    if (e.progress == e.progressMax) return;

    final data = await Client.request(
      _updateProgressMutation,
      e.progressToMap(),
      popOnErr: false,
    );
    if (data == null) return;

    e.updateProgress(data['SaveMediaListEntry']);

    final ListSort sorting = _filters[Filterable.SORT];
    final ListStatus? entryStatus = Convert.strToEnum(
      e.status,
      ListStatus.values,
    );

    // If sorting doesn't depend on progress, replace entry
    if (sorting != ListSort.PROGRESS && sorting != ListSort.PROGRESS_DESC)
      for (final list in _lists) {
        if (list.status != null && list.status != entryStatus) continue;

        for (int i = 0; i < list.entries.length; i++)
          if (list.entries[i].mediaId == e.mediaId) {
            list.entries[i] = e;
            break;
          }
      }
    // Otherwise, remove and insert sorted
    else
      for (final list in _lists) {
        if (list.status != null && list.status != entryStatus) continue;

        for (int i = 0; i < list.entries.length; i++)
          if (list.entries[i].mediaId == e.mediaId) {
            list.entries.removeAt(i);
            list.insertSorted(e, sorting);
            break;
          }
      }

    // Replace in filtered
    for (int i = 0; i < _entries.length; i++)
      if (_entries[i].mediaId == e.mediaId) {
        _entries[i] = e;
        break;
      }
  }

  Future<void> removeEntry(EntryModel entry) async {
    final data = await Client.request(
      _removeEntryMutation,
      {'entryId': entry.entryId},
      popOnErr: false,
    );

    if (data == null || data['DeleteMediaListEntry']['deleted'] == false)
      return;

    final List<String> customLists = [];
    for (final cl in entry.customLists.entries)
      if (cl.value) customLists.add(cl.key.toLowerCase());

    for (final list in _lists)
      if ((!entry.hiddenFromStatusLists &&
              entry.status == list.status &&
              !list.isCustomList) ||
          (list.isCustomList && customLists.contains(list.name.toLowerCase())))
        list.removeByMediaId(entry.mediaId);

    for (int i = 0; i < _lists.length; i++)
      if (_lists[i].entries.isEmpty) {
        if (i <= _listIndex.value) _listIndex.value--;
        _lists.removeAt(i--);
      }

    filter();
  }

  // ***************************************************************************
  // FILTERING
  // ***************************************************************************

  void filter() {
    if (_lists.isEmpty) return;

    final List<String>? formatIn = _filters[Filterable.FORMAT_IN];
    final List<String>? statusIn = _filters[Filterable.STATUS_IN];
    final List<String>? genreIn = _filters[Filterable.GENRE_IN];
    final List<String>? genreNotIn = _filters[Filterable.GENRE_NOT_IN];
    final search =
        (_filters[Filterable.SEARCH] as String?)?.toLowerCase() ?? '';

    final list = _lists[_listIndex()];
    final e = <ListEntryModel>[];

    for (final entry in list.entries) {
      if (search != '' && !entry.title!.toLowerCase().contains(search))
        continue;

      if (formatIn != null) {
        bool isIn = false;
        for (final format in formatIn)
          if (entry.format == format) {
            isIn = true;
            break;
          }
        if (!isIn) continue;
      }

      if (statusIn != null) {
        bool isIn = false;
        for (final status in statusIn)
          if (entry.status == status) {
            isIn = true;
            break;
          }
        if (!isIn) continue;
      }

      if (genreIn != null) {
        bool isIn = false;
        for (final genre in entry.genres)
          if (genreIn.contains(genre)) {
            isIn = true;
            break;
          }
        if (!isIn) continue;
      }

      if (genreNotIn != null) {
        bool isIn = false;
        for (final genre in entry.genres)
          if (genreNotIn.contains(genre)) {
            isIn = true;
            break;
          }
        if (isIn) continue;
      }

      e.add(entry);
    }

    _entries.assignAll(e);
  }

  @override
  dynamic getFilterWithKey(String key) => _filters[key];

  @override
  void setFilterWithKey(String key, {dynamic value, bool update = false}) {
    if (value == null ||
        (value is List && value.isEmpty) ||
        (value is String && value.trim().isEmpty)) {
      _filters.remove(key);
    } else {
      _filters[key] = value;
    }

    if (update) {
      scrollTo(0);
      filter();
    }
  }

  @override
  void clearAllFilters({bool update = true}) => clearFiltersWithKeys([
        Filterable.STATUS_IN,
        Filterable.FORMAT_IN,
        Filterable.GENRE_IN,
        Filterable.GENRE_NOT_IN,
      ], update: update);

  @override
  void clearFiltersWithKeys(List<String> keys, {bool update = true}) {
    for (final key in keys) {
      _filters.remove(key);
    }

    if (update) {
      scrollTo(0);
      filter();
    }
  }

  @override
  bool anyActiveFilterFrom(List<String> keys) {
    for (final key in keys) if (_filters.containsKey(key)) return true;
    return false;
  }

  @override
  void onInit() {
    super.onInit();
    fetch();
  }
}
