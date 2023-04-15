class LANG {
  static final RegExp _tamilPattern = RegExp(r'[\u0B80-\u0BFF]');
  static bool isTamil(String input) {
    // TODO - send language test in socket message
    return false;
//    return _tamilPattern.hasMatch(input);
  }
}
