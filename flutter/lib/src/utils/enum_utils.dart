extension EnumByNameSafe<T extends Enum> on Iterable<T> {
  T byNameOrDefault(String name, T defaultValue) {
    for (final value in this) {
      if (value.name == name) return value;
    }
    return defaultValue;
  }
}
