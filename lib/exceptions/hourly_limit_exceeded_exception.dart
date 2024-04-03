class HourlyLimitExceededException implements Exception {
  final String message;
  HourlyLimitExceededException([this.message = 'Prekoračili ste limit objave oglasa po satu!']);

  @override
  String toString() => message;
}

class GeneralUploadException implements Exception {
  final String message;
  GeneralUploadException([this.message = 'Generalna greška prilikom objavljivanja.']);

  @override
  String toString() => message;
}
