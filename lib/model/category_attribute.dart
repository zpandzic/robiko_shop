class CategoryAttribute {
  final int id;
  final String? type;
  final String? name;
  final String? inputType;
  final String? displayName;
  final List<String>? options;
  final int? rank;
  final int? order;
  final bool? required;
  final bool? highlighted;

  CategoryAttribute({
    required this.id,
    this.type,
    this.name,
    this.inputType,
    this.displayName,
    this.options,
    this.rank,
    this.order,
    this.required,
    this.highlighted,
  });

  factory CategoryAttribute.fromJson(Map<String, dynamic> json) {
    return CategoryAttribute(
      id: json['id'] as int,
      type: json['type'] as String?,
      name: json['name'] as String?,
      inputType: json['input_type'] as String?,
      displayName: json['display_name'] as String?,
      options:
          (json['options'] as List<dynamic>?)?.map((e) => e as String).toList(),
      rank: json['rank'] as int?,
      order: json['order'] as int?,
      required: json['required'] as bool?,
      highlighted: json['highlighted'] as bool?,
    );
  }
}
