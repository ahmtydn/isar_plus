import 'package:isar_plus/isar.dart';

part 'geo.g.dart';

@embedded
class Place {
  Place({
    this.id,
    this.url,
    this.placeType,
    this.name,
    this.fullName,
    this.countryCode,
    this.country,
  });

  String? id;

  String? url;

  @Enumerated(EnumType.name)
  PlaceType? placeType;

  String? name;

  String? fullName;

  String? countryCode;

  String? country;
}

enum PlaceType { admin, country, city, poi, neighborhood }

@embedded
class Coordinates {
  Coordinates({this.coordinates, this.type});

  List<double>? coordinates;

  String? type;
}
