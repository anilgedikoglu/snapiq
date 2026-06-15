import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/storage_service.dart';
import '../services/theme_service.dart';
import '../services/locale_service.dart';
import '../widgets/animated_background.dart';
import '../widgets/neon_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  StorageService? _storage;
  bool _sound = true;
  bool _vibration = true;
  bool _reduceAnim = false;
  String _selectedTheme = 'neon';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await StorageService.getInstance();
    if (mounted) {
      setState(() {
        _storage = s;
        _sound = s.soundEnabled;
        _vibration = s.vibrationEnabled;
        _reduceAnim = s.reduceAnimations;
        _selectedTheme = s.selectedTheme;
      });
    }
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1B2A),
        title: Text(S.settingsResetData,
            style: const TextStyle(color: Colors.white)),
        content: Text(
            S.settingsResetConfirm,
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(S.cancel,
                style: const TextStyle(color: Color(0xFF00B4FF))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(S.delete,
                style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true && _storage != null) {
      await _storage!.clearAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.settingsDataReset),
            backgroundColor: const Color(0xFF0D1B2A),
          ),
        );
        await _load();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white70, size: 20),
                    ),
                    Text(
                      S.settingsTitle,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              if (_storage == null)
                const Expanded(
                    child: Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF00B4FF))))
              else
                Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(S.settingsSound),
          _toggleTile(
            title: S.settingsSoundFX,
            icon: Icons.volume_up_rounded,
            value: _sound,
            onChanged: (v) async {
              setState(() => _sound = v);
              await _storage!.saveSoundEnabled(v);
            },
          ),
          _toggleTile(
            title: S.settingsVibration,
            icon: Icons.vibration_rounded,
            value: _vibration,
            onChanged: (v) async {
              setState(() => _vibration = v);
              await _storage!.saveVibrationEnabled(v);
            },
          ),
          const SizedBox(height: 20),
          _sectionTitle(S.settingsVisual),
          _toggleTile(
            title: S.settingsReduceAnim,
            icon: Icons.motion_photos_off_rounded,
            value: _reduceAnim,
            onChanged: (v) async {
              setState(() => _reduceAnim = v);
              await _storage!.saveReduceAnimations(v);
            },
          ),
          const SizedBox(height: 16),
          Text(S.spinTheme,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 10),
          _buildThemeSelector(),
          const SizedBox(height: 32),
          _sectionTitle(S.settingsLanguage),
          const SizedBox(height: 8),
          _buildLanguageSelector(),
          const SizedBox(height: 32),
          _sectionTitle(S.settingsData),
          const SizedBox(height: 8),
          NeonButton(
            text: S.settingsResetData,
            onPressed: _confirmReset,
            color: Colors.redAccent,
            width: double.infinity,
            icon: Icons.delete_forever_rounded,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              color: Color(0xFF00B4FF),
              fontWeight: FontWeight.bold,
              fontSize: 14)),
    );
  }

  Widget _toggleTile({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF00B4FF).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00B4FF), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF00B4FF),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: ThemeService.themes.map((t) {
        final isSelected = _selectedTheme == t.id;
        return GestureDetector(
          onTap: () async {
            setState(() => _selectedTheme = t.id);
            await _storage!.saveTheme(t.id);
          },
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: t.primaryColor,
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: t.primaryColor.withValues(alpha: 0.6),
                            blurRadius: 12,
                            spreadRadius: 2,
                          )
                        ]
                      : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(t.name,
                  style: TextStyle(
                      color: isSelected ? t.primaryColor : Colors.white38,
                      fontSize: 10)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLanguageSelector() {
    final isEnglish = LocaleService.instance.isEnglish;
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () async {
              await LocaleService.instance.setEnglish(false);
              if (mounted) setState(() {});
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: !isEnglish
                    ? const Color(0xFF00B4FF).withValues(alpha: 0.2)
                    : const Color(0xFF0D1B2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: !isEnglish
                      ? const Color(0xFF00B4FF)
                      : const Color(0xFF00B4FF).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🇹🇷', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    'Türkçe',
                    style: TextStyle(
                      color: !isEnglish ? Colors.white : Colors.white70,
                      fontSize: 14,
                      fontWeight:
                          !isEnglish ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () async {
              await LocaleService.instance.setEnglish(true);
              if (mounted) setState(() {});
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isEnglish
                    ? const Color(0xFF00B4FF).withValues(alpha: 0.2)
                    : const Color(0xFF0D1B2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isEnglish
                      ? const Color(0xFF00B4FF)
                      : const Color(0xFF00B4FF).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🇬🇧', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    'English',
                    style: TextStyle(
                      color: isEnglish ? Colors.white : Colors.white70,
                      fontSize: 14,
                      fontWeight:
                          isEnglish ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
