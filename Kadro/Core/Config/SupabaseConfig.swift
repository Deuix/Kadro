import Foundation

enum SupabaseConfig {
    /// Public project URL. Safe to ship in the app.
    static let projectURLString = "https://hzxncydkkbwqwegcxkmz.supabase.co"
    
    /// Legacy anon JWT key is used for Edge Function calls with verify_jwt=true.
    /// This is low-privilege and safe to embed in a mobile app.
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh6eG5jeWRra2J3cXdlZ2N4a216Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQyNTI4MzIsImV4cCI6MjA4OTgyODgzMn0.H8QfBNpQ4txZdjrwbYC-1XRT_ZXQ1lk-eivIwEkAD6c"
    
    static let generateContentFunctionName = "generate-content"
    
    static var generateContentURL: URL {
        URL(string: projectURLString + "/functions/v1/" + generateContentFunctionName)!
    }
}
