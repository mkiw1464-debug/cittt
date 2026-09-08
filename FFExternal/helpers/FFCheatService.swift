import Foundation

// MARK: - Constants

enum FFGame: String, CaseIterable {
    case freeFire    = "com.dts.freefireth"
    case freefireMax = "com.dts.freefiremax"

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

    /// Folder name inside the GitHub repo
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

/// Maps each feature to its GitHub raw URL.
/// Folder structure in repo:
///   /Free Fire/<Feature>/<file>
///   /Free Fire Max/<Feature>/<file>
enum FFCheatManifest {
    static let repoBase = "https://raw.githubusercontent.com/mkiw1464-debug/kntollshahhaha/main"

    /// Target filename inside gameassetbundles/
    static let targetFileName = "cache_res.CfnFf59sr1SbsqQ6JqTKsEusjKs~3D"

    static func rawURL(game: FFGame, feature: FFFeature) -> URL? {
        let gamePath: String
        switch game {
        case .freeFire:    gamePath = "Free%20Fire"
        case .freefireMax: gamePath = "Free%20Fire%20Max"
        }
        let urlString = "\(repoBase)/\(gamePath)/\(feature.folderName)/\(targetFileName)"
        return URL(string: urlString)
    }

    /// Checks if a cheat file exists on GitHub (HEAD request).
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

    /// Downloads cheat file data from GitHub.
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
    /// Target path relative to the app's Data container root
    /// Full path = <containerRoot>/Documents/contentcache/Compulsory/ios/gameassetbundles/<targetFileName>
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

    /// Downloads cheat data and replaces the target game asset file.
    /// Backs up the original first.
    static func inject(game: FFGame, feature: FFFeature) async throws {
        let bundleID = game.rawValue

        // 1. Resolve container
        guard let containerPath = ContainerStore.resolveAppContainerPath(bundleID: bundleID) else {
            throw FFCheatError.containerNotFound(bundleID)
        }

        // Grant sandbox access if needed (iOS 26+)
        let handle = ContainerStore.grantContainerAccess(containerPath)
        defer { if handle >= 0 { bad_query_release(handle) } }

        let target = targetURL(containerPath: containerPath)
        let fm = FileManager.default

        // 2. Ensure target exists
        guard fm.fileExists(atPath: target.path) else {
            throw FFCheatError.targetFileMissing
        }

        // 3. Backup original if not already backed up
        let backup = backupURL(bundleID: bundleID)
        if !fm.fileExists(atPath: backup.path) {
            do {
                try fm.copyItem(at: target, to: backup)
                log("ffext: backed up \(bundleID) -> \(backup.lastPathComponent)")
            } catch {
                throw FFCheatError.backupFailed
            }
        }

        // 4. Download cheat file
        let cheatData = try await FFCheatManifest.download(game: game, feature: feature)
        log("ffext: downloaded \(feature.rawValue) (\(cheatData.count) bytes)")

        // 5. Write to temp then rename atomically
        let tmpURL = target.deletingLastPathComponent()
            .appendingPathComponent(".ffext-tmp-\(UUID().uuidString)")

        do {
            guard fm.createFile(atPath: tmpURL.path, contents: cheatData) else {
                throw FFCheatError.replacementFailed("createFile failed")
            }
            guard rename(tmpURL.path, target.path) == 0 else {
                try? fm.removeItem(at: tmpURL)
                throw FFCheatError.replacementFailed("rename errno=\(errno)")
            }
            log("ffext: inject OK \(bundleID) \(feature.rawValue)")
        } catch let e as FFCheatError {
            throw e
        } catch {
            throw FFCheatError.replacementFailed(error.localizedDescription)
        }
    }

    // MARK: Restore

    /// Restores the backed-up original file.
    static func restore(game: FFGame) throws {
        let bundleID = game.rawValue

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
            log("ffext: restore OK \(bundleID)")
        } catch {
            throw FFCheatError.restoreFailed
        }
    }
}
