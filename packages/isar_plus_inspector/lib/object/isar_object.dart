class IsarObject {
  const IsarObject(this.data);

  final Map<String, dynamic> data;

  dynamic getValue(String propertyName) => data[propertyName];

  IsarObject? getNested(String propertyName, {String? linkCollection}) {
    final data = this.data[propertyName] as Map<String, dynamic>?;
    if (data != null) {
      return IsarObject(data);
    } else {
      return null;
    }
  }

  List<IsarObject?>? getNestedList(
    String propertyName, {
    String? linkCollection,
  }) {
    final list = data[propertyName] as List<dynamic>?;
    if (list == null) {
      return null;
    }

    final objects = <IsarObject?>[];
    for (var i = 0; i < list.length; i++) {
      final item = list[i];
      if (item == null) {
        objects.add(null);
      } else {
        objects.add(IsarObject(item as Map<String, dynamic>));
      }
    }

    return objects;
  }
}
