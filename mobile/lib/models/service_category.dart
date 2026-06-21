class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.name,
    this.description,
  });

  final String id;
  final String name;
  final String? description;

  factory ServiceCategory.fromMap(Map<String, dynamic> map) {
    return ServiceCategory(
      id: map['id'] as String,
      name: map['name_en'] as String? ?? 'Service',
      description: map['description_en'] as String?,
    );
  }
}
