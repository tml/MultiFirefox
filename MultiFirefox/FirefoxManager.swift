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

    nonisolated static func isFirefoxApp(_ name: String) -> Bool {
        let lower = name.lowercased()
        return (lower.hasPrefix("firefox") || lower.hasPrefix("minefield"))
            && name.hasSuffix(".app")
    }

    nonisolated static func filterVersions(from names: [String]) -> [String] {
        names
            .filter { isFirefoxApp($0) }
            .map { String($0.dropLast(4)) }
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

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

    nonisolated static func buildAppBundle(version: String, profile: String, in directory: URL) {
        let appDir = directory.appendingPathComponent("\(version)-\(profile).app")
        let macosDir = appDir.appendingPathComponent("Contents/MacOS")
        let launcher = macosDir.appendingPathComponent("launcher")
        let infoPlist = appDir.appendingPathComponent("Contents/Info.plist")

        let fm = FileManager.default
        try? fm.createDirectory(at: macosDir, withIntermediateDirectories: true)

        let script = """
#!/bin/bash
open -na "/Applications/\(version).app" --args -no-remote -P "\(profile)"
"""
        try? script.write(to: launcher, atomically: true, encoding: .utf8)

        let bundleId = "com.multifirefox.shortcut.\(version.lowercased().replacingOccurrences(of: " ", with: "-"))-\(profile.lowercased())"
        let plist = """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>launcher</string>
    <key>CFBundleName</key>
    <string>\(version)-\(profile)</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIdentifier</key>
    <string>\(bundleId)</string>
</dict>
</plist>
"""
        try? plist.write(to: infoPlist, atomically: true, encoding: .utf8)

        try? FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: launcher.path
        )
    }

    func createApplication(version: String, profile: String) {
        let desktop = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Desktop")
        Self.buildAppBundle(version: version, profile: profile, in: desktop)
    }

    // MARK: - Init and loading

    init() { load() }

    func load() {
        versions = Self.loadVersions()
        profiles = Self.loadProfiles()
    }

    func reloadProfiles() {
        profiles = Self.loadProfiles()
    }

    nonisolated static func loadVersions() -> [String] {
        guard let enumerator = FileManager.default.enumerator(atPath: applicationsPath) else {
            return []
        }
        var result: [String] = []
        while let name = enumerator.nextObject() as? String {
            let lower = name.lowercased()
            if isFirefoxApp(name) {
                result.append(String((name as NSString).lastPathComponent.dropLast(4)))
                enumerator.skipDescendants()
            } else if !(lower.hasPrefix("firefox") || lower.hasPrefix("minefield")) {
                enumerator.skipDescendants()
            }
        }
        return result.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    nonisolated static func loadProfiles() -> [String] {
        guard let content = try? String(contentsOfFile: profilesIniPath, encoding: .utf8) else {
            return []
        }
        return parseProfiles(from: content)
    }

    // MARK: - Launching

    func launch(version: String, profile: String) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        p.arguments = [
            "-na", "\(Self.applicationsPath)/\(version).app",
            "--args", "-no-remote", "-P", profile
        ]
        try? p.run()
        NSApplication.shared.terminate(nil)
    }

    func openProfileManager(version: String) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        p.arguments = [
            "-n", "\(Self.applicationsPath)/\(version).app",
            "--args", "--profilemanager"
        ]
        try? p.run()
    }
}
