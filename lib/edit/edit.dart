import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otraku/collections/entry.dart';
import 'package:otraku/settings/user_settings.dart';
import 'package:otraku/utils/api.dart';
import 'package:otraku/utils/convert.dart';
import 'package:otraku/utils/graphql.dart';

/// Update an entry and return the entry id. This may be useful, if
/// the entry didn't exist up until now, i.e. there wasn't an id.
Future<int?> updateEntry(Edit oldEdit, Edit newEdit) async {
  try {
    final data = await Api.get(GqlMutation.updateEntry, newEdit.toMap());
    return data['SaveMediaListEntry']['id'];
  } catch (e) {
    return null;
  }
}

/// Increment entry progress. The entry's custom lists are returned,
/// so that all of them can easily be updated locally.
Future<List<String>?> updateProgress(int mediaId, int progress) async {
  try {
    final data = await Api.get(
      GqlMutation.updateProgress,
      {'mediaId': mediaId, 'progress': progress},
    );

    final customLists = <String>[];
    for (final e in data['SaveMediaListEntry']['customLists'].entries)
      if (e.value) customLists.add(e.key.toString().toLowerCase());
    return customLists;
  } catch (e) {
    return null;
  }
}

/// Remove an entry.
Future<void> removeEntry(int entryId) async {
  try {
    await Api.get(GqlMutation.removeEntry, {'entryId': entryId});
  } catch (e) {}
}

final currentEditProvider = FutureProvider.autoDispose.family<Edit, int>(
  (ref, id) async {
    final data = await Api.get(GqlQuery.media, {'id': id, 'withMain': true});
    return Edit(data['Media'], ref.watch(userSettingsProvider));
  },
);

final editProvider = StateProvider.autoDispose<Edit>(
  (ref) => Edit._(mediaId: -1),
);

class Edit {
  Edit._({
    required this.mediaId,
    this.type,
    this.entryId,
    this.status,
    this.progress = 0,
    this.progressMax,
    this.progressVolumes = 0,
    this.progressVolumesMax,
    this.score = 0,
    this.repeat = 0,
    this.notes = '',
    this.startedAt,
    this.completedAt,
    this.private = false,
    this.hiddenFromStatusLists = false,
    this.advancedScores = const {},
    this.customLists = const {},
  });

  factory Edit(Map<String, dynamic> map, UserSettings settings) {
    final customLists = <String, bool>{};
    if (map['mediaListEntry']?['customLists'] != null) {
      for (final e in map['mediaListEntry']['customLists'].entries)
        customLists[e.key] = e.value;
    } else {
      if (map['type'] == 'ANIME')
        for (final c in settings.animeCustomLists) customLists[c] = false;
      else
        for (final c in settings.mangaCustomLists) customLists[c] = false;
    }

    if (map['mediaListEntry'] == null)
      return Edit._(
        type: map['type'],
        mediaId: map['id'],
        progressMax: map['episodes'] ?? map['chapters'],
        progressVolumesMax: map['volumes'],
        customLists: customLists,
      );

    final advancedScores = <String, double>{};
    if (map['mediaListEntry']['advancedScores'] != null)
      for (final e in map['mediaListEntry']['advancedScores'].entries)
        advancedScores[e.key] = e.value.toDouble();

    return Edit._(
      type: map['type'],
      mediaId: map['id'],
      entryId: map['mediaListEntry']['id'],
      status: map['mediaListEntry']['status'] != null
          ? EntryStatus.values.byName(map['mediaListEntry']['status'])
          : null,
      progress: map['mediaListEntry']['progress'] ?? 0,
      progressMax: map['episodes'] ?? map['chapters'],
      progressVolumes: map['mediaListEntry']['progressVolumes'] ?? 0,
      progressVolumesMax: map['volumes'],
      score: (map['mediaListEntry']['score'] ?? 0).toDouble(),
      repeat: map['mediaListEntry']['repeat'] ?? 0,
      notes: map['mediaListEntry']['notes'] ?? '',
      startedAt: Convert.mapToDateTime(map['mediaListEntry']['startedAt']),
      completedAt: Convert.mapToDateTime(map['mediaListEntry']['completedAt']),
      private: map['mediaListEntry']['private'] ?? false,
      hiddenFromStatusLists:
          map['mediaListEntry']['hiddenFromStatusLists'] ?? false,
      advancedScores: advancedScores,
      customLists: customLists,
    );
  }

  final int mediaId;
  final String? type;
  final EntryStatus? status;
  final int progress;
  final int? progressMax;
  final int progressVolumes;
  final int? progressVolumesMax;
  final double score;
  final int repeat;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final bool private;
  final bool hiddenFromStatusLists;
  final Map<String, double> advancedScores;
  final Map<String, bool> customLists;
  int? entryId;
  String notes;

  Edit copyWith({
    EntryStatus? status,
    int? progress,
    int? progressVolumes,
    double? score,
    int? repeat,
    String? notes,
    DateTime? Function()? startedAt,
    DateTime? Function()? completedAt,
    bool? private,
    bool? hiddenFromStatusLists,
    Map<String, double>? advancedScores,
    Map<String, bool>? customLists,
  }) =>
      Edit._(
        type: type,
        mediaId: mediaId,
        entryId: entryId,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        progressMax: progressMax,
        progressVolumes: progressVolumes ?? this.progressVolumes,
        progressVolumesMax: progressVolumesMax,
        score: score ?? this.score,
        repeat: repeat ?? this.repeat,
        notes: notes ?? this.notes,
        startedAt: startedAt?.call() ?? this.startedAt,
        completedAt: completedAt?.call() ?? this.completedAt,
        private: private ?? this.private,
        hiddenFromStatusLists:
            hiddenFromStatusLists ?? this.hiddenFromStatusLists,
        advancedScores: advancedScores ?? {...this.advancedScores},
        customLists: customLists ?? {...this.customLists},
      );

  Edit emptyCopy() => Edit._(
        type: type,
        mediaId: mediaId,
        progressMax: progressMax,
        progressVolumesMax: progressVolumesMax,
      );

  Map<String, dynamic> toMap() => {
        'mediaId': mediaId,
        'status': (status ?? EntryStatus.CURRENT).name,
        'progress': progress,
        'progressVolumes': progressVolumes,
        'score': score,
        'repeat': repeat,
        'notes': notes,
        'startedAt': Convert.dateTimeToMap(startedAt),
        'completedAt': Convert.dateTimeToMap(completedAt),
        'private': private,
        'hiddenFromStatusLists': hiddenFromStatusLists,
        'advancedScores': advancedScores.entries.map((e) => e.value).toList(),
        'customLists': customLists.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toList(),
      };
}