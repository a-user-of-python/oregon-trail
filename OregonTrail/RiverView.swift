import SwiftUI

struct RiverView: View {
    @ObservedObject var game: Game

    private var lm: Landmark { game.currentLandmark }
    private var depth: Double { game.currentRiverDepth }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text(lm.name)
                    .font(.largeTitle.weight(.bold))
                    .multilineTextAlignment(.center)
                Text(game.dateString)
                    .font(.title3.weight(.semibold))

                AnimatedRiver()
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.25), lineWidth: 1))

                Panel {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(lm.blurb)
                            .font(.title3)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("The river is about \(String(format: "%.1f", depth)) feet deep at the crossing.")
                            .font(.title3.weight(.bold))
                        // depth gauge
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.black.opacity(0.35))
                                Capsule()
                                    .fill(depth <= 2.6 ? Color.green : (depth <= 4.0 ? Color.orange : Color.red))
                                    .frame(width: max(14, g.size.width * CGFloat(min(depth, 8) / 8)))
                            }
                        }
                        .frame(height: 18)
                        if game.recentRain > 0 {
                            Text("Recent rains have swollen the river.")
                                .font(.body.weight(.semibold))
                                .foregroundColor(.orange)
                        }
                        Text(depthAdvice)
                            .font(.body)
                    }
                }

                VStack(spacing: 12) {
                    BigButton(title: "Ford the River") { game.crossRiver(.ford) }
                    BigButton(title: "Caulk the Wagon and Float Across") { game.crossRiver(.caulk) }
                    if let price = lm.ferryPrice {
                        BigButton(title: "Take the Ferry — \(moneyString(price))") { game.crossRiver(.ferry) }
                    }
                    BigButton(title: "Wait a Day and Watch the River",
                              color: Color(red: 0.65, green: 0.78, blue: 0.62)) {
                        game.crossRiver(.wait)
                    }
                }

                Text("Fording is free but dangerous in deep water. Caulking works in deeper water but the wagon can still swamp. A ferry is safe — if you can pay. Waiting costs food and time, but rivers often fall.")
                    .font(.body)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
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
