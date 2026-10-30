import SwiftUI

// MARK: - Hunting: pixel prairie, code-drawn animal sprites, tap to shoot.
// (Spawn/movement/scoring logic identical to before — only the art changed:
// emoji animals, grass, and muzzle flash are now pixel sprites.)

struct HuntAnimal: Identifiable {
    let id = UUID()
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
                        .font(otDisplay(.title))
                    Text("Tap an animal to shoot it. Every tap costs a bullet.")
                        .font(.body)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Bullets: \(bulletsLeft)")
                        .font(.headline)
                        .foregroundColor(OT.amber)
                    Text("Meat: \(meat) lbs")
                        .font(.headline)
                        .foregroundColor(OT.amber)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)

            GeometryReader { geo in
                ZStack {
                    // pixel prairie: banded sky, ranges, ground
                    PixelScene(weather: .warm, animated: false, wagon: false,
                               pace: .steady, groundTopFrac: 0.32, seed: 21)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    // pixel grass tufts scattered over the field
                    ForEach(0..<14, id: \.self) { i in
                        GrassTuftArt()
                            .opacity(0.8)
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
                        AnimalArt(name: a.name, height: a.size, flip: a.dir < 0)
                            .contentShape(Rectangle())
                            .position(x: a.x * geo.size.width, y: a.y * geo.size.height)
                            .onTapGesture { shoot(a) }
                    }
                    // shot effects: pixel starburst + floating result
                    ForEach(effects) { e in
                        let age = Date().timeIntervalSince(e.born)
                        ZStack {
                            BurstArt()
                                .opacity(age < 0.16 ? 1 : 0)
                            if !e.label.isEmpty {
                                Text(e.label)
                                    .font(.body.weight(.heavy))
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
                    .font(.body.weight(.semibold))
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
        let kinds: [(String, Int, Double, CGFloat)] = [
            ("rabbit", 15, 0.55, 40),
            ("deer", 60, 0.38, 56),
            ("bear", 130, 0.26, 72),
            ("buffalo", 200, 0.20, 84),
        ]
        let count = initial ? 4 : 1
        for _ in 0..<count {
            let k = kinds.randomElement()!
            let fromLeft = Bool.random()
            animals.append(HuntAnimal(
                name: k.0, meat: k.1,
                x: fromLeft ? -0.05 : 1.05,
                y: Double.random(in: 0.15...0.85),
                speed: k.2 * Double.random(in: 0.8...1.25),
                dir: fromLeft ? 1 : -1,
                size: k.3
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

// MARK: - Pixel hunt art

struct AnimalArt: View {
    var name: String
    var height: CGFloat
    var flip: Bool
    var body: some View {
        let s = PXArt.animal(named: name)
        Canvas { ctx, size in
            var pix = Pix(ctx: ctx, cell: size.height / CGFloat(s.h))
            drawSpriteD(&pix, s, x: 0, y: 0, flip: flip)
        }
        .frame(width: height * CGFloat(s.w) / CGFloat(s.h), height: height)
    }
}

struct GrassTuftArt: View {
    var body: some View {
        Canvas { ctx, size in
            var pix = Pix(ctx: ctx, cell: size.height / CGFloat(PXArt.grassTuft.h))
            drawSprite(&pix, PXArt.grassTuft, x: 0, y: 0)
        }
        .frame(width: 30, height: 17)
    }
}

struct BurstArt: View {
    var body: some View {
        Canvas { ctx, size in
            var pix = Pix(ctx: ctx, cell: size.width / CGFloat(PXArt.burst.w))
            drawSprite(&pix, PXArt.burst, x: 0, y: 0)
        }
        .frame(width: 46, height: 41)
    }
}
