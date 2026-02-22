import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/entities/log_settings.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/log_settings_repository.dart';

class UpdateLogSettings {
  final LogSettingsRepository _repository;

  UpdateLogSettings(this._repository);

  Future<Either<Failure, void>> call(LogSettings settings) {
    return _repository.saveSettings(settings);
  }
}
