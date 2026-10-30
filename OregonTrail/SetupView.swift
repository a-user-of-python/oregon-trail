import SwiftUI

// MARK: - Party setup: pixel hero title card + journal panels.
// (All state, defaults, and game calls identical to before — presentation only.)

struct SetupView: View {
    @ObservedObject var game: Game

    @State private var profession: Profession = .banker
    @State private var names: [String] = ["", "", "", "", ""]
    @State private var month: Int = 4

    private let monthHints: [Int: String] = [
        3: "March — early. Cold and mud on the trail, but plenty of time.",
        4: "April — a fine balance of grass and time.",
        5: "May — the classic start. Good grass, and the rivers are crossable.",
        6: "June — good grazing, but you must keep moving.",
        7: "July — very late. Snow may trap you in the mountains.",
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                ZStack(alignment: .bottomLeading) {
                    PixelScene(weather: .warm, animated: true, wagon: true,
                               pace: .steady, groundTopFrac: 0.55, seed: 5)
                        .frame(height: 190)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("THE OREGON TRAIL")
                            .font(otDisplay(.largeTitle))
                        Text("Independence, Missouri · 1847")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(OT.cream)
                    .shadow(color: .black.opacity(0.65), radius: 3, x: 0, y: 1)
                    .padding(16)
                }
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.25), lineWidth: 1))

                Text("2,040 miles of prairie, rivers, and mountains stand between you and a new life in Oregon. Get your whole party there alive.")
                    .font(.body)
                    .multilineTextAlignment(.center)

                ParchmentPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(text: "Choose your profession", color: OT.amberDark)
                        ForEach(Profession.allCases, id: \.self) { p in
                            Button {
                                profession = p
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(p.title)
                                            .font(otDisplay(.headline, weight: .semibold))
                                        Text("Starts with \(moneyString(p.money)) · Final score ×\(p.multiplier)")
                                            .font(.body)
                                            .foregroundColor(profession == p ? OT.darkText : OT.inkSoft)
                                    }
                                    Spacer()
                                    if profession == p {
                                        Text("✓").font(.title.weight(.bold))
                                    }
                                }
                                .foregroundColor(profession == p ? OT.darkText : OT.ink)
                                .padding(14)
                                .frame(maxWidth: .infinity, minHeight: 42)
                                .background(profession == p ? OT.amber : Color.white.opacity(0.35))
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .stroke(profession == p ? OT.amberDark : OT.parchmentEdge, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                ParchmentPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(text: "Name your party of five", color: OT.amberDark)
                        ForEach(0..<5, id: \.self) { i in
                            HStack {
                                Text(i == 0 ? "Leader:" : "Member \(i + 1):")
                                    .font(.body.weight(.semibold))
                                    .frame(width: 120, alignment: .leading)
                                TextField(i == 0 ? "Wagon leader" : "Name", text: $names[i])
                                    .font(.body)
                                    .foregroundColor(.black)
                                    .padding(10)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .autocorrectionDisabled()
                            }
                        }
                        Text("Leave a name blank and we'll pick one.")
                            .font(.body)
                            .foregroundColor(OT.inkSoft)
                    }
                }

                ParchmentPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(text: "When do you leave Independence?", color: OT.amberDark)
                        HStack(spacing: 8) {
                            ForEach(3...7, id: \.self) { m in
                                Button {
                                    month = m
                                } label: {
                                    Text(monthShort(m))
                                        .font(.headline)
                                        .foregroundColor(month == m ? OT.darkText : OT.ink)
                                        .frame(maxWidth: .infinity, minHeight: 44)
                                        .background(month == m ? OT.amber : Color.white.opacity(0.35))
                                        .cornerRadius(10)
                                        .overlay(RoundedRectangle(cornerRadius: 10)
                                            .stroke(month == m ? OT.amberDark : OT.parchmentEdge, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        Text(monthHints[month] ?? "")
                            .font(.body)
                    }
                }

                BigButton(title: "Start the Journey") {
                    game.startNewGame(profession: profession, names: names, month: month)
                }
                Text("First stop: Matt's General Store, to outfit your wagon.")
                    .font(.body)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
        }
    }

    private func monthShort(_ m: Int) -> String {
        ["", "", "", "Mar", "Apr", "May", "Jun", "Jul"][m]
    }
}
