import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otraku/collection/collection_models.dart';
import 'package:otraku/edit/edit_model.dart';
import 'package:otraku/media/media_providers.dart';
import 'package:otraku/settings/settings_provider.dart';
import 'package:otraku/utils/api.dart';
import 'package:otraku/utils/graphql.dart';

/// Updates an entry with an edit and returns the entry, or an error
/// if unsuccessful. There is an api bug in entry updating, which prevents
/// certain data from being returned. This is why 2 requests are needed.
Future<Object> updateEntry(Edit edit, int userId) async {
  try {
    await Api.get(GqlMutation.updateEntry, edit.toMap());

    final data = await Api.get(
      GqlQuery.listEntry,
      {'userId': userId, 'mediaId': edit.mediaId},
    );
    return Entry(data['MediaList']);
  } catch (e) {
    return e;
  }
}

/// Increments entry progress and returns the entry's custom lists
/// (`List<String>`) or an error if unsuccessful. The lists are
/// used to easily update the entry locally.
Future<Object> updateProgress(int mediaId, int progress) async {
  try {
    final data = await Api.get(
      GqlMutation.updateProgress,
      {'mediaId': mediaId, 'progress': progress},
    );

    final entries = data['SaveMediaListEntry']?['customLists']?.entries;
    if (entries == null) return <String>[];

    final customLists = <String>[];
    for (final e in entries) {
      if (e.value) customLists.add(e.key.toString().toLowerCase());
    }
    return customLists;
  } catch (e) {
    return e;
  }
}

/// Removes an entry and returns an error if unsuccessful.
Future<Object?> removeEntry(int entryId) async {
  try {
    await Api.get(GqlMutation.removeEntry, {'entryId': entryId});
    return null;
  } catch (e) {
    return e;
  }
}

class EditTag {
  const EditTag(this.id, [this.setComplete = false]);

  final int id;
  final bool setComplete;

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => hashCode == other.hashCode;
}

final oldEditProvider = FutureProvider.autoDispose.family(
  (ref, EditTag tag) async {
    if (ref.exists(mediaProvider(tag.id))) {
      return ref.watch(mediaProvider(tag.id)).value!.edit;
    }

    final data = await Api.get(GqlQuery.entry, {'mediaId': tag.id});
    return Edit(data['Media'], ref.watch(settingsProvider.notifier).value);
  },
);

final newEditProvider = StateProvider.autoDispose.family((ref, EditTag tag) {
  final old = ref.watch(oldEditProvider(tag)).valueOrNull ?? Edit.temp();
  return old.copy(tag.setComplete);
});
