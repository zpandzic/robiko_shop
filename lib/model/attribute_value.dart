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
}
