import SwiftUI

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
                ZStack {
                    SkyView(weather: .warm)
                    WagonCanvas(phase: 0.9)
                }
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.25), lineWidth: 1))

                VStack(spacing: 6) {
                    Text("THE OREGON TRAIL")
                        .font(.largeTitle.weight(.heavy))
                        .multilineTextAlignment(.center)
                    Text("Independence, Missouri · 1847")
                        .font(.body)
                    Text("2,040 miles of prairie, rivers, and mountains stand between you and a new life in Oregon. Get your whole party there alive.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.top, 6)
                }

                Panel {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choose your profession")
                            .font(.headline)
                        ForEach(Profession.allCases, id: \.self) { p in
                            Button {
                                profession = p
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(p.title)
                                            .font(.headline)
                                        Text("Starts with \(moneyString(p.money)) · Final score ×\(p.multiplier)")
                                            .font(.body)
                                    }
                                    Spacer()
                                    if profession == p {
                                        Text("✓").font(.title.weight(.bold))
                                    }
                                }
                                .foregroundColor(profession == p ? OT.darkText : OT.cream)
                                .padding(14)
                                .frame(maxWidth: .infinity, minHeight: 42)
                                .background(profession == p ? OT.amber : OT.panelLight)
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Panel {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Name your party of five")
                            .font(.headline)
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
                    }
                }

                Panel {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("When do you leave Independence?")
                            .font(.headline)
                        HStack(spacing: 8) {
                            ForEach(3...7, id: \.self) { m in
                                Button {
                                    month = m
                                } label: {
                                    Text(monthShort(m))
                                        .font(.headline)
                                        .foregroundColor(month == m ? OT.darkText : OT.cream)
                                        .frame(maxWidth: .infinity, minHeight: 44)
                                        .background(month == m ? OT.amber : OT.panelLight)
                                        .cornerRadius(10)
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
