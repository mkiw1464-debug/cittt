import Foundation

// MARK: - String Decryptor (shared key 0x5A)

private enum _X {
    static let k: UInt8 = 0x5A
    static func d(_ b: [UInt8]) -> String {
        String(bytes: b.map { $0 ^ k }, encoding: .utf8) ?? ""
    }
}

// MARK: - Constants

enum FFGame: String, CaseIterable {
    case freeFire    = "__ff"
    case freefireMax = "__ffmax"

    var bundleID: String {
        switch self {
        case .freeFire:
            return _X.d([0x39,0x35,0x37,0x74,0x3e,0x2e,0x29,0x74,
                         0x3c,0x28,0x3f,0x3f,0x3c,0x33,0x28,0x3f,0x2e,0x32])
        case .freefireMax:
            return _X.d([0x39,0x35,0x37,0x74,0x3e,0x2e,0x29,0x74,
                         0x3c,0x28,0x3f,0x3f,0x3c,0x33,0x28,0x3f,0x37,0x3b,0x22])
        }
    }

    var plistRelativePath: String {
        switch self {
        case .freeFire:
            return _X.d([0x16,0x33,0x38,0x28,0x3b,0x28,0x23,0x75,0x0a,
                         0x28,0x3f,0x3c,0x3f,0x28,0x3f,0x34,0x39,0x3f,0x29,
                         0x75,0x39,0x35,0x37,0x74,0x3e,0x2e,0x29,0x74,0x3c,
                         0x28,0x3f,0x3f,0x3c,0x33,0x28,0x3f,0x2e,0x32,0x74,
                         0x2a,0x36,0x33,0x29,0x2e])
        case .freefireMax:
            return _X.d([0x16,0x33,0x38,0x28,0x3b,0x28,0x23,0x75,0x0a,
                         0x28,0x3f,0x3c,0x3f,0x28,0x3f,0x34,0x39,0x3f,0x29,
                         0x75,0x39,0x35,0x37,0x74,0x3e,0x2e,0x29,0x74,0x3c,
                         0x28,0x3f,0x3f,0x3c,0x33,0x28,0x3f,0x37,0x3b,0x22,
                         0x74,0x2a,0x36,0x33,0x29,0x2e])
        }
    }

    var plistFileName: String {
        switch self {
        case .freeFire:
            return _X.d([0x39,0x35,0x37,0x74,0x3e,0x2e,0x29,0x74,0x3c,
                         0x28,0x3f,0x3f,0x3c,0x33,0x28,0x3f,0x2e,0x32,0x74,
                         0x2a,0x36,0x33,0x29,0x2e])
        case .freefireMax:
            return _X.d([0x39,0x35,0x37,0x74,0x3e,0x2e,0x29,0x74,0x3c,
                         0x28,0x3f,0x3f,0x3c,0x33,0x28,0x3f,0x37,0x3b,0x22,
                         0x74,0x2a,0x36,0x33,0x29,0x2e])
        }
    }

    var displayName: String {
        switch self {
        case .freeFire:    return "Free Fire"
        case .freefireMax: return "Free Fire Max"
        }
    }
}

// MARK: - Documents filenames (obfuscated same as original)

private enum ESPFiles {
    private static let _cfg:   [UInt8] = [0x39,0x35,0x34,0x3c,0x33,0x3d,0x74,0x38,0x33,0x34]
    private static let _local: [UInt8] = [0x36,0x35,0x39,0x3b,0x36,0x19,0x35,0x34,0x3c,0x33,
                                           0x3d,0x74,0x30,0x29,0x35,0x34]
    private static let _patch: [UInt8] = [0x1b,0x29,0x29,0x3f,0x37,0x38,0x36,0x23,0x77,0x19,
                                           0x09,0x32,0x3b,0x28,0x2a,0x77,0x2a,0x3b,0x2e,0x39,
                                           0x32,0x74,0x38,0x23,0x2e,0x3f,0x29]

    static var configBin:   String { _X.d(_cfg) }
    static var localConfig: String { _X.d(_local) }
    static var patchBytes:  String { _X.d(_patch) }
    static var documentsFiles: [String] { [configBin, localConfig, patchBytes] }
}

// MARK: - GitHub Manifest (unchanged from original)

enum FFCheatManifest {
    private static let _rb: [UInt8] = [
        0x32,0x2e,0x2e,0x2a,0x29,0x60,0x75,0x75,
        0x28,0x3b,0x2d,0x74,0x3d,0x33,0x2e,0x32,
        0x2f,0x38,0x2f,0x29,0x3f,0x28,0x29,0x35,
        0x34,0x2e,0x3f,0x34,0x2e,0x74,0x39,0x35,
        0x37,0x75,0x37,0x31,0x33,0x2d,0x6b,0x6e,
        0x6c,0x6e,0x77,0x3e,0x3f,0x38,0x2f,0x3d,
        0x75,0x39,0x33,0x2e,0x38,0x3b,0x28,0x2f,
        0x75,0x37,0x3b,0x33,0x34
    ]
    private static let _tf: [UInt8] = [
        0x39,0x3b,0x39,0x32,0x3f,0x05,0x28,0x3f,0x29,0x74,0x19,0x3c,
        0x34,0x1c,0x3c,0x6f,0x63,0x29,0x28,0x6b,0x09,0x38,0x29,0x2b,
        0x0b,0x6c,0x10,0x2b,0x0e,0x11,0x29,0x1f,0x2f,0x29,0x30,0x11,
        0x29,0x24,0x69,0x1e
    ]

    static var repoBase:       String { _X.d(_rb) }
    static var targetFileName: String { _X.d(_tf) }

    private static func gameSegment(_ game: FFGame) -> String {
        switch game {
        case .freeFire:    return "Free%20Fire"
        case .freefireMax: return "Free%20Fire%20Max"
        }
    }

    static func rawURL(game: FFGame, feature: FFFeature, fileName: String? = nil) -> URL? {
        let name = fileName ?? targetFileName
        return URL(string: "\(repoBase)/\(gameSegment(game))/\(feature.folderName)/\(name)")
    }

    static func checkAvailability(game: FFGame, feature: FFFeature) async -> Bool {
        if feature.isESP {
            let filesToCheck = ESPFiles.documentsFiles + [game.plistFileName]
            for name in filesToCheck {
                guard let url = rawURL(game: game, feature: feature, fileName: name) else { return false }
                var req = URLRequest(url: url); req.httpMethod = "HEAD"; req.timeoutInterval = 8
                do {
                    let (_, r) = try await URLSession.shared.data(for: req)
                    if (r as? HTTPURLResponse)?.statusCode != 200 { return false }
                } catch { return false }
            }
            return true
        }
        guard let url = rawURL(game: game, feature: feature) else { return false }
        var req = URLRequest(url: url); req.httpMethod = "HEAD"; req.timeoutInterval = 8
        do {
            let (_, r) = try await URLSession.shared.data(for: req)
            return (r as? HTTPURLResponse)?.statusCode == 200
        } catch { return false }
    }

    static func download(game: FFGame, feature: FFFeature, fileName: String? = nil) async throws -> Data {
        guard let url = rawURL(game: game, feature: feature, fileName: fileName) else {
            throw FFCheatError.fileUnavailable
        }
        let (data, response) = try await URLSession.shared.data(for: URLRequest(url: url, timeoutInterval: 30))
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw FFCheatError.fileUnavailable }
        return data
    }
}

// MARK: - FFFeature

enum FFFeature: String, CaseIterable {
    case esp         = "ESP"

    var folderName:   String { rawValue }
    var displayName:  String { "ESP" }
    var isESP:        Bool   { true }
}

// MARK: - Errors

enum FFCheatError: LocalizedError {
    case containerNotFound(String)
    case fileUnavailable
    case targetFileMissing
    case replacementFailed(String)
    case backupFailed
    case restoreFailed
    case noBackup

    var errorDescription: String? {
        switch self {
        case .containerNotFound(let id): return "Container not found: \(id)"
        case .fileUnavailable:           return "Cheat file unavailable"
        case .targetFileMissing:         return "Target file not found"
        case .replacementFailed(let r):  return "Replace failed: \(r)"
        case .backupFailed:              return "Backup failed"
        case .restoreFailed:             return "Restore failed"
        case .noBackup:                  return "No backup — inject first"
        }
    }
}

// MARK: - Backups

private enum Backups {
    static var dir: String {
        let p = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? "/tmp")
            + "/ffext_backups"
        try? FileManager.default.createDirectory(atPath: p, withIntermediateDirectories: true)
        return p
    }
    static func plistURL(bundleID: String) -> URL {
        URL(fileURLWithPath: dir).appendingPathComponent("\(bundleID)_plist.bak")
    }
}

// MARK: - FFCheatService

enum FFCheatService {

    static func espDocsURL(containerPath: String) -> URL {
        URL(fileURLWithPath: containerPath).appendingPathComponent("Documents")
    }

    static func plistTargetURL(containerPath: String, game: FFGame) -> URL {
        URL(fileURLWithPath: containerPath).appendingPathComponent(game.plistRelativePath)
    }

    static func hasBackup(bundleID: String) -> Bool {
        FileManager.default.fileExists(atPath: Backups.plistURL(bundleID: bundleID).path)
    }

    // MARK: - Write config files dari CheatConfig (ON/OFF buttons)
    // Dipanggil setiap kali user toggle feature — tulis terus ke container.
    // TIDAK download apa-apa. TIDAK inject baru.
    // Assembly-CSharp-patch.bytes mesti dah ada (dari inject pertama).

    static func applyConfig(_ cfg: CheatConfig, game: FFGame) throws {
        let bundleID = game.bundleID
        guard let containerPath = ContainerStore.resolveAppContainerPath(bundleID: bundleID) else {
            throw FFCheatError.containerNotFound(bundleID)
        }
        let handle = ContainerStore.grantContainerAccess(containerPath)
        defer { if handle >= 0 { bad_query_release(handle) } }

        let fm = FileManager.default

        // 1. config.bin → Documents/
        let docsURL = espDocsURL(containerPath: containerPath)
        try fm.createDirectory(at: docsURL, withIntermediateDirectories: true)
        try cfg.buildConfigBin()
            .write(to: docsURL.appendingPathComponent(ESPFiles.configBin), options: .atomic)

        // 2. localConfig.json → Documents/
        try cfg.buildLocalConfigJSON()
            .write(to: docsURL.appendingPathComponent(ESPFiles.localConfig), options: .atomic)

        // 3. plist → Library/Preferences/
        let plistTarget = plistTargetURL(containerPath: containerPath, game: game)
        try fm.createDirectory(
            at: plistTarget.deletingLastPathComponent(),
            withIntermediateDirectories: true)

        // Read existing plist to preserve game keys, then merge cheat keys on top
        let existingData = fm.fileExists(atPath: plistTarget.path)
            ? try? Data(contentsOf: plistTarget)
            : nil

        var base: [String: Any] = [:]
        if let d = existingData,
           let parsed = try? PropertyListSerialization.propertyList(from: d, options: [], format: nil)
            as? [String: Any] {
            base = parsed
        }
        let merged = cfg.buildPlistDict(base: base)
        let plistData = try PropertyListSerialization.data(
            fromPropertyList: merged, format: .xml, options: 0)
        try plistData.write(to: plistTarget, options: .atomic)

        log("ffext: config applied \(bundleID)")
    }

    // MARK: - First inject (downloads Assembly-CSharp-patch.bytes + initial files)
    // Dipanggil sekali je bila user tekan INJECT buat pertama kali.
    // Lepas ni, guna applyConfig untuk update features.

    static func inject(game: FFGame, cfg: CheatConfig) async throws {
        let bundleID = game.bundleID
        guard let containerPath = ContainerStore.resolveAppContainerPath(bundleID: bundleID) else {
            throw FFCheatError.containerNotFound(bundleID)
        }
        let handle = ContainerStore.grantContainerAccess(containerPath)
        defer { if handle >= 0 { bad_query_release(handle) } }

        let fm      = FileManager.default
        let docsURL = espDocsURL(containerPath: containerPath)
        try fm.createDirectory(at: docsURL, withIntermediateDirectories: true)

        // 1. Download Assembly-CSharp-patch.bytes dari GitHub
        let patchData = try await FFCheatManifest.download(game: game, feature: .esp,
                                                            fileName: ESPFiles.patchBytes)
        let patchDest = docsURL.appendingPathComponent(ESPFiles.patchBytes)
        let patchTmp  = docsURL.appendingPathComponent(".\(UUID().uuidString)")
        guard fm.createFile(atPath: patchTmp.path, contents: patchData) else {
            throw FFCheatError.replacementFailed("createFile patch")
        }
        guard rename(patchTmp.path, patchDest.path) == 0 else {
            try? fm.removeItem(at: patchTmp)
            throw FFCheatError.replacementFailed("rename patch")
        }
        log("ffext: patch.bytes injected")

        // 2. Write config files (config.bin + localConfig.json + plist) dari user settings
        try applyConfig(cfg, game: game)

        // 3. Save plist backup supaya boleh restore
        let plistTarget = plistTargetURL(containerPath: containerPath, game: game)
        let plistBackup = Backups.plistURL(bundleID: bundleID)
        if fm.fileExists(atPath: plistTarget.path), !fm.fileExists(atPath: plistBackup.path) {
            try? fm.copyItem(at: plistTarget, to: plistBackup)
        }
        log("ffext: inject complete \(bundleID)")
    }

    // MARK: - Restore (buang semua cheat files, restore plist asal)

    static func restore(game: FFGame) throws {
        let bundleID = game.bundleID
        guard let containerPath = ContainerStore.resolveAppContainerPath(bundleID: bundleID) else {
            throw FFCheatError.containerNotFound(bundleID)
        }
        let handle = ContainerStore.grantContainerAccess(containerPath)
        defer { if handle >= 0 { bad_query_release(handle) } }

        let fm = FileManager.default
        let plistBackup = Backups.plistURL(bundleID: bundleID)
        guard fm.fileExists(atPath: plistBackup.path) else { throw FFCheatError.noBackup }

        // Delete 3 Documents files
        let docsURL = espDocsURL(containerPath: containerPath)
        for fileName in ESPFiles.documentsFiles {
            try? fm.removeItem(at: docsURL.appendingPathComponent(fileName))
        }

        // Restore plist asal
        let plistTarget = plistTargetURL(containerPath: containerPath, game: game)
        _ = try? FileReplacementService.replace(target: plistTarget, with: plistBackup)
        try? fm.removeItem(at: plistBackup)
        log("ffext: restore complete \(bundleID)")
    }
}
