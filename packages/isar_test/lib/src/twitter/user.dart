import 'package:isar_plus/isar.dart';
import 'package:isar_test/src/twitter/entities.dart';

part 'user.g.dart';

@embedded
class User {
  User({
    this.idStr,
    this.name,
    this.screenName,
    this.location,
    this.url,
    this.entities,
    this.description,
    this.protected,
    this.verified,
    this.followersCount,
    this.friendsCount,
    this.listedCount,
    this.favoritesCount,
    this.statusesCount,
    this.createdAt,
    this.profileBannerUrl,
    this.profileImageUrlHttps,
    this.defaultProfile,
    this.defaultProfileImage,
    this.withheldInCountries,
    this.withheldScope,
  });

  String? idStr;

  String? name;

  String? screenName;

  String? location;

  String? url;

  UserEntities? entities;

  String? description;

  bool? protected;

  bool? verified;

  int? followersCount;

  int? friendsCount;

  int? listedCount;

  int? favoritesCount;

  int? statusesCount;

  DateTime? createdAt;

  String? profileBannerUrl;

  String? profileImageUrlHttps;

  bool? defaultProfile;

  bool? defaultProfileImage;

  List<String>? withheldInCountries;

  String? withheldScope;
}

@embedded
class UserEntities {
  UserEntities({this.url, this.description});

  UserEntityUrl? url;

  UserEntityUrl? description;
}

@embedded
class UserEntityUrl {
  UserEntityUrl({this.urls});

  List<Url>? urls;
}
