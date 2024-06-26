import 'package:otraku/model/paged.dart';
import 'package:otraku/model/relation.dart';
import 'package:otraku/model/tile_item.dart';
import 'package:otraku/util/extensions.dart';
import 'package:otraku/util/markdown.dart';
import 'package:otraku/feature/discover/discover_models.dart';
import 'package:otraku/feature/settings/settings_model.dart';

TileItem staffItem(Map<String, dynamic> map) => TileItem(
      id: map['id'],
      type: DiscoverType.staff,
      title: map['name']['userPreferred'],
      imageUrl: map['image']['large'],
    );

class Staff {
  Staff._({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.altNames,
    required this.dateOfBirth,
    required this.dateOfDeath,
    required this.bloodType,
    required this.homeTown,
    required this.gender,
    required this.age,
    required this.startYear,
    required this.endYear,
    required this.siteUrl,
    required this.favorites,
    required this.isFavorite,
  });

  factory Staff(Map<String, dynamic> map, PersonNaming personNaming) {
    final names = map['name'];
    final nameSegments = [
      names['first'],
      if (names['middle']?.isNotEmpty ?? false) names['middle'],
      if (names['last']?.isNotEmpty ?? false) names['last'],
    ];

    final fullName = personNaming == PersonNaming.romajiWestern
        ? nameSegments.join(' ')
        : nameSegments.reversed.toList().join(' ');
    final nativeName = names['native'];

    final altNames = List<String>.from(names['alternative'] ?? []);

    String name;
    if (nativeName != null) {
      if (personNaming != PersonNaming.native) {
        name = fullName;
        altNames.insert(0, nativeName);
      } else {
        name = nativeName;
        altNames.insert(0, fullName);
      }
    } else {
      name = fullName;
    }

    final yearsActive = map['yearsActive'] as List?;

    return Staff._(
      id: map['id'],
      name: name,
      altNames: altNames,
      imageUrl: map['image']['large'],
      description: parseMarkdown(map['description'] ?? ''),
      dateOfBirth: StringUtil.fromFuzzyDate(map['dateOfBirth']),
      dateOfDeath: StringUtil.fromFuzzyDate(map['dateOfDeath']),
      bloodType: map['bloodType'],
      homeTown: map['homeTown'],
      gender: map['gender'],
      age: map['age']?.toString(),
      startYear: yearsActive != null && yearsActive.isNotEmpty
          ? yearsActive[0].toString()
          : null,
      endYear: yearsActive != null && yearsActive.length > 1
          ? yearsActive[1].toString()
          : null,
      siteUrl: map['siteUrl'],
      favorites: map['favourites'] ?? 0,
      isFavorite: map['isFavourite'] ?? false,
    );
  }

  final int id;
  final String name;
  final String imageUrl;
  final String description;
  final List<String> altNames;
  final String? dateOfBirth;
  final String? dateOfDeath;
  final String? bloodType;
  final String? homeTown;
  final String? gender;
  final String? age;
  final String? startYear;
  final String? endYear;
  final String? siteUrl;
  final int favorites;
  bool isFavorite;
}

class StaffRelations {
  const StaffRelations({
    this.charactersAndMedia = const Paged(),
    this.roles = const Paged(),
  });

  final Paged<(Relation, Relation)> charactersAndMedia;
  final Paged<Relation> roles;
}
