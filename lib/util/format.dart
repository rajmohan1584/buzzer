class FMT {
  static String sec(double? sec) {
    if (sec == null) return "";
    return sec.toStringAsFixed(0);
  }
}
