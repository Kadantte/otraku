import 'package:flutter/foundation.dart';
import 'package:otraku/enums/enum_helper.dart';
import 'package:otraku/enums/list_sort_enum.dart';
import 'package:otraku/enums/media_list_status_enum.dart';
import 'package:otraku/models/collection.dart';
import 'package:otraku/models/date_time_mapping.dart';
import 'package:otraku/models/entry_list.dart';
import 'package:otraku/models/page_data/edit_entry.dart';
import 'package:otraku/models/sample_data/media_entry.dart';
import 'package:otraku/providers/network_service.dart';

class Collections with ChangeNotifier {
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
              status
              startDate {year month day}
              endDate {year month day}
              episodes
              chapters
              volumes
              coverImage {large}
              nextAiringEpisode {timeUntilAiring episode}
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

  static const _updateEntryQuery = r'''
    mutation UpdateEntry($entryId: Int, $mediaId: Int, $status: MediaListStatus,
        $score: Float, $progress: Int, $progressVolumes: Int, $repeat: Int,
        $private: Boolean, $notes: String, $hiddenFromStatusLists: Boolean,
        $customLists: [String], $startedAt: FuzzyDateInput, $completedAt: FuzzyDateInput) {
      SaveMediaListEntry(id: $entryId, mediaId: $mediaId, status: $status,
        score: $score, progress: $progress, progressVolumes: $progressVolumes,
        repeat: $repeat, private: $private, notes: $notes, 
        hiddenFromStatusLists: $hiddenFromStatusLists, customLists: $customLists,
        startedAt: $startedAt, completedAt: $completedAt) {
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
            status
            startDate {year month day}
            endDate {year month day}
            episodes
            chapters
            volumes
            coverImage {large}
            nextAiringEpisode {timeUntilAiring episode}
          }
        }
    }
  ''';

  static const _removeEntryQuery = r'''
    mutation RemoveEntry($entryId: Int) {
      DeleteMediaListEntry(id: $entryId) {
        Deleted {
          deleted
        }
      }
    }
  ''';

  // ***************************************************************************
  // DATA
  // ***************************************************************************

  void init(int id) => _viewerId = id;

  int _viewerId;
  Collection _myAnime;
  Collection _myManga;
  Collection _other;
  _CollectionSelection _currentCollection;
  bool _fetching = false;

  // ***************************************************************************
  // COLLECTION MANAGEMENT
  // ***************************************************************************

  void assignCollection(bool ofAnime, int userId) {
    if (userId == null) {
      if (ofAnime) {
        if (_myAnime == null) fetchMyAnime();
        _currentCollection = _CollectionSelection.myAnime;
      } else {
        if (_myManga == null) fetchMyManga();
        _currentCollection = _CollectionSelection.myManga;
      }
      _other = null;
    } else {
      if (_other == null) fetchUserCollection(ofAnime, userId);
      _currentCollection = _CollectionSelection.other;
    }
  }

  Collection get collection =>
      _currentCollection == _CollectionSelection.myAnime
          ? _myAnime
          : _currentCollection == _CollectionSelection.myManga
              ? _myManga
              : _other;

  bool get fetching => _fetching;

  // ***************************************************************************
  // DATA FETCHING
  // ***************************************************************************

  Future<void> fetchMyAnime() async {
    _myAnime = await _fetchCollection(true, _viewerId);
    if (_myAnime != null) notifyListeners();
  }

  Future<void> fetchMyManga() async {
    _myManga = await _fetchCollection(false, _viewerId);
    if (_myManga != null) notifyListeners();
  }

  Future<void> fetchUserCollection(bool ofAnime, int userId) async {
    _other = await _fetchCollection(ofAnime, userId);
    if (_other != null) notifyListeners();
  }

  Future<Collection> _fetchCollection(bool ofAnime, int userId) async {
    if (userId == null) return null;
    _fetching = true;

    Map<String, dynamic> data = await NetworkService.request(
      _collectionQuery,
      {'userId': userId, 'type': ofAnime ? 'ANIME' : 'MANGA'},
      popOnError: false,
    );

    if (data == null) return null;

    data = data['MediaListCollection'];

    final metaData = ofAnime
        ? data['user']['mediaListOptions']['animeList']
        : data['user']['mediaListOptions']['mangaList'];

    List<EntryList> lists = [];

    for (final String section in metaData['sectionOrder']) {
      final lIndex = (data['lists'] as List<dynamic>)
          .indexWhere((listData) => listData['name'] == section);

      if (lIndex == -1) continue;

      final l = (data['lists'] as List<dynamic>).removeAt(lIndex);

      lists.add(_createList(l, metaData['splitCompletedSectionByFormat']));
    }

    for (final l in data['lists']) {
      lists.add(_createList(l, metaData['splitCompletedSectionByFormat']));
    }

    ListSort sorting;
    switch (data['user']['mediaListOptions']['rowOrder']) {
      case 'title':
        sorting = ListSort.TITLE;
        break;
      case 'score':
        sorting = ListSort.SCORE_DESC;
        break;
      case 'updatedAt':
        sorting = ListSort.UPDATED_AT_DESC;
        break;
      case 'createdAt':
        sorting = ListSort.CREATED_AT_DESC;
        break;
    }

    _fetching = false;

    return Collection(
      notifyHandle: () => notifyListeners(),
      fetchHandle: userId == _viewerId
          ? ofAnime
              ? fetchMyAnime
              : fetchMyManga
          : null,
      userId: _viewerId,
      ofAnime: ofAnime,
      completedListIsSplit: metaData['splitCompletedSectionByFormat'],
      scoreFormat: data['user']['mediaListOptions']['scoreFormat'],
      lists: lists,
      initialSort: sorting,
    );
  }

  // ***************************************************************************
  // ENTRY EDITING
  // ***************************************************************************

  Future<bool> updateEntry(EditEntry original, EditEntry changed) async {
    final List<String> customLists =
        changed.customLists.where((t) => t.item2).map((t) => t.item1).toList();

    final data = await NetworkService.request(
      _updateEntryQuery,
      {
        'mediaId': changed.mediaId,
        'entryId': changed.entryId,
        'status': describeEnum(changed.status),
        'progress': changed.progress,
        'progressVolumes': changed.progressVolumes,
        'score': changed.score,
        'repeat': changed.repeat,
        'notes': changed.notes,
        'startedAt': dateTimeToMap(changed.startedAt),
        'completedAt': dateTimeToMap(changed.completedAt),
        'private': changed.private,
        'hiddenFromStatusLists': changed.hiddenFromStatusLists,
        'customLists': customLists,
      },
    );

    if (data == null) return false;

    MediaEntry entry = _createEntry(data['SaveMediaListEntry']);

    if (changed.type == 'ANIME') {
      _myAnime.updateEntry(original, changed, entry, customLists);
    } else {
      _myManga.updateEntry(original, changed, entry, customLists);
    }

    return true;
  }

  Future<bool> removeEntry(EditEntry entry) async {
    final data = await NetworkService.request(
      _removeEntryQuery,
      {'entryId': entry.entryId},
    );

    if (data == null ||
        data['DeleteMediaListEntry']['Deleted']['deleted'] == false)
      return false;

    if (entry.type == 'ANIME') {
      _myAnime.removeEntry(entry);
    } else {
      _myManga.removeEntry(entry);
    }

    return true;
  }

  // ***************************************************************************
  // HELPER FUNCTIONS FOR CLEANER CODE
  // ***************************************************************************

  EntryList _createList(Map<String, dynamic> l, bool completedListIsSplit) {
    List<MediaEntry> entries = [];
    for (final e in l['entries']) entries.add(_createEntry(e));

    return EntryList(
      name: l['name'],
      isCustomList: l['isCustomList'],
      status: !l['isCustomList']
          ? stringToEnum(l['status'], MediaListStatus.values)
          : null,
      splitCompletedListFormat: completedListIsSplit &&
              !l['isCustomList'] &&
              l['status'] == 'COMPLETED'
          ? l['entries'][0]['media']['format']
          : null,
      entries: entries,
    );
  }

  MediaEntry _createEntry(Map<String, dynamic> entry) => MediaEntry(
        mediaId: entry['mediaId'],
        title: entry['media']['title']['userPreferred'],
        cover: entry['media']['coverImage']['large'],
        nextEpisode: entry['media']['nextAiringEpisode'] != null
            ? entry['media']['nextAiringEpisode']['episode']
            : null,
        timeUntilAiring: entry['media']['nextAiringEpisode'] != null
            ? secondsToTime(
                entry['media']['nextAiringEpisode']['timeUntilAiring'],
              )
            : null,
        format: entry['media']['format'],
        progress: entry['progress'],
        progressMax: entry['media']['episodes'] ?? entry['media']['chapters'],
        progressVolumes: entry['progressVolumes'],
        progressVolumesMax: entry['media']['volumes'],
        score: entry['score'].toDouble(),
        startDate: mapToDateTime(entry['startedAt']),
        endDate: mapToDateTime(entry['completedAt']),
        repeat: entry['repeat'],
        notes: entry['notes'],
        createdAt: entry['createdAt'],
        updatedAt: entry['updatedAt'],
      );
}

enum _CollectionSelection {
  myAnime,
  myManga,
  other,
}
