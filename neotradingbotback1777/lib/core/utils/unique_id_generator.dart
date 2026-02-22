class UniqueIdGenerator {
  static int _lastTimestamp = 0;

  /// Generates a unique timestamp-based ID.
  /// Ensures monotonicity and uniqueness even during rapid calls within the same isolate.
  static int generateUniqueTimestamp() {
    int now = DateTime.now().millisecondsSinceEpoch;

    if (now <= _lastTimestamp) {
      // If we are in the same millisecond (or clock went backwards),
      // we increment the sequence or force the timestamp forward.
      // Here we choose to use a sequence number if we want to keep the timestamp "real",
      // but for pure ID purposes, incrementing the timestamp is simpler and sufficient
      // if we don't strictly need it to match wall-clock time perfectly.
      //
      // However, to avoid drifting too far into the future during high load,
      // using a composite ID (timestamp + sequence) is often better.
      // But given the usage strings like 'BUY_ETHUSDT_1234567890',
      // an incremented timestamp is easier to integrate.

      _lastTimestamp++;
      now = _lastTimestamp;
    } else {
      _lastTimestamp = now;
    }

    return now;
  }

  /// Generates a unique string ID with a prefix.
  /// Example: generateStringId('ORD') -> 'ORD_1678901234567'
  static String generateStringId(String prefix) {
    return '${prefix}_${generateUniqueTimestamp()}';
  }
}
