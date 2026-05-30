import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _username;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get username => _username;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Simular retraso de red de 1.5 segundos
    await Future.delayed(const Duration(milliseconds: 1500));

    final trimmedEmail = email.trim();
    final trimmedPassword = password.trim();

    if (trimmedEmail.isEmpty || trimmedPassword.isEmpty) {
      _errorMessage = "Por favor, complete todos los campos.";
      _isLoading = false;
      notifyListeners();
      return false;
    }

    // Credenciales predefinidas para propósitos de prueba
    if (trimmedEmail == 'admin@gmail.com' && trimmedPassword == 'admin123') {
      _isAuthenticated = true;
      _username = "Administrador";
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage =
          "Credenciales incorrectas. Intente con admin@gmail.com / admin123";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _isAuthenticated = false;
    _username = null;
    notifyListeners();
  }

  Future<bool> sendResetCode(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Simular retraso de red de 1.5 segundos
    await Future.delayed(const Duration(milliseconds: 1500));

    final trimmedEmail = email.trim();

    if (trimmedEmail.isEmpty) {
      _errorMessage = "Por favor, ingrese su correo electrónico.";
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Simular retraso de red de 1.5 segundos
    await Future.delayed(const Duration(milliseconds: 1500));

    final trimmedCode = code.trim();
    final trimmedPassword = newPassword.trim();

    if (trimmedCode.isEmpty || trimmedPassword.isEmpty) {
      _errorMessage = "Por favor, complete todos los campos.";
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (trimmedCode.length != 6) {
      _errorMessage = "El código de seguridad debe tener 6 dígitos.";
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (trimmedPassword.length < 6) {
      _errorMessage = "La contraseña debe tener al menos 6 caracteres.";
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }
}
