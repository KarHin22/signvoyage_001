enum RecognizedGesture {
  thumbsUp,
  yeah,
  peace,
  ok,
  none;

  String get englishText {
    switch (this) {
      case RecognizedGesture.thumbsUp:
        return 'Thumbs up! Great job.';
      case RecognizedGesture.yeah:
        return 'Yeah!';
      case RecognizedGesture.peace:
        return 'Peace sign.';
      case RecognizedGesture.ok:
        return 'OK.';
      case RecognizedGesture.none:
        return '';
    }
  }
}

