import SwiftUI

// MARK: - Illustrated landmark arrival cards (original, code-drawn)

struct LandmarkArtView: View {
    var landmark: Landmark

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            // sky
            var sky = Path()
            sky.addRect(CGRect(x: 0, y: 0, width: w, height: h))
            ctx.fill(sky, with: .linearGradient(Gradient(colors: [Color(red: 0.36, green: 0.58, blue: 0.84),
                                                            Color(red: 0.80, green: 0.89, blue: 0.96)]),
                                          startPoint: CGPoint(x: 0, y: 0),
                                          endPoint: CGPoint(x: 0, y: h)))
            // sun
            var sun = Path()
            sun.addEllipse(in: CGRect(x: w * 0.80, y: h * 0.08, width: 34, height: 34))
            ctx.fill(sun, with: .color(Color(red: 0.99, green: 0.85, blue: 0.40)))
            // ground
            var ground = Path()
            ground.addRect(CGRect(x: 0, y: h * 0.72, width: w, height: h * 0.28))
            ctx.fill(ground, with: .color(Color(red: 0.45, green: 0.58, blue: 0.32)))

            switch landmark.kind {
            case .fort: drawFort(ctx, w: w, h: h)
            case .river: drawRiverScene(ctx, w: w, h: h)
            case .pass: drawPass(ctx, w: w, h: h)
            case .end: drawValley(ctx, w: w, h: h)
            case .start: drawTown(ctx, w: w, h: h)
            case .choice, .sight: drawSight(ctx, w: w, h: h, name: landmark.name)
            }
        }
    }

    private func drawFort(_ ctx: GraphicsContext, w: CGFloat, h: CGFloat) {
        var ctx = ctx
        let base = h * 0.72
        // palisade logs
        let logW: CGFloat = 13
        var x = w * 0.14
        while x < w * 0.86 {
            var log = Path()
            log.addRoundedRect(in: CGRect(x: x, y: base - h * 0.34, width: logW, height: h * 0.34),
                               cornerSize: CGSize(width: 6, height: 6))
            ctx.fill(log, with: .color(Color(red: 0.55, green: 0.40, blue: 0.24)))
            x += logW + 2
        }
        // gate
        var gate = Path()
        gate.addRect(CGRect(x: w * 0.44, y: base - h * 0.24, width: w * 0.12, height: h * 0.24))
        ctx.fill(gate, with: .color(Color(red: 0.30, green: 0.21, blue: 0.12)))
        // flag
        var pole = Path()
        pole.move(to: CGPoint(x: w * 0.5, y: base - h * 0.24))
        pole.addLine(to: CGPoint(x: w * 0.5, y: base - h * 0.52))
        ctx.stroke(pole, with: .color(Color(red: 0.35, green: 0.25, blue: 0.15)), lineWidth: 3)
        var flag = Path()
        flag.move(to: CGPoint(x: w * 0.5, y: base - h * 0.52))
        flag.addLine(to: CGPoint(x: w * 0.5 + 26, y: base - h * 0.47))
        flag.addLine(to: CGPoint(x: w * 0.5, y: base - h * 0.42))
        flag.closeSubpath()
        ctx.fill(flag, with: .color(Color(red: 0.75, green: 0.25, blue: 0.22)))
    }

    private func drawRiverScene(_ ctx: GraphicsContext, w: CGFloat, h: CGFloat) {
        var ctx = ctx
        // far hills
        var hills = Path()
        hills.move(to: CGPoint(x: 0, y: h * 0.55))
        hills.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.55), control: CGPoint(x: w * 0.25, y: h * 0.30))
        hills.addQuadCurve(to: CGPoint(x: w, y: h * 0.55), control: CGPoint(x: w * 0.75, y: h * 0.34))
        hills.addLine(to: CGPoint(x: w, y: h * 0.72))
        hills.addLine(to: CGPoint(x: 0, y: h * 0.72))
        hills.closeSubpath()
        ctx.fill(hills, with: .color(Color(red: 0.40, green: 0.53, blue: 0.36)))
        // water
        var water = Path()
        water.addRect(CGRect(x: 0, y: h * 0.55, width: w, height: h * 0.45))
        ctx.fill(water, with: .linearGradient(Gradient(colors: [Color(red: 0.25, green: 0.50, blue: 0.72),
                                                          Color(red: 0.15, green: 0.36, blue: 0.58)]),
                                        startPoint: CGPoint(x: 0, y: h * 0.55),
                                        endPoint: CGPoint(x: 0, y: h)))
        // wave lines
        var waves = Path()
        for row in 0..<4 {
            let y = h * (0.62 + 0.09 * Double(row))
            for col in 0..<6 {
                let x = w * (0.06 + 0.16 * Double(col)) + (row % 2 == 0 ? 0 : w * 0.05)
                waves.move(to: CGPoint(x: x, y: y))
                waves.addQuadCurve(to: CGPoint(x: x + w * 0.08, y: y),
                                   control: CGPoint(x: x + w * 0.04, y: y - 5))
            }
        }
        ctx.stroke(waves, with: .color(Color.white.opacity(0.6)), lineWidth: 2)
    }

    private func drawPass(_ ctx: GraphicsContext, w: CGFloat, h: CGFloat) {
        var ctx = ctx
        let peaks: [(CGFloat, CGFloat, CGFloat)] = [(0.02, 0.55, 0.16), (0.30, 0.62, 0.06), (0.58, 0.52, 0.20)]
        for (fx, fw, top) in peaks {
            var m = Path()
            let apex = CGPoint(x: w * (fx + fw / 2), y: h * top)
            m.move(to: CGPoint(x: w * fx, y: h * 0.74))
            m.addLine(to: apex)
            m.addLine(to: CGPoint(x: w * (fx + fw), y: h * 0.74))
            m.closeSubpath()
            ctx.fill(m, with: .color(Color(red: 0.45, green: 0.48, blue: 0.55)))
            var cap = Path()
            cap.move(to: CGPoint(x: apex.x - w * fw * 0.14, y: h * top + h * 0.10))
            cap.addLine(to: apex)
            cap.addLine(to: CGPoint(x: apex.x + w * fw * 0.14, y: h * top + h * 0.10))
            cap.addLine(to: CGPoint(x: apex.x + w * fw * 0.05, y: h * top + h * 0.06))
            cap.addLine(to: CGPoint(x: apex.x, y: h * top + h * 0.10))
            cap.addLine(to: CGPoint(x: apex.x - w * fw * 0.05, y: h * top + h * 0.06))
            cap.closeSubpath()
            ctx.fill(cap, with: .color(.white))
        }
    }

    private func drawValley(_ ctx: GraphicsContext, w: CGFloat, h: CGFloat) {
        var ctx = ctx
        // farmhouse
        var house = Path()
        house.addRect(CGRect(x: w * 0.40, y: h * 0.52, width: w * 0.16, height: h * 0.20))
        ctx.fill(house, with: .color(Color(red: 0.85, green: 0.80, blue: 0.72)))
        var roof = Path()
        roof.move(to: CGPoint(x: w * 0.375, y: h * 0.52))
        roof.addLine(to: CGPoint(x: w * 0.48, y: h * 0.40))
        roof.addLine(to: CGPoint(x: w * 0.585, y: h * 0.52))
        roof.closeSubpath()
        ctx.fill(roof, with: .color(Color(red: 0.62, green: 0.30, blue: 0.22)))
        // trees
        for fx in [0.16, 0.68, 0.80] {
            var trunk = Path()
            trunk.addRect(CGRect(x: w * fx, y: h * 0.58, width: 6, height: h * 0.14))
            ctx.fill(trunk, with: .color(Color(red: 0.40, green: 0.28, blue: 0.16)))
            var crown = Path()
            crown.addEllipse(in: CGRect(x: w * fx - 20, y: h * 0.34, width: 46, height: 46))
            ctx.fill(crown, with: .color(Color(red: 0.25, green: 0.50, blue: 0.25)))
        }
        // crop rows
        var rows = Path()
        for i in 0..<5 {
            let y = h * (0.80 + 0.04 * Double(i))
            rows.move(to: CGPoint(x: w * 0.06, y: y))
            rows.addLine(to: CGPoint(x: w * 0.94, y: y))
        }
        ctx.stroke(rows, with: .color(Color(red: 0.30, green: 0.52, blue: 0.24)), lineWidth: 2.5)
    }

    private func drawTown(_ ctx: GraphicsContext, w: CGFloat, h: CGFloat) {
        var ctx = ctx
        let base = h * 0.72
        let buildings: [(CGFloat, CGFloat, CGFloat)] = [(0.08, 0.16, 0.26), (0.28, 0.20, 0.34), (0.52, 0.15, 0.24), (0.70, 0.18, 0.30)]
        for (fx, fw, fh) in buildings {
            var b = Path()
            b.addRect(CGRect(x: w * fx, y: base - h * fh, width: w * fw, height: h * fh))
            ctx.fill(b, with: .color(Color(red: 0.62, green: 0.47, blue: 0.33)))
            var r = Path()
            r.move(to: CGPoint(x: w * fx - 4, y: base - h * fh))
            r.addLine(to: CGPoint(x: w * (fx + fw / 2), y: base - h * fh - 12))
            r.addLine(to: CGPoint(x: w * (fx + fw) + 4, y: base - h * fh))
            r.closeSubpath()
            ctx.fill(r, with: .color(Color(red: 0.45, green: 0.30, blue: 0.20)))
            var win = Path()
            win.addRect(CGRect(x: w * (fx + fw / 2) - 5, y: base - h * fh * 0.55, width: 10, height: 12))
            ctx.fill(win, with: .color(Color(red: 0.99, green: 0.85, blue: 0.45)))
        }
        // church spire
        var spire = Path()
        spire.move(to: CGPoint(x: w * 0.895, y: base - h * 0.30))
        spire.addLine(to: CGPoint(x: w * 0.915, y: base - h * 0.46))
        spire.addLine(to: CGPoint(x: w * 0.935, y: base - h * 0.30))
        spire.closeSubpath()
        ctx.fill(spire, with: .color(Color(red: 0.92, green: 0.90, blue: 0.85)))
    }

    private func drawSight(_ ctx: GraphicsContext, w: CGFloat, h: CGFloat, name: String) {
        var ctx = ctx
        if name.contains("Chimney") {
            // the famous spire
            var rock = Path()
            rock.move(to: CGPoint(x: w * 0.30, y: h * 0.72))
            rock.addLine(to: CGPoint(x: w * 0.44, y: h * 0.72))
            rock.addLine(to: CGPoint(x: w * 0.40, y: h * 0.38))
            rock.addLine(to: CGPoint(x: w * 0.415, y: h * 0.14))
            rock.addLine(to: CGPoint(x: w * 0.455, y: h * 0.14))
            rock.addLine(to: CGPoint(x: w * 0.45, y: h * 0.38))
            rock.addLine(to: CGPoint(x: w * 0.58, y: h * 0.72))
            rock.closeSubpath()
            ctx.fill(rock, with: .color(Color(red: 0.78, green: 0.58, blue: 0.38)))
        } else if name.contains("Independence Rock") {
            var dome = Path()
            dome.move(to: CGPoint(x: w * 0.16, y: h * 0.72))
            dome.addQuadCurve(to: CGPoint(x: w * 0.84, y: h * 0.72),
                              control: CGPoint(x: w * 0.5, y: h * 0.08))
            dome.closeSubpath()
            ctx.fill(dome, with: .color(Color(red: 0.62, green: 0.55, blue: 0.50)))
        } else if name.contains("Soda") {
            // bubbling springs
            var mound = Path()
            mound.move(to: CGPoint(x: w * 0.2, y: h * 0.72))
            mound.addQuadCurve(to: CGPoint(x: w * 0.8, y: h * 0.72),
                               control: CGPoint(x: w * 0.5, y: h * 0.42))
            mound.closeSubpath()
            ctx.fill(mound, with: .color(Color(red: 0.85, green: 0.78, blue: 0.66)))
            for i in 0..<7 {
                let bx = w * (0.34 + 0.055 * Double(i))
                let by = h * (0.60 - 0.03 * Double(i % 3))
                var bubble = Path()
                bubble.addEllipse(in: CGRect(x: bx, y: by, width: 10 + Double(i % 3) * 4, height: 10 + Double(i % 3) * 4))
                ctx.fill(bubble, with: .color(Color.white.opacity(0.75)))
            }
        } else {
            // The Dalles: river gorge
            var gorge = Path()
            gorge.move(to: CGPoint(x: 0, y: h * 0.30))
            gorge.addLine(to: CGPoint(x: w * 0.38, y: h * 0.52))
            gorge.addLine(to: CGPoint(x: w * 0.38, y: h))
            gorge.addLine(to: CGPoint(x: 0, y: h))
            gorge.closeSubpath()
            ctx.fill(gorge, with: .color(Color(red: 0.50, green: 0.44, blue: 0.40)))
            var gorge2 = Path()
            gorge2.move(to: CGPoint(x: w, y: h * 0.30))
            gorge2.addLine(to: CGPoint(x: w * 0.62, y: h * 0.52))
            gorge2.addLine(to: CGPoint(x: w * 0.62, y: h))
            gorge2.addLine(to: CGPoint(x: w, y: h))
            gorge2.closeSubpath()
            ctx.fill(gorge2, with: .color(Color(red: 0.45, green: 0.39, blue: 0.36)))
            var rapids = Path()
            rapids.addRect(CGRect(x: w * 0.38, y: h * 0.52, width: w * 0.24, height: h * 0.48))
            ctx.fill(rapids, with: .color(Color(red: 0.30, green: 0.55, blue: 0.75)))
        }
    }
}

// MARK: - Animated river for the crossing screen

struct AnimatedRiver: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { tl in
            Canvas { ctx, size in
                let w = size.width, h = size.height
                let t = tl.date.timeIntervalSinceReferenceDate
                // far bank
                var hills = Path()
                hills.move(to: CGPoint(x: 0, y: h * 0.30))
                hills.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.30), control: CGPoint(x: w * 0.25, y: h * 0.06))
                hills.addQuadCurve(to: CGPoint(x: w, y: h * 0.30), control: CGPoint(x: w * 0.75, y: h * 0.10))
                hills.addLine(to: CGPoint(x: w, y: h * 0.40))
                hills.addLine(to: CGPoint(x: 0, y: h * 0.40))
                hills.closeSubpath()
                var sky = Path()
                sky.addRect(CGRect(x: 0, y: 0, width: w, height: h * 0.40))
                ctx.fill(sky, with: .linearGradient(Gradient(colors: [Color(red: 0.36, green: 0.58, blue: 0.84),
                                                                Color(red: 0.80, green: 0.89, blue: 0.96)]),
                                              startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 0, y: h * 0.4)))
                ctx.fill(hills, with: .color(Color(red: 0.40, green: 0.53, blue: 0.36)))
                // water
                var water = Path()
                water.addRect(CGRect(x: 0, y: h * 0.38, width: w, height: h * 0.62))
                ctx.fill(water, with: .linearGradient(Gradient(colors: [Color(red: 0.28, green: 0.53, blue: 0.74),
                                                                  Color(red: 0.13, green: 0.33, blue: 0.55)]),
                                                startPoint: CGPoint(x: 0, y: h * 0.38), endPoint: CGPoint(x: 0, y: h)))
                // three drifting wave layers
                for layer in 0..<3 {
                    let speed = 14.0 + Double(layer) * 9.0
                    let yBase = h * (0.50 + 0.15 * Double(layer))
                    let off = (t * speed).truncatingRemainder(dividingBy: Double(w) / 4)
                    var wave = Path()
                    var x = -off - Double(w) / 4
                    while x < Double(w) {
                        wave.move(to: CGPoint(x: CGFloat(x), y: yBase))
                        wave.addQuadCurve(to: CGPoint(x: CGFloat(x) + w / 8, y: yBase),
                                          control: CGPoint(x: CGFloat(x) + w / 16, y: yBase - 5))
                        x += Double(w) / 4
                    }
                    ctx.stroke(wave, with: .color(Color.white.opacity(0.35 + 0.15 * Double(layer))), lineWidth: 2.2)
                }
                // near bank
                var bank = Path()
                bank.move(to: CGPoint(x: 0, y: h))
                bank.addLine(to: CGPoint(x: 0, y: h * 0.90))
                bank.addQuadCurve(to: CGPoint(x: w, y: h * 0.94), control: CGPoint(x: w * 0.5, y: h * 0.84))
                bank.addLine(to: CGPoint(x: w, y: h))
                bank.closeSubpath()
                ctx.fill(bank, with: .color(Color(red: 0.55, green: 0.44, blue: 0.28)))
            }
        }
    }
}
