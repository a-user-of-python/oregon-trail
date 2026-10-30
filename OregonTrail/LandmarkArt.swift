import SwiftUI

// MARK: - Pixel landmark arrival art (original, code-drawn on the pixel grid)

private func pxDisc(_ pix: inout Pix, cx: Int, cy: Int, r: Int, c: Color) {
    for dy in -r...r {
        let half = Int(Double(r) * cos(Double(dy) / Double(r) * .pi / 2))
        pix.r(cx - half, cy + dy, half * 2 + 1, 1, c)
    }
}

/// Shared backdrop: banded sky, sun, a cloud, speckled ground.
private func pxBackdrop(_ pix: inout Pix, cols: Int, rows: Int, groundFrac: Double = 0.72) -> Int {
    let (top, mid, hor) = skyBands(for: .warm)
    let g = Int(Double(rows) * groundFrac)
    pix.r(0, 0, cols, g * 2 / 5, top)
    pix.r(0, g * 2 / 5, cols, g * 3 / 5 - g * 2 / 5, mid)
    pix.r(0, g * 3 / 5, cols, g - g * 3 / 5, hor)
    pxDisc(&pix, cx: cols * 5 / 6, cy: max(3, g / 4), r: 3, c: PX.sun)
    pix.r(cols / 8, 2, 6, 1, PX.cloud)
    pix.r(cols / 8 - 1, 3, 10, 1, PX.cloud)
    pix.r(0, g, cols, rows - g, PX.grass)
    for i in 0..<60 {
        let sx = phash(i * 3, cols)
        let sy = g + phash(i * 11, max(1, rows - g))
        pix.p(sx, sy, i % 2 == 0 ? PX.grassDark : PX.grassLite)
    }
    return g
}

struct LandmarkArtView: View {
    var landmark: Landmark

    var body: some View {
        Canvas { ctx, size in
            guard size.width > 4, size.height > 4 else { return }
            let cols = 120
            let cell = size.width / CGFloat(cols)
            let rows = Int(size.height / cell) + 1
            var pix = Pix(ctx: ctx, cell: cell)
            draw(&pix, cols: cols, rows: rows)
        }
    }

    private func draw(_ pix: inout Pix, cols: Int, rows: Int) {
        switch landmark.kind {
        case .fort:
            let g = pxBackdrop(&pix, cols: cols, rows: rows)
            drawFort(&pix, cols: cols, rows: rows, g: g)
        case .river:
            drawRiverScene(&pix, cols: cols, rows: rows)
        case .pass:
            let g = pxBackdrop(&pix, cols: cols, rows: rows, groundFrac: 0.80)
            drawPass(&pix, cols: cols, rows: rows, g: g)
        case .end:
            let g = pxBackdrop(&pix, cols: cols, rows: rows)
            drawValley(&pix, cols: cols, rows: rows, g: g)
        case .start:
            let g = pxBackdrop(&pix, cols: cols, rows: rows)
            drawTown(&pix, cols: cols, rows: rows, g: g)
        case .choice, .sight:
            let g = pxBackdrop(&pix, cols: cols, rows: rows)
            drawSight(&pix, cols: cols, rows: rows, g: g, name: landmark.name)
        }
    }

    private func drawFort(_ pix: inout Pix, cols: Int, rows: Int, g: Int) {
        let wallTop = g - rows / 3
        // palisade: pointed logs
        var x = cols / 8
        while x < cols * 7 / 8 {
            pix.r(x, wallTop + 1, 3, g - wallTop - 1, PX.wood)
            pix.p(x + 1, wallTop, PX.wood)
            pix.r(x, wallTop + 4, 3, 1, PX.woodDark)
            pix.r(x, g - 4, 3, 1, PX.woodDark)
            x += 4
        }
        // gate
        pix.r(cols / 2 - 4, g - rows / 5, 8, rows / 5, PX.woodDark)
        // flag on a pole
        let px = cols / 2
        pix.r(px, wallTop - rows / 6, 1, rows / 6 + (g - wallTop) / 2, PX.ink)
        pix.r(px + 1, wallTop - rows / 6, 7, 2, Color(red: 0.75, green: 0.25, blue: 0.22))
        pix.r(px + 1, wallTop - rows / 6 + 2, 5, 1, Color(red: 0.75, green: 0.25, blue: 0.22))
    }

    private func drawRiverScene(_ pix: inout Pix, cols: Int, rows: Int) {
        let g = pxBackdrop(&pix, cols: cols, rows: rows, groundFrac: 0.52)
        // water below the hill line
        pix.r(0, g, cols, rows - g, PX.water)
        for row in 0..<4 {
            let y = g + 2 + row * ((rows - g) / 4)
            for col in 0..<6 {
                let x = (col * cols / 6 + (row % 2) * 5) % cols
                pix.r(x, y, 6, 1, PX.foam.opacity(0.65))
            }
        }
        pix.r(0, rows - 2, cols, 2, PX.dirt)
    }

    private func drawPass(_ pix: inout Pix, cols: Int, rows: Int, g: Int) {
        let peaks: [(Double, Double, Double)] = [(0.10, 0.34, 0.55), (0.44, 0.36, 0.66), (0.76, 0.32, 0.48)]
        for x in 0..<cols {
            var top = g
            for (cf, hw, hf) in peaks {
                let c = cf * Double(cols) + hw * Double(cols) / 2
                let w = hw * Double(cols)
                let d = abs(Double(x) - c)
                if d < w / 1.0 {
                    let hgt = hf * Double(g) * (1 - d / w)
                    top = min(top, g - Int(hgt))
                }
            }
            if top < g {
                pix.r(x, top, 1, g - top, PX.rock)
                if g - top > 8 { pix.r(x, top, 1, 3, PX.snow) }
                if x % 2 == 0 { pix.p(x, top + 4, PX.rockDark) }
            }
        }
    }

    private func drawValley(_ pix: inout Pix, cols: Int, rows: Int, g: Int) {
        // farmhouse
        let hx = cols * 2 / 5, hw = cols / 6, hh = rows / 5
        pix.r(hx, g - hh, hw, hh, PX.canvasTop)
        for i in 0..<4 {
            pix.r(hx - 2 + i, g - hh - 3 + i, hw + 4 - i * 2, 1, Color(red: 0.58, green: 0.28, blue: 0.20))
        }
        pix.r(hx + hw / 2 - 1, g - hh / 2, 3, hh / 2, PX.woodDark)
        pix.r(hx + 3, g - hh + 3, 3, 3, PX.sun)
        // pines
        drawSprite(&pix, PXArt.pine, x: cols / 7, y: g - PXArt.pine.h)
        drawSprite(&pix, PXArt.pine, x: cols * 3 / 4, y: g - PXArt.pine.h + 2)
        // crop rows
        for i in 0..<3 {
            pix.r(cols / 12, g + 2 + i * 2, cols * 5 / 6, 1, PX.grassDark)
        }
    }

    private func drawTown(_ pix: inout Pix, cols: Int, rows: Int, g: Int) {
        let buildings: [(Int, Int, Int)] = [(6, 16, 12), (28, 20, 16), (54, 14, 11), (74, 18, 14)]
        for (bx, bw, bh) in buildings {
            let x = bx * cols / 100, w = bw * cols / 100, h = bh * rows / 40
            pix.r(x, g - h, w, h, PX.woodLight)
            pix.r(x - 1, g - h, w + 2, 1, PX.woodDark)
            pix.r(x + w / 2 - 1, g - h / 2, 2, 3, PX.sun)
        }
        // church spire
        let sx = cols * 88 / 100
        pix.r(sx, g - rows / 4, 6, rows / 4, PX.canvasTop)
        pix.r(sx + 2, g - rows / 4 - 4, 2, 4, PX.canvasTop)
        pix.p(sx + 2, g - rows / 4 - 5, PX.ink)
    }

    private func drawSight(_ pix: inout Pix, cols: Int, rows: Int, g: Int, name: String) {
        if name.contains("Chimney") {
            // stepped spire on a cone base
            let bx = cols * 2 / 5
            for i in 0..<6 {
                pix.r(bx - i * 2, g - 2 - i, 16 + i * 4, 1, PX.rock)
            }
            pix.r(bx + 5, g - rows / 3, 6, rows / 3 - 6, PX.rock)
            pix.r(bx + 5, g - rows / 3, 6, 2, PX.rockDark)
        } else if name.contains("Independence Rock") {
            // stepped dome
            let w0 = cols * 3 / 5, x0 = cols / 5
            let domeH = rows / 3
            for i in 0..<domeH {
                let inset = Int(Double(i) * Double(i)) / max(1, domeH) * w0 / (2 * domeH) * 2
                pix.r(x0 + inset, g - 1 - i, w0 - inset * 2, 1, i % 3 == 2 ? PX.rockDark : PX.rock)
            }
        } else if name.contains("Soda") {
            // mineral mound with bubbles
            let x0 = cols / 4, w0 = cols / 2
            for i in 0..<5 {
                pix.r(x0 + i * 3, g - 1 - i, w0 - i * 6, 1, PX.canvasMid)
            }
            for i in 0..<7 {
                let bx = x0 + 6 + phash(i * 13, w0 - 12)
                let by = g - 6 - phash(i * 7, 3)
                pix.r(bx, by, 2, 2, PX.foam.opacity(0.85))
            }
        } else {
            // The Dalles: rock gorge with a water channel
            pix.r(0, g - rows / 4, cols * 2 / 5, rows / 4, PX.rock)
            pix.r(cols * 3 / 5, g - rows / 4, cols * 2 / 5, rows / 4, PX.rockDark)
            pix.r(cols * 2 / 5, g - rows / 6, cols / 5, rows / 6 + (rows - g), PX.water)
            pix.r(cols * 2 / 5 + 2, g - rows / 8, 4, 1, PX.foam)
            pix.r(cols / 2, g + 2, 4, 1, PX.foam)
        }
    }
}

// MARK: - Animated pixel river for the crossing screen

struct AnimatedRiver: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { tl in
            Canvas { ctx, size in
                guard size.width > 4, size.height > 4 else { return }
                let cols = 120
                let cell = size.width / CGFloat(cols)
                let rows = Int(size.height / cell) + 1
                var pix = Pix(ctx: ctx, cell: cell)
                let t = tl.date.timeIntervalSinceReferenceDate
                let (top, mid, hor) = skyBands(for: .warm)
                let waterTop = rows * 2 / 5
                pix.r(0, 0, cols, waterTop / 2, top)
                pix.r(0, waterTop / 2, cols, waterTop - waterTop / 2, mid)
                pix.r(0, waterTop - 2, cols, 2, hor)
                // far hills (stepped)
                for x in 0..<cols {
                    let lift = Int((sin(Double(x) * 0.06) * 0.5 + 0.5) * 4.0) + 1
                    pix.r(x, waterTop - lift, 1, lift, PX.hillFar)
                }
                // water: alternating bands + drifting foam dashes in 3 lanes
                pix.r(0, waterTop, cols, rows - waterTop, PX.water)
                for y in waterTop..<rows where (y - waterTop) % 4 == 3 {
                    pix.r(0, y, cols, 1, PX.waterDeep.opacity(0.5))
                }
                for lane in 0..<3 {
                    let y = waterTop + 3 + lane * ((rows - waterTop) / 3)
                    let speed = 10.0 + Double(lane) * 6.0
                    let off = Int(t * speed) % 24
                    var x = -off
                    while x < cols {
                        pix.r(x, y, 7, 1, PX.foam.opacity(0.5 + 0.14 * Double(lane)))
                        x += 24
                    }
                }
                // near bank
                for x in 0..<cols {
                    let wobble = (x / 8) % 2
                    pix.r(x, rows - 3 + wobble, 1, 3 - wobble, PX.dirt)
                }
            }
        }
    }
}
