enum RecognizedGesture {
  peace,
  goodJob,
  bad,
  goodbye,
  letterA,
  letterC,
  letterD,
  letterI,
  letterL,
  letterY,
  none;

  String get englishText {
    switch (this) {
      case RecognizedGesture.peace:
        return 'Peace sign';
      case RecognizedGesture.goodJob:
        return 'Good job';
      case RecognizedGesture.bad:
        return 'Bad';
      case RecognizedGesture.goodbye:
        return 'Goodbye';
      case RecognizedGesture.letterA:
        return 'A';
      case RecognizedGesture.letterC:
        return 'C';
      case RecognizedGesture.letterD:
        return 'D';
      case RecognizedGesture.letterI:
        return 'I';
      case RecognizedGesture.letterL:
        return 'L';
      case RecognizedGesture.letterY:
        return 'Y';
      case RecognizedGesture.none:
        return '';
    }
  }
}

