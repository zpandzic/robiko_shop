class NuicCsv {
  String katBroj;
  String barcode;
  String nazivRobe;
  double vpc;
  double mpc;

  NuicCsv({
    required this.katBroj,
    required this.barcode,
    required this.nazivRobe,
    required this.vpc,
    required this.mpc,
  });

  factory NuicCsv.fromCsvRow(List<dynamic> row, Map<String, int> columnIndexes) {
    return NuicCsv(
      katBroj: row[columnIndexes['Kataloški broj']!].toString(),
      barcode: row[columnIndexes['Barcode']!].toString(),
      nazivRobe: row[columnIndexes['Naziv robe']!].toString(),
      vpc: double.tryParse(
          row[columnIndexes['VPC']!].toString().replaceAll(',', '.')) ??
          0.0,
      mpc: double.tryParse(
          row[columnIndexes['MPC']!].toString().replaceAll(',', '.')) ??
          0.0,
    );
  }
}
