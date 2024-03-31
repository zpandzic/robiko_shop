class AttributeValue {
  final int id;
  String value;

  AttributeValue({required this.id, required this.value});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'value': value,
    };
  }

  static AttributeValue fromJson(Map<String, dynamic> json) => AttributeValue(
        id: json['id'],
        value: json['value'],
      );
}
