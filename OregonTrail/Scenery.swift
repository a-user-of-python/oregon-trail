import SwiftUI

// MARK: - Original drawn scenery (all artwork is code-drawn shapes — no assets)

// MARK: Sky

func skyColors(for weather: Weather) -> [Color] {
    switch weather {
    case .warm: return [Color(red: 0.35, green: 0.58, blue: 0.85), Color(red: 0.78, green: 0.88, blue: 0.97)]
    case .hot: return [Color(red: 0.45, green: 0.62, blue: 0.88), Color(red: 0.98, green: 0.85, blue: 0.60)]
    case .cool: return [Color(red: 0.42, green: 0.60, blue: 0.82), Color(red: 0.82, green: 0.89, blue: 0.95)]
    case .cold, .veryCold: return [Color(red: 0.55, green: 0.65, blue: 0.80), Color(red: 0.88, green: 0.92, blue: 0.97)]
    case .rainy, .veryRainy: return [Color(red: 0.38, green: 0.45, blue: 0.55), Color(red: 0.66, green: 0.72, blue: 0.78)]
    case .snowy, .verySnowy: return [Color(red: 0.70, green: 0.78, blue: 0.88), Color(red: 0.93, green: 0.95, blue: 0.99)]
    case .foggy: return [Color(red: 0.62, green: 0.68, blue: 0.72), Color(red: 0.85, green: 0.88, blue: 0.89)]
    }
}

struct HillShape: Shape {
    var lift: CGFloat = 0.55   // ridge height (fraction of height)
    var amp: CGFloat = 0.10    // rolling amount
    var phase: CGFloat = 0
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let base = rect.height * lift
        let a = rect.height * amp
        p.move(to: CGPoint(x: 0, y: rect.height))
        p.addLine(to: CGPoint(x: 0, y: base + sin(phase) * a))
        p.addQuadCurve(to: CGPoint(x: rect.width * 0.5, y: base - a),
                       control: CGPoint(x: rect.width * 0.25, y: base + a * 1.7))
        p.addQuadCurve(to: CGPoint(x: rect.width, y: base + a * 0.6),
                       control: CGPoint(x: rect.width * 0.75, y: base - a * 1.9))
        p.addLine(to: CGPoint(x: rect.width, y: rect.height))
        p.closeSubpath()
        return p
    }
}

struct SkyView: View {
    var weather: Weather
    var body: some View {
        ZStack {
            LinearGradient(colors: skyColors(for: weather), startPoint: .top, endPoint: .bottom)
            if weather == .warm || weather == .hot {
                GeometryReader { geo in
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.99, green: 0.85, blue: 0.40))
                            .frame(width: 54, height: 54)
                            .position(x: geo.size.width * 0.82, y: geo.size.height * 0.24)
                        Circle()
                            .fill(Color(red: 0.99, green: 0.85, blue: 0.40).opacity(0.35))
                            .frame(width: 84, height: 84)
                            .position(x: geo.size.width * 0.82, y: geo.size.height * 0.24)
                    }
                }
            }
            if weather.isWet || weather == .foggy {
                GeometryReader { geo in
                    ForEach(0..<3, id: \.self) { i in
                        Ellipse()
                            .fill(Color.white.opacity(weather == .foggy ? 0.5 : 0.75))
                            .frame(width: geo.size.width * 0.42, height: 26)
                            .position(x: geo.size.width * (0.22 + 0.28 * Double(i)),
                                      y: geo.size.height * (0.16 + 0.07 * Double(i % 2)))
                    }
                }
            }
            HillShape(lift: 0.62, amp: 0.10, phase: 1.3)
                .fill(Color(red: 0.42, green: 0.55, blue: 0.38))
            HillShape(lift: 0.78, amp: 0.08, phase: 4.1)
                .fill(Color(red: 0.30, green: 0.46, blue: 0.28))
        }
    }
}

// MARK: Wagon + oxen (Canvas-drawn, phase-animated)

struct WagonCanvas: View {
    var phase: Double

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let u = min(w / 340, h / 150)
            let gy = h * 0.86  // ground line

            // ground
            var ground = Path()
            ground.addRect(CGRect(x: 0, y: gy, width: w, height: h - gy))
            ctx.fill(ground, with: .color(Color(red: 0.55, green: 0.44, blue: 0.26)))
            // grass strokes
            var grass = Path()
            for i in 0..<26 {
                let gx = CGFloat((i * 67) % Int(max(w, 1)))
                grass.move(to: CGPoint(x: gx, y: gy + 4))
                grass.addLine(to: CGPoint(x: gx + 3, y: gy - 5))
            }
            ctx.stroke(grass, with: .color(Color(red: 0.36, green: 0.50, blue: 0.24)), lineWidth: 2)

            drawOx(ctx, cx: w * 0.86, gy: gy, u: u, phase: phase + 0.7, tint: Color(red: 0.42, green: 0.36, blue: 0.30))
            drawOx(ctx, cx: w * 0.70, gy: gy, u: u, phase: phase, tint: Color(red: 0.50, green: 0.43, blue: 0.36))

            // harness line from wagon to oxen
            var harness = Path()
            harness.move(to: CGPoint(x: w * 0.585, y: gy - 34 * u))
            harness.addLine(to: CGPoint(x: w * 0.655, y: gy - 38 * u))
            ctx.stroke(harness, with: .color(Color(red: 0.25, green: 0.18, blue: 0.10)), lineWidth: 2.5 * u)

            drawWagon(ctx, w: w, gy: gy, u: u, phase: phase)
        }
    }

    private func drawWagon(_ ctx: GraphicsContext, w: CGFloat, gy: CGFloat, u: CGFloat, phase: Double) {
        var ctx = ctx
        // canopy
        var canopy = Path()
        let left = w * 0.14, right = w * 0.60, baseY = gy - 34 * u, topY = gy - 88 * u
        canopy.move(to: CGPoint(x: left, y: baseY))
        canopy.addQuadCurve(to: CGPoint(x: right, y: baseY),
                            control: CGPoint(x: (left + right) / 2, y: topY - 16 * u))
        canopy.closeSubpath()
        ctx.fill(canopy, with: .color(Color(red: 0.96, green: 0.93, blue: 0.84)))
        ctx.stroke(canopy, with: .color(Color(red: 0.75, green: 0.70, blue: 0.58)), lineWidth: 2)
        // canopy ribs
        var ribs = Path()
        for f in [0.25, 0.5, 0.75] {
            let x = left + (right - left) * CGFloat(f)
            ribs.move(to: CGPoint(x: x, y: baseY))
            ribs.addQuadCurve(to: CGPoint(x: x, y: baseY - 6 * u),
                              control: CGPoint(x: x, y: topY + 26 * u))
        }
        ctx.stroke(ribs, with: .color(Color(red: 0.80, green: 0.75, blue: 0.62)), lineWidth: 1.5)
        // bed
        var bed = Path()
        bed.addRect(CGRect(x: w * 0.115, y: gy - 34 * u, width: w * 0.51, height: 13 * u))
        ctx.fill(bed, with: .color(Color(red: 0.48, green: 0.32, blue: 0.17)))
        var bedLine = Path()
        bedLine.move(to: CGPoint(x: w * 0.115, y: gy - 27 * u))
        bedLine.addLine(to: CGPoint(x: w * 0.625, y: gy - 27 * u))
        ctx.stroke(bedLine, with: .color(Color(red: 0.36, green: 0.23, blue: 0.12)), lineWidth: 2)
        // wheels (spokes rotate with phase)
        drawWheel(ctx, cx: w * 0.20, cy: gy - 15 * u, r: 15 * u, phase: phase)
        drawWheel(ctx, cx: w * 0.545, cy: gy - 15 * u, r: 15 * u, phase: phase)
    }

    private func drawWheel(_ ctx: GraphicsContext, cx: CGFloat, cy: CGFloat, r: CGFloat, phase: Double) {
        var ctx = ctx
        ctx.translateBy(x: cx, y: cy)
        ctx.rotate(by: .radians(phase))
        var tire = Path()
        tire.addEllipse(in: CGRect(x: -r, y: -r, width: r * 2, height: r * 2))
        ctx.stroke(tire, with: .color(Color(red: 0.30, green: 0.20, blue: 0.11)), lineWidth: r * 0.22)
        var spokes = Path()
        for k in 0..<3 {
            let a = Double(k) * Double.pi / 3
            spokes.move(to: CGPoint(x: -cos(a) * Double(r) * 0.85, y: -sin(a) * Double(r) * 0.85))
            spokes.addLine(to: CGPoint(x: cos(a) * Double(r) * 0.85, y: sin(a) * Double(r) * 0.85))
        }
        ctx.stroke(spokes, with: .color(Color(red: 0.42, green: 0.29, blue: 0.15)), lineWidth: r * 0.14)
        var hub = Path()
        hub.addEllipse(in: CGRect(x: -r * 0.22, y: -r * 0.22, width: r * 0.44, height: r * 0.44))
        ctx.fill(hub, with: .color(Color(red: 0.30, green: 0.20, blue: 0.11)))
    }

    private func drawOx(_ ctx: GraphicsContext, cx: CGFloat, gy: CGFloat, u: CGFloat, phase: Double, tint: Color) {
        var ctx = ctx
        let bodyY = gy - 44 * u
        // legs (swing with phase)
        var legs = Path()
        let legXs: [CGFloat] = [-19, -9, 11, 21]
        for (i, lx) in legXs.enumerated() {
            let swing = sin(phase + Double(i % 2) * Double.pi) * 5 * u
            legs.move(to: CGPoint(x: cx + lx * u, y: bodyY + 20 * u))
            legs.addLine(to: CGPoint(x: cx + lx * u + CGFloat(swing), y: gy))
        }
        ctx.stroke(legs, with: .color(tint), lineWidth: 4.5 * u)
        // body
        var body = Path()
        body.addRoundedRect(in: CGRect(x: cx - 27 * u, y: bodyY, width: 54 * u, height: 21 * u),
                            cornerSize: CGSize(width: 8 * u, height: 8 * u))
        ctx.fill(body, with: .color(tint))
        // head (front, lowered)
        var head = Path()
        head.addRoundedRect(in: CGRect(x: cx + 22 * u, y: bodyY + 6 * u, width: 17 * u, height: 14 * u),
                            cornerSize: CGSize(width: 5 * u, height: 5 * u))
        ctx.fill(head, with: .color(tint))
        // snout
        var snout = Path()
        snout.addRoundedRect(in: CGRect(x: cx + 33 * u, y: bodyY + 12 * u, width: 8 * u, height: 8 * u),
                             cornerSize: CGSize(width: 3 * u, height: 3 * u))
        ctx.fill(snout, with: .color(Color(red: 0.30, green: 0.24, blue: 0.20)))
        // horns
        var horns = Path()
        horns.move(to: CGPoint(x: cx + 25 * u, y: bodyY + 6 * u))
        horns.addQuadCurve(to: CGPoint(x: cx + 21 * u, y: bodyY - 3 * u),
                           control: CGPoint(x: cx + 21 * u, y: bodyY + 2 * u))
        horns.move(to: CGPoint(x: cx + 33 * u, y: bodyY + 6 * u))
        horns.addQuadCurve(to: CGPoint(x: cx + 38 * u, y: bodyY - 3 * u),
                           control: CGPoint(x: cx + 37 * u, y: bodyY + 2 * u))
        ctx.stroke(horns, with: .color(Color(red: 0.92, green: 0.89, blue: 0.80)), lineWidth: 2.5 * u)
        // tail
        var tail = Path()
        let sway = sin(phase * 1.3) * 3 * u
        tail.move(to: CGPoint(x: cx - 27 * u, y: bodyY + 3 * u))
        tail.addQuadCurve(to: CGPoint(x: cx - 31 * u + CGFloat(sway), y: bodyY + 22 * u),
                          control: CGPoint(x: cx - 30 * u, y: bodyY + 12 * u))
        ctx.stroke(tail, with: .color(tint), lineWidth: 3 * u)
    }
}

// MARK: Weather effects overlay (rain / snow)

struct WeatherFX: View {
    var weather: Weather
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { tl in
            Canvas { ctx, size in
                let t = tl.date.timeIntervalSinceReferenceDate
                let w = Double(size.width), h = Double(size.height)
                if weather.isWet {
                    let n = weather == .veryRainy ? 90 : 55
                    var drops = Path()
                    for i in 0..<n {
                        let x = (Double((i * 97) % 401) / 401.0) * w + (t * 30).truncatingRemainder(dividingBy: 40) - 20
                        let y = (Double((i * 57) % 389) / 389.0 + (t * 1.9).truncatingRemainder(dividingBy: 1.0) / 1.0).truncatingRemainder(dividingBy: 1.0) * (h + 30) - 15
                        drops.move(to: CGPoint(x: x, y: y))
                        drops.addLine(to: CGPoint(x: x - 3, y: y + 13))
                    }
                    ctx.stroke(drops, with: .color(Color.white.opacity(0.55)), lineWidth: 1.6)
                } else if weather.isSnow {
                    let n = weather == .verySnowy ? 80 : 45
                    for i in 0..<n {
                        let baseX = (Double((i * 89) % 397) / 397.0) * w
                        let x = baseX + sin(t * 0.9 + Double(i)) * 12
                        let y = ((Double((i * 71) % 383) / 383.0) + (t * 0.06 * (1.0 + Double(i % 3) * 0.3))).truncatingRemainder(dividingBy: 1.0) * h
                        let r = 1.8 + Double(i % 3) * 0.8
                        var flake = Path()
                        flake.addEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
                        ctx.fill(flake, with: .color(Color.white.opacity(0.85)))
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: The living travel scene (sky + hills + wagon + weather)

struct TrailScene: View {
    var weather: Weather
    var pace: Pace
    var body: some View {
        ZStack {
            SkyView(weather: weather)
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { tl in
                let speed: Double = pace == .steady ? 1.0 : (pace == .strenuous ? 1.7 : 2.5)
                WagonCanvas(phase: tl.date.timeIntervalSinceReferenceDate * speed * 2.4)
            }
            WeatherFX(weather: weather)
        }
    }
}
