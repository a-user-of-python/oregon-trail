import SwiftUI

// MARK: - River crossing: animated pixel river, journal depth card,
// decision cards for the four ways across. (Choices and advice verbatim.)

struct RiverView: View {
    @ObservedObject var game: Game

    private var lm: Landmark { game.currentLandmark }
    private var depth: Double { game.currentRiverDepth }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text(lm.name)
                        .font(otDisplay(.largeTitle))
                        .multilineTextAlignment(.center)
                    Text(game.dateString)
                        .font(.body.weight(.semibold))
                        .foregroundColor(OT.cream.opacity(0.85))
                }

                AnimatedRiver()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.25), lineWidth: 1))

                ParchmentPanel {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(lm.blurb)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("The river is about \(String(format: "%.1f", depth)) feet deep at the crossing.")
                            .font(.headline)
                        depthGauge
                        if game.recentRain > 0 {
                            Text("Recent rains have swollen the river.")
                                .font(.body.weight(.semibold))
                                .foregroundColor(Color(red: 0.72, green: 0.36, blue: 0.05))
                        }
                        Text(depthAdvice)
                            .font(.body)
                    }
                }

                VStack(spacing: 12) {
                    ChoiceCard(title: "Ford the River",
                               subtitle: "Free — but dangerous in deep water.",
                               parchment: true) { game.crossRiver(.ford) }
                    ChoiceCard(title: "Caulk the Wagon and Float Across",
                               subtitle: "Works in deeper water, but the wagon can still swamp.",
                               parchment: true) { game.crossRiver(.caulk) }
                    if let price = lm.ferryPrice {
                        ChoiceCard(title: "Take the Ferry — \(moneyString(price))",
                                   subtitle: "The safe way across — if you can pay.",
                                   parchment: true) { game.crossRiver(.ferry) }
                    }
                    ChoiceCard(title: "Wait a Day and Watch the River",
                               subtitle: "Costs food and time, but rivers often fall.",
                               parchment: true) { game.crossRiver(.wait) }
                }

                Text("Fording is free but dangerous in deep water. Caulking works in deeper water but the wagon can still swamp. A ferry is safe — if you can pay. Waiting costs food and time, but rivers often fall.")
                    .font(.body)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
        }
    }

    /// Segmented pixel-block gauge; same thresholds and reading as before.
    private var depthGauge: some View {
        let segments = 16
        let filled = Int((min(depth, 8) / 8 * Double(segments)).rounded())
        let color: Color = depth <= 2.6 ? Color(red: 0.25, green: 0.48, blue: 0.22)
            : (depth <= 4.0 ? Color(red: 0.85, green: 0.50, blue: 0.10) : Color(red: 0.72, green: 0.20, blue: 0.14))
        return HStack(spacing: 3) {
            ForEach(0..<segments, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(i < filled ? color : OT.parchmentDeep)
                    .frame(height: 16)
            }
        }
    }

    private var depthAdvice: String {
        switch depth {
        case ..<2.6: return "Shallow enough to ford with care."
        case ..<4.0: return "Fording is possible, but the current will push hard against the wagon."
        case ..<5.5: return "Deep. Fording now is a gamble — floating or the ferry is wiser."
        default: return "Very deep and swift. Fording would be near suicide. Float, pay, or wait."
        }
    }
}
