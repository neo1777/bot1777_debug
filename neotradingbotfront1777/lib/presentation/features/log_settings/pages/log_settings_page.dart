import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neotradingbotfront1777/core/di/injection.dart';
import 'package:neotradingbotfront1777/domain/entities/log_settings.dart';
import 'package:neotradingbotfront1777/presentation/features/log_settings/bloc/log_settings_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/log_settings/bloc/log_settings_event.dart';
import 'package:neotradingbotfront1777/presentation/features/log_settings/bloc/log_settings_state.dart';

class LogSettingsPage extends StatelessWidget {
  const LogSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<LogSettingsBloc>()..add(LogSettingsFetched()),
      child: const LogSettingsView(),
    );
  }
}

class LogSettingsView extends StatelessWidget {
  const LogSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Settings')),
      body: BlocConsumer<LogSettingsBloc, LogSettingsState>(
        listener: (context, state) {
          if (state.status == LogSettingsStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Unknown error')),
            );
          }
        },
        builder: (context, state) {
          if (state.status == LogSettingsStatus.initial ||
              (state.status == LogSettingsStatus.loading &&
                  state.settings == null)) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.settings == null) {
            return const Center(child: Text('No settings available'));
          }

          final settings = state.settings!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildLogLevelSection(context, settings),
              const Divider(height: 32),
              _buildOutputSection(context, settings),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLogLevelSection(BuildContext context, LogSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Log Level', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        RadioGroup<LogLevel>(
          groupValue: settings.logLevel,
          onChanged: (value) {
            if (value != null) {
              context.read<LogSettingsBloc>().add(
                LogSettingsUpdated(settings.copyWith(logLevel: value)),
              );
            }
          },
          child: Column(
            children:
                LogLevel.values
                    .map(
                      (level) => RadioListTile<LogLevel>(
                        title: Text(level.value),
                        value: level,
                        // groupValue and onChanged are handled by RadioGroup
                      ),
                    )
                    .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildOutputSection(BuildContext context, LogSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Outputs', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Enable Console Logging'),
          value: settings.enableConsoleLogging,
          onChanged: (value) {
            context.read<LogSettingsBloc>().add(
              LogSettingsUpdated(
                settings.copyWith(enableConsoleLogging: value),
              ),
            );
          },
        ),
        SwitchListTile(
          title: const Text('Enable File Logging'),
          value: settings.enableFileLogging,
          onChanged: (value) {
            context.read<LogSettingsBloc>().add(
              LogSettingsUpdated(settings.copyWith(enableFileLogging: value)),
            );
          },
        ),
      ],
    );
  }
}
