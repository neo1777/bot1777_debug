import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/entities/log_settings.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/log_settings_repository.dart';

class GetLogSettings {
  final LogSettingsRepository _repository;

  GetLogSettings(this._repository);

  Future<Either<Failure, LogSettings>> call() {
    return _repository.getSettings();
  }
}
