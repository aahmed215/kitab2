// ═══════════════════════════════════════════════════════════════════
// CONTENT_FILTER.DART — Profanity & Inappropriate Content Filter
// Checks text for profanity, slurs, controversial terms, and
// blasphemy. Used for user-facing fields: names, bio, usernames.
// Client-side first line of defense — server-side moderation
// can be added via Supabase Edge Function for stronger enforcement.
// ═══════════════════════════════════════════════════════════════════

/// Result of a content check.
class ContentCheckResult {
  final bool isClean;
  final String? reason;

  const ContentCheckResult.clean() : isClean = true, reason = null;
  const ContentCheckResult.blocked(this.reason) : isClean = false;
}

/// Checks text content for inappropriate material.
class ContentFilter {
  const ContentFilter._();

  /// Check a username specifically — includes reserved name check
  /// plus all content checks.
  static ContentCheckResult checkUsername(String username) {
    if (username.trim().isEmpty) return const ContentCheckResult.clean();

    final lower = username.trim().toLowerCase();

    // Reserved system names
    if (_reservedUsernames.contains(lower)) {
      return const ContentCheckResult.blocked(
        'This username is not available.',
      );
    }

    // Then run the standard content check
    return check(username);
  }

  /// Check a text field for inappropriate content.
  /// Returns clean if OK, or blocked with a user-friendly reason.
  static ContentCheckResult check(String text) {
    if (text.trim().isEmpty) return const ContentCheckResult.clean();

    final lower = text.toLowerCase();

    // 1. Profanity
    for (final word in _profanity) {
      if (lower.contains(word)) {
        return const ContentCheckResult.blocked(
          'This contains inappropriate language. Please remove it.',
        );
      }
    }

    // 2. Slurs and hate speech
    for (final word in _slurs) {
      if (lower.contains(word)) {
        return const ContentCheckResult.blocked(
          'This contains offensive or hateful language.',
        );
      }
    }

    // 3. Blasphemy / religious disrespect
    for (final phrase in _blasphemy) {
      if (lower.contains(phrase)) {
        return const ContentCheckResult.blocked(
          'This contains disrespectful content.',
        );
      }
    }

    // 4. Controversial / extremist terms
    for (final word in _extremist) {
      if (_matchesWholeWord(lower, word)) {
        return const ContentCheckResult.blocked(
          'This contains restricted content.',
        );
      }
    }

    return const ContentCheckResult.clean();
  }

  /// Check if a word appears as a whole word (not substring).
  /// Used for words that might appear in legitimate contexts as substrings.
  static bool _matchesWholeWord(String text, String word) {
    final regex = RegExp('\\b$word\\b', caseSensitive: false);
    return regex.hasMatch(text);
  }

  // ─── Word Lists ───
  // These are kept minimal but effective. Not exhaustive — a production
  // app would use a dedicated moderation API (e.g., OpenAI Moderation,
  // Perspective API, or AWS Comprehend).

  static const _profanity = [
    'fuck', 'fck', 'f*ck', 'f**k', 'fuk', 'fuq',
    'shit', 'sh1t', 'sh!t', 'sht',
    'bitch', 'b1tch', 'btch',
    'asshole', 'a\$\$hole', 'assh0le',
    'dick', 'd1ck',
    'cock', 'c0ck',
    'cunt', 'c*nt',
    'bastard', 'b@stard',
    'whore', 'wh0re',
    'slut', 'sl*t',
    'damn', 'dammit',
    'piss',
    'crap',
    'wanker',
    'twat',
    'bollocks',
    'motherfucker', 'mf',
    'stfu', 'gtfo', 'lmfao',
    'porn', 'p0rn',
  ];

  static const _slurs = [
    'nigger', 'n1gger', 'nigg@', 'n*gger', 'nigga',
    'faggot', 'f@ggot', 'fag',
    'retard', 'ret@rd',
    'spic', 'sp1c',
    'chink', 'ch1nk',
    'kike', 'k1ke',
    'wetback',
    'tranny',
    'shemale',
    'towelhead',
    'raghead',
    'sandnigger',
    'gook',
    'beaner',
    'cracker',
  ];

  static const _blasphemy = [
    'god damn', 'goddamn',
    'fuck god', 'f*ck god',
    'fuck allah', 'f*ck allah',
    'fuck jesus', 'f*ck jesus',
    'fuck islam', 'f*ck islam',
    'fuck religion',
    'god is dead',
    'allah is fake',
    'jesus is fake',
    'islam is fake',
    'religion is cancer',
    'curse god', 'curse allah',
  ];

  static const _extremist = [
    'nazi', 'hitler', 'heil',
    'isis', 'isil', 'daesh',
    'al qaeda', 'alqaeda',
    'taliban',
    'jihadi', // note: 'jihad' alone is legitimate Islamic term
    'white power', 'white supremac',
    'kill all', 'death to',
    'ethnic cleansing', 'genocide',
    'terrorist',
    'bomb threat',
  ];

  /// Reserved usernames that cannot be claimed.
  static const _reservedUsernames = {
    // System
    'admin', 'administrator', 'mod', 'moderator',
    'root', 'system', 'null', 'undefined', 'void',
    // App-specific
    'kitab', 'mykitab', 'kitabapp',
    // Roles
    'support', 'help', 'info', 'contact', 'feedback',
    'official', 'staff', 'team', 'bot', 'service',
    // Technical
    'api', 'www', 'mail', 'email', 'ftp', 'ssh',
    'test', 'testing', 'debug', 'dev', 'developer',
    'staging', 'production', 'demo',
    // Account
    'account', 'accounts', 'login', 'signin', 'signup',
    'register', 'auth', 'profile', 'user', 'users',
    'settings', 'config', 'dashboard',
    // Content
    'blog', 'news', 'about', 'privacy', 'terms',
    'legal', 'security', 'status',
    // Reserved for future
    'explore', 'discover', 'search', 'trending',
    'notification', 'notifications', 'message', 'messages',
    'invite', 'share', 'social', 'community',
    'everyone', 'all', 'public', 'private',
    'anonymous', 'guest', 'unknown',
  };
}
