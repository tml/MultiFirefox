import Foundation
import AppKit

@MainActor
final class FirefoxManager: ObservableObject {
    @Published var versions: [String] = []
    @Published var profiles: [String] = []

    private static let applicationsPath = "/Applications"
    private static let profilesIniPath =
        ("~/Library/Application Support/Firefox/profiles.ini" as NSString)
            .expandingTildeInPath

    nonisolated static func parseProfiles(from iniContent: String) -> [String] {
        var names: [String] = []
        for line in iniContent.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("Name=") {
                names.append(String(trimmed.dropFirst(5)))
            }
        }
        let others = names
            .filter { $0 != "default" }
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        return names.contains("default") ? ["default"] + others : others
    }
}
