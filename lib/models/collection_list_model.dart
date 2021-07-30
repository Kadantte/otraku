import 'package:otraku/utils/convert.dart';
import 'package:otraku/enums/entry_sort.dart';
import 'package:otraku/enums/list_status.dart';
import 'package:otraku/models/list_entry_model.dart';

class CollectionListModel {
  final String name;
  final ListStatus? status;
  final bool isCustomList;
  final String? splitCompletedListFormat;
  final List<ListEntryModel> entries;

  CollectionListModel._({
    required this.name,
    required this.isCustomList,
    required this.entries,
    this.status,
    this.splitCompletedListFormat,
  });

  factory CollectionListModel(Map<String, dynamic> map, bool splitCompleted) =>
      CollectionListModel._(
        name: map['name'],
        isCustomList: map['isCustomList'] ?? false,
        status: !map['isCustomList']
            ? Convert.strToEnum(map['status'], ListStatus.values)
            : null,
        splitCompletedListFormat: splitCompleted &&
                !map['isCustomList'] &&
                map['status'] == 'COMPLETED'
            ? map['entries'][0]['media']['format']
            : null,
        entries: (map['entries'] as List<dynamic>)
            .map((e) => ListEntryModel(e))
            .toList(),
      );

  void removeByMediaId(final int? id) {
    for (int i = 0; i < entries.length; i++)
      if (id == entries[i].mediaId) {
        entries.removeAt(i);
        return;
      }
  }

  void insertSorted(final ListEntryModel item, final EntrySort? s) {
    final compare = _compareFn(s);
    for (int i = 0; i < entries.length; i++)
      if (compare(item, entries[i]) <= 0) {
        entries.insert(i, item);
        return;
      }
    entries.add(item);
  }

  void sort(final EntrySort? s) => entries.sort(_compareFn(s));

  int Function(ListEntryModel, ListEntryModel) _compareFn(final EntrySort? s) {
    switch (s) {
      case EntrySort.TITLE:
        return (a, b) => a.title!.compareTo(b.title!);
      case EntrySort.TITLE_DESC:
        return (a, b) => b.title!.compareTo(a.title!);
      case EntrySort.SCORE:
        return (a, b) {
          final comparison = a.score.compareTo(b.score);
          if (comparison != 0) return comparison;
          return a.title!.compareTo(b.title!);
        };
      case EntrySort.SCORE_DESC:
        return (a, b) {
          final comparison = b.score.compareTo(a.score);
          if (comparison != 0) return comparison;
          return a.title!.compareTo(b.title!);
        };
      case EntrySort.UPDATED_AT:
        return (a, b) {
          final comparison = a.updatedAt!.compareTo(b.updatedAt!);
          if (comparison != 0) return comparison;
          return a.title!.compareTo(b.title!);
        };
      case EntrySort.UPDATED_AT_DESC:
        return (a, b) {
          final comparison = b.updatedAt!.compareTo(a.updatedAt!);
          if (comparison != 0) return comparison;
          return a.title!.compareTo(b.title!);
        };
      case EntrySort.CREATED_AT:
        return (a, b) {
          final comparison = a.createdAt!.compareTo(b.createdAt!);
          if (comparison != 0) return comparison;
          return a.title!.compareTo(b.title!);
        };
      case EntrySort.CREATED_AT_DESC:
        return (a, b) {
          final comparison = b.createdAt!.compareTo(a.createdAt!);
          if (comparison != 0) return comparison;
          return a.title!.compareTo(b.title!);
        };
      case EntrySort.PROGRESS:
        return (a, b) {
          final comparison = a.progress.compareTo(b.progress);
          if (comparison != 0) return comparison;
          return a.title!.compareTo(b.title!);
        };
      case EntrySort.PROGRESS_DESC:
        return (a, b) {
          final comparison = b.progress.compareTo(a.progress);
          if (comparison != 0) return comparison;
          return a.title!.compareTo(b.title!);
        };
      case EntrySort.REPEAT:
        return (a, b) {
          final comparison = a.repeat.compareTo(b.repeat);
          if (comparison != 0) return comparison;
          return a.title!.compareTo(b.title!);
        };
      case EntrySort.REPEAT_DESC:
        return (a, b) {
          final comparison = b.repeat.compareTo(a.repeat);
          if (comparison != 0) return comparison;
          return a.title!.compareTo(b.title!);
        };
      default:
        return (_, __) => 0;
    }
  }
}
