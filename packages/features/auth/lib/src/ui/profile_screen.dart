import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _avatarController;
  String _selectedCurrency = 'USD';
  String _selectedDateFormat = 'MM/DD/YYYY';
  bool _isEditing = false;

  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'INR', 'JPY'];
  final List<String> _dateFormats = ['MM/DD/YYYY', 'DD/MM/YYYY', 'YYYY-MM-DD'];

  @override
  void initState() {
    super.initState();
    // Initialize with current state if available
    final state = context.read<AuthBloc>().state;
    UserModel? user;
    if (state is AuthAuthenticated) {
      user = state.user;
    }

    _nameController = TextEditingController(text: user?.name ?? '');
    _avatarController = TextEditingController(text: user?.avatar ?? '');
    _selectedCurrency = user?.currency ?? 'USD';
    _selectedDateFormat = user?.dateFormat ?? 'MM/DD/YYYY';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to log out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Dismiss dialog
              context.read<AuthBloc>().add(AuthLogoutRequested());
              Navigator.of(
                context,
              ).popUntil((route) => route.isFirst); // Bounce to root
            },
            child: const Text(
              'Logout',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onSave() {
    context.read<AuthBloc>().add(
      AuthProfileUpdateRequested(
        name: _nameController.text.trim(),
        avatar: _avatarController.text.trim(),
        currency: _selectedCurrency,
        dateFormat: _selectedDateFormat,
      ),
    );
    setState(() => _isEditing = false);
  }

  Future<void> _pickImage(ImageSource source) async {
    // Explicitly ask for camera permission if needed
    if (source == ImageSource.camera &&
        !kIsWeb &&
        (Platform.isAndroid || Platform.isIOS)) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera permission required.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
    }

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64String = base64Encode(bytes);
        // Prefix with data URI so backend or other clients know it's base64 image
        final finalAvatarStr = 'data:image/png;base64,$base64String';
        setState(() {
          _avatarController.text = finalAvatarStr;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showImagePickerModal() {
    final bool supportsCamera =
        !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Local Storage / Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (supportsCamera)
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  ImageProvider? _getAvatarImageProvider(String source) {
    final trimmedSource = source.trim();
    if (trimmedSource.isEmpty) return null;

    if (trimmedSource.startsWith('data:image')) {
      try {
        final commaIndex = trimmedSource.indexOf(',');
        if (commaIndex == -1) return null;

        // Clean base64 string by removing all whitespace characters (including newlines)
        final base64Str = trimmedSource
            .substring(commaIndex + 1)
            .replaceAll(RegExp(r'\s+'), '');
        return MemoryImage(base64Decode(base64Str));
      } catch (e) {
        return null;
      }
    } else {
      try {
        return NetworkImage(trimmedSource);
      } catch (e) {
        return null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: const Text('Profile Settings'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                // Discard changes and revert to view mode
                setState(() {
                  _isEditing = false;
                  final state = context.read<AuthBloc>().state;
                  if (state is AuthAuthenticated) {
                    _nameController.text = state.user.name;
                    _avatarController.text = state.user.avatar;
                    _selectedCurrency = state.user.currency;
                    _selectedDateFormat = state.user.dateFormat;
                  }
                });
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () => _confirmLogout(context),
            ),
        ],
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is AuthAuthenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile Updated Successfully'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24.0,
              right: 24.0,
              bottom: 24.0,
              top: MediaQuery.paddingOf(context).top + kToolbarHeight + 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Builder(
                    builder: (context) {
                      final provider = _getAvatarImageProvider(
                        _avatarController.text,
                      );
                      return Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: provider,
                            child: provider == null
                                ? const Icon(Icons.person, size: 50)
                                : null,
                          ),
                          if (_isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: _showImagePickerModal,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                AppTextField(
                  label: 'Full Name',
                  controller: _nameController,
                  prefixIcon: const Icon(Icons.person_outline),
                  readOnly: !_isEditing,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Avatar URL',
                  controller: _avatarController,
                  hintText: 'https://example.com/avatar.jpg',
                  prefixIcon: const Icon(Icons.image_outlined),
                  readOnly: !_isEditing,
                  onChanged: (val) {
                    setState(() {}); // Trigger rebuild to update avatar preview
                  },
                ),
                const SizedBox(height: 24),

                Text('Currency Preference', style: AppTypography.labelLarge),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _currencies.contains(_selectedCurrency)
                      ? _selectedCurrency
                      : 'USD',
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  items: _currencies.map((curr) {
                    return DropdownMenuItem(value: curr, child: Text(curr));
                  }).toList(),
                  onChanged: _isEditing
                      ? (val) {
                          if (val != null) {
                            setState(() => _selectedCurrency = val);
                          }
                        }
                      : null,
                ),
                const SizedBox(height: 24),

                Text('Date Format', style: AppTypography.labelLarge),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _dateFormats.contains(_selectedDateFormat)
                      ? _selectedDateFormat
                      : 'MM/DD/YYYY',
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  items: _dateFormats.map((df) {
                    return DropdownMenuItem(value: df, child: Text(df));
                  }).toList(),
                  onChanged: _isEditing
                      ? (val) {
                          if (val != null) {
                            setState(() => _selectedDateFormat = val);
                          }
                        }
                      : null,
                ),
                if (_isEditing) ...[
                  const SizedBox(height: 48),
                  AppButton(
                    label: 'Save Changes',
                    isLoading: isLoading,
                    onPressed: _onSave,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
