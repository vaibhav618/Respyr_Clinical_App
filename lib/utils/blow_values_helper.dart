class BlowValuesHelper{
  String getBlowString(List<double> values) {
    return values.map((e) => e.toStringAsFixed(2)).join(',');
  }
}