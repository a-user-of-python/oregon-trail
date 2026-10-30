import SwiftUI

// MARK: - Pixel landscapes (original, code-drawn on the pixel grid)
//
// Layered composition in the reference style: banded sky with dithered
// transitions, sun/moon, drifting blocky clouds, a stepped mountain range,
// rolling hills, speckled ground with a dirt trail, the wagon team, and a
// dark foreground grass fringe. Weather re-palettes the whole scene.

// MARK: Sky palettes per weather (top, mid, horizon)

func skyBands(for weather: Weather) -> (Color, Color, Color) {
    switch weather {
    case .warm:  return (Color(red: 0.16, green: 0.38, blue: 0.72),
                         Color(red: 0.38, green: 0.60, blue: 0.86),
                         Color(red: 0.74, green: 0.86, blue: 0.94))
    case .hot:   return (Color(red: 0.20, green: 0.42, blue: 0.76),
                         Color(red: 0.45, green: 0.66, blue: 0.88),
                         Color(red: 0.96, green: 0.82, blue: 0.55))
    case .cool:  return (Color(red: 0.24, green: 0.40, blue: 0.64),
                         Color(red: 0.47, green: 0.62, blue: 0.78),
                         Color(red: 0.78, green: 0.86, blue: 0.90))
    case .cold, .veryCold:
                 return (Color(red: 0.32, green: 0.44, blue: 0.60),
                         Color(red: 0.56, green: 0.66, blue: 0.76),
                         Color(red: 0.85, green: 0.90, blue: 0.94))
    case .rainy, .veryRainy:
                 return (Color(red: 0.24, green: 0.30, blue: 0.40),
                         Color(red: 0.40, green: 0.48, blue: 0.56),
                         Color(red: 0.62, green: 0.69, blue: 0.73))
    case .snowy, .verySnowy:
                 return (Color(red: 0.45, green: 0.56, blue: 0.70),
                         Color(red: 0.65, green: 0.74, blue: 0.84),
                         Color(red: 0.90, green: 0.93, blue: 0.96))
    case .foggy: return (Color(red: 0.44, green: 0.50, blue: 0.52),
                         Color(red: 0.60, green: 0.65, blue: 0.65),
                         Color(red: 0.78, green: 0.81, blue: 0.79))
    }
}

private func groundPalette(for weather: Weather) -> (base: Color, dark: Color, lite: Color, hill: Color) {
    switch weather {
    case .snowy, .verySnowy:
        return (Color(red: 0.87, green: 0.90, blue: 0.92), Color(red: 0.72, green: 0.79, blue: 0.83),
                Color(red: 0.96, green: 0.97, blue: 0.98), Color(red: 0.62, green: 0.70, blue: 0.76))
    case .rainy, .veryRainy:
        return (Color(red: 0.24, green: 0.38, blue: 0.18), Color(red: 0.17, green: 0.29, blue: 0.13),
                Color(red: 0.32, green: 0.48, blue: 0.23), Color(red: 0.28, green: 0.40, blue: 0.24))
    case .hot:
        return (Color(red: 0.55, green: 0.52, blue: 0.24), Color(red: 0.44, green: 0.42, blue: 0.18),
                Color(red: 0.66, green: 0.62, blue: 0.30), Color(red: 0.48, green: 0.50, blue: 0.26))
    default:
        return (PX.grass, PX.grassDark, PX.grassLite, PX.hillFar)
    }
}

// MARK: Scene renderer

/// Draws the full landscape into `pix`. `t` is animation time in seconds
/// (pass a constant for a still). Grid is `cols` x `rows` cells.
func drawPixelLandscape(_ pix: inout Pix, cols: Int, rows: Int, weather: Weather,
                        t: Double, wagon: Bool, pace: Pace,
                        groundTopFrac: Double, seed: Int) {
    let horizon = Int(Double(rows) * groundTopFrac)
    let gp = groundPalette(for: weather)
    let (skyTop, skyMid, skyHor) = skyBands(for: weather)
    let snowy = weather.isSnow

    // --- sky: three bands + checker dither at the seams
    let b1 = horizon * 2 / 5
    let b2 = horizon * 4 / 5
    pix.r(0, 0, cols, b1, skyTop)
    pix.r(0, b1, cols, b2 - b1, skyMid)
    pix.r(0, b2, cols, horizon - b2, skyHor)
    for x in 0..<cols where (x + b1) % 2 == 0 { pix.p(x, b1, skyTop) }
    for x in 0..<cols where (x + b2) % 2 == 0 { pix.p(x, b2, skyMid) }

    // --- sun (clear) or pale disc (cold/snow), none in rain/fog
    if weather == .warm || weather == .hot {
        drawDisc(&pix, cx: cols * 4 / 5, cy: max(4, horizon / 4), r: 4, c: PX.sun)
        drawDisc(&pix, cx: cols * 4 / 5, cy: max(4, horizon / 4), r: 6, c: PX.sun.opacity(0.25))
    } else if weather == .cold || weather == .veryCold || snowy {
        drawDisc(&pix, cx: cols * 4 / 5, cy: max(4, horizon / 4), r: 3, c: PX.cloud.opacity(0.8))
    }

    // --- clouds (blocky clusters, slow drift)
    let drift = Int(t * 1.2)
    let cloudC: Color = (weather.isWet || weather == .foggy) ? PX.cloudShad : PX.cloud
    for i in 0..<3 {
        let baseX = phash(i * 31 + seed, cols + 30) - 15
        let cx = ((baseX + drift) % (cols + 24) + (cols + 24)) % (cols + 24) - 12
        let cy = 2 + phash(i * 17 + seed, max(3, horizon / 3))
        drawCloud(&pix, x: cx, y: cy, c: cloudC)
    }

    // --- mountain range (stepped silhouettes, snow caps on the tall peaks)
    let peaks: [(Double, Double, Double)] = [(0.16, 0.30, 0.34), (0.50, 0.38, 0.44), (0.84, 0.30, 0.30)]
    for x in 0..<cols {
        var top = horizon
        for (cf, hw, hf) in peaks {
            let c = cf * Double(cols), w = hw * Double(cols)
            let d = abs(Double(x) - c)
            if d < w {
                let hgt = hf * Double(rows) * (1 - d / w)
                top = min(top, horizon - Int(hgt))
            }
        }
        if top < horizon {
            pix.r(x, top, 1, horizon - top, PX.mtn)
            if horizon - top > 9 { pix.r(x, top, 1, 2, PX.snow) }
            if x % 3 == 0 { pix.r(x, top + 3, 1, horizon - top - 3, PX.mtnDark.opacity(0.35)) }
        }
    }

    // --- rolling far hills
    for x in 0..<cols {
        let lift = Int((sin(Double(x) * 0.045 + Double(seed)) * 0.5 + 0.5) * Double(max(3, rows / 14))) + 2
        pix.r(x, horizon - lift, 1, lift + 2, gp.hill)
    }

    // --- ground
    pix.r(0, horizon, cols, rows - horizon, gp.base)
    // speckles
    let gRows = max(1, rows - horizon)
    for i in 0..<170 {
        let sx = phash(i * 3 + seed * 7, cols)
        let sy = horizon + phash(i * 11 + seed, gRows)
        pix.p(sx, sy, i % 2 == 0 ? gp.dark : gp.lite)
    }
    // scattered grass tufts on the plain
    if !snowy {
        for i in 0..<10 {
            let tx = phash(i * 41 + seed, cols - 8)
            let ty = horizon + 2 + phash(i * 19 + seed, max(2, gRows - 6))
            drawSprite(&pix, PXArt.grassTuft, x: tx, y: ty)
        }
    }

    // --- dirt trail (a wavy-edged band the wagon rolls on)
    let gy = rows - 9   // ground contact row for hooves/wheels
    for x in 0..<cols {
        let wobble = (x / 9) % 2
        pix.r(x, gy - 2 + wobble, 1, 5, PX.dirt)
        if phash(x * 5 + seed, 7) == 0 { pix.p(x, gy + 1, PX.dirtDark) }
        if phash(x * 9 + seed, 11) == 0 { pix.p(x, gy - 1 + wobble, PX.dirtLight) }
    }

    // --- the wagon team
    if wagon {
        let speed: Double = pace == .steady ? 1.0 : (pace == .strenuous ? 1.7 : 2.5)
        drawWagonTeam(&pix, rearX: max(4, (cols - 88) / 2), gy: gy, t: t, speed: speed)
    }

    // --- weather effects
    if weather.isWet {
        let n = weather == .veryRainy ? 80 : 48
        for i in 0..<n {
            let rx = (phash(i * 13 + seed, cols) + Int(t * 5)) % cols
            let ry = (phash(i * 29 + seed, rows) + Int(t * 34)) % rows
            pix.r(rx, ry, 1, 3, PX.foam.opacity(0.45))
        }
    } else if snowy {
        let n = weather == .verySnowy ? 70 : 40
        for i in 0..<n {
            let sway = Int(sin(t * 1.2 + Double(i)) * 1.5)
            let rx = ((phash(i * 17 + seed, cols) + sway) % cols + cols) % cols
            let ry = (phash(i * 23 + seed, rows) + Int(t * (5.0 + Double(i % 3)))) % rows
            pix.p(rx, ry, PX.snow.opacity(0.9))
            if i % 4 == 0 { pix.p(rx + 1, ry, PX.snow.opacity(0.7)) }
        }
    } else if weather == .foggy {
        for k in 0..<3 {
            let fy = horizon / 3 + k * (rows / 5)
            pix.r(0, fy, cols, 3, PX.cloud.opacity(0.18))
        }
    }

    // --- foreground fringe (dark grass silhouettes along the bottom edge)
    let fg: Color = snowy ? Color(red: 0.55, green: 0.63, blue: 0.68) : Color(red: 0.15, green: 0.27, blue: 0.11)
    for i in 0..<(cols / 2) {
        let fx = i * 2 + phash(i + seed, 2)
        let fh = 1 + phash(i * 7 + seed, 3)
        pix.r(fx, rows - fh, 1, fh, fg)
    }
}

private func drawDisc(_ pix: inout Pix, cx: Int, cy: Int, r: Int, c: Color) {
    for dy in -r...r {
        let half = Int(Double(r) * cos(Double(dy) / Double(r) * .pi / 2))
        pix.r(cx - half, cy + dy, half * 2 + 1, 1, c)
    }
}

private func drawCloud(_ pix: inout Pix, x: Int, y: Int, c: Color) {
    pix.r(x + 2, y, 6, 1, c)
    pix.r(x, y + 1, 11, 2, c)
    pix.r(x + 1, y + 3, 8, 1, PX.cloudShad.opacity(0.55))
}

// MARK: Wagon + ox team (procedural pixel drawing, step-animated)

func drawWagonTeam(_ pix: inout Pix, rearX: Int, gy: Int, t: Double, speed: Double) {
    let step = Int(t * speed * 2.2)
    let bob = (step % 2 == 0) ? 0 : 0   // wheels stay grounded; motion reads in spokes/legs

    // dust puffs behind the rear wheel
    for k in 0..<3 {
        let age = (Int(t * 3 * speed) + k * 3) % 9
        let dx = rearX - 2 - age
        let dy = gy - 1 - age / 3
        pix.r(dx, dy, 2, 1, PX.dust.opacity(0.55 - Double(age) * 0.05))
    }

    // ---- wagon
    let bedY = gy - 6 + bob
    // rear wheel (bigger) + front wheel
    drawWheel(&pix, cx: rearX + 6, cy: gy - 3, r: 4, step: step)
    drawWheel(&pix, cx: rearX + 32, cy: gy - 2, r: 3, step: step + 1)
    // bed
    pix.r(rearX, bedY, 38, 2, PX.wood)
    pix.r(rearX, bedY, 38, 1, PX.woodLight)
    pix.r(rearX + 1, bedY + 2, 36, 1, PX.woodDark)
    // side boards hint
    pix.p(rearX + 9, bedY + 1, PX.woodDark)
    pix.p(rearX + 19, bedY + 1, PX.woodDark)
    pix.p(rearX + 29, bedY + 1, PX.woodDark)
    // canopy: stepped arch, 7 rows tall, cream with shaded right fall
    let cx0 = rearX + 3, cw = 31
    let arch: [(Int, Int)] = [(10, 11), (6, 19), (3, 25), (1, 29), (0, 31), (0, 31), (0, 31)]
    for (i, (inset, wdt)) in arch.enumerated() {
        let y = bedY - 7 + i
        pix.r(cx0 + inset, y, wdt, 1, i < 2 ? PX.canvasTop : PX.canvasMid)
        pix.r(cx0 + inset + wdt - 3, y, 3, 1, PX.canvasLow.opacity(0.8))
    }
    // canopy ribs
    for fx in [0.28, 0.52, 0.76] {
        let rx = cx0 + Int(Double(cw) * fx)
        pix.r(rx, bedY - 4, 1, 4, PX.canvasLow)
    }
    // tongue from bed front down to the lead ox yoke
    pix.r(rearX + 38, bedY + 1, 6, 1, PX.woodDark)
    pix.r(rearX + 43, bedY + 2, 4, 1, PX.woodDark)

    // ---- oxen (two, in line)
    drawOx(&pix, x: rearX + 44, gy: gy, frame: step % 2, tint: PX.oxBody, dark: PX.oxDark)
    drawOx(&pix, x: rearX + 63, gy: gy, frame: (step + 1) % 2, tint: Color(red: 0.50, green: 0.41, blue: 0.32), dark: Color(red: 0.38, green: 0.30, blue: 0.22))
}

private func drawWheel(_ pix: inout Pix, cx: Int, cy: Int, r: Int, step: Int) {
    for dy in -r...r {
        for dx in -r...r {
            let d2 = dx * dx + dy * dy
            if d2 <= r * r && d2 >= (r - 1) * (r - 1) {
                pix.p(cx + dx, cy + dy, PX.woodDark)
            }
        }
    }
    // spokes at 45° steps, rotating with `step`
    let dirs: [(Int, Int)] = [(1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0), (-1, -1), (0, -1), (1, -1)]
    for k in 0..<4 {
        let d = dirs[(step + k * 2) % 8]
        for s in 1..<r {
            pix.p(cx + d.0 * s, cy + d.1 * s, PX.wood)
        }
    }
    pix.r(cx - 1, cy - 1, 2, 2, PX.ink)
}

private func drawOx(_ pix: inout Pix, x: Int, gy: Int, frame: Int, tint: Color, dark: Color) {
    // legs (two-frame walk: pairs alternate a 1-cell stride)
    let legXs = [2, 5, 12, 15]
    for (i, lx) in legXs.enumerated() {
        let stride = ((i < 2) == (frame == 0)) ? 1 : 0
        pix.r(x + lx, gy - 3, 1, 3, dark)
        pix.p(x + lx + stride, gy, dark)
    }
    // body
    pix.r(x + 2, gy - 9, 13, 1, tint)
    pix.r(x, gy - 8, 17, 3, tint)
    pix.r(x + 1, gy - 5, 15, 1, dark)   // belly shade
    // tail (sways with frame)
    pix.r(x - 1, gy - 8, 1, 4, dark)
    pix.p(x - 1 + frame, gy - 4, dark)
    // head, lowered at the front
    let hx = x + 17
    pix.r(hx, gy - 7, 4, 3, tint)
    pix.r(hx + 3, gy - 5, 2, 2, dark)   // muzzle
    pix.p(hx + 1, gy - 6, PX.ink)      // eye
    // horns + ears
    pix.p(hx, gy - 8, PX.horn)
    pix.p(hx - 1, gy - 9, PX.horn)
    pix.p(hx + 3, gy - 8, PX.horn)
    pix.p(hx + 4, gy - 9, PX.horn)
    // yoke bar over the neck
    pix.r(hx - 2, gy - 8, 5, 1, PX.woodDark)
}

// MARK: SwiftUI scene view

struct PixelScene: View {
    var weather: Weather
    var animated: Bool = true
    var wagon: Bool = true
    var pace: Pace = .steady
    var groundTopFrac: Double = 0.60
    var seed: Int = 7

    var body: some View {
        if animated {
            TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { tl in
                canvas(t: tl.date.timeIntervalSinceReferenceDate)
            }
        } else {
            canvas(t: 2.35)
        }
    }

    private func canvas(t: Double) -> some View {
        Canvas { ctx, size in
            guard size.width > 4, size.height > 4 else { return }
            let cols = size.width >= size.height ? 168 : 132
            let cell = size.width / CGFloat(cols)
            let rows = Int(size.height / cell) + 1
            var pix = Pix(ctx: ctx, cell: cell)
            drawPixelLandscape(&pix, cols: cols, rows: rows, weather: weather,
                               t: t, wagon: wagon, pace: pace,
                               groundTopFrac: groundTopFrac, seed: seed)
        }
    }
}

/// The living travel scene used on the trail screen.
struct TrailScene: View {
    var weather: Weather
    var pace: Pace
    var body: some View {
        PixelScene(weather: weather, animated: true, wagon: true, pace: pace,
                   groundTopFrac: 0.58, seed: 7)
    }
}
