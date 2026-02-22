import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/settings_repository.dart';

class GetSettings {
  final SettingsRepository _repository;
  GetSettings(this._repository);

  Future<Either<Failure, AppSettings>> call() {
    return _repository.getSettings();
  }
}
