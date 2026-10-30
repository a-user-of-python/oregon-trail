import SwiftUI

// MARK: - Pixel art engine (all art is drawn in code on a coarse pixel grid)
//
// Every scene and sprite in the game is rendered as chunky, cell-aligned
// rectangles — real pixel art, one shared palette, no image assets.
// Sprites are defined as character maps; scenes are drawn procedurally
// with the same Pix helper so the whole game shares one look.

// MARK: Palette (disciplined, shared by every screen)

enum PX {
    static let ink       = Color(red: 0.13, green: 0.09, blue: 0.05)  // outlines, deep shadow
    static let woodDark  = Color(red: 0.32, green: 0.20, blue: 0.10)
    static let wood      = Color(red: 0.48, green: 0.31, blue: 0.15)
    static let woodLight = Color(red: 0.62, green: 0.44, blue: 0.23)
    static let canvasTop = Color(red: 0.97, green: 0.93, blue: 0.83)
    static let canvasMid = Color(red: 0.90, green: 0.83, blue: 0.66)
    static let canvasLow = Color(red: 0.78, green: 0.68, blue: 0.48)
    static let dirt      = Color(red: 0.62, green: 0.46, blue: 0.25)
    static let dirtDark  = Color(red: 0.47, green: 0.33, blue: 0.17)
    static let dirtLight = Color(red: 0.72, green: 0.56, blue: 0.33)
    static let grass     = Color(red: 0.33, green: 0.50, blue: 0.22)
    static let grassDark = Color(red: 0.24, green: 0.40, blue: 0.17)
    static let grassLite = Color(red: 0.45, green: 0.62, blue: 0.28)
    static let hillFar   = Color(red: 0.36, green: 0.50, blue: 0.30)
    static let hillNear  = Color(red: 0.27, green: 0.42, blue: 0.21)
    static let mtn       = Color(red: 0.38, green: 0.46, blue: 0.58)
    static let mtnDark   = Color(red: 0.30, green: 0.37, blue: 0.48)
    static let snow      = Color(red: 0.95, green: 0.97, blue: 0.98)
    static let rock      = Color(red: 0.52, green: 0.44, blue: 0.36)
    static let rockDark  = Color(red: 0.40, green: 0.33, blue: 0.26)
    static let water     = Color(red: 0.20, green: 0.44, blue: 0.66)
    static let waterDeep = Color(red: 0.12, green: 0.31, blue: 0.52)
    static let foam      = Color(red: 0.86, green: 0.94, blue: 0.97)
    static let sun       = Color(red: 1.00, green: 0.85, blue: 0.30)
    static let cloud     = Color(red: 0.96, green: 0.97, blue: 0.96)
    static let cloudShad = Color(red: 0.78, green: 0.83, blue: 0.86)
    static let oxBody    = Color(red: 0.44, green: 0.35, blue: 0.27)
    static let oxDark    = Color(red: 0.33, green: 0.25, blue: 0.19)
    static let horn      = Color(red: 0.94, green: 0.89, blue: 0.76)
    static let dust      = Color(red: 0.80, green: 0.70, blue: 0.52)
    static let gold      = Color(red: 0.93, green: 0.71, blue: 0.28)
    static let stone     = Color(red: 0.62, green: 0.60, blue: 0.56)
    static let stoneDark = Color(red: 0.45, green: 0.43, blue: 0.40)
}

// MARK: Pixel canvas helper

/// Draws cell-aligned rectangles into a GraphicsContext.
/// Grid coordinates are Ints; `cell` is the pixel size in points.
struct Pix {
    var ctx: GraphicsContext
    let cell: CGFloat

    mutating func r(_ x: Int, _ y: Int, _ w: Int, _ h: Int, _ c: Color) {
        guard w > 0, h > 0 else { return }
        ctx.fill(Path(CGRect(x: CGFloat(x) * cell, y: CGFloat(y) * cell,
                             width: CGFloat(w) * cell, height: CGFloat(h) * cell)),
                 with: .color(c))
    }
    mutating func p(_ x: Int, _ y: Int, _ c: Color) { r(x, y, 1, 1, c) }

    /// Fractional placement (for sprites positioned by game state, e.g. hunting).
    mutating func rd(_ x: Double, _ y: Double, _ w: Double, _ h: Double, _ c: Color) {
        guard w > 0, h > 0 else { return }
        ctx.fill(Path(CGRect(x: CGFloat(x) * cell, y: CGFloat(y) * cell,
                             width: CGFloat(w) * cell, height: CGFloat(h) * cell)),
                 with: .color(c))
    }
}

/// Deterministic 0..<mod hash — stable speckle/cloud layouts with no RNG state.
func phash(_ n: Int, _ mod: Int) -> Int {
    var x = (n &* 2654435761) & 0x7fffffff
    x ^= x >> 13
    x = (x &* 1103515245 + 12345) & 0x7fffffff
    return mod > 0 ? x % mod : 0
}

// MARK: Sprites (character maps; '.' = transparent)

struct Sprite {
    let rows: [String]
    let map: [Character: Color]
    var w: Int { rows.map { $0.count }.max() ?? 0 }
    var h: Int { rows.count }
}

func drawSprite(_ pix: inout Pix, _ s: Sprite, x: Int, y: Int, flip: Bool = false) {
    for (ry, row) in s.rows.enumerated() {
        let chars = Array(row)
        for (rx, ch) in chars.enumerated() {
            guard let c = s.map[ch] else { continue }
            let dx = flip ? (s.w - 1 - rx) : rx
            pix.p(x + dx, y + ry, c)
        }
    }
}

/// Fractional-position sprite drawing (hunting animals).
func drawSpriteD(_ pix: inout Pix, _ s: Sprite, x: Double, y: Double, flip: Bool = false) {
    for (ry, row) in s.rows.enumerated() {
        let chars = Array(row)
        for (rx, ch) in chars.enumerated() {
            guard let c = s.map[ch] else { continue }
            let dx = flip ? Double(s.w - 1 - rx) : Double(rx)
            pix.rd(x + dx, y + Double(ry), 1, 1, c)
        }
    }
}

// MARK: Creature + object sprites

enum PXArt {

    static let tombstone = Sprite(rows: [
        "....KKKKK....",
        "..KKSSSSSKK..",
        ".KSSSSSSSSSK.",
        ".KSKKKKKKKSK.",
        ".KSK.....KSK.",
        ".KSKKKKKKKSK.",
        ".KSSSSSSSSSK.",
        ".KSSSSSSSSSK.",
        ".KSSSSSSSSSK.",
        "KKSSSSSSSSSKK",
        "KDDSSSSSSSDDK",
        "DDDDDDDDDDDDD",
    ], map: ["K": PX.ink, "S": PX.stone, "D": PX.stoneDark])

    static let burst = Sprite(rows: [
        "....G....",
        ".G..G..G.",
        "..G.G.G..",
        "GGG.G.GGG",
        "....G....",
        "..G.G.G..",
        ".G..G..G.",
        "....G....",
    ], map: ["G": PX.gold])

    static let pine = Sprite(rows: [
        ".....K......",
        "....KGK.....",
        "....GGG.....",
        "...GGGGG....",
        "...KGKGK....",
        "..GGGGGGG...",
        "..GGGGGGG...",
        ".KGGGGGGGK..",
        ".GGGGGGGGG..",
        "GGGGGGGGGGG.",
        ".....W......",
        ".....W......",
    ], map: ["K": PX.ink, "G": PX.grassDark, "W": PX.woodDark])

    static let grassTuft = Sprite(rows: [
        "G..G..G",
        "G..G.G.",
        "GG.G.GG",
        "GGGGGGG",
    ], map: ["G": PX.grassDark])

    // MARK: Hunting animals (side view, facing right)

    static let rabbit = Sprite(rows: [
        "....K.....K...",
        "....K.....K...",
        "....K....K....",
        "....KK..K.K...",
        "......KKKK....",
        ".....KBBBBK...",
        ".WWKBBBBBBBK..",
        ".WWBBBBBBBBBK.",
        "..KBBBBBBBBK..",
        "...K..K...K...",
    ], map: ["K": PX.ink, "B": Color(red: 0.72, green: 0.65, blue: 0.55),
             "W": PX.canvasTop])

    static let deer = Sprite(rows: [
        ".................K.K....",
        "................K.K.K...",
        ".................K......",
        "................KKK.....",
        "...............KBBBK....",
        "..............KBBBBBK...",
        ".............KBBBBBBK...",
        "............KBBBBBBBK...",
        "..KBBBBBBBBBBBBBBBBK....",
        ".KBBBBBBBBBBBBBBBK......",
        ".KBBBBBBBBBBBBBK........",
        "..KBBBBBBBBBBK..........",
        "...K..K...K..K..........",
        "...K..K...K..K..........",
        "...K..K...K..K..........",
        "...K..K...K..K..........",
    ], map: ["K": PX.ink, "B": Color(red: 0.62, green: 0.45, blue: 0.28)])

    static let bear = Sprite(rows: [
        "................................",
        ".....KK.........................",
        "....KBBK....KKK.................",
        "...KBBBBKKKBBBBBK...............",
        "..KBBBBBBBBBBBBBBBK.............",
        ".KBBBBBBBBBBBBBBBBBK............",
        ".KBBBBBBBBBBBBBBBBBBK...........",
        ".KBBBBBBBBBBBBBBBBBBBK..........",
        "..KBBBBBBBBBBBBBBBBBK...........",
        "...KKBBBBBBBBBBBBKK.............",
        ".....K..K....K..K...............",
        ".....K..K....K..K...............",
        ".....K..K....K..K...............",
    ], map: ["K": PX.ink, "B": Color(red: 0.36, green: 0.27, blue: 0.19)])

    static let buffalo = Sprite(rows: [
        "..................................",
        "..........KKK.....................",
        "........KDDDDDK........K..........",
        ".......KDDDDDDDK......K.K.........",
        "......KDDKDDDDDDK....KDDDK........",
        ".....KDDDDDDDDDDDK..KDDDDDK.......",
        "....KDDDDDDDDDDDDDKKDDDDDDK.......",
        "...KDDDDDDDDDDDDDDDDDDDDDDK.......",
        "...KDDDDDDDDDDDDDDDDDDDDDDK.......",
        "....KDDDDDDDDDDDDDDDDDDDK.........",
        ".....KKDDDDDDDDDDDDDDKK...........",
        ".......K..K......K..K.............",
        ".......K..K......K..K.............",
        ".......K..K......K..K.............",
    ], map: ["K": PX.ink, "D": Color(red: 0.30, green: 0.22, blue: 0.15)])

    static func animal(named name: String) -> Sprite {
        switch name {
        case "rabbit": return rabbit
        case "deer": return deer
        case "bear": return bear
        default: return buffalo
        }
    }
}

// MARK: Party member avatar (tiny pixel portrait, colors vary by seed)

func drawAvatar(_ pix: inout Pix, x: Int, y: Int, seed: Int, alive: Bool) {
    let skins: [Color] = [
        Color(red: 0.96, green: 0.80, blue: 0.64), Color(red: 0.85, green: 0.62, blue: 0.44),
        Color(red: 0.62, green: 0.42, blue: 0.27), Color(red: 0.45, green: 0.30, blue: 0.18),
    ]
    let hairs: [Color] = [
        Color(red: 0.25, green: 0.16, blue: 0.08), Color(red: 0.55, green: 0.36, blue: 0.16),
        Color(red: 0.78, green: 0.60, blue: 0.30), Color(red: 0.40, green: 0.40, blue: 0.42),
        Color(red: 0.65, green: 0.25, blue: 0.12),
    ]
    let shirts: [Color] = [
        Color(red: 0.62, green: 0.25, blue: 0.18), Color(red: 0.22, green: 0.38, blue: 0.55),
        Color(red: 0.35, green: 0.50, blue: 0.28), Color(red: 0.72, green: 0.55, blue: 0.22),
        Color(red: 0.48, green: 0.32, blue: 0.52),
    ]
    let skin = alive ? skins[seed % skins.count] : PX.stone
    let hair = alive ? hairs[(seed + 1) % hairs.count] : PX.stoneDark
    let shirt = alive ? shirts[(seed + 2) % shirts.count] : PX.stoneDark
    // hair
    pix.r(x + 2, y, 8, 2, hair)
    pix.r(x + 1, y + 1, 1, 3, hair)
    pix.r(x + 10, y + 1, 1, 3, hair)
    // face
    pix.r(x + 2, y + 2, 8, 5, skin)
    // eyes
    if alive {
        pix.p(x + 4, y + 4, PX.ink)
        pix.p(x + 7, y + 4, PX.ink)
    } else {
        pix.p(x + 4, y + 4, PX.ink)
        pix.p(x + 7, y + 4, PX.ink)
    }
    // shoulders / shirt
    pix.r(x + 1, y + 8, 10, 4, shirt)
    pix.r(x, y + 9, 12, 3, shirt)
}
