enum ItemType { text, link, file, folder, application, nestedList, randomFileFromFolder }

enum ItemCategory { fun, serious }

class MoodProfile {
  const MoodProfile({
    required this.funMultiplier,
    required this.seriousMultiplier,
  });

  final double funMultiplier;
  final double seriousMultiplier;

  factory MoodProfile.fromJson(Map<String, dynamic> json) {
    return MoodProfile(
      funMultiplier: (json['fun'] as num?)?.toDouble() ?? 1.0,
      seriousMultiplier: (json['serious'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fun': funMultiplier,
      'serious': seriousMultiplier,
    };
  }
}

class MoodPolicy {
  const MoodPolicy({
    required this.activeMood,
    required this.profiles,
  });

  final String activeMood;
  final Map<String, MoodProfile> profiles;

  factory MoodPolicy.defaultPolicy() {
    return MoodPolicy(
      activeMood: 'neutral',
      profiles: const {
        'neutral': MoodProfile(funMultiplier: 1.0, seriousMultiplier: 1.0),
        'bad': MoodProfile(funMultiplier: 1.4, seriousMultiplier: 1.0),
      },
    );
  }

  factory MoodPolicy.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return MoodPolicy.defaultPolicy();
    }

    final profilesJson = json['profiles'] as Map<String, dynamic>? ?? {};
    final profiles = <String, MoodProfile>{};
    for (final entry in profilesJson.entries) {
      profiles[entry.key] = MoodProfile.fromJson(entry.value as Map<String, dynamic>);
    }

    return MoodPolicy(
      activeMood: json['active_mood'] as String? ?? 'neutral',
      profiles: profiles.isEmpty ? MoodPolicy.defaultPolicy().profiles : profiles,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'active_mood': activeMood,
      'profiles': profiles.map((key, value) => MapEntry(key, value.toJson())),
    };
  }
}

class RandomDomItem {
  const RandomDomItem({
    required this.id,
    required this.type,
    required this.value,
    required this.weight,
    required this.category,
  });

  final String id;
  final ItemType type;
  final String value;
  final double weight;
  final ItemCategory category;

  factory RandomDomItem.fromJson(Map<String, dynamic> json, int index) {
    return RandomDomItem(
      id: json['id'] as String? ?? 'item_$index',
      type: _parseType(json['type'] as String? ?? 'text'),
      value: json['value'] as String? ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
      category: _parseCategory(json['category'] as String? ?? 'serious'),
    );
  }

  static ItemType _parseType(String value) {
    return switch (value) {
      'text' => ItemType.text,
      'link' => ItemType.link,
      'file' => ItemType.file,
      'folder' => ItemType.folder,
      'application' => ItemType.application,
      'nested_list' => ItemType.nestedList,
      'random_file_from_folder' => ItemType.randomFileFromFolder,
      _ => ItemType.text,
    };
  }

  static ItemCategory _parseCategory(String value) {
    return value == 'fun' ? ItemCategory.fun : ItemCategory.serious;
  }

  String typeToConfigValue() {
    return switch (type) {
      ItemType.text => 'text',
      ItemType.link => 'link',
      ItemType.file => 'file',
      ItemType.folder => 'folder',
      ItemType.application => 'application',
      ItemType.nestedList => 'nested_list',
      ItemType.randomFileFromFolder => 'random_file_from_folder',
    };
  }

  String categoryToConfigValue() {
    return category == ItemCategory.fun ? 'fun' : 'serious';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': typeToConfigValue(),
      'value': value,
      'weight': weight,
      'category': categoryToConfigValue(),
    };
  }

  RandomDomItem copyWith({
    String? id,
    ItemType? type,
    String? value,
    double? weight,
    ItemCategory? category,
  }) {
    return RandomDomItem(
      id: id ?? this.id,
      type: type ?? this.type,
      value: value ?? this.value,
      weight: weight ?? this.weight,
      category: category ?? this.category,
    );
  }
}

class RandomDomList {
  const RandomDomList({
    required this.name,
    required this.items,
  });

  final String name;
  final List<RandomDomItem> items;

  factory RandomDomList.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return RandomDomList(
      name: json['name'] as String? ?? 'Untitled',
      items: itemsJson
          .asMap()
          .entries
          .map((entry) => RandomDomItem.fromJson(entry.value as Map<String, dynamic>, entry.key))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  RandomDomList copyWith({
    String? name,
    List<RandomDomItem>? items,
  }) {
    return RandomDomList(
      name: name ?? this.name,
      items: items ?? this.items,
    );
  }
}

class RandomDomConfig {
  const RandomDomConfig({
    required this.schemaVersion,
    required this.moodPolicy,
    required this.lists,
  });

  final int schemaVersion;
  final MoodPolicy moodPolicy;
  final Map<String, RandomDomList> lists;

  factory RandomDomConfig.fromJson(Map<String, dynamic> json) {
    final listsJson = json['lists'] as Map<String, dynamic>? ?? {};
    final lists = <String, RandomDomList>{};
    for (final entry in listsJson.entries) {
      lists[entry.key] = RandomDomList.fromJson(entry.value as Map<String, dynamic>);
    }

    return RandomDomConfig(
      schemaVersion: json['schema_version'] as int? ?? 1,
      moodPolicy: MoodPolicy.fromJson(json['mood_policy'] as Map<String, dynamic>?),
      lists: lists,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schema_version': schemaVersion,
      'mood_policy': moodPolicy.toJson(),
      'lists': lists.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  RandomDomConfig copyWith({
    int? schemaVersion,
    MoodPolicy? moodPolicy,
    Map<String, RandomDomList>? lists,
  }) {
    return RandomDomConfig(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      moodPolicy: moodPolicy ?? this.moodPolicy,
      lists: lists ?? this.lists,
    );
  }
}
