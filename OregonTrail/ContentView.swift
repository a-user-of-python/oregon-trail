import SwiftUI

// MARK: - Shared style (accessibility first: large type, high contrast, big targets)

enum OT {
    static let bg = Color(red: 0.09, green: 0.16, blue: 0.10)
    static let panel = Color(red: 0.15, green: 0.24, blue: 0.16)
    static let panelLight = Color(red: 0.22, green: 0.33, blue: 0.23)
    static let cream = Color(red: 0.98, green: 0.95, blue: 0.87)
    static let amber = Color(red: 0.93, green: 0.73, blue: 0.36)
    static let danger = Color(red: 0.45, green: 0.10, blue: 0.08)
    static let darkText = Color(red: 0.10, green: 0.09, blue: 0.05)
}

struct BigButton: View {
    var title: String
    var color: Color = OT.amber
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(OT.darkText)
                .frame(maxWidth: .infinity, minHeight: 46)
                .background(color)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct Panel<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(OT.panel)
            .cornerRadius(14)
    }
}

func moneyString(_ v: Double) -> String {
    v.truncatingRemainder(dividingBy: 1) == 0
        ? "$\(Int(v))"
        : String(format: "$%.2f", v)
}

// MARK: - Root

struct ContentView: View {
    @ObservedObject var game: Game

    var body: some View {
        ZStack {
            OT.bg.ignoresSafeArea()
            Group {
                switch game.phase {
                case .setup:
                    SetupView(game: game)
                case .store:
                    StoreView(game: game, factor: 1.0, isInitialStore: true) {}
                case .traveling:
                    TrailView(game: game)
                case .river:
                    RiverView(game: game)
                case .landmark:
                    LandmarkView(game: game)
                case .hunting:
                    HuntView(game: game)
                case .event:
                    EventView(game: game)
                case .gameOver, .won:
                    EndView(game: game)
                }
            }
            .foregroundColor(OT.cream)
            .animation(.easeInOut(duration: 0.3), value: game.phase)
        }
    }
}

// MARK: - Event / tombstone screen

struct EventView: View {
    @ObservedObject var game: Game

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if game.messageIsDeath {
                    Text("🪦")
                        .font(.system(size: 48))
                }
                Panel {
                    Text(game.message)
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                }
                BigButton(title: "Continue") {
                    game.dismissEvent()
                }
            }
            .padding(20)
        }
    }
}

// MARK: - End screen

struct EndView: View {
    @ObservedObject var game: Game

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text(game.phase == .won ? "🌄" : "🪦")
                    .font(.system(size: 48))
                Text(game.endTitle)
                    .font(.title.weight(.bold))
                    .multilineTextAlignment(.center)
                Panel {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(game.endText)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                        if game.phase == .gameOver {
                            Text("You reached mile \(Int(game.milesTraveled)) of 2,040.")
                                .font(.body.weight(.semibold))
                            Text("Date: \(game.dateString)")
                                .font(.body)
                        }
                    }
                }
                BigButton(title: "Start a New Journey") {
                    game.backToSetup()
                }
            }
            .padding(20)
        }
    }
}
