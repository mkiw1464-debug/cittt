import SwiftUI

// MARK: - Sidebar Tab

private enum PXTab: String, CaseIterable {
    case mira  = "MIRA"
    case esp   = "ESP"
    case raioX = "RAIO-X"
    case geral = "GERAL"

    var icon: String {
        switch self {
        case .mira:  return "scope"
        case .esp:   return "eye"
        case .raioX: return "cube"
        case .geral: return "slider.horizontal.3"
        }
    }
}

// MARK: - App State

final class FFAppState: ObservableObject {
    @Published var exploitStatus:  ExploitStatus = .notStarted
    @Published var exploitRunning  = false
    @Published var isInjected      = false
    @Published var isInjecting     = false
    @Published var injectError:    String? = nil
    @Published var applyError:     String? = nil

    private var autoRunDone = false

    var exploitReady: Bool { exploitStatus.isSuccess }

    func boot() {
        let v = AppInfo.versionTuple
        guard ExploitSupportPolicy.isSupported(
            major: v.major, minor: v.minor, patch: v.patch, build: AppInfo.osBuild) else {
            exploitStatus = .unsupported("iOS \(AppInfo.osVersion)")
            return
        }
        if KernelExploit.requiresSandboxEscape && KernelExploit.hasSandboxAccess() {
            exploitStatus = .success(method: "kexploit")
            return
        }
        if !autoRunDone { autoRunDone = true; runExploit() }
    }

    func runExploit() {
        guard !exploitRunning, !exploitStatus.isSuccess else { return }
        exploitRunning = true; exploitStatus = .notStarted
        DispatchQueue.global(qos: .userInitiated).async {
            let ok = KernelExploit.run()
            DispatchQueue.main.async {
                self.exploitRunning = false
                self.exploitStatus  = ok
                    ? .success(method: "kexploit")
                    : .failed(method: "kexploit", code: -1)
            }
        }
    }

    func syncInjectedState(game: FFGame) {
        isInjected = FFCheatService.hasBackup(bundleID: game.bundleID)
    }

    // First inject — download patch.bytes + tulis config
    func doInject(game: FFGame, cfg: CheatConfig) {
        guard !isInjecting else { return }
        isInjecting = true; injectError = nil
        Task {
            do {
                try await FFCheatService.inject(game: game, cfg: cfg)
                await MainActor.run { self.isInjecting = false; self.isInjected = true }
            } catch {
                await MainActor.run {
                    self.isInjecting = false
                    self.injectError = error.localizedDescription
                }
            }
        }
    }

    // Apply config (toggle update) — NO download, just write files
    func applyConfig(game: FFGame, cfg: CheatConfig) {
        applyError = nil
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try FFCheatService.applyConfig(cfg, game: game)
            } catch {
                DispatchQueue.main.async { self.applyError = error.localizedDescription }
            }
        }
    }

    func doRestore(game: FFGame) {
        do {
            try FFCheatService.restore(game: game)
            isInjected = false
        } catch {
            injectError = error.localizedDescription
        }
    }
}

// MARK: - Main Menu View

struct MainMenuView: View {
    let licenseInfo: LicenseInfo
    let onLogout:    () -> Void

    @StateObject private var appState   = FFAppState()
    @StateObject private var cfg        = CheatConfig()
    @State private var selectedTab:     PXTab   = .esp
    @State private var selectedGame:    FFGame  = .freeFire
    @State private var countdown:       String  = ""
    @State private var showLogout       = false
    @State private var showRestoreAlert = false
    @State private var revalidateTick   = 0

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            PXTheme.backgroundDeep.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Divider().background(PXTheme.separator)

                HStack(spacing: 0) {
                    sidebar
                    Divider().background(PXTheme.separator)
                    contentArea
                }
                .frame(maxHeight: .infinity)

                Divider().background(PXTheme.separator)
                bottomBar
            }
        }
        .onAppear {
            appState.boot()
            appState.syncInjectedState(game: selectedGame)
            refreshCountdown()
        }
        .onReceive(timer) { _ in
            refreshCountdown()
            if let exp = licenseInfo.expiryDate, exp < Date() { onLogout() }
            revalidateTick += 1
            if revalidateTick >= 60 {
                revalidateTick = 0
                Task {
                    let still = await LicenseService.revalidateBackground(key: licenseInfo.key)
                    if !still { await MainActor.run { onLogout() } }
                }
            }
        }
        .onChange(of: selectedGame) { g in appState.syncInjectedState(game: g) }
        .alert("Logout?", isPresented: $showLogout) {
            Button("Logout", role: .destructive) { onLogout() }
            Button("Batal", role: .cancel) {}
        }
        .alert("Restore?", isPresented: $showRestoreAlert) {
            Button("Restore", role: .destructive) { appState.doRestore(game: selectedGame) }
            Button("Batal", role: .cancel) {}
        } message: { Text("Ini akan restore semua file game asal.") }
        .alert(appState.injectError ?? "", isPresented: .init(
            get: { appState.injectError != nil },
            set: { if !$0 { appState.injectError = nil } }
        )) { Button("OK", role: .cancel) {} }
    }

    // MARK: Top Bar

    private var topBar: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(PXTheme.accent).frame(width: 40, height: 40)
                Image(systemName: "scope")
                    .font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("ProjectX")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(PXTheme.text)
                Text("PAINEL EXTERNO")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(PXTheme.textSecondary).tracking(1.5)
            }
            Spacer()

            // Status pill
            HStack(spacing: 5) {
                Circle()
                    .fill(appState.exploitReady ? PXTheme.online : PXTheme.warn)
                    .frame(width: 7, height: 7)
                Text(appState.exploitReady ? "ONLINE" : (appState.exploitRunning ? "LOADING..." : "OFFLINE"))
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(PXTheme.text).tracking(1)
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(PXTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            // Game picker
            Menu {
                ForEach(FFGame.allCases, id: \.self) { g in
                    Button(g.displayName) { selectedGame = g }
                }
            } label: {
                Text(selectedGame.displayName)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(PXTheme.accent)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(PXTheme.accentGlow)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            Button { showLogout = true } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(PXTheme.textSecondary)
                    .frame(width: 38, height: 38)
                    .background(PXTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(PXTheme.background)
    }

    // MARK: Sidebar

    private var sidebar: some View {
        VStack(spacing: 2) {
            ForEach(PXTab.allCases, id: \.self) { tab in
                sidebarItem(tab)
            }
            Spacer()
        }
        .padding(.vertical, 10)
        .frame(width: PXTheme.sidebarWidth)
        .background(PXTheme.sidebar)
    }

    private func sidebarItem(_ tab: PXTab) -> some View {
        let sel = selectedTab == tab
        return Button {
            withAnimation(.easeInOut(duration: 0.16)) { selectedTab = tab }
        } label: {
            VStack(spacing: 5) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: sel ? .bold : .regular))
                    .foregroundStyle(sel ? PXTheme.accent : PXTheme.textSecondary)
                Text(tab.rawValue)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(sel ? PXTheme.accent : PXTheme.textSecondary)
                    .tracking(0.5)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 12)
            .background(sel ? PXTheme.accentGlow : Color.clear)
            .overlay(
                Rectangle().fill(sel ? PXTheme.accent : Color.clear).frame(width: 3),
                alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    // MARK: Content

    private var contentArea: some View {
        ScrollView {
            VStack(spacing: 10) {
                switch selectedTab {
                case .mira:  MiraPanel(cfg: cfg, onToggle: applyIfInjected)
                case .esp:   ESPPanel(cfg: cfg, onToggle: applyIfInjected)
                case .raioX: RaioXPanel(cfg: cfg, onToggle: applyIfInjected)
                case .geral: GeralPanel(cfg: cfg, onToggle: applyIfInjected)
                }
            }
            .padding(12)
        }
        .background(PXTheme.backgroundDeep)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // Apply to FF container setiap kali toggle — HANYA bila dah inject
    private func applyIfInjected() {
        guard appState.isInjected else { return }
        appState.applyConfig(game: selectedGame, cfg: cfg)
    }

    // MARK: Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 10) {
            // Restore / Clear
            Button {
                if appState.isInjected { showRestoreAlert = true }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trash").font(.system(size: 13, weight: .semibold))
                    Text("LIMPAR").font(.system(size: 13, weight: .bold, design: .rounded))
                }
                .frame(maxWidth: .infinity).padding(.vertical, 15)
                .foregroundStyle(PXTheme.text)
                .background(PXTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: PXTheme.cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: PXTheme.cornerRadius, style: .continuous)
                        .strokeBorder(PXTheme.glassBorder, lineWidth: 0.8))
                .opacity(appState.isInjected ? 1 : 0.4)
            }
            .buttonStyle(.plain)

            // Inject / Injected
            Button {
                if !appState.isInjected {
                    appState.doInject(game: selectedGame, cfg: cfg)
                }
            } label: {
                HStack(spacing: 6) {
                    if appState.isInjecting {
                        ProgressView().tint(.white).scaleEffect(0.8)
                    } else {
                        Image(systemName: appState.isInjected ? "checkmark.seal.fill" : "play.fill")
                            .font(.system(size: 13, weight: .bold))
                    }
                    Text(appState.isInjecting ? "INJETANDO..." :
                         appState.isInjected  ? "INJETADO ✓"  : "INICIAR")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .frame(maxWidth: .infinity).padding(.vertical, 15)
                .foregroundStyle(.white)
                .background(
                    appState.isInjected
                        ? PXTheme.accentDark
                        : (appState.exploitReady ? PXTheme.accent : PXTheme.textDim))
                .clipShape(RoundedRectangle(cornerRadius: PXTheme.cornerRadius, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!appState.exploitReady || appState.isInjecting || appState.isInjected)
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(PXTheme.background)
    }

    private func refreshCountdown() {
        if let exp = licenseInfo.expiryDate {
            countdown = LicenseService.countdownString(from: exp)
        }
    }
}

// MARK: - Toggle Row

private struct TRow: View {
    let icon:  String
    let title: String
    @Binding var isOn: Bool
    var subtitle: String? = nil
    var onChange: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isOn ? PXTheme.accentDark : PXTheme.cardElevated)
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isOn ? .white : PXTheme.textSecondary)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(PXTheme.text)
                if let sub = subtitle {
                    Text(sub).font(.system(size: 10, weight: .regular, design: .rounded))
                        .foregroundStyle(PXTheme.textSecondary)
                }
            }
            Spacer()
            Toggle("", isOn: $isOn).labelsHidden().tint(PXTheme.accent)
                .onChange(of: isOn) { _ in onChange?() }
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: PXTheme.cornerRadius, style: .continuous)
                .fill(PXTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: PXTheme.cornerRadius, style: .continuous)
                        .strokeBorder(isOn ? PXTheme.redBorder : PXTheme.glassBorder,
                                      lineWidth: isOn ? 1.0 : 0.7)))
        .animation(.easeInOut(duration: 0.15), value: isOn)
    }
}

private struct SRow: View {
    let icon:  String; let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step:  Double = 1; var unit: String = ""
    var onChange: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(PXTheme.accentDark).frame(width: 34, height: 34)
                    Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                }
                Text(title).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(PXTheme.text)
                Spacer()
                Text("\(Int(value))\(unit)").font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(PXTheme.accent)
            }
            Slider(value: $value, in: range, step: step).tint(PXTheme.accent)
                .onChange(of: value) { _ in onChange?() }
        }
        .padding(.horizontal, 12).padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: PXTheme.cornerRadius, style: .continuous).fill(PXTheme.card)
            .overlay(RoundedRectangle(cornerRadius: PXTheme.cornerRadius, style: .continuous)
                .strokeBorder(PXTheme.glassBorder, lineWidth: 0.7)))
    }
}

private struct StepRow: View {
    let icon: String; let title: String
    @Binding var value: Int; let range: ClosedRange<Int>
    var onChange: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(PXTheme.accentDark).frame(width: 34, height: 34)
                Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
            }
            Text(title).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(PXTheme.text)
            Spacer()
            HStack(spacing: 0) {
                Button { if value > range.lowerBound { value -= 1; onChange?() } } label: {
                    Image(systemName: "minus").frame(width: 34, height: 32)
                        .foregroundStyle(PXTheme.text).background(PXTheme.cardElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }.buttonStyle(.plain)
                Button { if value < range.upperBound { value += 1; onChange?() } } label: {
                    Image(systemName: "plus").frame(width: 34, height: 32)
                        .foregroundStyle(PXTheme.text).background(PXTheme.cardElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }.buttonStyle(.plain)
                Text("\(value)").font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(PXTheme.accent).frame(minWidth: 28).padding(.leading, 6)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: PXTheme.cornerRadius, style: .continuous).fill(PXTheme.card)
            .overlay(RoundedRectangle(cornerRadius: PXTheme.cornerRadius, style: .continuous)
                .strokeBorder(PXTheme.glassBorder, lineWidth: 0.7)))
    }
}

private struct SecHeader: View {
    let title: String
    var body: some View {
        Text(title).font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(PXTheme.accent).tracking(1)
            .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 4).padding(.top, 6)
    }
}

// MARK: - Feature Panels

private struct MiraPanel: View {
    @ObservedObject var cfg: CheatConfig
    var onToggle: () -> Void

    var body: some View {
        SecHeader(title: "AIMBOT")
        TRow(icon: "scope",              title: "Aimbot",              isOn: $cfg.aimOn,      onChange: onToggle)
        TRow(icon: "person.crop.circle", title: "Head",                isOn: $cfg.aimHead,    onChange: onToggle)
        TRow(icon: "circle.dashed",      title: "Neck",                isOn: $cfg.aimNeck,    onChange: onToggle)
        TRow(icon: "figure.stand",       title: "Body",                isOn: $cfg.aimBody,    onChange: onToggle)

        SecHeader(title: "SILENT AIM")
        TRow(icon: "dot.circle",         title: "Silent Aim",
             subtitle: "Peluru bengkok ke target dalam FOV",            isOn: $cfg.silentAim,  onChange: onToggle)

        SecHeader(title: "AIM FOV")
        TRow(icon: "viewfinder.circle",  title: "Tunjuk Bulatan FOV",  isOn: $cfg.aimFovVisible, onChange: onToggle)
        SRow(icon: "arrow.up.and.down.and.arrow.left.and.right",
             title: "Radius FOV", value: $cfg.aimFovRadius,
             range: 10...360, step: 5, unit: "°",                      onChange: onToggle)
    }
}

private struct ESPPanel: View {
    @ObservedObject var cfg: CheatConfig
    var onToggle: () -> Void

    var body: some View {
        SecHeader(title: "ESP")
        TRow(icon: "eye",                        title: "ESP On/Off",          isOn: $cfg.espOn,        onChange: onToggle)
        TRow(icon: "square.dashed",              title: "Box ESP",             isOn: $cfg.espBox,       onChange: onToggle)
        TRow(icon: "heart.fill",                 title: "HP Bar",              isOn: $cfg.espHP,        onChange: onToggle)
        TRow(icon: "person.text.rectangle",      title: "Nama",                isOn: $cfg.espName,      onChange: onToggle)
        TRow(icon: "ruler",                      title: "Jarak",               isOn: $cfg.espDistance,  onChange: onToggle)
        TRow(icon: "arrow.up.circle",            title: "Arah",                isOn: $cfg.espDirection, onChange: onToggle)
        TRow(icon: "mappin.circle",              title: "Mark Musuh",          isOn: $cfg.espMarkEnemy, onChange: onToggle)
        SRow(icon: "scope", title: "Jarak Max", value: $cfg.espMaxDist,
             range: 20...200, step: 5, unit: "m",                               onChange: onToggle)
    }
}

private struct RaioXPanel: View {
    @ObservedObject var cfg: CheatConfig
    var onToggle: () -> Void

    var body: some View {
        SecHeader(title: "RAIO-X")
        TRow(icon: "eye.fill",              title: "Xray Watak",          isOn: $cfg.xrayChar,     onChange: onToggle)
        TRow(icon: "square.stack.3d.up",    title: "Xray Dinding",        isOn: $cfg.xrayWall,     onChange: onToggle)
        TRow(icon: "rectangle.on.rectangle",title: "Tembus Dinding",      isOn: $cfg.xrayThruWall, onChange: onToggle)
        StepRow(icon: "timer",       title: "Masa Hidup",  value: $cfg.xrayOnTime,  range: 1...30, onChange: onToggle)
        StepRow(icon: "timer.circle",title: "Masa Mati",   value: $cfg.xrayOffTime, range: 1...30, onChange: onToggle)

        SecHeader(title: "OUTLINE / CONTOUR")
        TRow(icon: "cube.transparent",      title: "3D Outline",          isOn: $cfg.outline3D,    onChange: onToggle)
        TRow(icon: "heart.text.square",     title: "Warna Ikut HP",       isOn: $cfg.outlineByHP,  onChange: onToggle)
        StepRow(icon: "line.3.horizontal",  title: "Lebar Outline", value: $cfg.outlineWidth, range: 1...30, onChange: onToggle)

        SecHeader(title: "WARNA OUTLINE")
        HStack(spacing: 6) {
            ForEach(OutlineColor.allCases, id: \.self) { c in
                Button {
                    cfg.outlineColor = c
                    onToggle()
                } label: {
                    Text(c.label)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                        .foregroundStyle(cfg.outlineColor == c ? .white : PXTheme.textSecondary)
                        .background(cfg.outlineColor == c ? PXTheme.accent : PXTheme.cardElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }.buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 4)
    }
}

private struct GeralPanel: View {
    @ObservedObject var cfg: CheatConfig
    var onToggle: () -> Void

    var body: some View {
        SecHeader(title: "WEAPON")
        TRow(icon: "bolt.fill",       title: "No Recoil",
             subtitle: "__mrf=0 / __xrf=0",                              isOn: $cfg.noRecoil,   onChange: onToggle)
        TRow(icon: "burst.fill",      title: "Fast Fire Rate",
             subtitle: "__spf=150",                                       isOn: $cfg.fastFire,   onChange: onToggle)
        TRow(icon: "aqi.low",         title: "No Spread",
             subtitle: "__swpf=100",                                      isOn: $cfg.noSpread,   onChange: onToggle)

        SecHeader(title: "MOVEMENT")
        TRow(icon: "figure.run",      title: "Speed Hack",
             subtitle: "set_EatSpeedScale intercept",                     isOn: $cfg.speedOn,    onChange: onToggle)

        if cfg.speedOn {
            SecHeader(title: "SPEED LEVEL")
            HStack(spacing: 6) {
                ForEach(SpeedLevel.allCases, id: \.self) { lvl in
                    Button {
                        cfg.speedLevel = lvl
                        onToggle()
                    } label: {
                        Text(lvl.label).font(.system(size: 11, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity).padding(.vertical, 9)
                            .foregroundStyle(cfg.speedLevel == lvl ? .white : PXTheme.textSecondary)
                            .background(cfg.speedLevel == lvl ? PXTheme.accent : PXTheme.cardElevated)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }.buttonStyle(.plain)
                }
            }.padding(.horizontal, 4)
        }

        SecHeader(title: "TEAM")
        TRow(icon: "cross.case",      title: "Fast Revive",
             subtitle: "__xrrv=1 (normal=864)",                           isOn: $cfg.fastRevive, onChange: onToggle)

        SecHeader(title: "GENERAL")
        TRow(icon: "speedometer",     title: "120 FPS",                  isOn: $cfg.fps120,     onChange: onToggle)
        TRow(icon: "arrow.up.left.and.arrow.down.right",
                                      title: "Dynamic Scale",            isOn: $cfg.dynamicScale, onChange: onToggle)
    }
}
