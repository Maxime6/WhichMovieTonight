//
//  DIContainer.swift
//  WhichMovieTonight
//
//  Created by AI Assistant on 25/04/2025.
//

import Foundation

// MARK: - Dependency Container Protocol

protocol DIContainerProtocol {
    func register<T>(_ type: T.Type, factory: @escaping () -> T)
    func resolve<T>(_ type: T.Type) -> T
    func unregister<T>(_ type: T.Type)
}

// MARK: - Dependency Container Implementation

final class DIContainer: DIContainerProtocol {
    static let shared = DIContainer()

    private var factories: [String: Any] = [:]
    private let queue = DispatchQueue(label: "DIContainer.queue", attributes: .concurrent)

    private init() {}

    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        queue.async(flags: .barrier) {
            self.factories[key] = factory
        }
    }

    func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        return queue.sync {
            guard let factory = factories[key] as? () -> T else {
                fatalError("❌ No registration found for \(type). Please register this dependency first.")
            }
            return factory()
        }
    }

    func unregister<T>(_ type: T.Type) {
        let key = String(describing: type)
        queue.async(flags: .barrier) {
            self.factories.removeValue(forKey: key)
        }
    }
}

// MARK: - Property Wrapper for Dependency Injection

@propertyWrapper
struct Injected<T> {
    private let keyPath: WritableKeyPath<DIContainer, T>?

    var wrappedValue: T {
        if let keyPath = keyPath {
            return DIContainer.shared[keyPath: keyPath]
        } else {
            return DIContainer.shared.resolve(T.self)
        }
    }

    init() {
        keyPath = nil
    }

    init(_ keyPath: WritableKeyPath<DIContainer, T>) {
        self.keyPath = keyPath
    }
}

// MARK: - Injectable Protocol

protocol Injectable {
    static func register(in container: DIContainerProtocol)
}

// MARK: - DI Extensions for Common Types

extension DIContainer {
    // Computed properties for easy access to common dependencies
    var userPreferencesService: UserPreferencesService {
        resolve(UserPreferencesService.self)
    }

    var userDataService: UserDataServiceProtocol {
        resolve(UserDataServiceProtocol.self)
    }

    var homeDataService: HomeDataServiceProtocol {
        resolve(HomeDataServiceProtocol.self)
    }

    var firestoreService: FirestoreServiceProtocol {
        resolve(FirestoreServiceProtocol.self)
    }

    var recommendationCacheService: RecommendationCacheServiceProtocol {
        resolve(RecommendationCacheServiceProtocol.self)
    }

    var notificationService: DailyNotificationServiceProtocol {
        resolve(DailyNotificationServiceProtocol.self)
    }
}

// MARK: - Dependency Registration Helper

enum DependencyManager {
    static func registerAllDependencies() {
        let container = DIContainer.shared

        // Register Services
        container.register(UserPreferencesService.self) {
            UserPreferencesService()
        }

        container.register(UserDataServiceProtocol.self) {
            UserMovieDataService()
        }

        container.register(HomeDataServiceProtocol.self) {
            HomeDataService()
        }

        container.register(FirestoreServiceProtocol.self) {
            FirestoreService()
        }

        container.register(RecommendationCacheServiceProtocol.self) {
            RecommendationCacheService()
        }

        container.register(DailyNotificationServiceProtocol.self) {
            DailyNotificationService()
        }

        // Register Repositories
        container.register(MovieRepository.self) {
            MovieRepositoryImpl()
        }

        // Register Use Cases
        container.register(GetDailyRecommendationsUseCase.self) {
            GetDailyRecommendationsUseCaseImpl(
                repository: container.resolve(MovieRepository.self)
            )
        }
    }
}
