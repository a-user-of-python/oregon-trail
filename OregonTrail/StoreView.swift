import SwiftUI

// MARK: - General store: a ledger page — parchment rows, tabular prices.
// (Buy logic, step sizes, and the no-oxen double-tap warning are unchanged.)

struct StoreView: View {
    @ObservedObject var game: Game
    var factor: Double
    var isInitialStore: Bool
    var onDone: () -> Void

    @State private var errorText: String = ""
    @State private var warnedNoOxen: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text(isInitialStore ? "Matt's General Store" : "Trading Post")
                        .font(otDisplay(.largeTitle))
                        .multilineTextAlignment(.center)
                    if isInitialStore {
                        Text("\"Howdy! I'm Matt. You'll want a good outfit before you head west — spend careful, but don't skimp on oxen or food.\"")
                            .font(.body)
                            .multilineTextAlignment(.center)
                    }
                }

                Panel {
                    HStack {
                        Text("Your money:")
                            .font(.headline)
                        Spacer()
                        Text(moneyString(game.cash))
                            .font(otDisplay(.title3))
                            .foregroundColor(OT.amber)
                    }
                }

                ParchmentPanel {
                    VStack(spacing: 0) {
                        ForEach(Array(StoreItem.allCases.enumerated()), id: \.element) { idx, item in
                            storeRow(item)
                            if idx < StoreItem.allCases.count - 1 {
                                Divider().background(OT.parchmentEdge)
                            }
                        }
                    }
                }

                if !errorText.isEmpty {
                    Text(errorText)
                        .font(.body.weight(.semibold))
                        .foregroundColor(Color(red: 1.0, green: 0.50, blue: 0.42))
                        .multilineTextAlignment(.center)
                }

                if isInitialStore {
                    if game.oxen == 0 {
                        Text("⚠️ You have no oxen! Your wagon cannot move without them.")
                            .font(.headline)
                            .foregroundColor(.orange)
                            .multilineTextAlignment(.center)
                    }
                    BigButton(title: "Leave the Store and Head West") {
                        if game.oxen == 0 && !warnedNoOxen {
                            warnedNoOxen = true
                            errorText = "You truly have no oxen. Tap again if you really mean to set out on foot."
                            return
                        }
                        _ = game.finishShopping()
                    }
                } else {
                    BigButton(title: "Done Trading") { onDone() }
                }
            }
            .padding(20)
        }
    }

    private func ownedText(_ item: StoreItem) -> String {
        switch item {
        case .oxen: return "\(game.oxen) oxen (\(game.oxen / 2) yoke)"
        case .food: return "\(game.food) lbs"
        case .clothing: return "\(game.clothing) sets"
        case .ammo: return "\(game.bullets) bullets"
        case .wheel: return "\(game.wheels)"
        case .axle: return "\(game.axles)"
        case .tongue: return "\(game.tongues)"
        }
    }

    private func step(for item: StoreItem) -> Int {
        switch item {
        case .food: return 50
        default: return 1
        }
    }

    private func buyLabel(_ item: StoreItem, qty: Int) -> String {
        switch item {
        case .oxen: return "Buy 1 yoke"
        case .food: return "Buy \(qty) lbs"
        case .ammo: return "Buy 1 box"
        case .wheel: return "Buy wheel"
        case .axle: return "Buy axle"
        case .tongue: return "Buy tongue"
        case .clothing: return "Buy 1 set"
        }
    }

    private func storeRow(_ item: StoreItem) -> some View {
        let unitPrice = item.basePrice * factor
        let st = step(for: item)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(otDisplay(.headline, weight: .semibold))
                    Text("\(moneyString(unitPrice)) each")
                        .font(.body)
                        .foregroundColor(OT.inkSoft)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("You have")
                        .font(.body)
                        .foregroundColor(OT.inkSoft)
                    Text(ownedText(item))
                        .font(.headline)
                        .foregroundColor(OT.amberDark)
                }
            }
            if isInitialStore {
                Text("Matt: \"\(item.advice)\"")
                    .font(.body.italic())
                    .foregroundColor(OT.inkSoft)
            }
            HStack(spacing: 10) {
                buyButton(item, qty: st, label: buyLabel(item, qty: st), price: unitPrice * Double(st))
                if item == .food {
                    buyButton(item, qty: 250, label: "Buy 250 lbs", price: unitPrice * 250)
                }
                if item == .ammo {
                    buyButton(item, qty: 5, label: "Buy 5 boxes", price: unitPrice * 5)
                }
            }
        }
        .padding(.vertical, 12)
    }

    private func buyButton(_ item: StoreItem, qty: Int, label: String, price: Double) -> some View {
        Button {
            if let err = game.buy(item: item, qty: qty, factor: factor) {
                errorText = err
            } else {
                errorText = ""
                warnedNoOxen = false
            }
        } label: {
            VStack(spacing: 2) {
                Text(label).font(.body.weight(.bold))
                Text(moneyString(price)).font(.body)
            }
            .foregroundColor(OT.darkText)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(game.cash >= price ? OT.amber : Color.gray.opacity(0.55))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}
