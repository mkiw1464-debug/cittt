import Foundation
import UIKit

// MARK: - Models

struct LicenseResponse: Codable {
    let valid: Bool
    let status: String?
    let expiresAt: String?
    let hwid: String?

    enum CodingKeys: String, CodingKey {
        case valid
        case status
        case expiresAt = "expires_at"
        case hwid
    }
}

struct LicenseInfo {
    let key: String
    let expiresAt: String
    let expiryDate: Date?
    let deviceName: String
    let hwid: String
    let iOSVersion: String
    let iPhoneModel: String
}

// MARK: - HWID

enum DeviceID {
    static var hwid: String {
        if let stored = UserDefaults.standard.string(forKey: "ffext_hwid") {
            return stored
        }
        let raw = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let hwid = "ios-\(raw.prefix(16).lowercased())"
        UserDefaults.standard.set(hwid, forKey: "ffext_hwid")
        return hwid
    }

    static var deviceName: String {
        UIDevice.current.name
    }

    /// Human-readable iPhone model e.g. "iPhone 15 Pro"
    static var iPhoneModel: String {
        var size: size_t = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        let identifier = String(cString: machine)
        return iPhoneModelName(from: identifier)
    }

    static var iOSVersion: String {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
    }

    // MARK: Model map (extend as needed)
    private static func iPhoneModelName(from identifier: String) -> String {
        let map: [String: String] = [
            // iPhone 16 series
            "iPhone17,1": "iPhone 16 Pro Max",
            "iPhone17,2": "iPhone 16 Pro",
            "iPhone17,3": "iPhone 16 Plus",
            "iPhone17,4": "iPhone 16",
            // iPhone 15 series
            "iPhone16,1": "iPhone 15 Pro Max",
            "iPhone16,2": "iPhone 15 Pro",
            "iPhone15,4": "iPhone 15 Plus",
            "iPhone15,5": "iPhone 15",
            // iPhone 14 series
            "iPhone15,2": "iPhone 14 Pro Max",
            "iPhone15,3": "iPhone 14 Pro",
            "iPhone14,7": "iPhone 14 Plus",
            "iPhone14,8": "iPhone 14",
            // iPhone 13 series
            // iPhone14,2 = iPhone 13 Pro  |  iPhone14,3 = iPhone 13 Pro Max
            "iPhone14,2": "iPhone 13 Pro",
            "iPhone14,3": "iPhone 13 Pro Max",
            "iPhone14,4": "iPhone 13 Mini",
            "iPhone14,5": "iPhone 13",
            // iPhone 12 series
            "iPhone13,1": "iPhone 12 Mini",
            "iPhone13,2": "iPhone 12",
            "iPhone13,3": "iPhone 12 Pro",
            "iPhone13,4": "iPhone 12 Pro Max",
            // iPhone 11 series
            "iPhone12,1": "iPhone 11",
            "iPhone12,3": "iPhone 11 Pro",
            "iPhone12,5": "iPhone 11 Pro Max",
            // Simulator
            "arm64": "Simulator",
            "x86_64": "Simulator",
        ]
        return map[identifier] ?? identifier
    }
}

// MARK: - Service

enum LicenseService {
    static let apiURL      = URL(string: "https://ffexxxx.vercel.app/api/licenses/validate")!
    static let storageKey  = "ffext_license_key"
    static let expiryKey   = "ffext_license_expiry"   // stores ISO8601 expiry string
    static let hwidLockKey = "ffext_license_hwid"     // stored hwid from server on first login

    // MARK: - Validate

    static func validate(key: String) async throws -> LicenseInfo {
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15

        let body: [String: Any] = [
            "key":  key,
            "hwid": DeviceID.hwid
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw LicenseError.networkError
        }
        guard (200..<300).contains(http.statusCode) else {
            throw LicenseError.serverError(http.statusCode)
        }

        let decoded = try JSONDecoder().decode(LicenseResponse.self, from: data)
        guard decoded.valid else {
            throw LicenseError.invalidKey
        }

        // 1-key 1-device enforcement:
        // If server returns an hwid that does NOT match ours, reject
        if let serverHwid = decoded.hwid, !serverHwid.isEmpty {
            if serverHwid != DeviceID.hwid {
                throw LicenseError.deviceMismatch
            }
        }

        let expiresAtRaw  = decoded.expiresAt ?? ""
        let expiryDate    = parseISODate(expiresAtRaw)
        let formattedExpiry = expiryDate.map { formatDate($0) } ?? expiresAtRaw

        // Check if already expired
        if let exp = expiryDate, exp < Date() {
            throw LicenseError.expired
        }

        let info = LicenseInfo(
            key:          key,
            expiresAt:    formattedExpiry,
            expiryDate:   expiryDate,
            deviceName:   DeviceID.deviceName,
            hwid:         DeviceID.hwid,
            iOSVersion:   DeviceID.iOSVersion,
            iPhoneModel:  DeviceID.iPhoneModel
        )
        store(key: key, expiryRaw: expiresAtRaw)
        return info
    }

    // MARK: - Auto-session restore (called on app launch if key stored)

    /// Builds LicenseInfo from stored credentials without hitting the network.
    /// Returns nil if key missing or expired — caller must go to login.
    static func restoreSession() -> LicenseInfo? {
        guard let key    = storedKey(),
              let expRaw = UserDefaults.standard.string(forKey: expiryKey) else {
            return nil
        }
        let expiryDate = parseISODate(expRaw)
        // Auto-logout if expired
        if let exp = expiryDate, exp < Date() {
            logout()
            return nil
        }
        return LicenseInfo(
            key:         key,
            expiresAt:   expiryDate.map { formatDate($0) } ?? expRaw,
            expiryDate:  expiryDate,
            deviceName:  DeviceID.deviceName,
            hwid:        DeviceID.hwid,
            iOSVersion:  DeviceID.iOSVersion,
            iPhoneModel: DeviceID.iPhoneModel
        )
    }

    // MARK: - Storage

    static func storedKey() -> String? {
        UserDefaults.standard.string(forKey: storageKey)
    }

    private static func store(key: String, expiryRaw: String) {
        UserDefaults.standard.set(key, forKey: storageKey)
        UserDefaults.standard.set(expiryRaw, forKey: expiryKey)
    }

    static func logout() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        UserDefaults.standard.removeObject(forKey: expiryKey)
    }

    // MARK: - Helpers

    private static func parseISODate(_ raw: String) -> Date? {
        let fmt1 = ISO8601DateFormatter()
        fmt1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = fmt1.date(from: raw) { return d }
        let fmt2 = ISO8601DateFormatter()
        fmt2.formatOptions = [.withInternetDateTime]
        return fmt2.date(from: raw)
    }

    private static func formatDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df.string(from: date)
    }

    /// Masks all but first segment and last 4 chars: FFEX-XXXX-XXXX-1234 -> FFEX-••••-••••-1234
    static func maskedKey(_ key: String) -> String {
        let parts = key.components(separatedBy: "-")
        guard parts.count >= 2 else {
            let visible = String(key.suffix(4))
            let hidden  = String(repeating: "•", count: max(0, key.count - 4))
            return hidden + visible
        }
        let last    = parts.last ?? ""
        let prefix  = parts.first ?? ""
        let midMask = Array(repeating: "••••", count: max(0, parts.count - 2))
        return ([prefix] + midMask + [last]).joined(separator: "-")
    }

    /// Returns remaining time string for countdown display
    static func countdownString(from expiryDate: Date) -> String {
        let now = Date()
        guard expiryDate > now else { return "Expired" }
        let diff = expiryDate.timeIntervalSince(now)
        let days    = Int(diff) / 86400
        let hours   = (Int(diff) % 86400) / 3600
        let minutes = (Int(diff) % 3600) / 60
        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            let secs = Int(diff) % 60
            return "\(minutes)m \(secs)s"
        }
    }
}

// MARK: - Errors

enum LicenseError: LocalizedError {
    case invalidKey
    case networkError
    case serverError(Int)
    case deviceMismatch
    case expired

    var errorDescription: String? {
        switch self {
        case .invalidKey:         return "Invalid or expired key"
        case .networkError:       return "Network error — check your connection"
        case .serverError(let c): return "Server error (\(c))"
        case .deviceMismatch:     return "Key is bound to another device"
        case .expired:            return "License key has expired"
        }
    }
}
