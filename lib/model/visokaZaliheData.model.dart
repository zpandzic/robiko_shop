class VisokaZalihe {
  int rbr;
  String sifraRobe;
  String barcode;
  String katBroj;
  String nazivRobe;
  String jmj;
  int stanje;
  double mpc;

  VisokaZalihe({
    required this.rbr,
    required this.sifraRobe,
    required this.barcode,
    required this.katBroj,
    required this.nazivRobe,
    required this.jmj,
    required this.stanje,
    required this.mpc,
  });

  factory VisokaZalihe.fromCsvRow(
      List<dynamic> row, Map<String, int> columnIndexes) {
    // Rbr.;MT;NadGrupa;Grupa;Šifra robe;Barcode;KatBroj;Naziv robe;Dob;NazivDob;Polica;Pretinac;JMJ;Stanje;PNBC;VPC;MPC;TD_Sifra;TD_ID;Top;Akt

    return VisokaZalihe(
      rbr: int.tryParse(row[columnIndexes['Rbr.']!].toString()) ?? 0,
      sifraRobe: row[columnIndexes['Šifra robe']!].toString(),
      barcode: row[columnIndexes['Barcode']!].toString(),
      katBroj: row[columnIndexes['KatBroj']!].toString(),
      nazivRobe: row[columnIndexes['Naziv robe']!].toString(),
      jmj: row[columnIndexes['JMJ']!].toString(),
      stanje: int.tryParse(row[columnIndexes['Stanje']!].toString()) ?? 0,
      mpc: double.tryParse(
              row[columnIndexes['MPC']!].toString().replaceAll(',', '.')) ??
          0.0,
    );
  }

  // factory VisokaZalihe.fromCsvRow(List<dynamic> row) {
  //   return VisokaZalihe(
  //     rbr: int.tryParse(row[0].toString()) ?? 0,
  //     sifraRobe: row[1].toString(),
  //     barcode: row[2].toString(),
  //     katBroj: row[3].toString(),
  //     nazivRobe: row[4].toString(),
  //     jmj: row[5].toString(),
  //     stanje: int.tryParse(row[6].toString()) ?? 0,
  //     mpc: double.tryParse(row[7].toString().replaceAll(',', '.')) ?? 0.0,
  //   );
  // }
}
