class FMT {
  static String sec(double? sec) {
    if (sec == null) return "";
    return sec.toStringAsFixed(0);
  }

  static String dur(double? sec) {
    if (sec == null) return "";
    return sec.toStringAsFixed(3);
  }

  static String buzzedDelta(Duration? delta) {
    if (delta == null) return "";

    int msec = delta.inMilliseconds;
    double sec = msec.toDouble() / 1000.0;
    String disp = "+${FMT.dur(sec)}s";
    return disp;
  }
}
