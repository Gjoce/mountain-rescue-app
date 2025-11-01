import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mountain_rescue/data/models/injury_model.dart';
import 'package:mountain_rescue/data/repositories/injury_repository.dart';
import '../../state/providers/auth_provider.dart';

class InjuryRegistrationScreen extends ConsumerStatefulWidget {
  const InjuryRegistrationScreen({super.key});

  @override
  ConsumerState<InjuryRegistrationScreen> createState() =>
      _InjuryRegistrationScreenState();
}

class _InjuryRegistrationScreenState
    extends ConsumerState<InjuryRegistrationScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _commentController = TextEditingController();
  Uint8List? _idPhotoBytes;

  String? _selectedSkiRun;
  DateTime? _birthDate;
  final Set<String> _selectedBodyParts = {};
  final Map<String, String> _injuryTypes = {};

  String? _selectedRegion;
  late AnimationController _pulseController;
  bool _isSubmitting = false;

  String? _selectedSeverity;

  final List<String> _severityOptions = [
    'minor',
    'moderate',
    'severe',
    'critical',
  ];

  final List<String> _skiRuns = [
    'Slope 1',
    'Slope 2',
    'Slope 3',
    'Slope 4',
    'Slope 5',
  ];

  final Map<String, BodyRegion> _bodyRegions = {
    'Head': BodyRegion('Head', 0.5, 0.02, [
      'Head-Forehead',
      'Head-Eyes',
      'Head-Nose',
      'Head-Mouth',
      'Head-Ear R',
      'Head-Ear L',
    ]),
    'Neck': BodyRegion('Neck', 0.5, 0.14, ['Neck']),
    'Chest': BodyRegion('Chest', 0.5, 0.22, [
      'Chest-Upper',
      'Chest-Lower',
      'Chest-Ribs R',
      'Chest-Ribs L',
    ]),
    'Abdomen': BodyRegion('Abdomen', 0.5, 0.32, [
      'Abdomen-Upper',
      'Abdomen-Lower',
    ]),
    'R-Shoulder': BodyRegion('R-Shoulder', 0.21, 0.18, [
      'R-Shoulder-Front',
      'R-Shoulder-Back',
      'R-Collarbone',
    ]),
    'R-Arm': BodyRegion('R-Arm', 0.07, 0.35, [
      'R-Upper Arm',
      'R-Elbow',
      'R-Forearm',
      'R-Wrist',
      'R-Hand',
      'R-Fingers',
    ]),
    'L-Shoulder': BodyRegion('L-Shoulder', 0.79, 0.18, [
      'L-Shoulder-Front',
      'L-Shoulder-Back',
      'L-Collarbone',
    ]),
    'L-Arm': BodyRegion('L-Arm', 0.95, 0.35, [
      'L-Upper Arm',
      'L-Elbow',
      'L-Forearm',
      'L-Wrist',
      'L-Hand',
      'L-Fingers',
    ]),
    'R-Leg': BodyRegion('R-Leg', 0.3, 0.60, [
      'R-Hip',
      'R-Thigh',
      'R-Knee',
      'R-Shin',
      'R-Ankle',
      'R-Foot',
    ]),
    'L-Leg': BodyRegion('L-Leg', 0.68, 0.60, [
      'L-Hip',
      'L-Thigh',
      'L-Knee',
      'L-Shin',
      'L-Ankle',
      'L-Foot',
    ]),
  };

  final List<String> _injuryTypeOptions = [
    'Fracture',
    'Sprain',
    'Wound',
    'Contusion',
    'Laceration',
    'Dislocation',
    'Other',
  ];

  Future<void> _pickIdPhoto() async {
    final ImagePicker picker = ImagePicker();

    final XFile? pickedFile = await picker.pickImage(
      source: await _showImageSourceDialog(),
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _idPhotoBytes = bytes);
    }
  }

  Future<ImageSource> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Choose image source'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text('Gallery'),
          ),
        ],
      ),
    ).then((value) => value ?? ImageSource.gallery);
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commentController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleBodyPart(String part) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedBodyParts.contains(part)) {
        _selectedBodyParts.remove(part);
        _injuryTypes.remove(part);
      } else {
        _selectedBodyParts.add(part);
        _showInjuryTypeDialog(part);
      }
    });
  }

  void _selectRegion(String? region) {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedRegion = region;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 7300)),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF1565C0)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  void _showInjuryTypeDialog(String bodyPart) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Injury Type - $bodyPart',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Theme(
          data: Theme.of(context).copyWith(
            radioTheme: RadioThemeData(
              fillColor: WidgetStateProperty.all(const Color(0xFF1565C0)),
            ),
          ),
          child: RadioGroup<String>(
            groupValue: _injuryTypes[bodyPart],
            onChanged: (value) {
              setState(() {
                _injuryTypes[bodyPart] = value!;
              });
              Navigator.pop(ctx);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _injuryTypeOptions.map((type) {
                return RadioListTile<String>(
                  value: type,
                  title: Text(
                    type,
                    style: const TextStyle(color: Colors.black),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitInjuryReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBodyParts.isEmpty || _birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }
    if (_selectedSeverity == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select severity')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final currentUser = await ref.read(currentUserProvider.future);
      if (currentUser == null) throw Exception('No authenticated user');

      final injury = Injury(
        id: '',
        rescuerId: currentUser.id,
        rescuerName: currentUser.name,
        rescuerEmail: currentUser.email,
        patientName: _nameController.text.trim(),
        patientBirthDate: _birthDate!,
        injuries: _injuryTypes.entries
            .map((e) => InjuryDetail(bodyPart: e.key, injuryType: e.value))
            .toList(),
        severity: _selectedSeverity!,
        skiSlope: _selectedSkiRun!,
        description: _commentController.text.trim(),
        timestamp: DateTime.now(),
        status: 'pending',
      );

      final repo = InjuryRepository();
      final docId = await repo.createInjury(injury.toMap());

      if (_idPhotoBytes != null) {
        try {
          final photoUrl = await repo.uploadIdPhoto(docId, _idPhotoBytes!);
          await repo.updateInjury(docId, {'photoUrl': photoUrl});
        } catch (uploadError) {
          throw Exception('Failed to upload ID photo: $uploadError');
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Injury report submitted (ID: $docId)')),
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Injury Report'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          currentUserAsync.when(
            data: (user) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  user?.name ?? 'Unknown',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
      body: Container(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Patient Info Section
              _buildSectionCard(
                isDark: isDark,
                title: 'Patient Information',
                icon: Icons.person,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      floatingLabelStyle: const TextStyle(
                        color: Color(0xFF1565C0),
                      ),
                      prefixIcon: const Icon(Icons.badge),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Color(0xFF2A2A2A) : Colors.grey,
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(
                          color: Color(0xFF1565C0),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: isDark ? Color(0xFF2A2A2A) : Colors.white,
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date of Birth',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? Colors.grey : Colors.grey,
                          ),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(
                            color: Color(0xFF1565C0),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: isDark ? Color(0xFF2A2A2A) : Colors.white,
                      ),
                      child: Text(
                        _birthDate == null
                            ? 'Select date'
                            : '${_birthDate!.month}/${_birthDate!.day}/${_birthDate!.year}',
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Theme(
                    data: Theme.of(context).copyWith(
                      canvasColor: isDark
                          ? const Color(0xFF2A2A2A)
                          : Colors.white,
                      colorScheme: Theme.of(context).colorScheme.copyWith(
                        primary: const Color(0xFF1565C0),
                        onSurface: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedSkiRun,
                      decoration: InputDecoration(
                        labelText: 'Ski Slope',
                        prefixIcon: const Icon(Icons.landscape),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF2A2A2A)
                            : Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? Colors.grey : Colors.grey.shade400,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF1565C0),
                            width: 2,
                          ),
                        ),
                      ),
                      items: _skiRuns.map((run) {
                        return DropdownMenuItem(value: run, child: Text(run));
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedSkiRun = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Body Diagram Section
              _buildSectionCard(
                isDark: isDark,
                title: 'Mark Injured Body Parts',
                icon: Icons.accessibility_new,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.touch_app, color: Color(0xFF1565C0)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedRegion == null
                                ? 'Tap a body part to see details'
                                : 'Select a specific part or go back',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.grey[800],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // R and L Labels positioned above the body diagram
                  if (_selectedRegion == null)
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _selectedRegion == null ? 1.0 : 0.0,
                      child: SizedBox(
                        height: 60,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 20,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: _buildSideLabel('R', isDark),
                              ),
                            ),
                            Positioned(
                              right: 20,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: _buildSideLabel('L', isDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_selectedRegion == null) const SizedBox(height: 10),

                  if (_selectedRegion != null) ...[
                    ElevatedButton.icon(
                      onPressed: () => _selectRegion(null),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back to Full Body'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(scale: animation, child: child),
                      );
                    },
                    child: _selectedRegion == null
                        ? _buildFullBodyView(isDark)
                        : _buildRegionDetailView(_selectedRegion!, isDark),
                  ),

                  if (_selectedBodyParts.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'Selected parts (${_selectedBodyParts.length}):',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSelectedPartsChips(isDark),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionCard(
                isDark: isDark,
                title: 'Injury Severity',
                icon: Icons.warning_amber,
                children: [
                  Theme(
                    data: Theme.of(context).copyWith(
                      canvasColor: isDark
                          ? const Color(0xFF2A2A2A)
                          : Colors.white,
                      dropdownMenuTheme: DropdownMenuThemeData(
                        inputDecorationTheme: InputDecorationTheme(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      colorScheme: Theme.of(context).colorScheme.copyWith(
                        primary: const Color(0xFF1565C0),
                        onSurface: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedSeverity,
                      decoration: InputDecoration(
                        labelText: 'Severity',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF2A2A2A)
                            : Colors.white,
                      ),
                      items: _severityOptions
                          .map(
                            (sev) => DropdownMenuItem(
                              value: sev,
                              child: Text(sev.toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedSeverity = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Comment Section
              _buildSectionCard(
                isDark: isDark,
                title: 'Additional Comments',
                icon: Icons.notes,
                children: [
                  TextFormField(
                    controller: _commentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Describe the injury in more detail...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF2A2A2A)
                          : Colors.white,
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('ID Photo', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickIdPhoto,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: _idPhotoBytes != null
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 32,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Image added',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, size: 40),
                              SizedBox(height: 8),
                              Text('Tap to choose camera or gallery'),
                            ],
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 22),
              // Submit Button
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitInjuryReport,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.send, size: 24),
                  label: Text(
                    _isSubmitting ? 'Submitting...' : 'Submit Report',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullBodyView(bool isDark) {
    return SizedBox(
      key: const ValueKey('fullBody'),
      height: 500,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final centerX = width / 2;

          return Stack(
            children: [
              Positioned.fill(
                child: Center(
                  child: Opacity(
                    opacity: 0.5,
                    child: Image.asset(
                      'assets/human-body-frontal.png',
                      fit: BoxFit.contain,
                      height: 500,
                    ),
                  ),
                ),
              ),
              ..._bodyRegions.entries.map((entry) {
                final hasSelection = entry.value.subParts.any(
                  (part) => _selectedBodyParts.contains(part),
                );

                return Positioned(
                  left: centerX + (entry.value.x - 0.5) * 300 - 30,
                  top: (entry.value.y * 500) - 10,
                  child: _buildRegionButton(
                    entry.key,
                    entry.value,
                    hasSelection,
                    isDark,
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSideLabel(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey.shade50],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            blurRadius: 8,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade800,
          letterSpacing: 1.5,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.1),
              offset: const Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionButton(
    String name,
    BodyRegion region,
    bool hasSelection,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => _selectRegion(name),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: hasSelection ? 1.15 : 1.0,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: hasSelection
                    ? Color.lerp(
                        const Color(0xFFE53935).withValues(alpha: 0.4),
                        const Color(0xFFE53935).withValues(alpha: 0.7),
                        _pulseController.value,
                      )
                    : const Color(0xFF1565C0).withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: Border.all(
                  color: hasSelection
                      ? const Color(0xFFE53935)
                      : const Color(0xFF1565C0),
                  width: hasSelection ? 3 : 2,
                ),
                boxShadow: hasSelection
                    ? [
                        BoxShadow(
                          color: const Color(0xFFE53935).withValues(
                            alpha: 0.3 + (_pulseController.value * 0.4),
                          ),
                          blurRadius: 10 + (_pulseController.value * 15),
                          spreadRadius: 2 + (_pulseController.value * 3),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasSelection ? Icons.check_circle : Icons.touch_app,
                    color: hasSelection
                        ? Colors.white
                        : const Color(0xFF1565C0),
                    size: 24,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name.split('-').last,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: hasSelection
                          ? Colors.white
                          : const Color(0xFF1565C0),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRegionDetailView(String regionName, bool isDark) {
    final region = _bodyRegions[regionName]!;

    return Container(
      key: ValueKey('detail_$regionName'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1565C0).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.zoom_in,
                  color: Color(0xFF1565C0),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      regionName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey[800],
                      ),
                    ),
                    Text(
                      'Select specific part',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: region.subParts.map((part) {
              final isSelected = _selectedBodyParts.contains(part);
              return _buildSubPartChip(part, isSelected, isDark);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubPartChip(String part, bool isSelected, bool isDark) {
    return GestureDetector(
      onTap: () => _toggleBodyPart(part),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE53935)
              : (isDark ? const Color(0xFF3A3A3A) : Colors.grey[200]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFE53935) : Colors.grey[400]!,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFE53935).withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              part,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.grey[800]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required bool isDark,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.1))
            : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF1565C0), size: 28),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSelectedPartsChips(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _selectedBodyParts.map((part) {
        final hasType = _injuryTypes.containsKey(part);
        return ActionChip(
          avatar: CircleAvatar(
            backgroundColor: const Color(0xFFE53935),
            child: Text(
              hasType ? '✓' : '!',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          label: Text(
            hasType ? '$part: ${_injuryTypes[part]}' : part,
            style: const TextStyle(fontSize: 13),
          ),
          onPressed: () => _showInjuryTypeDialog(part),
          backgroundColor: const Color(0xFFE53935).withValues(alpha: 0.15),
          side: const BorderSide(color: Color(0xFFE53935)),
        );
      }).toList(),
    );
  }
}

class BodyRegion {
  final String englishName;
  final double x;
  final double y;
  final List<String> subParts;

  BodyRegion(this.englishName, this.x, this.y, this.subParts);
}
