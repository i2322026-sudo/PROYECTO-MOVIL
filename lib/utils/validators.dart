import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────
//  Validators — validaciones de formato reutilizables en toda
//  la app. Solo validan FORMA (no consultan RENIEC/SUNAT; esa
//  verificación real ya la hace el backend en
//  documento.controller.js contra apisperu.com).
//
//  Cada función devuelve null si es válido, o un String con el
//  mensaje de error a mostrar si no lo es — pensado para usarse
//  directo en el parámetro `validator` de un TextFormField, o
//  llamado a mano antes de enviar un formulario.
// ─────────────────────────────────────────────────────────────

class Validators {
  Validators._();

  /// DNI peruano: 8 dígitos, no puede empezar con 0.
  static String? dni(String? valor) {
    final v = (valor ?? '').trim();
    if (v.isEmpty) return 'Ingresa el DNI';
    if (!RegExp(r'^[1-9]\d{7}$').hasMatch(v)) {
      return 'El DNI debe tener 8 dígitos';
    }
    return null;
  }

  /// RUC peruano: 11 dígitos, empieza con 10/15/17/20, con
  /// dígito verificador (módulo 11) válido.
  static String? ruc(String? valor) {
    final v = (valor ?? '').trim();
    if (v.isEmpty) return 'Ingresa el RUC';
    if (!RegExp(r'^\d{11}$').hasMatch(v)) {
      return 'El RUC debe tener 11 dígitos';
    }
    if (!['10', '15', '17', '20'].contains(v.substring(0, 2))) {
      return 'El RUC debe empezar con 10, 15, 17 o 20';
    }
    if (!_rucDigitoVerificadorValido(v)) {
      return 'El RUC ingresado no es válido';
    }
    return null;
  }

  static bool _rucDigitoVerificadorValido(String ruc) {
    const factores = [5, 4, 3, 2, 7, 6, 5, 4, 3, 2];
    var suma = 0;
    for (var i = 0; i < 10; i++) {
      suma += int.parse(ruc[i]) * factores[i];
    }
    final resto = suma % 11;
    final digitoCalculado = resto <= 1 ? resto : 11 - resto;
    return digitoCalculado == int.parse(ruc[10]);
  }

  /// Celular peruano: 9 dígitos, siempre empieza con 9.
  /// (Misma regla que ya usa el backend: /^9\d{8}$/)
  static String? telefono(String? valor, {bool obligatorio = true}) {
    final v = (valor ?? '').trim();
    if (v.isEmpty) return obligatorio ? 'Ingresa el teléfono' : null;
    if (!v.startsWith('9')) return 'El número debe empezar con 9';
    if (v.length < 9) return 'Faltan dígitos';
    return null;
  }

  /// Correo electrónico: formato básico usuario@dominio.tld
  static String? correo(String? valor) {
    final v = (valor ?? '').trim();
    if (v.isEmpty) return 'Ingresa el correo';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
      return 'Ingresa un correo válido';
    }
    return null;
  }

  /// Contraseña: misma regla exacta que exige el backend
  /// (utils/passwordPolicy.js) — mínimo 8 caracteres, con letras,
  /// números y un carácter especial.
  static String? password(String? valor) {
    final v = valor ?? '';
    if (v.isEmpty) return 'Ingresa la contraseña';
    final regexFuerte = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$');
    if (!regexFuerte.hasMatch(v)) {
      return 'La contraseña debe tener al menos 8 caracteres, con letras, números y un carácter especial (ej: !@#\$%).';
    }
    return null;
  }

  /// Código OTP: exactamente 5 dígitos numéricos (formato usado
  /// en verificar_otp_login_screen y confirmar_otp_colaborador_screen).
  static String? otp(String? valor) {
    final v = (valor ?? '').trim();
    if (v.isEmpty) return 'Ingresa el código';
    if (!RegExp(r'^\d{5}$').hasMatch(v)) {
      return 'El código debe tener 5 dígitos';
    }
    return null;
  }

  /// Precio: número positivo mayor a 0.
  static String? precio(String? valor) {
    final v = (valor ?? '').trim();
    if (v.isEmpty) return 'Ingresa el precio';
    final n = double.tryParse(v);
    if (n == null) return 'Ingresa un precio válido';
    if (n <= 0) return 'El precio debe ser mayor a 0';
    return null;
  }

  /// Stock: entero mayor o igual a 0. Vacío es válido (se asume 0).
  static String? stock(String? valor) {
    final v = (valor ?? '').trim();
    if (v.isEmpty) return null;
    final n = int.tryParse(v);
    if (n == null) return 'Ingresa un número entero';
    if (n < 0) return 'El stock no puede ser negativo';
    return null;
  }

  /// Código de barras: 8, 12 o 13 dígitos (EAN-8, UPC-A, EAN-13).
  static String? codigoBarra(String? valor, {bool obligatorio = false}) {
    final v = (valor ?? '').trim();
    if (v.isEmpty) return obligatorio ? 'Ingresa el código de barras' : null;
    if (!RegExp(r'^\d{8}$|^\d{12}$|^\d{13}$').hasMatch(v)) {
      return 'El código de barras debe tener 8, 12 o 13 dígitos';
    }
    return null;
  }

  /// Nombre o apellido: solo letras (con tildes/ñ) y espacios,
  /// mínimo 2 caracteres.
  static String? nombre(String? valor, {String campo = 'Este campo'}) {
    final v = (valor ?? '').trim();
    if (v.isEmpty) return 'Ingresa $campo';
    if (v.length < 2) return '$campo debe tener al menos 2 caracteres';
    if (!RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ ]+$").hasMatch(v)) {
      return '$campo solo puede tener letras';
    }
    return null;
  }

  /// Confirma que la contraseña nueva y su confirmación coincidan.
  static String? confirmarPassword(String? nueva, String? confirmacion) {
    if (nueva != confirmacion) return 'Las contraseñas no coinciden';
    return null;
  }

  // ─────────────────────────────────────────────────────────
  //  inputFormatters — bloquean la escritura inválida EN EL
  //  MOMENTO (no solo avisan después de tocar "Guardar").
  //  Se pasan al parámetro `inputFormatters` de CampoTexto.
  // ─────────────────────────────────────────────────────────

  /// Celular peruano mientras se escribe: solo dígitos, máximo 9.
  /// (El "debe empezar con 9" se avisa como error debajo del campo,
  /// no se bloquea al teclear — si no, un número viejo guardado que
  /// empieza distinto queda imposible de corregir escribiendo.)
  static List<TextInputFormatter> formatoCelular = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(9),
  ];

  /// DNI peruano mientras se escribe: solo dígitos, máximo 8.
  static List<TextInputFormatter> formatoDni = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(8),
  ];

  /// Nombre/apellido mientras se escribe: bloquea números y
  /// símbolos, solo deja letras (con tildes/ñ) y espacios.
  static List<TextInputFormatter> formatoNombre = [
    FilteringTextInputFormatter.allow(RegExp(r"[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ ]")),
  ];
}
