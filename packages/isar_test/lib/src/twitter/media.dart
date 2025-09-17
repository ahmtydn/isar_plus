import 'package:isar_plus/isar.dart';

part 'media.g.dart';

@embedded
class Media {
  Media({
    this.displayUrl,
    this.expandedUrl,
    this.idStr,
    this.indices,
    this.mediaUrl,
    this.mediaUrlHttps,
    this.sizes,
    this.sourceStatusIdStr,
    this.type,
    this.url,
    this.videoInfo,
    this.additionalMediaInfo,
  });

  String? displayUrl;

  String? expandedUrl;

  String? idStr;

  List<int>? indices;

  String? mediaUrl;

  String? mediaUrlHttps;

  Sizes? sizes;

  String? sourceStatusIdStr;

  String? type;

  String? url;

  VideoInfo? videoInfo;

  AdditionalMediaInfo? additionalMediaInfo;
}

@embedded
class Sizes {
  Sizes({this.thumb, this.medium, this.small, this.large});

  Size? thumb;

  Size? medium;

  Size? small;

  Size? large;
}

@embedded
class Size {
  Size({this.w, this.h, this.resize});

  int? w;

  int? h;

  String? resize;
}

@embedded
class AdditionalMediaInfo {
  AdditionalMediaInfo({
    this.title,
    this.description,
    this.embeddable,
    this.monetizable,
  });

  String? title;

  String? description;

  bool? embeddable;

  bool? monetizable;
}

@embedded
class VideoInfo {
  VideoInfo({this.aspectRatio, this.durationMillis, this.variants});

  List<int>? aspectRatio;

  int? durationMillis;

  List<Variant>? variants;
}

@embedded
class Variant {
  Variant({this.bitrate, this.contentType, this.url});

  int? bitrate;

  String? contentType;

  String? url;
}
