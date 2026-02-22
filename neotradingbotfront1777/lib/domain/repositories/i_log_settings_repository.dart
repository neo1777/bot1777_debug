import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/domain/entities/log_settings.dart';

abstract class ILogSettingsRepository {
  Future<Either<Failure, LogSettings>> getLogSettings();
  Future<Either<Failure, LogSettings>> updateLogSettings(LogSettings settings);
}
