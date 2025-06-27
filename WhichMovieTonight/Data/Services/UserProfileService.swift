import Combine
import FirebaseFirestore
import Foundation

/// Service for managing user profile data including preferences on Firebase
/// Replaces UserPreferencesService with cloud storage and local caching
@MainActor
class UserProfileService: ObservableObject {
    private let db = Firestore.firestore()
    private let userDefaults = UserDefaults.standard

    // Cache keys for local fallback
    private let favoriteGenresKey = "cached_favoriteGenres"
    private let favoriteActorsKey = "cached_favoriteActors"
    private let favoriteStreamingPlatformsKey = "cached_favoriteStreamingPlatforms"
    private let lastSyncKey = "userProfile_lastSync"

    // Published properties for SwiftUI reactivity
    @Published var favoriteGenres: [MovieGenre] = []
    @Published var favoriteActors: [String] = []
    @Published var favoriteStreamingPlatforms: [StreamingPlatform] = []
    @Published var isLoading = false

    // Cache management
    private let cacheExpirationMinutes = 30
    private var lastSyncDate: Date? {
        get { userDefaults.object(forKey: lastSyncKey) as? Date }
        set { userDefaults.set(newValue, forKey: lastSyncKey) }
    }

    init() {
        loadCachedPreferences()
    }

    // MARK: - Public Methods

    /// Load user preferences with Firebase sync
    func loadUserPreferences(userId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Check if cache is still valid
            if let lastSync = lastSyncDate,
               Date().timeIntervalSince(lastSync) < Double(cacheExpirationMinutes * 60)
            {
                print("📱 Using cached user preferences (last sync: \(lastSync))")
                return
            }

            // Fetch from Firebase
            let userProfile = try await fetchUserProfile(userId: userId)

            // Update published properties
            favoriteGenres = userProfile.favoriteGenres
            favoriteActors = userProfile.favoriteActors
            favoriteStreamingPlatforms = userProfile.favoriteStreamingPlatforms

            // Cache locally
            cachePreferences()
            lastSyncDate = Date()

            print("✅ User preferences loaded from Firebase")

        } catch {
            print("⚠️ Failed to load user preferences from Firebase: \(error)")
            print("📱 Using cached preferences as fallback")
            loadCachedPreferences()
        }
    }

    /// Save user preferences to Firebase with local cache update
    func saveUserPreferences(userId: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let userProfile = UserProfile(
            favoriteGenres: favoriteGenres,
            favoriteActors: favoriteActors,
            favoriteStreamingPlatforms: favoriteStreamingPlatforms
        )

        try await saveUserProfile(userId: userId, userProfile: userProfile)

        // Update local cache
        cachePreferences()
        lastSyncDate = Date()

        print("✅ User preferences saved to Firebase")
    }

    /// Get current preferences as UserPreferences model
    func getUserPreferences() -> UserPreferences {
        return UserPreferences(
            favoriteGenres: favoriteGenres,
            favoriteActors: favoriteActors,
            favoriteStreamingPlatforms: favoriteStreamingPlatforms
        )
    }

    // MARK: - Genres Management

    func toggleGenre(_ genre: MovieGenre, userId: String) async {
        if favoriteGenres.contains(genre) {
            favoriteGenres.removeAll { $0 == genre }
        } else {
            favoriteGenres.append(genre)
        }

        do {
            try await saveUserPreferences(userId: userId)
        } catch {
            print("⚠️ Failed to save genre preference: \(error)")
        }
    }

    func isGenreSelected(_ genre: MovieGenre) -> Bool {
        favoriteGenres.contains(genre)
    }

    // MARK: - Actors Management

    func addActor(_ actor: String, userId: String) async {
        if !favoriteActors.contains(actor) {
            favoriteActors.append(actor)

            do {
                try await saveUserPreferences(userId: userId)
            } catch {
                print("⚠️ Failed to save actor preference: \(error)")
            }
        }
    }

    func removeActor(_ actor: String, userId: String) async {
        favoriteActors.removeAll { $0 == actor }

        do {
            try await saveUserPreferences(userId: userId)
        } catch {
            print("⚠️ Failed to save actor preference: \(error)")
        }
    }

    // MARK: - Streaming Platforms Management

    func toggleStreamingPlatform(_ platform: StreamingPlatform, userId: String) async {
        if favoriteStreamingPlatforms.contains(platform) {
            favoriteStreamingPlatforms.removeAll { $0 == platform }
        } else {
            favoriteStreamingPlatforms.append(platform)
        }

        do {
            try await saveUserPreferences(userId: userId)
        } catch {
            print("⚠️ Failed to save streaming platform preference: \(error)")
        }
    }

    func isStreamingPlatformSelected(_ platform: StreamingPlatform) -> Bool {
        favoriteStreamingPlatforms.contains(platform)
    }

    // MARK: - Private Methods

    /// Fetch user profile from Firebase
    private func fetchUserProfile(userId: String) async throws -> UserProfile {
        let document = try await db.collection("userProfiles").document(userId).getDocument()

        if document.exists, let data = document.data() {
            return try UserProfile(from: data)
        } else {
            // Return default profile for new users
            print("📝 Creating default user profile for new user")
            return UserProfile()
        }
    }

    /// Save user profile to Firebase
    private func saveUserProfile(userId: String, userProfile: UserProfile) async throws {
        let data = userProfile.toFirestoreData()
        try await db.collection("userProfiles").document(userId).setData(data, merge: true)
    }

    /// Load preferences from local cache
    private func loadCachedPreferences() {
        // Load genres
        if let data = userDefaults.data(forKey: favoriteGenresKey),
           let genreStrings = try? JSONDecoder().decode([String].self, from: data)
        {
            favoriteGenres = genreStrings.compactMap { MovieGenre(rawValue: $0) }
        }

        // Load actors
        if let actors = userDefaults.stringArray(forKey: favoriteActorsKey) {
            favoriteActors = actors
        }

        // Load streaming platforms
        if let data = userDefaults.data(forKey: favoriteStreamingPlatformsKey),
           let platformStrings = try? JSONDecoder().decode([String].self, from: data)
        {
            favoriteStreamingPlatforms = platformStrings.compactMap { StreamingPlatform(rawValue: $0) }
        }

        print("📱 Loaded cached user preferences")
    }

    /// Cache preferences locally for offline access
    private func cachePreferences() {
        // Cache genres
        let genreStrings = favoriteGenres.map { $0.rawValue }
        if let data = try? JSONEncoder().encode(genreStrings) {
            userDefaults.set(data, forKey: favoriteGenresKey)
        }

        // Cache actors
        userDefaults.set(favoriteActors, forKey: favoriteActorsKey)

        // Cache streaming platforms
        let platformStrings = favoriteStreamingPlatforms.map { $0.rawValue }
        if let data = try? JSONEncoder().encode(platformStrings) {
            userDefaults.set(data, forKey: favoriteStreamingPlatformsKey)
        }

        print("💾 Cached user preferences locally")
    }
}

// MARK: - UserProfile Model

struct UserProfile {
    var favoriteGenres: [MovieGenre] = []
    var favoriteActors: [String] = []
    var favoriteStreamingPlatforms: [StreamingPlatform] = []
    var createdAt: Date = .init()
    var updatedAt: Date = .init()

    init() {}

    init(favoriteGenres: [MovieGenre], favoriteActors: [String], favoriteStreamingPlatforms: [StreamingPlatform]) {
        self.favoriteGenres = favoriteGenres
        self.favoriteActors = favoriteActors
        self.favoriteStreamingPlatforms = favoriteStreamingPlatforms
        updatedAt = Date()
    }

    /// Initialize from Firestore data
    init(from data: [String: Any]) throws {
        if let genreStrings = data["favoriteGenres"] as? [String] {
            favoriteGenres = genreStrings.compactMap { MovieGenre(rawValue: $0) }
        }

        if let actors = data["favoriteActors"] as? [String] {
            favoriteActors = actors
        }

        if let platformStrings = data["favoriteStreamingPlatforms"] as? [String] {
            favoriteStreamingPlatforms = platformStrings.compactMap { StreamingPlatform(rawValue: $0) }
        }

        if let timestamp = data["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        }

        if let timestamp = data["updatedAt"] as? Timestamp {
            updatedAt = timestamp.dateValue()
        } else {
            updatedAt = Date()
        }
    }

    /// Convert to Firestore data
    func toFirestoreData() -> [String: Any] {
        return [
            "favoriteGenres": favoriteGenres.map { $0.rawValue },
            "favoriteActors": favoriteActors,
            "favoriteStreamingPlatforms": favoriteStreamingPlatforms.map { $0.rawValue },
            "createdAt": createdAt,
            "updatedAt": Date(),
        ]
    }

    /// Check if profile has valid preferences for recommendations
    var isValid: Bool {
        return !favoriteGenres.isEmpty && !favoriteStreamingPlatforms.isEmpty
    }
}
