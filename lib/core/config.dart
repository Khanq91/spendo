class AppConfig {
  /// The cloud side of the app: Supabase auth, PowerSync sync and the SePay
  /// bank link. Off until the server side (RLS, sync rules, the SePay
  /// webhook) is in place — flipping this is the only change the app needs.
  ///
  /// Off: the splash skips the server step, the Settings hub has no "Ngân
  /// hàng tự động" row, and nothing touches `Supabase.instance`. On: the
  /// Sao lưu & đồng bộ page grows a "Tài khoản Spendo" group with sign-in,
  /// PowerSync connects once a session exists, and the bank page asks for a
  /// sign-in before it lets a mapping be added.
  static const cloudEnabled = false;

  static const supabaseUrl = 'https://emsrrdmtipcomfffbeus.supabase.co';
  static const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVtc3JyZG10aXBjb21mZmZiZXVzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcxODI3OTksImV4cCI6MjA5Mjc1ODc5OX0.6o94tAjiquEMRQCwpZcC_Zuj4TksdnRXe0mEIBko1j8';
  static const powerSyncUrl = 'https://69edbc468fe0e0dee71ea86d.powersync.journeyapps.com';
}