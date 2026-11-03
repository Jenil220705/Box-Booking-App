import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import 'core_providers.dart';

class SettingsNotifier extends Notifier<AppSettings> {
  static const _dark = 'hz_dark';
  static const _wa = 'hz_wa_tmpl';
  static const _recurWa = 'hz_recur_wa_tmpl';
  static const _sms = 'hz_sms_tmpl';
  static const _ground = 'hz_ground_name';
  static const _address = 'hz_ground_address';
  static const _contact = 'hz_ground_contact';
  static const _opens = 'hz_opens';
  static const _closes = 'hz_closes';
  static const _waAlerts = 'hz_wa_alerts';
  static const _conflict = 'hz_conflict_detect';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    const d = AppSettings();
    final p = _prefs;
    return AppSettings(
      darkMode: p.getBool(_dark) ?? d.darkMode,
      waTemplate: p.getString(_wa) ?? d.waTemplate,
      recurringWaTemplate: p.getString(_recurWa) ?? d.recurringWaTemplate,
      smsTemplate: p.getString(_sms) ?? d.smsTemplate,
      groundName: p.getString(_ground) ?? d.groundName,
      address: p.getString(_address) ?? d.address,
      contact: p.getString(_contact) ?? d.contact,
      opens: p.getString(_opens) ?? d.opens,
      closes: p.getString(_closes) ?? d.closes,
      whatsappAlerts: p.getBool(_waAlerts) ?? d.whatsappAlerts,
      conflictDetection: p.getBool(_conflict) ?? d.conflictDetection,
    );
  }

  Future<void> setDarkMode(bool value) async {
    state = state.copyWith(darkMode: value);
    await _prefs.setBool(_dark, value);
  }

  Future<void> setWhatsappAlerts(bool value) async {
    state = state.copyWith(whatsappAlerts: value);
    await _prefs.setBool(_waAlerts, value);
  }

  Future<void> setConflictDetection(bool value) async {
    state = state.copyWith(conflictDetection: value);
    await _prefs.setBool(_conflict, value);
  }

  Future<void> saveWaTemplate(String value) async {
    state = state.copyWith(waTemplate: value);
    await _prefs.setString(_wa, value);
  }

  Future<void> saveRecurringTemplate(String value) async {
    state = state.copyWith(recurringWaTemplate: value);
    await _prefs.setString(_recurWa, value);
  }

  Future<void> saveSmsTemplate(String value) async {
    state = state.copyWith(smsTemplate: value);
    await _prefs.setString(_sms, value);
  }

  Future<void> saveGround({
    required String name,
    required String address,
    required String contact,
    required String opens,
    required String closes,
  }) async {
    state = state.copyWith(
      groundName: name,
      address: address,
      contact: contact,
      opens: opens,
      closes: closes,
    );
    await Future.wait([
      _prefs.setString(_ground, name),
      _prefs.setString(_address, address),
      _prefs.setString(_contact, contact),
      _prefs.setString(_opens, opens),
      _prefs.setString(_closes, closes),
    ]);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
