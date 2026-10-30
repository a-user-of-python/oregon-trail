import SwiftUI

// MARK: - Shared style
//
// Visual language (see UI-BRIEF.md): pixel-art scenes as the hero surface,
// deep-green translucent docks over them, parchment "trail journal" panels
// for story and decisions, serif display type for headings. All text uses
// Dynamic Type styles at natural proportions; contrast does the work.

enum OT {
    static let bg = Color(red: 0.07, green: 0.13, blue: 0.08)
    static let panel = Color(red: 0.13, green: 0.22, blue: 0.14)
    static let panelLight = Color(red: 0.20, green: 0.31, blue: 0.21)
    static let cream = Color(red: 0.98, green: 0.95, blue: 0.87)
    static let amber = Color(red: 0.93, green: 0.73, blue: 0.36)
    static let amberDark = Color(red: 0.55, green: 0.36, blue: 0.08)
    static let sage = Color(red: 0.65, green: 0.78, blue: 0.62)
    static let danger = Color(red: 0.45, green: 0.10, blue: 0.08)
    static let darkText = Color(red: 0.10, green: 0.09, blue: 0.05)
    // journal parchment
    static let parchment = Color(red: 0.95, green: 0.90, blue: 0.78)
    static let parchmentDeep = Color(red: 0.90, green: 0.83, blue: 0.66)
    static let parchmentEdge = Color(red: 0.72, green: 0.62, blue: 0.42)
    static let ink = Color(red: 0.16, green: 0.12, blue: 0.07)
    static let inkSoft = Color(red: 0.35, green: 0.28, blue: 0.18)
}

/// Serif display font (New York) at a Dynamic Type style.
func otDisplay(_ style: Font.TextStyle, weight: Font.Weight = .bold) -> Font {
    .system(style, design: .serif).weight(weight)
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
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
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
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.07), lineWidth: 1))
    }
}

/// The trail-journal surface: warm parchment, ink text.
struct ParchmentPanel<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundColor(OT.ink)
            .background(OT.parchment)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(OT.parchmentEdge, lineWidth: 1.5))
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

struct SectionLabel: View {
    var text: String
    var color: Color = OT.amber
    var body: some View {
        Text(text.uppercased())
            .font(.caption.weight(.bold))
            .tracking(1.4)
            .foregroundColor(color)
    }
}

/// Compact label-over-value chip that floats on a scene.
struct StatChip: View {
    var label: String
    var value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(0.8)
                .foregroundColor(OT.cream.opacity(0.65))
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundColor(OT.cream)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.38))
        .cornerRadius(9)
    }
}

/// Full-width decision card: a title, a one-line consequence, a chevron.
struct ChoiceCard: View {
    var title: String
    var subtitle: String = ""
    var parchment: Bool = false
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(parchment ? OT.ink : OT.cream)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(parchment ? OT.inkSoft : OT.cream.opacity(0.75))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer()
                Text("›")
                    .font(.title2.weight(.bold))
                    .foregroundColor(parchment ? OT.amberDark : OT.amber)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(parchment ? OT.parchment : OT.panel)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(parchment ? OT.parchmentEdge : Color.white.opacity(0.07), lineWidth: parchment ? 1.5 : 1))
        }
        .buttonStyle(.plain)
    }
}

/// Thin health bar with the game's green/orange/red reading.
struct HealthBar: View {
    var health: Double
    var width: CGFloat = 74
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.black.opacity(0.45))
                .frame(width: width, height: 8)
            RoundedRectangle(cornerRadius: 3)
                .fill(health > 50 ? Color(red: 0.35, green: 0.80, blue: 0.35)
                      : (health > 25 ? Color.orange : Color.red))
                .frame(width: max(3, width * CGFloat(health) / 100), height: 8)
        }
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

// MARK: - Event / tombstone screen (a page from the trail journal)

struct EventView: View {
    @ObservedObject var game: Game

    var body: some View {
        ZStack {
            PixelScene(weather: game.weather, animated: false, wagon: true,
                       pace: game.pace, groundTopFrac: 0.55, seed: 11)
                .ignoresSafeArea()
            Color.black.opacity(0.35).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    Spacer(minLength: 30)
                    ParchmentPanel {
                        VStack(alignment: .leading, spacing: 14) {
                            if game.messageIsDeath {
                                HStack { Spacer(); TombstoneArt(); Spacer() }
                            }
                            Text(game.message)
                                .font(otDisplay(.title3, weight: .semibold))
                                .fixedSize(horizontal: false, vertical: true)
                            Text(game.dateString)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(OT.inkSoft)
                        }
                    }
                    BigButton(title: "Continue") {
                        game.dismissEvent()
                    }
                }
                .padding(20)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

/// Small pixel tombstone, drawn from the shared sprite.
struct TombstoneArt: View {
    var body: some View {
        Canvas { ctx, size in
            let cell = size.height / CGFloat(PXArt.tombstone.h)
            var pix = Pix(ctx: ctx, cell: cell)
            let x = Int((size.width / cell - CGFloat(PXArt.tombstone.w)) / 2)
            drawSprite(&pix, PXArt.tombstone, x: max(0, x), y: 0)
        }
        .frame(width: 66, height: 72)
    }
}

// MARK: - End screen

struct EndView: View {
    @ObservedObject var game: Game

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ZStack(alignment: .bottomLeading) {
                    PixelScene(weather: game.phase == .won ? .warm : .foggy,
                               animated: false, wagon: true, pace: .steady,
                               groundTopFrac: 0.55, seed: game.phase == .won ? 3 : 13)
                        .frame(height: 190)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    Text(game.endTitle)
                        .font(otDisplay(.title))
                        .foregroundColor(OT.cream)
                        .shadow(color: .black.opacity(0.6), radius: 3, x: 0, y: 1)
                        .padding(14)
                }
                ParchmentPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(game.endText)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                        if game.phase == .gameOver {
                            Divider().background(OT.parchmentEdge)
                            Text("You reached mile \(Int(game.milesTraveled)) of 2,040.")
                                .font(.body.weight(.semibold))
                            Text("Date: \(game.dateString)")
                                .font(.body)
                                .foregroundColor(OT.inkSoft)
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
