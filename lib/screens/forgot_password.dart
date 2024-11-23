import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../consts/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController cityController = TextEditingController();
  final TextEditingController bookController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController studentController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  String? errorText;

  bool _isPasswordVisible = false;

  Future<void> resetPassword() async {

    final userCredentialsBox = await Hive.openBox<Map>('userCredentials');

    if (cityController.text == "Rawalpindi" &&
        bookController.text == "Criminology" &&
        dobController.text == "29.11.1995" &&
        studentController.text == "Ayesha") {
      await userCredentialsBox.put('3810301109757', {
        'password': newPasswordController.text,
      });
      Navigator.pop(context);
    } else {
      setState(() {
        errorText = "Incorrect answers. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainColor,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: AppColors.secondaryColor,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Reset Password",
                  style: TextStyle(
                    color: AppColors.secondaryColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Answer the following questions to reset your password:",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _buildStyledTextField(cityController, "City"),
                const SizedBox(height: 20),
                _buildStyledTextField(bookController, "Special Book"),
                const SizedBox(height: 20),
                _buildStyledTextField(dobController, "Date of Birth"),
                const SizedBox(height: 20),
                _buildStyledTextField(studentController, "Student"),
                const SizedBox(height: 20),
                _buildPasswordTextField(newPasswordController, "New Password"),
                if (errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      errorText!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text(
                    "Reset Password",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  onPressed: resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStyledTextField(
      TextEditingController controller,
      String hintText, {
        bool isPassword = false,
      }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white),
        filled: true,
        fillColor: AppColors.secondaryColor.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildPasswordTextField(
      TextEditingController controller, String hintText) {
    return TextField(
      controller: controller,
      obscureText: !_isPasswordVisible,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white),
        filled: true,
        fillColor: AppColors.secondaryColor.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
      ),
    );
  }
}
