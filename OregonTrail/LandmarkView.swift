import SwiftUI

struct LandmarkView: View {
    @ObservedObject var game: Game
    @State private var showStore = false
    @State private var offer: Game.TradeOffer? = nil
    @State private var tradeDone = false
    @State private var tradeNote = ""

    private var lm: Landmark { game.currentLandmark }
    private var factor: Double { priceFactor(miles: lm.miles) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text(lm.name)
                    .font(.title.weight(.bold))
                    .multilineTextAlignment(.center)
                Text("Mile \(lm.miles) · \(game.dateString)")
                    .font(.body.weight(.semibold))

                LandmarkArtView(landmark: lm)
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.25), lineWidth: 1))

                Panel {
                    Text(lm.blurb)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Panel {
                    VStack(spacing: 10) {
                        HStack {
                            Text("Health").font(.body)
                            Spacer()
                            Text(game.healthStatus.title).font(.headline).foregroundColor(OT.amber)
                        }
                        HStack {
                            Text("Food").font(.body)
                            Spacer()
                            Text("\(game.food) lbs").font(.headline).foregroundColor(OT.amber)
                        }
                        HStack {
                            Text("Party alive").font(.body)
                            Spacer()
                            Text("\(game.aliveMembers.count) of \(game.members.count)").font(.headline).foregroundColor(OT.amber)
                        }
                    }
                }

                if lm.hasStore {
                    BigButton(title: "Buy Supplies at the Fort") { showStore = true }
                    Text("Prices here run \(factor == 1 ? "the same as" : "about \(factor)×") Independence prices.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                }

                tradeCard

                BigButton(title: "Rest 1 Day Here", color: Color(red: 0.65, green: 0.78, blue: 0.62)) {
                    game.restDayAtStop()
                }
                BigButton(title: "Continue on the Trail") {
                    game.leaveLandmark()
                }
            }
            .padding(20)
        }
        .sheet(isPresented: $showStore) {
            ZStack {
                OT.bg.ignoresSafeArea()
                StoreView(game: game, factor: factor, isInitialStore: false) { showStore = false }
                    .foregroundColor(OT.cream)
            }
        }
        .onAppear {
            if offer == nil { offer = game.makeTradeOffer() }
        }
    }

    @ViewBuilder
    private var tradeCard: some View {
        if let offer = offer, !tradeDone {
            Panel {
                VStack(alignment: .leading, spacing: 12) {
                    Text("A traveler wants to trade")
                        .font(.headline)
                    Text("They offer you \(offer.wantText) in exchange for \(offer.giveText).")
                        .font(.body)
                    if !tradeNote.isEmpty {
                        Text(tradeNote).font(.body.weight(.semibold)).foregroundColor(.orange)
                    }
                    HStack(spacing: 10) {
                        BigButton(title: "Accept Trade") {
                            if game.canAccept(offer) {
                                game.acceptTrade(offer)
                                tradeDone = true
                            } else {
                                tradeNote = "You don't have what they're asking for."
                            }
                        }
                        BigButton(title: "No Thanks", color: Color(red: 0.65, green: 0.78, blue: 0.62)) {
                            tradeDone = true
                        }
                    }
                }
            }
        }
    }
}
