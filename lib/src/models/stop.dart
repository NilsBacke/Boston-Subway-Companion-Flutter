class Stop {
  String id;
  String name;
  double latitude;
  double longitude;
  String directionDestination;
  String directionName;

  String get directionDescription =>
      this.directionName + "bound towards " + this.directionDestination;

  static const idKey = "id";
  static const nameKey = "name";
  static const latitudeKey = "latitude";
  static const longitudeKey = "longitude";
  static const directionKey = "platform_name";
  static const attributesKey = "attributes";
  static const directionNameKey = "direction_name";

  static const List<String> northList = ["Alewife", "Oak Grove"];
  static const List<String> southList = [
    "Ashmont/Braintree",
    "Ashmont",
    "Braintree",
    "Forest Hills",
    "Mattapan"
  ];
  static const List<String> westList = [
    "Bowdoin",
    "Boston College",
    "Cleveland Circle",
    "Riverside",
    "Heath Street",
    "Cleveland Circle/Riverside"
  ];
  static const List<String> eastList = [
    "Wonderland",
    "Park Street",
    "North Station",
    "Government Center",
    "Lechmere"
  ];

  Stop(this.id, this.name, this.latitude, this.longitude,
      this.directionDestination, this.directionName);

  Stop.fromJson(Map<String, dynamic> parsedJson) {
    final attributes = parsedJson[attributesKey];
    this.id = parsedJson[idKey];
    this.name = attributes[nameKey];
    this.latitude = attributes[latitudeKey];
    this.longitude = attributes[longitudeKey];
    this.directionDestination = attributes[directionKey];
    this.directionName =
        _convertDirectionToName(this.directionDestination, this.id);
  }

  Map<String, dynamic> toJson() => {
        idKey: id,
        nameKey: name,
        longitudeKey: longitude.toString(),
        latitudeKey: latitude.toString(),
        directionKey: directionDestination,
        directionNameKey: directionName
      };

  String _convertDirectionToName(String direction, String id) {
    if (northList.contains(direction) ||
        direction.toLowerCase().contains("north") ||
        direction.toLowerCase().contains(
            northList.fold("", (t1, t2) => t1.toString() + t2.toString()))) {
      return "North";
    } else if (southList.contains(direction) ||
        direction.toLowerCase().contains("south") ||
        direction.toLowerCase().contains(
            southList.fold("", (t1, t2) => t1.toString() + t2.toString()))) {
      return "South";
    } else if (eastList.contains(direction) ||
        direction.toLowerCase().contains("east") ||
        direction.toLowerCase().contains(
            eastList.fold("", (t1, t2) => t1.toString() + t2.toString()))) {
      return "East";
    } else if (westList.contains(direction) ||
        direction.toLowerCase().contains("west") ||
        direction.toLowerCase().contains(
            westList.fold("", (t1, t2) => t1.toString() + t2.toString()))) {
      return "West";
    } else {
      // TODO will need to do something with these weird stops
      return "";
    }
  }
}