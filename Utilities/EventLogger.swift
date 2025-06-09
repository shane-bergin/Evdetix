import Foundation

enum EventLogger {

    static let logURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = dir.appendingPathComponent("Evdetix", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("EventLog.json")
    }()

    static func load() -> [EventLog] {
        guard let data = try? Data(contentsOf: logURL),
              let logs = try? JSONDecoder().decode([EventLog].self, from: data) else {
            return []
        }
        return logs
    }

    static func save(_ logs: [EventLog]) {
        if let data = try? JSONEncoder().encode(logs) {
            try? data.write(to: logURL)
        }
    }

    static func append(_ log: EventLog) {
        var logs = load()
        logs.append(log)
        save(logs)
    }

    private static let categoryListKey = "TimerCategories"

    static func loadCategories() -> [String] {
        UserDefaults.standard.stringArray(forKey: categoryListKey) ?? []
    }

    static func saveCategories(_ categories: [String]) {
        UserDefaults.standard.set(categories, forKey: categoryListKey)
    }
}
