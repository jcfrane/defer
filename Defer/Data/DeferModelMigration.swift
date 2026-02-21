import Foundation

enum DeferModelMigration {
    enum StoreVersion: Int {
        case v1 = 1
    }

    private static let schemaVersionKey = "swiftdata.schema.version"
    private static let currentVersion = StoreVersion.v1.rawValue

    static func prepareStore(defaults: UserDefaults = .standard) {
        let storedVersion = defaults.integer(forKey: schemaVersionKey)

        if storedVersion == 0 {
            defaults.set(currentVersion, forKey: schemaVersionKey)
            return
        }

        guard storedVersion < currentVersion else { return }

        runMigrations(from: storedVersion, to: currentVersion, defaults: defaults)
        defaults.set(currentVersion, forKey: schemaVersionKey)
    }

    private static func runMigrations(from oldVersion: Int, to newVersion: Int, defaults: UserDefaults) {
        for version in (oldVersion + 1)...newVersion {
            migrate(to: version, defaults: defaults)
        }
    }

    private static func migrate(to version: Int, defaults: UserDefaults) {
        switch version {
        case StoreVersion.v1.rawValue:
            // Baseline schema: nothing to transform.
            break
        default:
            break
        }
    }
}
