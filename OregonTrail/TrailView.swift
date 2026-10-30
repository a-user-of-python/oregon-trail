import SwiftUI

// MARK: - Travel screen: the scene is the screen.
// Landscape: full-bleed pixel landscape, HUD chips floating on it, party
// strip + controls in a slim bottom dock. Portrait: tall hero scene on top,
// compact journal controls below. No scrolling column of cards.

struct TrailView: View {
    @ObservedObject var game: Game
    @State private var showMap = false
    @State private var confirmNewGame = false

    var body: some View {
        GeometryReader { geo in
            if geo.size.width > geo.size.height {
                landscape(geo)
            } else {
                portrait(geo)
            }
        }
        .sheet(isPresented: $showMap) {
            MapView(game: game)
        }
    }

    // MARK: Layouts

    private func landscape(_ geo: GeometryProxy) -> some View {
        ZStack {
            TrailScene(weather: game.weather, pace: game.pace)
                .ignoresSafeArea()
                .onTapGesture { game.continueOnTrail() }
            VStack(spacing: 10) {
                topBar
                HStack { destinationCard; Spacer() }
                Spacer()
                if confirmNewGame { confirmCard }
                bottomDock
            }
            .padding(14)
        }
    }

    private func portrait(_ geo: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                TrailScene(weather: game.weather, pace: game.pace)
                    .onTapGesture { game.continueOnTrail() }
                VStack(spacing: 8) {
                    topBar
                    HStack { destinationCard; Spacer() }
                    Spacer()
                    HStack {
                        Spacer()
                        Text("Tap the scene to roll on ›")
                            .font(.caption.weight(.bold))
                            .foregroundColor(OT.cream)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(Color.black.opacity(0.45))
                            .cornerRadius(8)
                    }
                }
                .padding(12)
            }
            .frame(height: geo.size.height * 0.45)
            ScrollView {
                VStack(spacing: 14) {
                    partyStrip
                    controlsBlock
                    actionButtons
                    if confirmNewGame { confirmCard }
                }
                .padding(16)
            }
        }
    }

    // MARK: HUD overlays

    private var topBar: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(game.dateString)
                    .font(otDisplay(.headline))
                    .foregroundColor(OT.cream)
                Text("\(game.weather.title) · Health: \(game.healthStatus.title)")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(OT.cream.opacity(0.8))
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(Color.black.opacity(0.38))
            .cornerRadius(9)
            Spacer()
            StatChip(label: "Food", value: "\(game.food) lbs")
            StatChip(label: "Oxen", value: "\(game.oxen)")
            StatChip(label: "Bullets", value: "\(game.bullets)")
            StatChip(label: "Clothing", value: "\(game.clothing)")
            StatChip(label: "Money", value: moneyString(game.cash))
        }
    }

    private var destinationCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(game.nextLandmark.name)
                .font(otDisplay(.subheadline))
                .foregroundColor(OT.cream)
            Text("\(game.milesToNextLandmark) miles · Mile \(Int(game.milesTraveled)) of 2,040")
                .font(.caption.weight(.semibold))
                .foregroundColor(OT.cream.opacity(0.8))
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.black.opacity(0.45))
                    Capsule()
                        .fill(OT.amber)
                        .frame(width: max(4, g.size.width * CGFloat(game.milesTraveled / 2040)))
                }
            }
            .frame(width: 170, height: 5)
            Text("Spare parts: \(game.wheels) wheels · \(game.axles) axles · \(game.tongues) tongues")
                .font(.caption2.weight(.semibold))
                .foregroundColor(OT.cream.opacity(0.7))
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.38))
        .cornerRadius(9)
    }

    // MARK: Party strip (compact chips, always visible)

    private var partyStrip: some View {
        HStack(spacing: 8) {
            ForEach(game.members) { m in
                HStack(spacing: 8) {
                    AvatarArt(seed: m.id, alive: m.alive)
                        .frame(width: 26, height: 26)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(m.name)
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(m.alive ? OT.cream : OT.cream.opacity(0.55))
                            .lineLimit(1)
                        if m.alive {
                            HealthBar(health: m.health, width: 58)
                        } else {
                            Text("† died on the trail")
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(Color(red: 0.95, green: 0.45, blue: 0.40))
                        }
                    }
                    if m.alive, let a = m.ailment {
                        Text(a.title)
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.orange)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .background(Color.black.opacity(0.38))
                .cornerRadius(10)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: Controls

    private var controlsBlock: some View {
        Panel {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(text: "Pace")
                HStack(spacing: 8) {
                    ForEach(Pace.allCases, id: \.self) { p in
                        choiceButton(title: p.title, selected: game.pace == p) { game.pace = p; game.save() }
                    }
                }
                SectionLabel(text: "Rations")
                HStack(spacing: 8) {
                    ForEach(Rations.allCases, id: \.self) { r in
                        choiceButton(title: r.title, selected: game.rations == r) { game.rations = r; game.save() }
                    }
                }
                Text("A grueling pace covers ground fast but wears everyone down. Bare-bones rations save food but cost health.")
                    .font(.subheadline)
                    .foregroundColor(OT.cream.opacity(0.75))
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            BigButton(title: "Continue on the Trail") { game.continueOnTrail() }
            HStack(spacing: 10) {
                BigButton(title: "Rest 1 Day", color: OT.sage) {
                    game.restDaysPlanned += 1
                    game.continueOnTrail()
                }
                BigButton(title: "Go Hunting", color: OT.sage) { game.goHunting() }
            }
            HStack(spacing: 10) {
                BigButton(title: "Look at the Map", color: OT.sage) { showMap = true }
                BigButton(title: "New Game", color: Color(red: 0.80, green: 0.55, blue: 0.45)) { confirmNewGame = true }
            }
        }
    }

    private var bottomDock: some View {
        VStack(spacing: 10) {
            partyStrip
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 5) {
                    SectionLabel(text: "Pace")
                    HStack(spacing: 6) {
                        ForEach(Pace.allCases, id: \.self) { p in
                            choiceButton(title: p.title, selected: game.pace == p) { game.pace = p; game.save() }
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 5) {
                    SectionLabel(text: "Rations")
                    HStack(spacing: 6) {
                        ForEach(Rations.allCases, id: \.self) { r in
                            choiceButton(title: r.title, selected: game.rations == r) { game.rations = r; game.save() }
                        }
                    }
                }
                Spacer()
                HStack(spacing: 8) {
                    dockButton("Rest", color: OT.sage) {
                        game.restDaysPlanned += 1
                        game.continueOnTrail()
                    }
                    dockButton("Hunt", color: OT.sage) { game.goHunting() }
                    dockButton("Map", color: OT.sage) { showMap = true }
                    dockButton("New", color: Color(red: 0.80, green: 0.55, blue: 0.45)) { confirmNewGame = true }
                    Button { game.continueOnTrail() } label: {
                        Text("Continue ›")
                            .font(.headline)
                            .foregroundColor(OT.darkText)
                            .padding(.horizontal, 20)
                            .frame(minHeight: 44)
                            .background(OT.amber)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(OT.bg.opacity(0.88))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private func dockButton(_ title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundColor(OT.darkText)
                .padding(.horizontal, 13)
                .frame(minHeight: 44)
                .background(color)
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private var confirmCard: some View {
        Panel {
            VStack(spacing: 10) {
                Text("Abandon this journey and start over?")
                    .font(.headline)
                HStack(spacing: 10) {
                    BigButton(title: "Yes, Start Over", color: Color(red: 0.85, green: 0.45, blue: 0.38)) {
                        game.backToSetup()
                    }
                    BigButton(title: "Keep Going") { confirmNewGame = false }
                }
            }
        }
    }

    private func choiceButton(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundColor(selected ? OT.darkText : OT.cream)
                .padding(.horizontal, 10)
                .frame(minHeight: 40)
                .background(selected ? OT.amber : OT.panelLight)
                .cornerRadius(9)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pixel avatar chip art

struct AvatarArt: View {
    var seed: Int
    var alive: Bool
    var body: some View {
        Canvas { ctx, size in
            let cell = size.width / 12
            var pix = Pix(ctx: ctx, cell: cell)
            drawAvatar(&pix, x: 0, y: 0, seed: seed, alive: alive)
        }
    }
}

// MARK: - Map (a page from the trail journal)

struct MapView: View {
    @ObservedObject var game: Game
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            OT.parchment.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Text("The Trail West")
                        .font(otDisplay(.title))
                        .foregroundColor(OT.ink)
                    Spacer()
                    Button("Close") { dismiss() }
                        .font(.headline)
                        .foregroundColor(OT.amberDark)
                }
                .padding(16)
                TrailRouteMap(game: game)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(allLandmarks.enumerated()), id: \.offset) { _, lm in
                            HStack(spacing: 12) {
                                Text(marker(for: lm))
                                    .font(.body.weight(.bold))
                                    .foregroundColor(markerColor(for: lm))
                                    .frame(width: 30)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(lm.name)
                                        .font(.title3.weight(game.nextLandmark.name == lm.name ? .bold : .regular))
                                        .foregroundColor(OT.ink)
                                    Text("Mile \(lm.miles)")
                                        .font(.body)
                                        .foregroundColor(OT.inkSoft)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            Divider().background(OT.parchmentEdge)
                        }
                    }
                }
            }
        }
    }

    private func marker(for lm: Landmark) -> String {
        if lm.miles <= Int(game.milesTraveled) { return "✓" }
        if game.nextLandmark.name == lm.name { return "▸" }
        return "·"
    }

    private func markerColor(for lm: Landmark) -> Color {
        if lm.miles <= Int(game.milesTraveled) { return Color(red: 0.25, green: 0.48, blue: 0.22) }
        if game.nextLandmark.name == lm.name { return OT.amberDark }
        return OT.inkSoft
    }
}

// MARK: - Drawn route map on parchment (ink trail + pixel wagon marker)

struct TrailRouteMap: View {
    @ObservedObject var game: Game

    private let labeled: Set<String> = [
        "Independence, Missouri", "Fort Kearny", "Fort Laramie",
        "Fort Hall", "Fort Boise", "Willamette Valley, Oregon",
    ]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(OT.parchmentDeep)
                RoundedRectangle(cornerRadius: 12)
                    .stroke(OT.parchmentEdge, lineWidth: 1.5)
                Path { p in
                    for i in 0...120 {
                        let f = Double(i) / 120.0
                        let pt = routePoint(f, w, h)
                        if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                    }
                }
                .stroke(OT.ink.opacity(0.75),
                        style: StrokeStyle(lineWidth: 3, dash: [8, 6]))
                ForEach(allLandmarks, id: \.name) { lm in
                    let f = Double(lm.miles) / 2040.0
                    let pt = routePoint(f, w, h)
                    let passed = lm.miles <= Int(game.milesTraveled)
                    Circle()
                        .fill(passed ? Color(red: 0.25, green: 0.48, blue: 0.22) : OT.parchment)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(OT.ink.opacity(0.7), lineWidth: 1.2))
                        .position(pt)
                    if labeled.contains(lm.name) {
                        Text(shortName(lm.name))
                            .font(.caption.weight(.bold))
                            .foregroundColor(OT.ink)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(OT.parchment.opacity(0.9))
                            .cornerRadius(5)
                            .position(x: min(max(pt.x, 52), w - 52),
                                      y: pt.y + (pt.y > h / 2 ? -19 : 19))
                    }
                }
                let wf = min(1.0, game.milesTraveled / 2040.0)
                let wpt = routePoint(wf, w, h)
                MiniWagonMark()
                    .frame(width: 36, height: 24)
                    .position(wpt)
            }
        }
        .frame(height: 220)
    }

    private func routePoint(_ f: Double, _ w: CGFloat, _ h: CGFloat) -> CGPoint {
        CGPoint(x: 26 + CGFloat(f) * (w - 52),
                y: h * 0.52 + CGFloat(sin(f * Double.pi * 2.2)) * h * 0.30)
    }

    private func shortName(_ name: String) -> String {
        name.replacingOccurrences(of: ", Missouri", with: "")
            .replacingOccurrences(of: ", Oregon", with: "")
    }
}

/// Tiny pixel wagon used as the map marker.
struct MiniWagonMark: View {
    var body: some View {
        Canvas { ctx, size in
            var pix = Pix(ctx: ctx, cell: size.width / 18)
            // canopy
            pix.r(3, 1, 10, 1, PX.canvasTop)
            pix.r(2, 2, 12, 1, PX.canvasMid)
            pix.r(2, 3, 12, 2, PX.canvasMid)
            // bed
            pix.r(1, 5, 14, 1, PX.wood)
            // wheels
            pix.r(3, 6, 2, 2, PX.woodDark)
            pix.r(12, 6, 2, 2, PX.woodDark)
            // lead ox
            pix.r(15, 3, 3, 2, PX.oxBody)
            pix.p(17, 2, PX.horn)
        }
    }
}
