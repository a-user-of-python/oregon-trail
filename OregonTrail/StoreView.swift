import SwiftUI

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
                        .font(.largeTitle.weight(.bold))
                        .multilineTextAlignment(.center)
                    if isInitialStore {
                        Text("\"Howdy! I'm Matt. You'll want a good outfit before you head west — spend careful, but don't skimp on oxen or food.\"")
                            .font(.title3)
                            .multilineTextAlignment(.center)
                    }
                }

                Panel {
                    HStack {
                        Text("Your money:")
                            .font(.title2.weight(.semibold))
                        Spacer()
                        Text(moneyString(game.cash))
                            .font(.title2.weight(.bold))
                            .foregroundColor(OT.amber)
                    }
                }

                ForEach(StoreItem.allCases, id: \.self) { item in
                    storeRow(item)
                }

                if !errorText.isEmpty {
                    Text(errorText)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                if isInitialStore {
                    if game.oxen == 0 {
                        Text("⚠️ You have no oxen! Your wagon cannot move without them.")
                            .font(.title3.weight(.bold))
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
        return Panel {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.title3.weight(.bold))
                        Text("\(moneyString(unitPrice)) each")
                            .font(.body)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("You have")
                            .font(.body)
                        Text(ownedText(item))
                            .font(.title3.weight(.bold))
                            .foregroundColor(OT.amber)
                    }
                }
                if isInitialStore {
                    Text("Matt: \"\(item.advice)\"")
                        .font(.body.italic())
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
        }
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
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(game.cash >= price ? OT.amber : Color.gray)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}
