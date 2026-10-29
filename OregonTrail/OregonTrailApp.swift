import SwiftUI

@main
struct OregonTrailApp: App {
    // If a journey was in progress when the app last closed, resume it.
    @StateObject private var game: Game = Game.loadSaved() ?? Game()

    var body: some Scene {
        WindowGroup {
            ContentView(game: game)
        }
    }
}
