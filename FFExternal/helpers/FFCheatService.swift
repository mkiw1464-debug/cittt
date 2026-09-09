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

    // Decoded at runtime — bundle IDs never appear as plaintext in binary
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
    case antena      = "Antena"
    case hologram    = "Hologram"

    var folderName: String { rawValue }

    var displayName: String {
        switch self {
        case .aimBody:     return "AimBody"
        case .aimNeck:     return "AimNeck"
        case .aimDrag:     return "AimDrag"
        case .magicBullet: return "Magic Bullet"
        case .antena:      return "Antena"
        case .hologram:    return "Hologram"
        }
    }
}

// MARK: - GitHub file manifest

enum FFCheatManifest {
    // "https://raw.githubusercontent.com/mkiw1464-debug/kntollshahhaha/main"
    private static let _rb: [UInt8] = [
        0x32, 0x2e, 0x2e, 0x2a, 0x29, 0x60, 0x75, 0x75, 0x28, 0x3b, 0x2d, 0x74,
        0x3d, 0x33, 0x2e, 0x32, 0x2f, 0x38, 0x2f, 0x29, 0x3f, 0x28, 0x39, 0x35,
        0x34, 0x2e, 0x3f, 0x34, 0x2e, 0x74, 0x39, 0x35, 0x37, 0x75, 0x37, 0x31,
        0x33, 0x2d, 0x6b, 0x6e, 0x6c, 0x6e, 0x77, 0x3e, 0x3f, 0x38, 0x2f, 0x3d,
        0x75, 0x31, 0x34, 0x2e, 0x35, 0x36, 0x36, 0x29, 0x32, 0x3b, 0x32, 0x32,
        0x3b, 0x32, 0x3b, 0x75, 0x37, 0x3b, 0x33, 0x34
    ]

    // "cache_res.CfnFf59sr1SbsqQ6JqTKsEusjKs~3D"
    private static let _tf: [UInt8] = [
        0x39, 0x3b, 0x39, 0x32, 0x3f, 0x05, 0x28, 0x3f, 0x29, 0x74, 0x19, 0x3c,
        0x34, 0x1c, 0x3c, 0x6f, 0x63, 0x29, 0x28, 0x6b, 0x09, 0x38, 0x29, 0x2b,
        0x0b, 0x6c, 0x10, 0x2b, 0x0e, 0x11, 0x29, 0x1f, 0x2f, 0x29, 0x30, 0x11,
        0x29, 0x24, 0x69, 0x1e
    ]

    static var repoBase:      String { _X.d(_rb) }
    static var targetFileName: String { _X.d(_tf) }

    static func rawURL(game: FFGame, feature: FFFeature) -> URL? {
        let gamePath: String
        switch game {
        // "Free%20Fire" / "Free%20Fire%20Max" — percent-encoded, safe as literal
        case .freeFire:    gamePath = "Free%20Fire"
        case .freefireMax: gamePath = "Free%20Fire%20Max"
        }
        let urlString = "\(repoBase)/\(gamePath)/\(feature.folderName)/\(targetFileName)"
        return URL(string: urlString)
    }

    static func checkAvailability(game: FFGame, feature: FFFeature) async -> Bool {
        guard let url = rawURL(game: game, feature: feature) else { return false }
        var req = URLRequest(url: url)
        req.httpMethod = "HEAD"
        req.timeoutInterval = 8
        do {
            let (_, response) = try await URLSession.shared.data(for: req)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    static func download(game: FFGame, feature: FFFeature) async throws -> Data {
        guard let url = rawURL(game: game, feature: feature) else {
            throw FFCheatError.fileUnavailable
        }
        let req = URLRequest(url: url, timeoutInterval: 30)
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
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
    static func targetURL(containerPath: String) -> URL {
        URL(fileURLWithPath: containerPath, isDirectory: true)
            .appendingPathComponent("Documents/contentcache/Compulsory/ios/gameassetbundles")
            .appendingPathComponent(FFCheatManifest.targetFileName)
    }

    static func backupURL(bundleID: String) -> URL {
        URL(fileURLWithPath: AppPaths.backups, isDirectory: true)
            .appendingPathComponent("\(bundleID)_\(FFCheatManifest.targetFileName).bak")
    }

    static func hasBackup(bundleID: String) -> Bool {
        FileManager.default.fileExists(atPath: backupURL(bundleID: bundleID).path)
    }

    // MARK: Inject

    static func inject(game: FFGame, feature: FFFeature) async throws {
        let bundleID = game.bundleID

        guard let containerPath = ContainerStore.resolveAppContainerPath(bundleID: bundleID) else {
            throw FFCheatError.containerNotFound(bundleID)
        }

        let handle = ContainerStore.grantContainerAccess(containerPath)
        defer { if handle >= 0 { bad_query_release(handle) } }

        let target = targetURL(containerPath: containerPath)
        let fm = FileManager.default

        guard fm.fileExists(atPath: target.path) else {
            throw FFCheatError.targetFileMissing
        }

        let backup = backupURL(bundleID: bundleID)
        if !fm.fileExists(atPath: backup.path) {
            do {
                try fm.copyItem(at: target, to: backup)
                log("backed up \(bundleID) -> \(backup.lastPathComponent)")
            } catch {
                throw FFCheatError.backupFailed
            }
        }

        let cheatData = try await FFCheatManifest.download(game: game, feature: feature)
        log("downloaded \(feature.rawValue) (\(cheatData.count) bytes)")

        let tmpURL = target.deletingLastPathComponent()
            .appendingPathComponent(".\(UUID().uuidString)")

        do {
            guard fm.createFile(atPath: tmpURL.path, contents: cheatData) else {
                throw FFCheatError.replacementFailed("createFile failed")
            }
            guard rename(tmpURL.path, target.path) == 0 else {
                try? fm.removeItem(at: tmpURL)
                throw FFCheatError.replacementFailed("rename errno=\(errno)")
            }
            log("inject OK \(bundleID) \(feature.rawValue)")
        } catch let e as FFCheatError {
            throw e
        } catch {
            throw FFCheatError.replacementFailed(error.localizedDescription)
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

        let backup = backupURL(bundleID: bundleID)
        guard FileManager.default.fileExists(atPath: backup.path) else {
            throw FFCheatError.noBackup
        }

        let target = targetURL(containerPath: containerPath)
        do {
            _ = try FileReplacementService.replace(target: target, with: backup)
            try? FileManager.default.removeItem(at: backup)
            log("restore OK \(bundleID)")
        } catch {
            throw FFCheatError.restoreFailed
        }
    }
}
