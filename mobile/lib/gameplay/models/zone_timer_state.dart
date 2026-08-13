class ZoneTimerState {
  String title;
  DateTime? endsAt;
  int secondsRemaining;

  ZoneTimerState({
    this.title = "NEXT SHRINK",
    this.endsAt,
    this.secondsRemaining = 0,
  });
}
