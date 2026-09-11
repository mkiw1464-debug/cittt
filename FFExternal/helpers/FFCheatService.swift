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
            // "com.dts.freefireth"
            return _X.d([0x39, 0x35, 0x37, 0x74, 0x3e, 0x2e, 0x29, 0x74,
                         0x3c, 0x28, 0x3f, 0x3f, 0x3c, 0x33, 0x28, 0x3f, 0x2e, 0x32])
        case .freefireMax:
            // "com.dts.freefiremax"
            return _X.d([0x39, 0x35, 0x37, 0x74, 0x3e, 0x2e, 0x29, 0x74,
                         0x3c, 0x28, 0x3f, 0x3f, 0x3c, 0x33, 0x28, 0x3f, 0x37, 0x3b, 0x22])
        }
    }

    var displayName: String {
        switch self {
        case .freeFire:    return "Free Fire"
        case .freefireMax: return "Free Fire Max"
        }
    }
}

enum FFFeature: String, CaseIterable {
    case aimBody     = "AimBody"
    case aimNeck     = "AimNeck"
    case aimDrag     = "AimDrag"
    case magicBullet = "MagicBullet"
    case aimChest    = "AimChest"
    case esp         = "ESP"

    var folderName: String { rawValue }

    var displayName: String {
        switch self {
        case .aimBody:     return "AimBody"
        case .aimNeck:     return "AimNeck"
        case .aimDrag:     return "AimDrag"
        case .magicBullet: return "Magic Bullet"
        case .aimChest:    return "AimChest"
        case .esp:         return "ESP"
        }
    }

    /// ESP guna flow inject-3-file ke Documents, bukan cache_res replacement
    var isESP: Bool { self == .esp }
}

// MARK: - ESP File Names (injected into game Documents/)

private enum ESPFiles {
    // "config.bin"
    private static let _cfg:   [UInt8] = [0x39, 0x35, 0x34, 0x3c, 0x33, 0x3d, 0x74, 0x38, 0x33, 0x34]
    // "localConfig.json"
    private static let _local: [UInt8] = [0x36, 0x35, 0x39, 0x3b, 0x36, 0x19, 0x35, 0x34, 0x3c, 0x33,
                                           0x3d, 0x74, 0x30, 0x29, 0x35, 0x34]
    // "Assembly-CSharp-patch.bytes"
    private static let _patch: [UInt8] = [0x1b, 0x29, 0x29, 0x3f, 0x37, 0x38, 0x36, 0x23, 0x77, 0x19,
                                           0x09, 0x32, 0x3b, 0x28, 0x2a, 0x77, 0x2a, 0x3b, 0x2e, 0x39,
                                           0x32, 0x74, 0x38, 0x23, 0x2e, 0x3f, 0x29]

    static var configBin:   String { _X.d(_cfg) }
    static var localConfig: String { _X.d(_local) }
    static var patchBytes:  String { _X.d(_patch) }
    static var all:         [String] { [configBin, localConfig, patchBytes] }
}

// MARK: - GitHub Manifest

enum FFCheatManifest {
    // "https://raw.githubusercontent.com/mkiw1464-debug/citbaru/main"
    private static let _rb: [UInt8] = [
        0x32, 0x2e, 0x2e, 0x2a, 0x29, 0x60, 0x75, 0x75,
        0x28, 0x3b, 0x2d, 0x74, 0x3d, 0x33, 0x2e, 0x32,
        0x2f, 0x38, 0x2f, 0x29, 0x3f, 0x28, 0x39, 0x35,
        0x34, 0x2e, 0x3f, 0x34, 0x2e, 0x74, 0x39, 0x35,
        0x37, 0x75, 0x37, 0x31, 0x33, 0x2d, 0x6b, 0x6e,
        0x6c, 0x6e, 0x77, 0x3e, 0x3f, 0x38, 0x2f, 0x3d,
        0x75, 0x39, 0x33, 0x2e, 0x38, 0x3b, 0x28, 0x2f,
        0x75, 0x37, 0x3b, 0x33, 0x34
    ]

    // "cache_res.CfnFf59sr1SbsqQ6JqTKsEusjKs~3D"
    private static let _tf: [UInt8] = [
        0x39, 0x3b, 0x39, 0x32, 0x3f, 0x05, 0x28, 0x3f, 0x29, 0x74, 0x19, 0x3c,
        0x34, 0x1c, 0x3c, 0x6f, 0x63, 0x29, 0x28, 0x6b, 0x09, 0x38, 0x29, 0x2b,
        0x0b, 0x6c, 0x10, 0x2b, 0x0e, 0x11, 0x29, 0x1f, 0x2f, 0x29, 0x30, 0x11,
        0x29, 0x24, 0x69, 0x1e
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
            for name in ESPFiles.all {
                guard let url = rawURL(game: game, feature: feature, fileName: name) else { return false }
                var req = URLRequest(url: url)
                req.httpMethod = "HEAD"
                req.timeoutInterval = 8
                do {
                    let (_, r) = try await URLSession.shared.data(for: req)
                    if (r as? HTTPURLResponse)?.statusCode != 200 { return false }
                } catch { return false }
            }
            return true
        }
        guard let url = rawURL(game: game, feature: feature) else { return false }
        var req = URLRequest(url: url)
        req.httpMethod = "HEAD"
        req.timeoutInterval = 8
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
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw FFCheatError.fileUnavailable
        }
        return data
    }
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
        case .containerNotFound(let id): return "App container not found: \(id)"
        case .fileUnavailable:           return "Cheat file unavailable (check GitHub)"
        case .targetFileMissing:         return "Target game asset file not found"
        case .replacementFailed(let r):  return "File replacement failed: \(r)"
        case .backupFailed:              return "Failed to create backup"
        case .restoreFailed:             return "Failed to restore original file"
        case .noBackup:                  return "No backup found — inject first"
        }
    }
}

// MARK: - Inject / Restore Service

enum FFCheatService {

    // MARK: Paths

    static func cacheResTargetURL(containerPath: String, game: FFGame) -> URL {
        URL(fileURLWithPath: containerPath, isDirectory: true)
            .appendingPathComponent("Documents/contentcache/Compulsory/ios/gameassetbundles")
            .appendingPathComponent(FFCheatManifest.targetFileName)
    }

    static func backupURL(bundleID: String, feature: FFFeature) -> URL {
        let backupsDir = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? "/tmp")
            + "/ffext_backups"
        try? FileManager.default.createDirectory(atPath: backupsDir, withIntermediateDirectories: true)
        return URL(fileURLWithPath: backupsDir)
            .appendingPathComponent("\(bundleID)_\(FFCheatManifest.targetFileName).bak")
    }

    static func espBackupDir(bundleID: String) -> URL {
        let backupsDir = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? "/tmp")
            + "/ffext_backups"
        try? FileManager.default.createDirectory(atPath: backupsDir, withIntermediateDirectories: true)
        return URL(fileURLWithPath: backupsDir)
            .appendingPathComponent("\(bundleID)_esp_backup")
    }

    static func hasBackup(bundleID: String) -> Bool {
        let fm = FileManager.default
        for feature in FFFeature.allCases where !feature.isESP {
            if fm.fileExists(atPath: backupURL(bundleID: bundleID, feature: feature).path) { return true }
        }
        return fm.fileExists(atPath: espBackupDir(bundleID: bundleID).path)
    }

    // MARK: Inject (entry)

    static func inject(game: FFGame, feature: FFFeature) async throws {
        let bundleID = game.bundleID
        guard let containerPath = ContainerStore.resolveAppContainerPath(bundleID: bundleID) else {
            throw FFCheatError.containerNotFound(bundleID)
        }
        let handle = ContainerStore.grantContainerAccess(containerPath)
        defer { if handle >= 0 { bad_query_release(handle) } }

        if feature.isESP {
            try await injectESP(game: game, bundleID: bundleID, containerPath: containerPath)
        } else {
            try await injectRegular(game: game, feature: feature, bundleID: bundleID, containerPath: containerPath)
        }
    }

    // MARK: Regular inject — replace cache_res file

    private static func injectRegular(
        game: FFGame,
        feature: FFFeature,
        bundleID: String,
        containerPath: String
    ) async throws {
        let target = cacheResTargetURL(containerPath: containerPath, game: game)
        let fm = FileManager.default

        guard fm.fileExists(atPath: target.path) else { throw FFCheatError.targetFileMissing }

        let backup = backupURL(bundleID: bundleID, feature: feature)
        if !fm.fileExists(atPath: backup.path) {
            do { try fm.copyItem(at: target, to: backup) }
            catch { throw FFCheatError.backupFailed }
        }

        let data = try await FFCheatManifest.download(game: game, feature: feature)
        let tmp  = target.deletingLastPathComponent().appendingPathComponent(".\(UUID().uuidString)")

        guard fm.createFile(atPath: tmp.path, contents: data) else {
            throw FFCheatError.replacementFailed("createFile failed")
        }
        guard rename(tmp.path, target.path) == 0 else {
            try? fm.removeItem(at: tmp)
            throw FFCheatError.replacementFailed("rename errno=\(errno)")
        }
        log("inject OK \(bundleID) \(feature.rawValue)")
    }

    // MARK: ESP inject — tambah 3 file ke Documents/

    private static func injectESP(
        game: FFGame,
        bundleID: String,
        containerPath: String
    ) async throws {
        let fm      = FileManager.default
        let docsURL = URL(fileURLWithPath: containerPath).appendingPathComponent("Documents")
        let bkpDir  = espBackupDir(bundleID: bundleID)
        try? fm.createDirectory(at: bkpDir, withIntermediateDirectories: true)

        for fileName in ESPFiles.all {
            let dest   = docsURL.appendingPathComponent(fileName)
            let bkpFile = bkpDir.appendingPathComponent(fileName)

            // Backup kalau file asal ada
            if fm.fileExists(atPath: dest.path) && !fm.fileExists(atPath: bkpFile.path) {
                try? fm.copyItem(at: dest, to: bkpFile)
            }

            let data = try await FFCheatManifest.download(game: game, feature: .esp, fileName: fileName)
            let tmp  = docsURL.appendingPathComponent(".\(UUID().uuidString)")
            guard fm.createFile(atPath: tmp.path, contents: data) else {
                throw FFCheatError.replacementFailed("createFile failed: \(fileName)")
            }
            guard rename(tmp.path, dest.path) == 0 else {
                try? fm.removeItem(at: tmp)
                throw FFCheatError.replacementFailed("rename failed: \(fileName)")
            }
            log("esp inject OK: \(fileName)")
        }
    }

    // MARK: Restore

    static func restore(game: FFGame) throws {
        let bundleID = game.bundleID
        guard let containerPath = ContainerStore.resolveAppContainerPath(bundleID: bundleID) else {
            throw FFCheatError.containerNotFound(bundleID)
        }
        let handle = ContainerStore.grantContainerAccess(containerPath)
        defer { if handle >= 0 { bad_query_release(handle) } }

        let fm = FileManager.default
        var anyRestored = false

        // Restore regular features
        for feature in FFFeature.allCases where !feature.isESP {
            let backup = backupURL(bundleID: bundleID, feature: feature)
            guard fm.fileExists(atPath: backup.path) else { continue }
            let target = cacheResTargetURL(containerPath: containerPath, game: game)
            _ = try? FileReplacementService.replace(target: target, with: backup)
            try? fm.removeItem(at: backup)
            log("restore OK \(bundleID)/\(feature.rawValue)")
            anyRestored = true
        }

        // ESP restore — delete 3 file (kalau ada backup, restore; kalau takde, delete je)
        let docsURL = URL(fileURLWithPath: containerPath).appendingPathComponent("Documents")
        let bkpDir  = espBackupDir(bundleID: bundleID)

        if fm.fileExists(atPath: bkpDir.path) {
            for fileName in ESPFiles.all {
                let dest    = docsURL.appendingPathComponent(fileName)
                let bkpFile = bkpDir.appendingPathComponent(fileName)
                if fm.fileExists(atPath: bkpFile.path) {
                    _ = try? FileReplacementService.replace(target: dest, with: bkpFile)
                } else {
                    try? fm.removeItem(at: dest)
                }
                log("esp restore: \(fileName)")
            }
            try? fm.removeItem(at: bkpDir)
            anyRestored = true
        }

        if !anyRestored { throw FFCheatError.noBackup }
    }
}
