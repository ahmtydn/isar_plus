import 'package:isar_plus/isar.dart';
import 'package:isar_test/src/twitter/media.dart';

part 'entities.g.dart';

@embedded
class Entities {
  Entities({
    this.hashtags,
    this.media,
    this.urls,
    this.userMentions,
    this.symbols,
    this.polls,
  });

  List<Hashtag>? hashtags;

  List<Media>? media;

  List<Url>? urls;

  List<UserMention>? userMentions;

  List<Symbol>? symbols;

  List<Poll>? polls;
}

@embedded
class Hashtag {
  Hashtag({this.indices, this.text});

  List<int>? indices;

  String? text;
}

@embedded
class Poll {
  Poll({this.options, this.endDatetime, this.durationMinutes});

  List<Option>? options;

  DateTime? endDatetime;

  String? durationMinutes;
}

@embedded
class Option {
  Option({this.position, this.text});

  int? position;

  String? text;
}

@embedded
class Symbol {
  Symbol({this.indices, this.text});

  List<int>? indices;

  String? text;
}

@embedded
class Url {
  Url({this.displayUrl, this.expandedUrl, this.indices, this.url});

  String? displayUrl;

  String? expandedUrl;

  List<int>? indices;

  String? url;
}

@embedded
class UserMention {
  UserMention({this.idStr, this.indices, this.name, this.screenName});

  String? idStr;

  List<int>? indices;

  String? name;

  String? screenName;
}
