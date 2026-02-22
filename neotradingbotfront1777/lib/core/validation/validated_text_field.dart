import 'package:flutter/material.dart';
import 'input_validator.dart';

/// A text field with built-in validation
class ValidatedTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final String? initialValue;
  final ValidationType validationType;
  final Function(String)? onChanged;
  final Function(String)? onValidated;
  final Function(String)? onValidationError;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final EdgeInsetsGeometry? contentPadding;
  final InputBorder? border;
  final InputBorder? enabledBorder;
  final InputBorder? focusedBorder;
  final InputBorder? errorBorder;
  final InputBorder? focusedErrorBorder;
  final Color? fillColor;
  final bool filled;

  const ValidatedTextField({
    required this.label,
    required this.validationType,
    Key? key,
    this.hint,
    this.initialValue,
    this.onChanged,
    this.onValidated,
    this.onValidationError,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.contentPadding,
    this.border,
    this.enabledBorder,
    this.focusedBorder,
    this.errorBorder,
    this.focusedErrorBorder,
    this.fillColor,
    this.filled = false,
  }) : super(key: key);

  @override
  State<ValidatedTextField> createState() => _ValidatedTextFieldState();

  // Public methods to access the state
  bool get isValid {
    final state = (key as GlobalKey<_ValidatedTextFieldState>?)?.currentState;
    return state?._isValid ?? false;
  }

  String get text {
    final state = (key as GlobalKey<_ValidatedTextFieldState>?)?.currentState;
    return state?._controller.text ?? '';
  }

  void clear() {
    final state = (key as GlobalKey<_ValidatedTextFieldState>?)?.currentState;
    state?._controller.clear();
    state?._validateInput('');
  }
}

class _ValidatedTextFieldState extends State<ValidatedTextField> {
  late TextEditingController _controller;
  String? _errorText;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');

    // Validate initial value if provided
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      _validateInput(widget.initialValue!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateInput(String value) {
    final result = _performValidation(value);

    setState(() {
      _isValid = result.isValid;
      _errorText = result.isValid ? null : result.errorMessage;
    });

    if (result.isValid) {
      widget.onValidated?.call(result.value.toString());
    } else {
      widget.onValidationError?.call(result.errorMessage ?? '');
    }
  }

  ValidationResult _performValidation(String value) {
    switch (widget.validationType) {
      case ValidationType.tradingAmount:
        return InputValidator.validateTradingAmount(value);
      case ValidationType.percentage:
        return InputValidator.validatePercentage(value);
      case ValidationType.symbol:
        return InputValidator.validateSymbol(value);
      case ValidationType.quantity:
        return InputValidator.validateQuantity(value);
      case ValidationType.price:
        return InputValidator.validatePrice(value);
      case ValidationType.integer:
        return InputValidator.validateInteger(value);
      case ValidationType.boolean:
        return InputValidator.validateBoolean(value);
      case ValidationType.email:
        return InputValidator.validateEmail(value);
      case ValidationType.apiKey:
        return InputValidator.validateApiKey(value);
      case ValidationType.none:
        return ValidationResult.success(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        errorText: _errorText,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.suffixIcon,
        border: widget.border,
        enabledBorder: widget.enabledBorder,
        focusedBorder: widget.focusedBorder,
        errorBorder: widget.errorBorder,
        focusedErrorBorder: widget.focusedErrorBorder,
        contentPadding: widget.contentPadding,
        fillColor: widget.fillColor,
        filled: widget.filled,
        counterText: widget.maxLength != null ? null : '',
      ),
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      enabled: widget.enabled,
      onChanged: (value) {
        _validateInput(value);
        widget.onChanged?.call(value);
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '${widget.label} is required';
        }
        final result = _performValidation(value);
        return result.isValid ? null : result.errorMessage;
      },
    );
  }

  /// Get the current validation state
  bool get isValid => _isValid;

  /// Get the current error text
  String? get errorText => _errorText;

  /// Get the current text value
  String get text => _controller.text;

  /// Set the text value programmatically
  void setText(String value) {
    _controller.text = value;
    _validateInput(value);
  }

  /// Clear the text field
  void clear() {
    _controller.clear();
    setState(() {
      _isValid = false;
      _errorText = null;
    });
  }
}

/// Types of validation available
enum ValidationType {
  tradingAmount,
  percentage,
  symbol,
  quantity,
  price,
  integer,
  boolean,
  email,
  apiKey,
  none,
}

/// A form with built-in validation for multiple fields
class ValidatedForm extends StatefulWidget {
  final Map<String, ValidatedTextField> fields;
  final Widget Function(Map<String, dynamic> validatedData)? builder;
  final VoidCallback? onFormValid;
  final VoidCallback? onFormInvalid;
  final Widget? submitButton;
  final VoidCallback? onSubmit;

  const ValidatedForm({
    required this.fields,
    Key? key,
    this.builder,
    this.onFormValid,
    this.onFormInvalid,
    this.submitButton,
    this.onSubmit,
  }) : super(key: key);

  @override
  State<ValidatedForm> createState() => _ValidatedFormState();
}

class _ValidatedFormState extends State<ValidatedForm> {
  final Map<String, bool> _fieldValidity = {};
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _initializeFieldValidity();
  }

  void _initializeFieldValidity() {
    for (final fieldName in widget.fields.keys) {
      _fieldValidity[fieldName] = false;
    }
  }

  void _updateFieldValidity(String fieldName, bool isValid) {
    setState(() {
      _fieldValidity[fieldName] = isValid;
      _isFormValid = _fieldValidity.values.every((valid) => valid);
    });

    if (_isFormValid) {
      widget.onFormValid?.call();
    } else {
      widget.onFormInvalid?.call();
    }
  }

  Map<String, dynamic> _getValidatedData() {
    final data = <String, dynamic>{};
    for (final entry in widget.fields.entries) {
      final fieldName = entry.key;
      final field = entry.value;
      if (field.isValid) {
        data[fieldName] = field.text;
      }
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...widget.fields.entries.map((entry) {
          final fieldName = entry.key;
          final field = entry.value;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ValidatedTextField(
              key: ValueKey(fieldName),
              label: field.label,
              hint: field.hint,
              initialValue: field.initialValue,
              validationType: field.validationType,
              keyboardType: field.keyboardType,
              obscureText: field.obscureText,
              prefixIcon: field.prefixIcon,
              suffixIcon: field.suffixIcon,
              maxLines: field.maxLines,
              maxLength: field.maxLength,
              enabled: field.enabled,
              contentPadding: field.contentPadding,
              border: field.border,
              enabledBorder: field.enabledBorder,
              focusedBorder: field.focusedBorder,
              errorBorder: field.errorBorder,
              focusedErrorBorder: field.focusedErrorBorder,
              fillColor: field.fillColor,
              filled: field.filled,
              onChanged: field.onChanged,
              onValidated: (value) {
                _updateFieldValidity(fieldName, true);
                field.onValidated?.call(value);
              },
              onValidationError: (error) {
                _updateFieldValidity(fieldName, false);
                field.onValidationError?.call(error);
              },
            ),
          );
        }).toList(),

        if (widget.builder != null) widget.builder!(_getValidatedData()),

        if (widget.submitButton != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Opacity(
              opacity: _isFormValid ? 1.0 : 0.5,
              child: widget.submitButton!,
            ),
          ),
      ],
    );
  }

  /// Get the current form validation state
  bool get isFormValid => _isFormValid;

  /// Get all validated data
  Map<String, dynamic> get validatedData => _getValidatedData();

  /// Reset all fields
  void resetForm() {
    for (final field in widget.fields.values) {
      field.clear();
    }
    _initializeFieldValidity();
    setState(() {
      _isFormValid = false;
    });
  }
}
