import SwiftUI

struct TrailView: View {
    @ObservedObject var game: Game
    @State private var showMap = false
    @State private var confirmNewGame = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 4) {
                    Text(game.dateString)
                        .font(.title.weight(.bold))
                    Text("Next landmark: \(game.nextLandmark.name) — \(game.milesToNextLandmark) miles")
                        .font(.body.weight(.semibold))
                        .multilineTextAlignment(.center)
                    Text("Miles traveled: \(Int(game.milesTraveled)) of 2,040")
                        .font(.body)
                }

                ZStack(alignment: .bottomLeading) {
                    TrailScene(weather: game.weather, pace: game.pace)
                        .frame(height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    Text("Tap the scene to roll on →")
                        .font(.body.weight(.bold))
                        .foregroundColor(OT.cream)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.55))
                        .cornerRadius(8)
                        .padding(10)
                }
                .onTapGesture { game.continueOnTrail() }

                statusPanel
                partyPanel
                controlsPanel

                BigButton(title: "Continue on the Trail") {
                    game.continueOnTrail()
                }

                HStack(spacing: 10) {
                    BigButton(title: "Rest 1 Day", color: Color(red: 0.65, green: 0.78, blue: 0.62)) {
                        game.restDaysPlanned += 1
                        game.continueOnTrail()
                    }
                    BigButton(title: "Go Hunting", color: Color(red: 0.65, green: 0.78, blue: 0.62)) {
                        game.goHunting()
                    }
                }
                HStack(spacing: 10) {
                    BigButton(title: "Look at the Map", color: Color(red: 0.65, green: 0.78, blue: 0.62)) {
                        showMap = true
                    }
                    BigButton(title: "New Game", color: Color(red: 0.80, green: 0.55, blue: 0.45)) {
                        confirmNewGame = true
                    }
                }
                if confirmNewGame {
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
            }
            .padding(20)
        }
        .sheet(isPresented: $showMap) {
            MapView(game: game)
        }
    }

    private var statusPanel: some View {
        Panel {
            VStack(spacing: 10) {
                statusRow("Weather", game.weather.title)
                statusRow("Health", game.healthStatus.title)
                statusRow("Food", "\(game.food) lbs")
                statusRow("Oxen", "\(game.oxen)")
                statusRow("Bullets", "\(game.bullets)")
                statusRow("Money", moneyString(game.cash))
                statusRow("Clothing", "\(game.clothing) sets")
                statusRow("Spare parts", "\(game.wheels) wheels · \(game.axles) axles · \(game.tongues) tongues")
            }
        }
    }

    private func statusRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.body)
            Spacer()
            Text(value).font(.headline).foregroundColor(OT.amber)
        }
    }

    private var partyPanel: some View {
        Panel {
            VStack(alignment: .leading, spacing: 10) {
                Text("Your party").font(.headline)
                ForEach(game.members) { m in
                    HStack(spacing: 10) {
                        Text(m.alive ? "●" : "†")
                            .foregroundColor(m.alive ? .green : .red)
                            .font(.body)
                        Text(m.name)
                            .font(.body.weight(.semibold))
                        Spacer()
                        if m.alive {
                            if let a = m.ailment {
                                Text(a.title)
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.orange)
                            }
                            // health bar
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.black.opacity(0.4))
                                    .frame(width: 90, height: 14)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(m.health > 50 ? Color.green : (m.health > 25 ? Color.orange : Color.red))
                                    .frame(width: max(4, 90 * m.health / 100), height: 14)
                            }
                        } else {
                            Text("died on the trail")
                                .font(.body)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
    }

    private var controlsPanel: some View {
        Panel {
            VStack(alignment: .leading, spacing: 14) {
                Text("Pace").font(.headline)
                HStack(spacing: 8) {
                    ForEach(Pace.allCases, id: \.self) { p in
                        choiceButton(title: p.title, selected: game.pace == p) { game.pace = p; game.save() }
                    }
                }
                Text("Rations").font(.headline)
                HStack(spacing: 8) {
                    ForEach(Rations.allCases, id: \.self) { r in
                        choiceButton(title: r.title, selected: game.rations == r) { game.rations = r; game.save() }
                    }
                }
                Text("A grueling pace covers ground fast but wears everyone down. Bare-bones rations save food but cost health.")
                    .font(.body)
            }
        }
    }

    private func choiceButton(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.body.weight(.bold))
                .foregroundColor(selected ? OT.darkText : OT.cream)
                .frame(maxWidth: .infinity, minHeight: 42)
                .background(selected ? OT.amber : OT.panelLight)
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Map

struct MapView: View {
    @ObservedObject var game: Game
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            OT.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Text("The Trail West")
                        .font(.title.weight(.bold))
                        .foregroundColor(OT.cream)
                    Spacer()
                    Button("Close") { dismiss() }
                        .font(.headline)
                        .foregroundColor(OT.amber)
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
                                    .font(.body)
                                    .frame(width: 34)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(lm.name)
                                        .font(.title3.weight(game.nextLandmark.name == lm.name ? .bold : .regular))
                                        .foregroundColor(OT.cream)
                                    Text("Mile \(lm.miles)")
                                        .font(.body)
                                        .foregroundColor(OT.cream.opacity(0.75))
                                }
                                Spacer()
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            Divider().background(Color.white.opacity(0.15))
                        }
                    }
                }
            }
        }
    }

    private func marker(for lm: Landmark) -> String {
        if lm.miles <= Int(game.milesTraveled) { return "✅" }
        if game.nextLandmark.name == lm.name { return "➡️" }
        return "·"
    }
}

// MARK: - Drawn route map (progress along a winding trail)

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
                    .fill(Color(red: 0.14, green: 0.24, blue: 0.28))
                // the winding route
                Path { p in
                    for i in 0...120 {
                        let f = Double(i) / 120.0
                        let pt = routePoint(f, w, h)
                        if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                    }
                }
                .stroke(OT.cream.opacity(0.9),
                        style: StrokeStyle(lineWidth: 4, dash: [9, 7]))
                // landmark dots + major labels
                ForEach(allLandmarks, id: \.name) { lm in
                    let f = Double(lm.miles) / 2040.0
                    let pt = routePoint(f, w, h)
                    let passed = lm.miles <= Int(game.milesTraveled)
                    Circle()
                        .fill(passed ? Color.green : OT.cream)
                        .frame(width: 11, height: 11)
                        .overlay(Circle().stroke(Color.black.opacity(0.5), lineWidth: 1))
                        .position(pt)
                    if labeled.contains(lm.name) {
                        Text(shortName(lm.name))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(OT.cream)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.55))
                            .cornerRadius(5)
                            .position(x: min(max(pt.x, 52), w - 52),
                                      y: pt.y + (pt.y > h / 2 ? -20 : 20))
                    }
                }
                // wagon marker
                let wf = min(1.0, game.milesTraveled / 2040.0)
                let wpt = routePoint(wf, w, h)
                ZStack {
                    Circle().fill(Color.orange).frame(width: 30, height: 30)
                    Circle().stroke(Color.white, lineWidth: 2.5).frame(width: 30, height: 30)
                    Text("🐂").font(.system(size: 17))
                }
                .position(wpt)
            }
        }
        .frame(height: 230)
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
