import SwiftUI

struct HuntAnimal: Identifiable {
    let id = UUID()
    var emoji: String
    var name: String
    var meat: Int
    var x: Double          // 0...1 across the field
    var y: Double          // 0.12...0.85 down the field
    var speed: Double      // fraction of field width per second
    var dir: Double        // +1 right, -1 left
    var size: CGFloat
}

struct ShotEffect: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    var label: String
    var hit: Bool
    var born: Date
}

struct HuntView: View {
    @ObservedObject var game: Game

    @State private var animals: [HuntAnimal] = []
    @State private var effects: [ShotEffect] = []
    @State private var shots: Int = 0
    @State private var meat: Int = 0
    @State private var lastHit: String = ""
    @State private var finished = false

    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    private var bulletsLeft: Int { max(0, game.bullets - shots) }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hunting")
                        .font(.title.weight(.bold))
                    Text("Tap an animal to shoot it. Every tap costs a bullet.")
                        .font(.body)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Bullets: \(bulletsLeft)")
                        .font(.title3.weight(.bold))
                        .foregroundColor(OT.amber)
                    Text("Meat: \(meat) lbs")
                        .font(.title3.weight(.bold))
                        .foregroundColor(OT.amber)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)

            GeometryReader { geo in
                ZStack {
                    // layered prairie scene: sky, sun, hills
                    SkyView(weather: .warm)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    // ground texture: simple original shapes
                    ForEach(0..<14, id: \.self) { i in
                        Text("🌾")
                            .font(.system(size: 26))
                            .opacity(0.55)
                            .position(x: CGFloat((i * 83) % 97) / 97 * geo.size.width,
                                      y: CGFloat((i * 47) % 40 + 58) / 100 * geo.size.height)
                    }
                    // miss layer: catches every tap that isn't on an animal
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(DragGesture(minimumDistance: 0).onEnded { v in
                            fireShot(at: CGPoint(x: v.location.x / max(geo.size.width, 1),
                                                 y: v.location.y / max(geo.size.height, 1)))
                        })
                    ForEach(animals) { a in
                        Text(a.emoji)
                            .font(.system(size: a.size))
                            .position(x: a.x * geo.size.width, y: a.y * geo.size.height)
                            .onTapGesture { shoot(a) }
                    }
                    // shot effects: muzzle flash + floating result
                    ForEach(effects) { e in
                        let age = Date().timeIntervalSince(e.born)
                        ZStack {
                            Text("💥")
                                .font(.system(size: 42))
                                .opacity(age < 0.16 ? 1 : 0)
                            if !e.label.isEmpty {
                                Text(e.label)
                                    .font(.title3.weight(.heavy))
                                    .foregroundColor(e.hit ? OT.amber : Color(red: 1.0, green: 0.45, blue: 0.40))
                                    .shadow(color: .black, radius: 2, x: 1, y: 1)
                                    .offset(y: -38 - age * 30)
                                    .opacity(age < 0.85 ? 1 : 0)
                            }
                        }
                        .position(x: e.x * geo.size.width, y: e.y * geo.size.height)
                    }
                }
            }
            .frame(maxHeight: .infinity)
            .padding(.horizontal, 12)

            if !lastHit.isEmpty {
                Text(lastHit)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(OT.amber)
            }

            BigButton(title: "Return to the Wagon") { finish() }
                .padding(.horizontal, 20)
                .padding(.bottom, 14)
        }
        .onReceive(timer) { _ in tick() }
        .onAppear { spawn(initial: true) }
    }

    // MARK: Game loop

    private func tick() {
        guard !finished else { return }
        for i in animals.indices {
            animals[i].x += animals[i].speed * animals[i].dir * 0.05
        }
        animals.removeAll { $0.x < -0.1 || $0.x > 1.1 }
        effects.removeAll { Date().timeIntervalSince($0.born) > 0.9 }
        if animals.count < 5 && Double.random(in: 0..<1) < 0.10 {
            spawn(initial: false)
        }
        if bulletsLeft <= 0 { finish() }
    }

    private func spawn(initial: Bool) {
        let kinds: [(String, String, Int, Double, CGFloat)] = [
            ("🐇", "rabbit", 15, 0.55, 46),
            ("🦌", "deer", 60, 0.38, 68),
            ("🐻", "bear", 130, 0.26, 88),
            ("🦬", "buffalo", 200, 0.20, 100),
        ]
        let count = initial ? 4 : 1
        for _ in 0..<count {
            let k = kinds.randomElement()!
            let fromLeft = Bool.random()
            animals.append(HuntAnimal(
                emoji: k.0, name: k.1, meat: k.2,
                x: fromLeft ? -0.05 : 1.05,
                y: Double.random(in: 0.15...0.85),
                speed: k.3 * Double.random(in: 0.8...1.25),
                dir: fromLeft ? 1 : -1,
                size: k.4
            ))
        }
    }

    private func shoot(_ animal: HuntAnimal) {
        guard bulletsLeft > 0 else { return }
        shots += 1
        meat += animal.meat
        lastHit = "Got a \(animal.name)! +\(animal.meat) lbs of meat."
        effects.append(ShotEffect(x: animal.x, y: animal.y,
                                  label: "+\(animal.meat) lbs", hit: true, born: Date()))
        animals.removeAll { $0.id == animal.id }
        if bulletsLeft <= 0 { finish() }
    }

    private func fireShot(at point: CGPoint) {
        guard bulletsLeft > 0 else { return }
        shots += 1
        lastHit = "Missed."
        effects.append(ShotEffect(x: Double(point.x), y: Double(point.y),
                                  label: "", hit: false, born: Date()))
        if bulletsLeft <= 0 { finish() }
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        game.returnFromHunt(meat: meat, bulletsUsed: shots)
    }
}
