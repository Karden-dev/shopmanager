// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wink_merchant/providers/auth_provider.dart';
import 'package:wink_merchant/utils/wink_theme.dart'; // Remplacement de AppTheme

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  
  // Contrôleurs pour les 4 chiffres du PIN
  final TextEditingController _pin1Controller = TextEditingController();
  final TextEditingController _pin2Controller = TextEditingController();
  final TextEditingController _pin3Controller = TextEditingController();
  final TextEditingController _pin4Controller = TextEditingController();

  final FocusNode _phoneFocus = FocusNode();
  final List<FocusNode> _pinFocusNodes = List.generate(4, (index) => FocusNode());

  bool _isLoading = false;
  String? _errorMessage;
  bool _rememberMe = true; 

  @override
  void dispose() {
    _phoneController.dispose();
    _pin1Controller.dispose();
    _pin2Controller.dispose();
    _pin3Controller.dispose();
    _pin4Controller.dispose();
    _phoneFocus.dispose();
    for (var node in _pinFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String _getPin() {
    return _pin1Controller.text + _pin2Controller.text + _pin3Controller.text + _pin4Controller.text;
  }
  
  void _pinInputHandler(String value, int index) {
    if (value.length == 1) {
      if (index < 3) {
        _pinFocusNodes[index + 1].requestFocus();
      } else {
        _pinFocusNodes[index].unfocus(); 
      }
    } else if (value.isEmpty && index > 0) {
      _pinFocusNodes[index - 1].requestFocus();
    }
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  Future<void> _login() async {
    final pin = _getPin();

    if (_phoneController.text.isEmpty) {
       setState(() => _errorMessage = 'Numéro de téléphone requis.');
       return;
    }

    if (pin.length != 4) {
      setState(() {
        _errorMessage = 'Veuillez entrer un code PIN à 4 chiffres.';
      });
      if (_pin1Controller.text.isEmpty) _pinFocusNodes[0].requestFocus();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Adaptation : On utilise AuthProvider du projet Marchand
      await Provider.of<AuthProvider>(context, listen: false).login(
        _phoneController.text.trim(),
        pin,
      );
      
      // La redirection est gérée automatiquement par main.dart

    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Widget helper pour une case de PIN
  Widget _buildPinInput(TextEditingController controller, FocusNode focusNode, int index) {
    return SizedBox(
      width: 60,
      height: 60,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        obscureText: true,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none, 
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: WinkTheme.primary, width: 2.0),
          ),
        ),
        onChanged: (value) => _pinInputHandler(value, index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fond blanc identique
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              
              // --- LOGO ---
              // Assurez-vous d'avoir ajouté l'image dans pubspec.yaml assets!
              Image.asset(
                'assets/images/logo.png',
                height: 100,
                errorBuilder: (c,e,s) => const Icon(Icons.store_mall_directory, size: 80, color: WinkTheme.primary), // Fallback si pas d'image
              ),

              const SizedBox(height: 40),
              
              Text(
                'Espace Marchand', // Seule différence de texte
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87, 
                ),
              ),
              const SizedBox(height: 40),
              
              // --- TÉLÉPHONE ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Numéro de téléphone', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                  const SizedBox(height: 8), 
                  TextField(
                    controller: _phoneController,
                    focusNode: _phoneFocus,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration( 
                      hintText: '',
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      // Adaptation des couleurs avec WinkTheme
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), 
                        borderSide: BorderSide(color: Colors.grey.shade300)
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), 
                        borderSide: const BorderSide(color: WinkTheme.primary, width: 2)
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onSubmitted: (_) => _pinFocusNodes[0].requestFocus(),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 5.0, left: 16.0),
                    child: Text('Ex: 650724683', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                ],
              ),
              const SizedBox(height: 25), 

              // --- PIN (4 CASES) ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Code PIN', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                    children: [
                      _buildPinInput(_pin1Controller, _pinFocusNodes[0], 0),
                      _buildPinInput(_pin2Controller, _pinFocusNodes[1], 1),
                      _buildPinInput(_pin3Controller, _pinFocusNodes[2], 2),
                      _buildPinInput(_pin4Controller, _pinFocusNodes[3], 3),
                    ],
                  ),
                ],
              ),

              // --- ERREUR ---
              if (_errorMessage != null) 
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 10),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold), // Rouge direct
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 30), 

              // --- BOUTON ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15), 
                    backgroundColor: WinkTheme.primary, // Orange Wink
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('SE CONNECTER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), 
                ),
              ),
              
              const SizedBox(height: 20),
              
              // --- OPTIONS ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (newValue) {
                      setState(() {
                        _rememberMe = newValue ?? true;
                      });
                    },
                    activeColor: WinkTheme.primary,
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _rememberMe = !_rememberMe),
                    child: const Text("Se souvenir de moi", style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),
              
              const SizedBox(height: 15),

              Center(
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Contactez le support Wink.")));
                  },
                  child: const Text( 
                    'Code PIN oublié ?',
                    style: TextStyle(
                      color: WinkTheme.primary, 
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}