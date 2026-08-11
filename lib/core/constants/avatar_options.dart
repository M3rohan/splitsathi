class AvatarOptions {
  AvatarOptions._();

  static const List<String> options = [
    'avatar_1',
    'avatar_2',
    'avatar_3',
    'avatar_4',
    'avatar_5',
    'avatar_6',
    'avatar_7',
    'avatar_8',
  ];

  static const Map<String, String> emojiMap = {
    'avatar_1': '🦊',
    'avatar_2': '🐼',
    'avatar_3': '🐨',
    'avatar_4': '🦁',
    'avatar_5': '🐯',
    'avatar_6': '🐸',
    'avatar_7': '🦉',
    'avatar_8': '🐙',
  };

  static String emojiFor(String? avatarId) => emojiMap[avatarId] ?? '🦊';
}
