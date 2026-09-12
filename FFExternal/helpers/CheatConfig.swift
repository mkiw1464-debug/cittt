import Foundation

// MARK: - Enums

enum OutlineColor: Int, CaseIterable {
    case blue = 1, red = 2, green = 3, yellow = 4
    var label: String {
        switch self {
        case .blue:   return "BLUE"
        case .red:    return "RED"
        case .green:  return "GREEN"
        case .yellow: return "YELLOW"
        }
    }
}

enum SpeedLevel: Int, CaseIterable {
    case x1 = 1, x2 = 2, x3 = 3, x5 = 5, x8 = 8
    var label: String { "x\(rawValue)" }
}

// MARK: - CheatConfig

final class CheatConfig: ObservableObject {

    // ── ESP
    @Published var espOn:          Bool   = true
    @Published var espBox:         Bool   = true
    @Published var espHP:          Bool   = true
    @Published var espName:        Bool   = true
    @Published var espDistance:    Bool   = true
    @Published var espDirection:   Bool   = true
    @Published var espMarkEnemy:   Bool   = true
    @Published var espMaxDist:     Double = 120

    // ── Aimbot
    @Published var aimOn:          Bool   = true
    @Published var aimHead:        Bool   = true
    @Published var aimNeck:        Bool   = false
    @Published var aimBody:        Bool   = true

    // ── Silent Aim
    // Intercepts SetAimRotation — peluru tetap kena target
    // walaupun tembak angin, selagi dalam FOV
    @Published var silentAim:      Bool   = false

    // ── Aim FOV
    @Published var aimFovVisible:  Bool   = false  // bulatan FOV kat ingame
    @Published var aimFovRadius:   Double = 75     // 0–360

    // ── No Recoil
    @Published var noRecoil:       Bool   = false  // __mrf=0

    // ── Fast Fire + No Spread
    @Published var fastFire:       Bool   = false  // __spf lower
    @Published var noSpread:       Bool   = false  // __swpf lower

    // ── Speed Hack
    @Published var speedOn:        Bool   = false
    @Published var speedLevel:     SpeedLevel = .x2

    // ── Fast Revive
    @Published var fastRevive:     Bool   = false  // __xrrv=1

    // ── Xray
    @Published var xrayChar:       Bool   = true
    @Published var xrayWall:       Bool   = false
    @Published var xrayThruWall:   Bool   = false
    @Published var xrayOnTime:     Int    = 5
    @Published var xrayOffTime:    Int    = 10

    // ── Outline
    @Published var outline3D:      Bool   = false
    @Published var outlineColor:   OutlineColor = .blue
    @Published var outlineWidth:   Int    = 10
    @Published var outlineByHP:    Bool   = false

    // ── General
    @Published var fps120:         Bool   = true
    @Published var dynamicScale:   Bool   = false

    // MARK: - Build plist dict
    func buildPlistDict(base: [String: Any] = [:]) -> [String: Any] {
        var d = base

        // ESP
        d["__espon"]     = espOn      ? 1 : 0
        d["__espm"]      = espOn      ? 31 : 0
        d["__hot"]       = espOn      ? 31 : 0
        d["__ebox"]      = espBox     ? 1 : 0
        d["__ehp"]       = espHP      ? 1 : 0
        d["__ename"]     = espName    ? 1 : 0
        d["__edistance"] = espDistance ? 1 : 0
        d["__edir"]      = espDirection ? 1 : 0
        d["__edist"]     = Int(espMaxDist)
        d["__elag"]      = 0
        d["__cage"]      = 0
        d["__mcwas"]     = 1

        // q-series (ILFix secondary read)
        d["__q00"] = espOn      ? 31 : 0
        d["__q01"] = espBox     ? 1 : 0
        d["__q02"] = espHP      ? 1 : 0
        d["__q03"] = espName    ? 1 : 0
        d["__q04"] = espDirection ? 1 : 0
        d["__q05"] = espDistance  ? 1 : 0
        d["__q06"] = espMarkEnemy ? 1 : 0
        d["__q07"] = espOn      ? 31 : 0
        d["__q08"] = Int(espMaxDist)
        d["__q09"] = 0

        // Aimbot
        d["__aa"]   = aimOn   ? 1 : 0
        d["__lhok"] = aimHead ? 1 : 0
        d["__lhx"]  = 7184
        d["__lhy"]  = 1269
        d["__lhz"]  = 1639
        d["__q10"]  = aimHead ? 1 : 0
        d["__q11"]  = aimBody ? 1 : 0
        d["__q12"]  = aimNeck ? 1 : 0
        d["__q13"]  = 0

        // Silent aim + FOV
        d["__moco"] = silentAim    ? 1 : 0
        d["__q18"]  = silentAim    ? 1 : 0
        d["__xsig"] = aimFovVisible ? 51075 : 0
        d["__xrad"] = Int(aimFovRadius)
        d["__q16"]  = Int(aimFovRadius)
        d["__q17"]  = 0

        // Xray timing
        d["__xon"]  = xrayOnTime
        d["__xoff"] = xrayOffTime
        d["__q14"]  = xrayOnTime
        d["__q15"]  = xrayOffTime

        // No recoil: __mrf=0 kills recoil, 965=normal
        d["__mrf"]  = noRecoil ? 0 : 965
        d["__xrf"]  = noRecoil ? 0 : 975

        // Fire rate + spread
        let fireFrame = fps120 ? 973 : (fastFire ? 150 : 500)
        d["__spf"]  = fireFrame
        d["__swpf"] = noSpread ? 100 : 975

        // Speed: __q21=on flag, __q20=multiplier (set_EatSpeedScale intercept)
        d["__q21"]  = speedOn ? 1 : 0
        d["__q20"]  = speedOn ? speedLevel.rawValue : 1

        // Fast revive: 1=instant, 864=normal
        d["__xrrv"] = fastRevive ? 1 : 864

        // Xray / outline
        d["__xray"]  = xrayChar    ? 1 : 0
        d["__xblk"]  = xrayWall    ? 1 : 0
        d["__xrwas"] = xrayThruWall ? 1 : 0
        d["__cgwas"] = outline3D   ? 1 : 0
        d["__cgc"]   = outlineColor.rawValue
        d["__cgw"]   = outlineWidth
        d["__q19"]   = outlineWidth
        d["__cghp"]  = outlineByHP ? 1 : 0
        d["__cgz"]   = 0

        // General
        d["__spec"]  = dynamicScale ? 1 : 0
        d["__dbg"]   = 0

        // Anticheat disable (ALWAYS)
        d["checkHacker"]   = false
        d["AimAssist"]     = aimOn ? 1 : 0
        d["testCodePatch"] = true  // REQUIRED — activates ILFix runtime

        return d
    }

    // MARK: - Build config.bin (32 bytes)
    func buildConfigBin() -> Data {
        var b = [UInt8](repeating: 0, count: 32)
        b[0]  = espOn         ? 1 : 0
        b[1]  = espBox        ? 1 : 0
        b[2]  = espDirection  ? 1 : 0
        b[3]  = espHP         ? 1 : 0
        b[4]  = espName       ? 1 : 0
        b[5]  = espDistance   ? 1 : 0
        b[6]  = UInt8(min(Int(espMaxDist), 200))
        b[7]  = xrayChar      ? 1 : 0
        b[8]  = aimOn         ? 1 : 0
        b[9]  = aimHead       ? 1 : 0
        b[10] = aimNeck       ? 1 : 0
        b[11] = aimBody       ? 1 : 0
        b[12] = silentAim     ? 1 : 0
        b[13] = aimFovVisible ? 1 : 0
        b[14] = UInt8(min(Int(aimFovRadius), 200))
        b[15] = noRecoil      ? 1 : 0
        b[16] = xrayThruWall  ? 1 : 0
        b[17] = UInt8(min(outlineWidth, 30))
        b[18] = outline3D     ? 1 : 0
        b[19] = outlineByHP   ? 1 : 0
        b[20] = fastRevive    ? 1 : 0
        b[21] = speedOn       ? 1 : 0
        b[22] = UInt8(speedLevel.rawValue)
        b[23] = xrayWall      ? 1 : 0
        b[24] = UInt8(outlineColor.rawValue)
        b[25] = UInt8(min(xrayOnTime,  30))
        b[26] = UInt8(min(xrayOffTime, 30))
        b[27] = 0
        b[28] = 0
        b[29] = fastFire      ? 1 : 0
        b[30] = noSpread      ? 1 : 0
        b[31] = 0
        return Data(b)
    }

    // MARK: - Build localConfig.json
    func buildLocalConfigJSON() -> Data {
        let dict: [String: Any] = [
            "testCodePatch": true,
            "checkHacker":   false,
            "silentAim":     silentAim,
            "aimFov":        aimFovVisible,
            "fovRadius":     Int(aimFovRadius),
            "noRecoil":      noRecoil,
            "speedHack":     speedOn,
            "speedValue":    speedLevel.rawValue,
            "fastRevive":    fastRevive,
            "fastFire":      fastFire,
            "noSpread":      noSpread,
            "espOn":         espOn,
            "aimOn":         aimOn,
            "xrayOn":        xrayChar,
        ]
        let opts: JSONSerialization.WritingOptions = [.sortedKeys]
        return (try? JSONSerialization.data(withJSONObject: dict, options: opts)) ?? Data()
    }
}
