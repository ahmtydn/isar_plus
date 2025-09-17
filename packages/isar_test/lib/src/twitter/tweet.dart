import 'package:isar_plus/isar.dart';
import 'package:isar_test/src/twitter/entities.dart';
import 'package:isar_test/src/twitter/geo.dart';
import 'package:isar_test/src/twitter/media.dart';
import 'package:isar_test/src/twitter/user.dart';

part 'tweet.g.dart';

@collection
class Tweet {
  Tweet({
    this.isarId,
    this.createdAt,
    this.idStr,
    this.source,
    this.truncated,
    this.inReplyToStatusIdStr,
    this.inReplyToUserIdStr,
    this.inReplyToScreenName,
    this.user,
    this.coordinates,
    this.place,
    this.quotedStatusIdStr,
    this.isQuoteStatus,
    this.quoteCount,
    this.replyCount,
    this.retweetCount,
    this.favoriteCount,
    this.entities,
    this.extendedEntities,
    this.favorited,
    this.retweeted,
    this.possiblySensitive,
    this.possiblySensitiveAppealable,
    this.currentUserRetweet,
    this.lang,
    this.quotedStatusPermalink,
    this.fullText,
    this.displayTextRange,
  });

  Id? isarId;

  DateTime? createdAt;

  String? idStr;

  String? source;

  bool? truncated;

  String? inReplyToStatusIdStr;

  String? inReplyToUserIdStr;

  String? inReplyToScreenName;

  User? user;

  Coordinates? coordinates;

  Place? place;

  String? quotedStatusIdStr;

  bool? isQuoteStatus;

  int? quoteCount;

  int? replyCount;

  int? retweetCount;

  int? favoriteCount;

  Entities? entities;

  Entities? extendedEntities;

  bool? favorited;

  bool? retweeted;

  bool? possiblySensitive;

  bool? possiblySensitiveAppealable;

  CurrentUserRetweet? currentUserRetweet;

  String? lang;

  QuotedStatusPermalink? quotedStatusPermalink;

  String? fullText;

  List<int>? displayTextRange;
}

@embedded
class CurrentUserRetweet {
  CurrentUserRetweet({this.idStr});

  String? idStr;
}

@embedded
class QuotedStatusPermalink {
  QuotedStatusPermalink({this.url, this.expanded, this.display});

  String? url;

  String? expanded;

  String? display;
}
