import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'credentials_screen.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});
  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final nameController = TextEditingController();
  final descController = TextEditingController();
  String selectedIcon = '📡';
  String selectedColor = '#00D4FF';
  String selectedBoard = 'ESP32';
  bool loading = false;
  String error = '';

  final List<String> icons = [
    '📡','💡','🤖','🚗','🏠','🔒',
    '⚡','🌡️','💧','🎮','🔊','📷',
    '🌿','🏭','✈️','🚀','🔬','💻',
  ];

  final List<Map> colors = [
    {'name': 'Cyan', 'hex': '#00D4FF', 'color': const Color(0xFF00D4FF)},
    {'name': 'Green', 'hex': '#22C55E', 'color': const Color(0xFF22C55E)},
    {'name': 'Purple', 'hex': '#7C3AED', 'color': const Color(0xFF7C3AED)},
    {'name': 'Red', 'hex': '#FF5252', 'color': const Color(0xFFFF5252)},
    {'name': 'Orange', 'hex': '#FF9800', 'color': const Color(0xFFFF9800)},
    {'name': 'Pink', 'hex': '#E91E63', 'color': const Color(0xFFE91E63)},
  ];

  final List<String> boards = [
    'ESP32', 'ESP8266', 'Arduino Uno',
    'Arduino Mega', 'Raspberry Pi', 'STM32',
  ];

  Future<void> _create() async {
    if (nameController.text.isEmpty) {
      setState(() => error = 'Project name is required');
      return;
    }
    setState(() { loading = true; error = ''; });
    try {
      final result = await ApiService.addDevice(
        nameController.text,
        selectedBoard,
        description: descController.text,
        icon: selectedIcon,
        color: selectedColor,
      );
      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => CredentialsScreen(device: result)));
      }
    } catch (e) {
      setState(() { error = 'Failed to create project'; });
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = colors.firstWhere(
      (c) => c['hex'] == selectedColor,
      orElse: () => colors[0],
    )['color'] as Color;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        leading: BackButton(color: const Color(0xFF00D4FF)),
        title: Text(
          'NEW PROJECT',
          style: GoogleFonts.orbitron(
            fontSize: 13, color: Colors.white, letterSpacing: 1,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF1E2D45)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Preview Card
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 120, height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: accentColor.withOpacity(0.5), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(selectedIcon, style: const TextStyle(fontSize: 50)),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Project Name
            _label('PROJECT NAME'),
            const SizedBox(height: 8),
            _textField(
              controller: nameController,
              hint: 'e.g. Bedroom Light',
              accentColor: accentColor,
            ),
            const SizedBox(height: 20),

            // Description
            _label('DESCRIPTION'),
            const SizedBox(height: 8),
            _textField(
              controller: descController,
              hint: 'e.g. Controls my bedroom lights via ESP32',
              maxLines: 2,
              accentColor: accentColor,
            ),
            const SizedBox(height: 20),

            // Icon Picker
            _label('PICK ICON'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1E2D45)),
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: icons.length,
                itemBuilder: (context, i) {
                  final isSelected = icons[i] == selectedIcon;
                  return GestureDetector(
                    onTap: () => setState(() => selectedIcon = icons[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accentColor.withOpacity(0.15)
                            : const Color(0xFF1A2234),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? accentColor
                              : const Color(0xFF1E2D45),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: accentColor.withOpacity(0.3),
                            blurRadius: 8,
                          ),
                        ] : null,
                      ),
                      child: Center(
                        child: Text(icons[i], style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Color Picker
            _label('PICK COLOR'),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: colors.map((c) {
                final isSelected = c['hex'] == selectedColor;
                return GestureDetector(
                  onTap: () => setState(() => selectedColor = c['hex'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (c['color'] as Color).withOpacity(0.2),
                      border: Border.all(
                        color: c['color'] as Color,
                        width: isSelected ? 3 : 1.5,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: (c['color'] as Color).withOpacity(0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ] : null,
                    ),
                    child: isSelected
                        ? Icon(Icons.check, color: c['color'] as Color, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Board Type
            _label('BOARD TYPE'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentColor.withOpacity(0.3)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedBoard,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF111827),
                  style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 14),
                  icon: Icon(Icons.keyboard_arrow_down, color: accentColor),
                  items: boards.map((b) => DropdownMenuItem(
                    value: b,
                    child: Text(b),
                  )).toList(),
                  onChanged: (v) => setState(() => selectedBoard = v!),
                ),
              ),
            ),
            const SizedBox(height: 8),

            if (error.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(error, style: const TextStyle(color: Color(0xFFFF5252), fontSize: 12)),
            ],

            const SizedBox(height: 32),

            // Create Button
            GestureDetector(
              onTap: loading ? null : _create,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Text(
                          'CREATE PROJECT',
                          style: GoogleFonts.orbitron(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: GoogleFonts.orbitron(
      fontSize: 10, color: Colors.grey, letterSpacing: 1.5,
    ),
  );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required Color accentColor,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.rajdhani(color: Colors.grey, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF111827),
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E2D45)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E2D45)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor),
        ),
      ),
    );
  }
}