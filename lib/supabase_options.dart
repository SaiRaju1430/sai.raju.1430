class SupabaseOptions {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://yelczpeowtvhosvwhzxf.supabase.co',
  );
  
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InllbGN6cGVvd3R2aG9zdndoenhmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgxNTkyNDEsImV4cCI6MjEwMzczNTI0MX0.p5BRWVDNvAk-Cy6uqTDEY6GxSM5QBV5_qOLiRWreE5E',
  );

  static const String webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '715352337545-3v7g0fet3pnt6utu72g3rfivuk623ihr.apps.googleusercontent.com',
  );

  static const String oneSignalAppId = String.fromEnvironment(
    'ONESIGNAL_APP_ID',
    defaultValue: 'YOUR_ONESIGNAL_APP_ID',
  );
}

