// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:google_fonts/google_fonts.dart'; // Add this line
// import 'dart:io'; // for File
// import 'package:image_picker/image_picker.dart';
// class RegistrationScreen extends StatelessWidget {
//   const RegistrationScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return const CreateAccountScreen();
//   }
// }
// class CreateAccountScreen extends StatefulWidget {
//   const CreateAccountScreen({super.key});
//
//   @override
//   State<CreateAccountScreen> createState() => _CreateAccountScreenState();
// }
// class _CreateAccountScreenState extends State<CreateAccountScreen> {
//   File? driverImage;
//   File? licenseImage;
//   File? nationalIdImage;
//
//   String? selectedCarType; // will be 'Comfort', 'Premium' or 'Business'
//
//   final ImagePicker _picker = ImagePicker();
//   final _formKey = GlobalKey<FormState>();
//   String selectedRole = 'Passenger';
//   bool isLoading = false;
//   bool acceptedTerms = false;
//   bool obscurePassword = true;
//   bool obscureConfirmPassword = true;
//
//   final nameController = TextEditingController();
//   final emailController = TextEditingController();
//   final phoneController = TextEditingController();
//   final carModelController = TextEditingController();
//   final carNumberController = TextEditingController();
//   final carTypeController = TextEditingController();
//   final licenseController = TextEditingController();
//   final passwordController = TextEditingController();
//   final confirmPasswordController = TextEditingController();
//   final nationalIdController = TextEditingController();
//
//   void showMessage(String msg, [Color color = Colors.red]) {
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
//   }
//
//
//   Map<String, dynamic> createRequestBody() {
//     final body = {
//       "name": nameController.text.trim(),
//       "email": emailController.text.trim().toLowerCase(),
//       "phone": phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), ''),
//       "password": passwordController.text.trim(),
//       "role": selectedRole == 'Passenger' ? 'rider' : 'driver',
//     };
//     if (selectedRole == 'Driver') {
//       body.addAll({
//         "nationalId": nationalIdController.text.trim(),
//         "carModel": carModelController.text.trim(),
//         "carNumber": carNumberController.text.trim(),
//         "carType": selectedCarType ?? "",                   // ← use the dropdown value        "licenseNumber": licenseController.text.trim(),
//       });
//     }
//
//     return body;
//   }
//
// // 1. Simplified Single API Call
// // 1. Single API Call that waits for Render to wake up
//   Future<void> _makeSingleApiCall(Map<String, dynamic> body) async {
//     final url = Uri.parse("https://sizemoretaxi-itpj.onrender.com/api/auth/register");
//
//     // Create a persistent client to prevent connection drops during Render spin-up
//     final client = http.Client();
//
//     try {
//       final response = await client.post(
//         url,
//         headers: {
//           'Content-Type': 'application/json',
//           'Accept': 'application/json', // Explicitly ask for JSON
//         },
//         body: jsonEncode(body),
//       );
//
//       final responseData = jsonDecode(response.body);
//
//       // Check for both 200 (OK) and 201 (Created)
//       if (response.statusCode == 201 || response.statusCode == 200) {
//         if (!mounted) return;
//
//         showMessage("Registration successful. OTP sent.", Colors.green);
//
//         await Future.delayed(const Duration(seconds: 2));
//
//         Navigator.pushNamed(
//           context,
//           '/login',
//           arguments: {
//             'email': emailController.text.trim(),
//             'role': selectedRole == 'Passenger' ? 'rider' : 'driver',
//           },
//         );
//       } else {
//         // If the user already exists, the server SHOULD return 400 or 409
//         final errorMessage = responseData['message'] ?? 'Registration failed';
//         throw Exception(errorMessage);
//       }
//     } catch (e) {
//       // If it fails because the user was created "long ago" in a previous hang,
//       // the error message from the server will likely be "User already exists".
//       throw Exception(e.toString().replaceAll('Exception: ', ''));
//     } finally {
//       client.close(); // Always close the client
//     }
//   }
//
//   // 2. Updated Register Function
//   Future<void> register() async {
//     if (!_formKey.currentState!.validate()) return;
//     if (!acceptedTerms) {
//       showMessage("Please accept terms and conditions");
//       return;
//     }
//     if (passwordController.text != confirmPasswordController.text) {
//       showMessage("Passwords don't match");
//       return;
//     }if (selectedRole == 'Driver') {
//       if (driverImage == null) {
//         showMessage("Please upload driver photo");
//         return;
//       }
//       if (licenseImage == null) {
//         showMessage("Please upload driving license photo");
//         return;
//       }
//       if (selectedCarType == null) {
//         showMessage("Please select car type");
//         return;
//       }
//     }
//
//     setState(() => isLoading = true);
//
//     try {
//       final body = createRequestBody();
//       // This will now wait until the server responds
//       await _makeSingleApiCall(body);
//     } catch (e) {
//       // Clear passwords on error so user can re-try safely
//       passwordController.clear();
//       confirmPasswordController.clear();
//       showMessage(e.toString().replaceAll('Exception: ', ''));
//     } finally {
//       // Only stop loading if we are still on this screen
//       if (mounted) {
//         setState(() => isLoading = false);
//       }
//     }
//   }
//
//   Future<void> _pickDriverImage() async {
//     try {
//       final XFile? pickedFile = await showModalBottomSheet<XFile?>(
//         context: context,
//         builder: (context) => Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(
//               leading: const Icon(Icons.camera_alt),
//               title: const Text('Take Photo'),
//               onTap: () async {
//                 final file = await _picker.pickImage(source: ImageSource.camera);
//                 Navigator.pop(context, file);
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.photo_library),
//               title: const Text('Choose from Gallery'),
//               onTap: () async {
//                 final file = await _picker.pickImage(source: ImageSource.gallery);
//                 Navigator.pop(context, file);
//               },
//             ),
//           ],
//         ),
//       );
//
//       if (pickedFile != null) {
//         setState(() {
//           driverImage = File(pickedFile.path);
//         });
//       }
//     } catch (e) {
//       showMessage("Error picking driver image: $e", Colors.orange);
//     }
//   }
//
//   Future<void> _pickLicenseImage() async {
//     // Same logic as above, just for license
//     try {
//       final XFile? pickedFile = await showModalBottomSheet<XFile?>(
//         context: context,
//         builder: (context) => Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(
//               leading: const Icon(Icons.camera_alt),
//               title: const Text('Take Photo'),
//               onTap: () async {
//                 final file = await _picker.pickImage(source: ImageSource.camera);
//                 Navigator.pop(context, file);
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.photo_library),
//               title: const Text('Choose from Gallery'),
//               onTap: () async {
//                 final file = await _picker.pickImage(source: ImageSource.gallery);
//                 Navigator.pop(context, file);
//               },
//             ),
//           ],
//         ),
//       );
//
//       if (pickedFile != null) {
//         setState(() {
//           licenseImage = File(pickedFile.path);
//         });
//       }
//     } catch (e) {
//       showMessage("Error picking license image: $e", Colors.orange);
//     }
//   }
//   Future<void> _pickNationalIdImage() async {
//     try {
//       final XFile? pickedFile = await showModalBottomSheet<XFile?>(
//         context: context,
//         builder: (context) => Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(
//               leading: const Icon(Icons.camera_alt),
//               title: const Text('Take Photo'),
//               onTap: () async {
//                 final file = await _picker.pickImage(
//                   source: ImageSource.camera,
//                 );
//                 Navigator.pop(context, file);
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.photo_library),
//               title: const Text('Choose from Gallery'),
//               onTap: () async {
//                 final file = await _picker.pickImage(
//                   source: ImageSource.gallery,
//                 );
//                 Navigator.pop(context, file);
//               },
//             ),
//           ],
//         ),
//       );
//
//       if (pickedFile != null) {
//         setState(() {
//           nationalIdImage = File(pickedFile.path);
//         });
//       }
//     } catch (e) {
//       showMessage("Error picking National ID image: $e", Colors.orange);
//     }
//   }
//   @override
//   Widget build(BuildContext context) {
//     // Define our new theme colors locally for easy editing
//     const primaryCyan = Color(0xFF22D3EE);
//     const deepBackground = Color(0xFF0F172A);
//     const surfaceSlate = Color(0xFF1E293B);
//
//     return Scaffold(
//       backgroundColor: deepBackground,
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: RadialGradient(
//               center: Alignment(0, -0.6),
//               radius: 1.2,
//               colors: [
//                 Color(0xFF16283E),
//                 Color(0xFF0F172A),
//               ],
//               stops: [0.0, 0.6]
//           )
//         ),
//         child: SingleChildScrollView(
//           physics: const BouncingScrollPhysics(),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               children: [
//                 const SizedBox(height: 50),
//
//                 // Header Section
//                 Text(
//                   'Create Account',
//                   style: GoogleFonts.spaceGrotesk( // Using a modern tech font if available
//                     color: Colors.white,
//                     fontSize: 32,
//                     fontWeight: FontWeight.bold,
//                     letterSpacing: -0.5,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   'Join the future of taxi services',
//                   style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
//                 ),
//
//                 const SizedBox(height: 30),
//
// // Column(
// //   children: [
// //     Container(
// //       height: 120,
// //       width: 120,
// //       decoration: BoxDecoration(
// //         shape: BoxShape.circle,
// //         color: const Color(0xFF008080),
// //         border: Border.all(
// //           color: primaryCyan.withOpacity(0.3),
// //           width: 1.5,
// //
// //         ),
// //         boxShadow: [
// //           BoxShadow(
// //             color: const Color(0xFF008080).withOpacity(0.3),
// //           blurRadius: 30,
// //             spreadRadius: 2,
// //           ),
// //         ],
// //
// //
// //
// //       ),
// //       child: ClipRRect(
// //         borderRadius: BorderRadius.circular(60),
// //         child: Padding(
// //           padding: const EdgeInsets.all(18),
// //           child: Image.asset(
// //             'assets/images/logo.png',
// //             fit: BoxFit.contain,
// //             errorBuilder: (context, error, stackTrace) => const Icon(
// //               Icons.local_taxi_rounded,
// //               size:50,
// //               color: primaryCyan,
// //             ),
// //           ),
// //         ),
// //       ),
// //     ),
// // const SizedBox(height: 15),
// //     Text(
// //       'SIZEMORETAXI',
// //       style: GoogleFonts.montserrat(
// //         color: Colors.white,
// //         fontSize: 22,
// //         fontWeight: FontWeight.w900,
// //         letterSpacing: 4.0,
// //       ),
// //     ),
// //   ],
// // ),
//                 Column(
//                   children: [
//                     const _LogoHeader(),
//                     const SizedBox(height: 15),
//                     Text(
//                       'SIZEMORETAXI',
//                       style: GoogleFonts.montserrat(
//                         color: Colors.white,
//                         fontSize: 22,
//                         fontWeight: FontWeight.w900,
//                         letterSpacing: 4.0,
//                       ),
//                     ),
//                   ],
//                 ),
//
//                 const SizedBox(height: 30),
//
//                 // Role Selector
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                   child: RoleSelector(
//                     selectedRole: selectedRole,
//                     onRoleChanged: (role) => setState(() => selectedRole = role),
//                     // Note: Ensure your RoleSelector widget uses the new primaryCyan
//                     // for its selected state background!
//                   ),
//                 ),
//
//                 const SizedBox(height: 10),
//
//
//                 // Form Input Fields
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 8),
//                   child: Column(
//                     children: [
//                       inputField("Full Name", nameController, icon: Icons.person_outline),
//                       inputField("Email Address", emailController, icon: Icons.email_outlined),
//                       inputField(
//                         "Phone Number",
//                         phoneController,
//                         icon: Icons.phone_android_outlined,
//                         helperText: "Format: 07xxxxxxxx",
//                       ),
//
//                       if (selectedRole == 'Driver') ...[
//                         inputField("Car Model", carModelController, icon: Icons.directions_car_filled_outlined),
//                         inputField("Car Number", carNumberController, icon: Icons.numbers_outlined),
//                         // inputField("Car Type", carTypeController, icon: Icons.category_outlined),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 "  Car Type",
//                                 style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w600),
//                               ),
//                               const SizedBox(height: 6),
//                               DropdownButtonFormField<String>(
//                                 value: selectedCarType,
//                                 hint: Text(
//                                   "Select car type",
//                                   style: TextStyle(color: Colors.white.withOpacity(0.4)),
//                                 ),
//                                 dropdownColor: const Color(0xFF1E293B),
//                                 style: const TextStyle(color: Colors.white),
//                                 decoration: InputDecoration(
//                                   prefixIcon: Icon(Icons.category_outlined, color: const Color(0xFF22D3EE).withOpacity(0.5), size: 20),
//                                   filled: true,
//                                   fillColor: const Color(0xFF1E293B),
//                                   contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//                                   enabledBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(16),
//                                     borderSide: const BorderSide(color: Colors.white10),
//                                   ),
//                                   focusedBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(16),
//                                     borderSide: const BorderSide(color: Color(0xFF22D3EE), width: 1.5),
//                                   ),
//                                 ),
//                                 items: ['Comfort', 'Premium', 'Business'].map((type) {
//                                   return DropdownMenuItem<String>(
//                                     value: type,
//                                     child: Text(type),
//                                   );
//                                 }).toList(),
//                                 onChanged: (value) {
//                                   setState(() {
//                                     selectedCarType = value;
//                                   });
//                                 },
//                                 validator: (value) {
//                                   if (value == null) return 'Please select car type';
//                                   return null;
//                                 },
//                               ),
//                             ],
//                           ),
//                         ),
//
//
//                         inputField("License Number", licenseController, icon: Icons.badge_outlined),
//
//
//                       ],
//
//                       if (selectedRole == 'Driver') ...[
//                         // ... car model, number, type, license number
//
//                         const SizedBox(height: 16),
//
//                         // Driver Photo
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 16),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 "  Driver Photo",
//                                 style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w600),
//                               ),
//                               const SizedBox(height: 8),
//                               GestureDetector(
//                                 onTap: _pickDriverImage,
//                                 child: Container(
//                                   height: 140,
//                                   width: double.infinity,
//                                   decoration: BoxDecoration(
//                                     color: const Color(0xFF1E293B),
//                                     borderRadius: BorderRadius.circular(16),
//                                     border: Border.all(color: Colors.white10),
//                                   ),
//                                   child: driverImage == null
//                                       ? Column(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       Icon(Icons.add_a_photo, color: const Color(0xFF22D3EE), size: 40),
//                                       const SizedBox(height: 12),
//                                       Text(
//                                         "Tap to take/upload driver photo",
//                                         style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
//                                       ),
//                                     ],
//                                   )
//                                       : ClipRRect(
//                                     borderRadius: BorderRadius.circular(16),
//                                     child: Image.file(
//                                       driverImage!,
//                                       fit: BoxFit.cover,
//                                       width: double.infinity,
//                                       height: 140,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//
//                         const SizedBox(height: 24),
//
//                         // License Photo – same style
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 16),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 "  Driving License Photo",
//                                 style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w600),
//                               ),
//                               const SizedBox(height: 8),
//                               GestureDetector(
//                                 onTap: _pickLicenseImage,
//                                 child: Container(
//                                   height: 140,
//                                   width: double.infinity,
//                                   decoration: BoxDecoration(
//                                     color: const Color(0xFF1E293B),
//                                     borderRadius: BorderRadius.circular(16),
//                                     border: Border.all(color: Colors.white10),
//                                   ),
//                                   child: licenseImage == null
//                                       ? Column(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       Icon(Icons.card_membership, color: const Color(0xFF22D3EE), size: 40),
//                                       const SizedBox(height: 12),
//                                       Text(
//                                         "Tap to take/upload license photo",
//                                         style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
//                                       ),
//                                     ],
//                                   )
//                                       : ClipRRect(
//                                     borderRadius: BorderRadius.circular(16),
//                                     child: Image.file(
//                                       licenseImage!,
//                                       fit: BoxFit.cover,
//                                       width: double.infinity,
//                                       height: 140,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//
//                         const SizedBox(height: 24),
//
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 16),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 "  National ID Photo",
//                                 style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w600),
//                               ),
//                               const SizedBox(height: 8),
//                               GestureDetector(
//                                 onTap: _pickNationalIdImage,
//                                 child: Container(
//                                   height: 140,
//                                   width: double.infinity,
//                                   decoration: BoxDecoration(
//                                     color: const Color(0xFF1E293B),
//                                     borderRadius: BorderRadius.circular(16),
//                                     border: Border.all(color: Colors.white10),
//                                   ),
//                                   child: nationalIdImage == null
//                                       ? Column(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       Icon(Icons.badge_outlined, color: const Color(0xFF22D3EE), size: 40),
//                                       const SizedBox(height: 12),
//                                       Text(
//                                         "Tap to take/upload national ID photo",
//                                         style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
//                                       ),
//                                     ],
//                                   )
//                                       : ClipRRect(
//                                     borderRadius: BorderRadius.circular(16),
//                                     child: Image.file(
//                                       nationalIdImage!,
//                                       fit: BoxFit.cover,
//                                       width: double.infinity,
//                                       height: 140,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//
//
//                         const SizedBox(height: 16),
//                       ],
//
//
//
//                       inputField(
//                         "Password",
//                         passwordController,
//                         obscureText: obscurePassword,
//                         icon: Icons.lock_outline,
//                         suffixIcon: IconButton(
//                           icon: Icon(
//                             obscurePassword ? Icons.visibility_off : Icons.visibility,
//                             color: primaryCyan.withOpacity(0.7),
//                             size: 20,
//                           ),
//                           onPressed: () => setState(() => obscurePassword = !obscurePassword),
//                         ),
//                       ),
//
//                       inputField(
//                         "Confirm Password",
//                         confirmPasswordController,
//                         obscureText: obscureConfirmPassword,
//                         icon: Icons.lock_reset_outlined,
//                         suffixIcon: IconButton(
//                           icon: Icon(
//                             obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
//                             color: primaryCyan.withOpacity(0.7),
//                             size: 20,
//                           ),
//                           onPressed: () => setState(() => obscureConfirmPassword = !obscureConfirmPassword),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 // Terms and Conditions Section
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//                   child: Row(
//                     children: [
//                       Theme(
//                         data: ThemeData(unselectedWidgetColor: Colors.white24),
//                         child: Checkbox(
//                           value: acceptedTerms,
//                           activeColor: primaryCyan,
//                           checkColor: deepBackground,
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
//                           onChanged: (value) => setState(() => acceptedTerms = value ?? false),
//                         ),
//                       ),
//                       Expanded(
//                         child: RichText(
//                           text: TextSpan(
//                             text: 'I agree to the ',
//                             style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
//                             children: [
//                               TextSpan(
//                                 text: 'Terms and Conditions',
//                                 style: const TextStyle(
//                                   color: primaryCyan,
//                                   fontWeight: FontWeight.bold,
//                                   decoration: TextDecoration.underline,
//                                 ),
//                                 recognizer: TapGestureRecognizer()
//                                   ..onTap = () => Navigator.pushNamed(context, '/termsandcondition'),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 // Main Submit Button
//                 Padding(
//                   padding: const EdgeInsets.all(24),
//                   child: Container(
//                     width: double.infinity,
//                     height: 55,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(16),
//                       gradient: LinearGradient(
//                         colors: [primaryCyan, primaryCyan.withBlue(255)],
//                       ),
//                       boxShadow: [
//                         BoxShadow(
//                           color: primaryCyan.withOpacity(0.3),
//                           blurRadius: 12,
//                           offset: const Offset(0, 4),
//                         )
//                       ],
//                     ),
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.transparent,
//                         shadowColor: Colors.transparent,
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                       ),
//                       onPressed: isLoading ? null : () => register(),
//                       child: isLoading
//                           ? const SizedBox(
//                         height: 24,
//                         width: 24,
//                         child: CircularProgressIndicator(color: deepBackground, strokeWidth: 2.5),
//                       )
//                           : const Text(
//                         'GET STARTED',
//                         style: TextStyle(
//                           color: deepBackground,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                           letterSpacing: 1.2,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//
//   Widget inputField(
//       String label,
//       TextEditingController controller, {
//         bool obscureText = false,
//         String? helperText,
//         Widget? suffixIcon,
//         IconData? icon, // New parameter for icons
//       }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "  $label",
//             style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w600),
//           ),
//           const SizedBox(height: 6),
//           TextFormField(
//             controller: controller,
//             obscureText: obscureText,
//             style: const TextStyle(color: Colors.white, fontSize: 15),
//             decoration: InputDecoration(
//               prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF22D3EE).withOpacity(0.5), size: 20) : null,
//               hintText: 'Your $label',
//               hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
//               filled: true,
//               fillColor: const Color(0xFF1E293B),
//               helperText: helperText,
//               helperStyle: const TextStyle(color: Colors.white24),
//               contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(16),
//                 borderSide: const BorderSide(color: Colors.white10),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(16),
//                 borderSide: const BorderSide(color: Color(0xFF22D3EE), width: 1.5),
//               ),
//               errorBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(16),
//                 borderSide: const BorderSide(color: Colors.redAccent, width: 1),
//               ),
//               focusedErrorBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(16),
//                 borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
//               ),
//               suffixIcon: suffixIcon,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//
// }
// class RoleSelector extends StatelessWidget {
//   final String selectedRole;
//   final ValueChanged<String> onRoleChanged;
//
//   const RoleSelector({
//     super.key,
//     required this.selectedRole,
//     required this.onRoleChanged,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     const primaryCyan = Color(0xFF22D3EE);
//
//     return Container(
//       height: 55,
//       padding: const EdgeInsets.all(6),
//       decoration: BoxDecoration(
//         color: const Color(0xFF1E293B), // Dark Slate
//         // color: const Color(0xFF494A22),
//
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.white.withOpacity(0.05)),
//       ),
//       child: Row(
//         children: ['Passenger', 'Driver'].map((role) {
//           final isSelected = selectedRole == role;
//           return Expanded(
//             child: GestureDetector(
//               onTap: () => onRoleChanged(role),
//
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 300),
//                 // padding: const EdgeInsets.symmetric(vertical: 8),
//                 decoration: BoxDecoration(
//                   color: isSelected ? primaryCyan : Colors.transparent,
//                   borderRadius: BorderRadius.circular(12),
//                   boxShadow: isSelected ? [
//                     BoxShadow(
//                       color: primaryCyan.withOpacity(0.3),
//                       blurRadius: 10,
//                       offset: const Offset(0, 4),
//                     )
//                   ] : [],
//                 ),
//                 alignment: Alignment.center,
//                 child: Text(
//                   role.toUpperCase(),
//                   style: GoogleFonts.inter(
//                     color: isSelected ? Colors.white : const Color(0xFF0F172A),
//                     fontSize: 13,
//                     fontWeight: FontWeight.bold,
//                     height: 1.1,
//                   ),
//                 ),
//               ),
//
//
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }
// }
// class _LogoHeader extends StatefulWidget {
//   const _LogoHeader();
//   @override
//   State<_LogoHeader> createState() => _LogoHeaderState();
// }
// class _LogoHeaderState extends State<_LogoHeader> with SingleTickerProviderStateMixin {
//   late final AnimationController _controller = AnimationController(
//     vsync: this,
//     duration: const Duration(seconds: 2),
//   )..repeat(reverse: true);
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     const primaryCyan = Color(0xFF22D3EE);
//     return AnimatedBuilder(
//       animation: _controller,
//       builder: (context, child) {
//         final glow = 20 + (_controller.value * 15);
//         return Container(
//           height: 120,
//           width: 120,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: const Color(0xFF008080),
//             border: Border.all(color: primaryCyan.withOpacity(0.3), width: 1.5),
//             boxShadow: [
//               BoxShadow(
//                 color: const Color(0xFF008080).withOpacity(0.35),
//                 blurRadius: glow,
//                 spreadRadius: 2,
//               ),
//             ],
//           ),
//           child: child,
//         );
//       },
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(60),
//         child: Padding(
//           padding: const EdgeInsets.all(18),
//           child: Image.asset(
//             'assets/images/logo.png',
//             fit: BoxFit.contain,
//             errorBuilder: (context, error, stackTrace) => const Icon(
//               Icons.local_taxi_rounded,
//               size: 50,
//               color: primaryCyan,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'dart:async';
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart'; // Add this line
import 'dart:io'; // for File
import 'package:image_picker/image_picker.dart';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CreateAccountScreen();
  }
}

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  // ─────────────────────────────────────────────────────────────
  // FEATURE FLAG: flip this back to `true` whenever you want the
  // driver photo / license / national ID upload steps back on.
  // Everything else (state, pickers, validation) is left in place,
  // just gated behind this flag.
  // ─────────────────────────────────────────────────────────────
  static const bool kEnableDocumentUpload = false;

  File? driverImage;
  File? licenseImage;
  File? nationalIdImage;

  String? selectedCarType; // will be 'Comfort', 'Premium' or 'Business'

  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  String selectedRole = 'Passenger';
  bool isLoading = false;
  bool acceptedTerms = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final carModelController = TextEditingController();
  final carNumberController = TextEditingController();
  final carTypeController = TextEditingController();
  final licenseController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nationalIdController = TextEditingController();

  // Theme palette — kept in one place so the whole screen stays consistent
  static const primaryCyan = Color(0xFF22D3EE);
  static const primaryCyanDark = Color(0xFF0EA5C4);
  static const deepBackground = Color(0xFF0B1220);
  static const surfaceSlate = Color(0xFF1A2436);
  static const surfaceSlateLight = Color(0xFF212D42);
  static const borderSubtle = Color(0x1AFFFFFF); // white 10%

  void showMessage(String msg, [Color color = Colors.redAccent]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Map<String, dynamic> createRequestBody() {
    final body = {
      "name": nameController.text.trim(),
      "email": emailController.text.trim().toLowerCase(),
      "phone": phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), ''),
      "password": passwordController.text.trim(),
      "role": selectedRole == 'Passenger' ? 'rider' : 'driver',
    };
    if (selectedRole == 'Driver') {
      body.addAll({
        "idNumber": nationalIdController.text.trim(),
        "carModel": carModelController.text.trim(),
        "carNumber": carNumberController.text.trim(),
        "carType": selectedCarType ?? "", // ← use the dropdown value
        "licenseNumber": licenseController.text.trim(),
      });
    }

    return body;
  }

  // Single API Call that waits for Render to wake up
  Future<void> _makeSingleApiCall(Map<String, dynamic> body) async {
    final url = Uri.parse("https://sizemoretaxi-itpj.onrender.com/api/auth/register");

    // Create a persistent client to prevent connection drops during Render spin-up
    final client = http.Client();

    try {
      final response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json', // Explicitly ask for JSON
        },
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body);

      // Check for both 200 (OK) and 201 (Created)
      if (response.statusCode == 201 || response.statusCode == 200) {
        if (!mounted) return;

        showMessage("Registration successful. OTP sent.", const Color(0xFF22C55E));

        await Future.delayed(const Duration(seconds: 2));

        Navigator.pushNamed(
          context,
          '/login',
          arguments: {
            'email': emailController.text.trim(),
            'role': selectedRole == 'Passenger' ? 'rider' : 'driver',
          },
        );
      } else {
        // If the user already exists, the server SHOULD return 400 or 409
        final errorMessage = responseData['message'] ?? 'Registration failed';
        throw Exception(errorMessage);
      }
    } catch (e) {
      // If it fails because the user was created "long ago" in a previous hang,
      // the error message from the server will likely be "User already exists".
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    } finally {
      client.close(); // Always close the client
    }
  }

  // Updated Register Function
  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!acceptedTerms) {
      showMessage("Please accept terms and conditions");
      return;
    }
    if (passwordController.text != confirmPasswordController.text) {
      showMessage("Passwords don't match");
      return;
    }

    if (selectedRole == 'Driver') {
      // Document upload is temporarily disabled — validation is skipped
      // while kEnableDocumentUpload is false.
      if (kEnableDocumentUpload) {
        if (driverImage == null) {
          showMessage("Please upload driver photo");
          return;
        }
        if (licenseImage == null) {
          showMessage("Please upload driving license photo");
          return;
        }
      }
      if (selectedCarType == null) {
        showMessage("Please select car type");
        return;
      }
    }

    setState(() => isLoading = true);

    try {
      final body = createRequestBody();
      // This will now wait until the server responds
      await _makeSingleApiCall(body);
    } catch (e) {
      // Clear passwords on error so user can re-try safely
      passwordController.clear();
      confirmPasswordController.clear();
      showMessage(e.toString().replaceAll('Exception: ', ''));
    } finally {
      // Only stop loading if we are still on this screen
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _pickDriverImage() async {
    try {
      final XFile? pickedFile = await showModalBottomSheet<XFile?>(
        context: context,
        backgroundColor: surfaceSlate,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => _imagePickerSheet(),
      );

      if (pickedFile != null) {
        setState(() {
          driverImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      showMessage("Error picking driver image: $e", Colors.orange);
    }
  }

  Future<void> _pickLicenseImage() async {
    try {
      final XFile? pickedFile = await showModalBottomSheet<XFile?>(
        context: context,
        backgroundColor: surfaceSlate,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => _imagePickerSheet(),
      );

      if (pickedFile != null) {
        setState(() {
          licenseImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      showMessage("Error picking license image: $e", Colors.orange);
    }
  }

  Future<void> _pickNationalIdImage() async {
    try {
      final XFile? pickedFile = await showModalBottomSheet<XFile?>(
        context: context,
        backgroundColor: surfaceSlate,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => _imagePickerSheet(),
      );

      if (pickedFile != null) {
        setState(() {
          nationalIdImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      showMessage("Error picking National ID image: $e", Colors.orange);
    }
  }

  Widget _imagePickerSheet() {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: primaryCyan),
            title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
            onTap: () async {
              final file = await _picker.pickImage(source: ImageSource.camera);
              if (context.mounted) Navigator.pop(context, file);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: primaryCyan),
            title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
            onTap: () async {
              final file = await _picker.pickImage(source: ImageSource.gallery);
              if (context.mounted) Navigator.pop(context, file);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.6),
            radius: 1.3,
            colors: [
              Color(0xFF17263D),
              deepBackground,
            ],
            stops: [0.0, 0.65],
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 46),

                // Header Section
                Text(
                  'Create Account',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Join the future of taxi services',
                  style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 14),
                ),

                const SizedBox(height: 28),

                Column(
                  children: [
                    const _LogoHeader(),
                    const SizedBox(height: 14),
                    Text(
                      'SIZEMORETAXI',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4.0,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Role Selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: RoleSelector(
                    selectedRole: selectedRole,
                    onRoleChanged: (role) => setState(() => selectedRole = role),
                  ),
                ),

                const SizedBox(height: 22),

                // ── Personal details card ──────────────────────────
                _sectionCard(
                  icon: Icons.person_rounded,
                  title: 'Personal Details',
                  children: [
                    inputField("Full Name", nameController, icon: Icons.person_outline),
                    inputField("Email Address", emailController, icon: Icons.email_outlined),
                    inputField(
                      "Phone Number",
                      phoneController,
                      icon: Icons.phone_android_outlined,
                      helperText: "Format: 07xxxxxxxx",
                    ),
                  ],
                ),

                // ── Driver details card (only for drivers) ─────────
                if (selectedRole == 'Driver')
                  _sectionCard(
                    icon: Icons.local_taxi_rounded,
                    title: 'Vehicle & Driver Details',
                    children: [
                      inputField("Car Model", carModelController, icon: Icons.directions_car_filled_outlined),
                      inputField("Car Number", carNumberController, icon: Icons.numbers_outlined),
                      _carTypeDropdown(),
                      inputField("License Number", licenseController, icon: Icons.badge_outlined),
                      inputField("National ID Number", nationalIdController, icon: Icons.perm_identity_outlined),

                      // Document upload — temporarily disabled.
                      // Set kEnableDocumentUpload = true to bring these back.
                      if (kEnableDocumentUpload) ...[
                        const SizedBox(height: 8),
                        _uploadTile(
                          label: "Driver Photo",
                          hint: "Tap to take/upload driver photo",
                          icon: Icons.add_a_photo,
                          image: driverImage,
                          onTap: _pickDriverImage,
                        ),
                        const SizedBox(height: 16),
                        _uploadTile(
                          label: "Driving License Photo",
                          hint: "Tap to take/upload license photo",
                          icon: Icons.card_membership,
                          image: licenseImage,
                          onTap: _pickLicenseImage,
                        ),
                        const SizedBox(height: 16),
                        _uploadTile(
                          label: "National ID Photo",
                          hint: "Tap to take/upload national ID photo",
                          icon: Icons.badge_outlined,
                          image: nationalIdImage,
                          onTap: _pickNationalIdImage,
                        ),
                      ] else ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: primaryCyan.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: primaryCyan.withOpacity(0.25)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: primaryCyan.withOpacity(0.9), size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Document uploads aren't required right now — you can add them later from your profile.",
                                  style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12.5, height: 1.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                // ── Security card ───────────────────────────────────
                _sectionCard(
                  icon: Icons.lock_outline_rounded,
                  title: 'Security',
                  children: [
                    inputField(
                      "Password",
                      passwordController,
                      obscureText: obscurePassword,
                      icon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: primaryCyan.withOpacity(0.7),
                          size: 20,
                        ),
                        onPressed: () => setState(() => obscurePassword = !obscurePassword),
                      ),
                    ),
                    inputField(
                      "Confirm Password",
                      confirmPasswordController,
                      obscureText: obscureConfirmPassword,
                      icon: Icons.lock_reset_outlined,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          color: primaryCyan.withOpacity(0.7),
                          size: 20,
                        ),
                        onPressed: () => setState(() => obscureConfirmPassword = !obscureConfirmPassword),
                      ),
                    ),
                  ],
                ),

                // Terms and Conditions Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: surfaceSlate.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Theme(
                          data: ThemeData(unselectedWidgetColor: Colors.white24),
                          child: Checkbox(
                            value: acceptedTerms,
                            activeColor: primaryCyan,
                            checkColor: deepBackground,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            onChanged: (value) => setState(() => acceptedTerms = value ?? false),
                          ),
                        ),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              text: 'I agree to the ',
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                              children: [
                                TextSpan(
                                  text: 'Terms and Conditions',
                                  style: const TextStyle(
                                    color: primaryCyan,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => Navigator.pushNamed(context, '/termsandcondition'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Main Submit Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [primaryCyanDark, primaryCyan],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryCyan.withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: isLoading ? null : () => register(),
                        child: Center(
                          child: isLoading
                              ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: deepBackground, strokeWidth: 2.5),
                          )
                              : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'GET STARTED',
                                style: GoogleFonts.inter(
                                  color: deepBackground,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, color: deepBackground, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 28, top: 4),
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13),
                      children: [
                        TextSpan(
                          text: 'Log in',
                          style: const TextStyle(
                            color: primaryCyan,
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => Navigator.pushNamed(context, '/login'),
                        ),
                      ],
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

  // Reusable card wrapper for grouping related fields with a small header
  Widget _sectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
        decoration: BoxDecoration(
          color: surfaceSlate.withOpacity(0.55),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryCyan.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: primaryCyan, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _carTypeDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "  Car Type",
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: selectedCarType,
            hint: Text(
              "Select car type",
              style: TextStyle(color: Colors.white.withOpacity(0.35)),
            ),
            dropdownColor: surfaceSlateLight,
            style: const TextStyle(color: Colors.white),
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryCyan.withOpacity(0.7)),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.category_outlined, color: primaryCyan.withOpacity(0.5), size: 20),
              filled: true,
              fillColor: surfaceSlateLight,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: primaryCyan, width: 1.5),
              ),
            ),
            items: ['Comfort', 'Premium', 'Business'].map((type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedCarType = value;
              });
            },
            validator: (value) {
              if (value == null) return 'Please select car type';
              return null;
            },
          ),
        ],
      ),
    );
  }

  // Kept for when uploads are re-enabled (kEnableDocumentUpload = true)
  Widget _uploadTile({
    required String label,
    required String hint,
    required IconData icon,
    required File? image,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "  $label",
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: surfaceSlateLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderSubtle),
              ),
              child: image == null
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: primaryCyan, size: 36),
                  const SizedBox(height: 10),
                  Text(
                    hint,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                  ),
                ],
              )
                  : ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  image,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 140,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget inputField(
      String label,
      TextEditingController controller, {
        bool obscureText = false,
        String? helperText,
        Widget? suffixIcon,
        IconData? icon,
        String? Function(String?)? validator,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "  $label",
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            obscureText: obscureText,
            validator: validator ?? (value) => (value == null || value.trim().isEmpty) ? '$label is required' : null,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            cursorColor: primaryCyan,
            decoration: InputDecoration(
              prefixIcon: icon != null ? Icon(icon, color: primaryCyan.withOpacity(0.55), size: 20) : null,
              hintText: 'Your $label',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
              filled: true,
              fillColor: surfaceSlateLight,
              helperText: helperText,
              helperStyle: const TextStyle(color: Colors.white24),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: primaryCyan, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.redAccent, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
              ),
              suffixIcon: suffixIcon,
            ),
          ),
        ],
      ),
    );
  }
}

class RoleSelector extends StatelessWidget {
  final String selectedRole;
  final ValueChanged<String> onRoleChanged;

  const RoleSelector({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    const primaryCyan = Color(0xFF22D3EE);
    const primaryCyanDark = Color(0xFF0EA5C4);

    return Container(
      height: 56,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2436),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: ['Passenger', 'Driver'].map((role) {
          final isSelected = selectedRole == role;
          return Expanded(
            child: GestureDetector(
              onTap: () => onRoleChanged(role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(colors: [primaryCyanDark, primaryCyan])
                      : null,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: primaryCyan.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      role == 'Passenger' ? Icons.person_rounded : Icons.local_taxi_rounded,
                      size: 16,
                      color: isSelected ? Colors.white : Colors.white38,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      role.toUpperCase(),
                      style: GoogleFonts.inter(
                        color: isSelected ? Colors.white : Colors.white38,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LogoHeader extends StatefulWidget {
  const _LogoHeader();
  @override
  State<_LogoHeader> createState() => _LogoHeaderState();
}

class _LogoHeaderState extends State<_LogoHeader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryCyan = Color(0xFF22D3EE);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final glow = 20 + (_controller.value * 18);
        return Container(
          height: 120,
          width: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0C4A4A), Color(0xFF083344)],
            ),
            border: Border.all(color: primaryCyan.withOpacity(0.35), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: primaryCyan.withOpacity(0.30),
                blurRadius: glow,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(60),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.local_taxi_rounded,
              size: 50,
              color: primaryCyan,
            ),
          ),
        ),
      ),
    );
  }
}