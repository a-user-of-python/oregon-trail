import Foundation
#if canImport(Combine)
import Combine
#endif

// MARK: - Oregon Trail game model (original code; classic 1985 structure)
// All game state and rules live here. Views only read state and call methods.

// MARK: Basic types

enum Profession: String, CaseIterable, Codable {
    case banker, carpenter, farmer
    var title: String {
        switch self {
        case .banker: return "Banker from Boston"
        case .carpenter: return "Carpenter from Ohio"
        case .farmer: return "Farmer from Illinois"
        }
    }
    var money: Double {
        switch self {
        case .banker: return 1600
        case .carpenter: return 800
        case .farmer: return 400
        }
    }
    var multiplier: Int {
        switch self {
        case .banker: return 1
        case .carpenter: return 2
        case .farmer: return 3
        }
    }
}

enum Pace: String, CaseIterable, Codable {
    case steady, strenuous, grueling
    var title: String { rawValue.capitalized }
    /// base miles per day before weather / oxen modifiers
    var baseMiles: Double {
        switch self {
        case .steady: return 15
        case .strenuous: return 22
        case .grueling: return 30
        }
    }
    /// daily health wear from travel at this pace
    var healthWear: Double {
        switch self {
        case .steady: return 0.4
        case .strenuous: return 1.1
        case .grueling: return 2.2
        }
    }
}

enum Rations: String, CaseIterable, Codable {
    case filling, meager, bareBones
    var title: String {
        switch self {
        case .filling: return "Filling"
        case .meager: return "Meager"
        case .bareBones: return "Bare bones"
        }
    }
    /// lbs of food per person per day
    var lbsPerPerson: Double {
        switch self {
        case .filling: return 3
        case .meager: return 2
        case .bareBones: return 1
        }
    }
    var healthEffect: Double {
        switch self {
        case .filling: return 0.9
        case .meager: return 0.0
        case .bareBones: return -1.2
        }
    }
}

enum Weather: String, Codable {
    case warm, cool, cold, veryCold, hot, rainy, veryRainy, snowy, verySnowy, foggy
    var title: String {
        switch self {
        case .warm: return "Warm"
        case .cool: return "Cool"
        case .cold: return "Cold"
        case .veryCold: return "Very cold"
        case .hot: return "Hot"
        case .rainy: return "Rainy"
        case .veryRainy: return "Very rainy"
        case .snowy: return "Snowy"
        case .verySnowy: return "Very snowy"
        case .foggy: return "Foggy"
        }
    }
    var speedFactor: Double {
        switch self {
        case .rainy: return 0.85
        case .veryRainy, .snowy, .foggy: return 0.65
        case .verySnowy: return 0.4
        default: return 1.0
        }
    }
    var isWet: Bool { self == .rainy || self == .veryRainy }
    var isSnow: Bool { self == .snowy || self == .verySnowy }
}

enum HealthStatus: String, Codable {
    case good, fair, poor, veryPoor
    var title: String {
        switch self {
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        case .veryPoor: return "Very poor"
        }
    }
}

enum Ailment: String, Codable {
    case dysentery, cholera, typhoid, fever, measles, exhaustion
    case brokenArm, brokenLeg, snakebite, frostbite
    var title: String {
        switch self {
        case .dysentery: return "dysentery"
        case .cholera: return "cholera"
        case .typhoid: return "typhoid fever"
        case .fever: return "a fever"
        case .measles: return "measles"
        case .exhaustion: return "exhaustion"
        case .brokenArm: return "a broken arm"
        case .brokenLeg: return "a broken leg"
        case .snakebite: return "a snake bite"
        case .frostbite: return "frostbite"
        }
    }
    var severity: Double {
        switch self {
        case .cholera: return 2.6
        case .dysentery: return 1.8
        case .typhoid: return 1.7
        case .snakebite: return 1.6
        case .brokenLeg: return 1.0
        case .measles: return 0.9
        case .fever: return 0.8
        case .frostbite: return 0.8
        case .brokenArm: return 0.6
        case .exhaustion: return 0.5
        }
    }
    var recoveryDays: ClosedRange<Int> {
        switch self {
        case .cholera: return 3...7
        case .dysentery: return 4...9
        case .typhoid: return 6...12
        case .snakebite: return 3...8
        case .brokenLeg: return 14...28
        case .brokenArm: return 10...20
        case .measles: return 5...10
        case .fever: return 3...7
        case .frostbite: return 5...12
        case .exhaustion: return 2...5
        }
    }
}

struct Member: Identifiable, Codable, Equatable {
    var id: Int
    var name: String
    var alive: Bool = true
    var health: Double = 100        // 0...100 personal health
    var ailment: Ailment? = nil
    var ailmentDaysLeft: Int = 0
}

// MARK: Landmarks

enum LandmarkKind: Codable {
    case start, river, fort, sight, pass, choice, end
}

struct Landmark: Codable {
    var name: String
    var miles: Int
    var kind: LandmarkKind
    var blurb: String
    var riverName: String? = nil    // set for river crossings
    var ferryPrice: Double? = nil   // nil = no ferry offered
    var hasStore: Bool = false
}

let allLandmarks: [Landmark] = [
    Landmark(name: "Independence, Missouri", miles: 0, kind: .start,
             blurb: "Your journey begins here. Outfit your wagon wisely — there is no turning back."),
    Landmark(name: "Kansas River Crossing", miles: 102, kind: .river,
             blurb: "The Kansas River runs wide here. You must cross it to continue west.",
             riverName: "Kansas River", ferryPrice: 5.0),
    Landmark(name: "Big Blue River Crossing", miles: 185, kind: .river,
             blurb: "The Big Blue River blocks the trail. Rain can swell it quickly.",
             riverName: "Big Blue River", ferryPrice: nil),
    Landmark(name: "Fort Kearny", miles: 304, kind: .fort,
             blurb: "A small army outpost on the Platte River. You can buy supplies, rest, and hear news of the trail.",
             hasStore: true),
    Landmark(name: "Chimney Rock", miles: 554, kind: .sight,
             blurb: "A towering spire of clay and sandstone, visible for miles. Every emigrant sketches it in their journal."),
    Landmark(name: "Fort Laramie", miles: 640, kind: .fort,
             blurb: "A busy trading post at the foothills of the mountains. Prices are higher here than back east.",
             hasStore: true),
    Landmark(name: "Independence Rock", miles: 830, kind: .sight,
             blurb: "A great dome of granite beside the Sweetwater River. Emigrants carve their names into its face."),
    Landmark(name: "South Pass", miles: 932, kind: .pass,
             blurb: "A broad, gentle saddle through the Rocky Mountains. You have crossed the Continental Divide — waters now flow to the Pacific."),
    Landmark(name: "Green River Crossing", miles: 989, kind: .river,
             blurb: "The Green River runs deep and swift. A ferry works here — for a price. (The cutoff by Fort Bridger joins the trail again beyond the river.)",
             riverName: "Green River", ferryPrice: 8.0),
    Landmark(name: "Soda Springs", miles: 1133, kind: .sight,
             blurb: "Bubbling springs fizz from the ground like soda water. The water tastes of iron and sulfur."),
    Landmark(name: "Fort Hall", miles: 1190, kind: .fort,
             blurb: "A Hudson's Bay trading post on the Snake River plain. Stock up — hard country lies ahead.",
             hasStore: true),
    Landmark(name: "Snake River Crossing", miles: 1373, kind: .river,
             blurb: "The Snake is the widest, most dangerous river on the whole trail. Indians with canoes sometimes help emigrants across.",
             riverName: "Snake River", ferryPrice: 7.0),
    Landmark(name: "Fort Boise", miles: 1485, kind: .fort,
             blurb: "A small trading post near the Boise River. The Blue Mountains loom ahead, and winter comes early there.",
             hasStore: true),
    Landmark(name: "Blue Mountains", miles: 1646, kind: .pass,
             blurb: "Steep, forested ridges. Snow can fall here even in early autumn. From the far side, some wagons strike for Fort Walla Walla; others push straight on to The Dalles."),
    Landmark(name: "The Dalles", miles: 1773, kind: .sight,
             blurb: "The Columbia River churns through rock channels. The Barlow Road over Mount Hood is the last hard climb before the valley."),
    Landmark(name: "Willamette Valley, Oregon", miles: 2040, kind: .end,
             blurb: "Rich green farmland under a gentle rain. You have reached Oregon City. Your new life begins."),
]

/// Store price multiplier by trail position (classic rising fort prices).
func priceFactor(miles: Int) -> Double {
    switch miles {
    case ..<300: return 1.0
    case ..<640: return 1.25
    case ..<1190: return 1.5
    case ..<1485: return 1.75
    default: return 2.0
    }
}

// MARK: Store items

enum StoreItem: String, CaseIterable, Codable {
    case oxen, food, clothing, ammo, wheel, axle, tongue
    var title: String {
        switch self {
        case .oxen: return "Oxen (per yoke of 2)"
        case .food: return "Food (per lb)"
        case .clothing: return "Clothing (per set)"
        case .ammo: return "Ammunition (box of 20)"
        case .wheel: return "Spare wagon wheel"
        case .axle: return "Spare wagon axle"
        case .tongue: return "Spare wagon tongue"
        }
    }
    var basePrice: Double {
        switch self {
        case .oxen: return 40.0
        case .food: return 0.20
        case .clothing: return 10.0
        case .ammo: return 2.0
        case .wheel: return 10.0
        case .axle: return 10.0
        case .tongue: return 10.0
        }
    }
    var advice: String {
        switch self {
        case .oxen: return "I recommend at least 3 yoke. I sell yokes of 2 oxen for $40."
        case .food: return "Flour, bacon, coffee, sugar — about $0.20 a pound. Take at least 200 lbs per person."
        case .clothing: return "Sets of clothing run $10 each. Extra sets help in bad weather."
        case .ammo: return "A box of 20 bullets costs $2. You'll want plenty for hunting."
        case .wheel, .axle, .tongue: return "Spare parts cost $10 each. A breakdown without one can strand you."
        }
    }
}

// MARK: Game phases

enum GamePhase: String, Codable {
    case setup            // choose profession / names / month
    case store            // Matt's General Store
    case traveling        // main loop
    case river            // at a river crossing decision
    case landmark         // stopped at a landmark (fort services live here too)
    case hunting
    case event            // showing a message / death pause
    case gameOver
    case won
}

enum RiverChoice: String, CaseIterable {
    case ford, caulk, ferry, wait
    var title: String {
        switch self {
        case .ford: return "Ford the river"
        case .caulk: return "Caulk the wagon and float it across"
        case .ferry: return "Pay for the ferry"
        case .wait: return "Wait a day to see if conditions improve"
        }
    }
}

// MARK: - The game state

final class Game: ObservableObject, Codable {

    // setup
    @Published var phase: GamePhase = .setup
    @Published var profession: Profession = .banker
    @Published var startMonth: Int = 3   // 3 = March ... 7 = July

    // calendar
    @Published var year: Int = 1847
    @Published var month: Int = 3
    @Published var day: Int = 1

    // party & supplies
    @Published var members: [Member] = []
    @Published var cash: Double = 0
    @Published var oxen: Int = 0          // individual oxen
    @Published var food: Int = 0          // lbs
    @Published var clothing: Int = 0      // sets
    @Published var bullets: Int = 0       // individual bullets
    @Published var wheels: Int = 0
    @Published var axles: Int = 0
    @Published var tongues: Int = 0

    // travel state
    @Published var milesTraveled: Double = 0
    @Published var pace: Pace = .steady
    @Published var rations: Rations = .filling
    @Published var weather: Weather = .warm
    @Published var nextLandmarkIndex: Int = 1
    @Published var restDaysPlanned: Int = 0
    @Published var riverWaitedDays: Int = 0

    // event / message state
    @Published var message: String = ""
    @Published var messageIsDeath: Bool = false
    @Published var phaseAfterEvent: GamePhase = .traveling

    // hunt result
    @Published var lastHuntMeat: Int = 0

    // end state
    @Published var finalScore: Int = 0
    @Published var endTitle: String = ""
    @Published var endText: String = ""

    // weather continuity (rain raises rivers)
    @Published var recentRain: Int = 0

    // river state (stable while the party is at a crossing)
    @Published var currentRiverDepth: Double = 3.0

    init() {}

    // MARK: Codable (manual, because of @Published wrappers)
    enum CodingKeys: String, CodingKey {
        case phase, profession, startMonth, year, month, day, members, cash, oxen, food,
             clothing, bullets, wheels, axles, tongues, milesTraveled, pace, rations,
             weather, nextLandmarkIndex, restDaysPlanned, riverWaitedDays, message,
             messageIsDeath, phaseAfterEvent, lastHuntMeat, finalScore, endTitle,
             endText, recentRain, currentRiverDepth
    }
    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        phase = try c.decode(GamePhase.self, forKey: .phase)
        profession = try c.decode(Profession.self, forKey: .profession)
        startMonth = try c.decode(Int.self, forKey: .startMonth)
        year = try c.decode(Int.self, forKey: .year)
        month = try c.decode(Int.self, forKey: .month)
        day = try c.decode(Int.self, forKey: .day)
        members = try c.decode([Member].self, forKey: .members)
        cash = try c.decode(Double.self, forKey: .cash)
        oxen = try c.decode(Int.self, forKey: .oxen)
        food = try c.decode(Int.self, forKey: .food)
        clothing = try c.decode(Int.self, forKey: .clothing)
        bullets = try c.decode(Int.self, forKey: .bullets)
        wheels = try c.decode(Int.self, forKey: .wheels)
        axles = try c.decode(Int.self, forKey: .axles)
        tongues = try c.decode(Int.self, forKey: .tongues)
        milesTraveled = try c.decode(Double.self, forKey: .milesTraveled)
        pace = try c.decode(Pace.self, forKey: .pace)
        rations = try c.decode(Rations.self, forKey: .rations)
        weather = try c.decode(Weather.self, forKey: .weather)
        nextLandmarkIndex = try c.decode(Int.self, forKey: .nextLandmarkIndex)
        restDaysPlanned = try c.decode(Int.self, forKey: .restDaysPlanned)
        riverWaitedDays = try c.decode(Int.self, forKey: .riverWaitedDays)
        message = try c.decode(String.self, forKey: .message)
        messageIsDeath = try c.decode(Bool.self, forKey: .messageIsDeath)
        phaseAfterEvent = try c.decode(GamePhase.self, forKey: .phaseAfterEvent)
        lastHuntMeat = try c.decode(Int.self, forKey: .lastHuntMeat)
        finalScore = try c.decode(Int.self, forKey: .finalScore)
        endTitle = try c.decode(String.self, forKey: .endTitle)
        endText = try c.decode(String.self, forKey: .endText)
        recentRain = try c.decode(Int.self, forKey: .recentRain)
        currentRiverDepth = try c.decodeIfPresent(Double.self, forKey: .currentRiverDepth) ?? 3.0
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(phase, forKey: .phase)
        try c.encode(profession, forKey: .profession)
        try c.encode(startMonth, forKey: .startMonth)
        try c.encode(year, forKey: .year)
        try c.encode(month, forKey: .month)
        try c.encode(day, forKey: .day)
        try c.encode(members, forKey: .members)
        try c.encode(cash, forKey: .cash)
        try c.encode(oxen, forKey: .oxen)
        try c.encode(food, forKey: .food)
        try c.encode(clothing, forKey: .clothing)
        try c.encode(bullets, forKey: .bullets)
        try c.encode(wheels, forKey: .wheels)
        try c.encode(axles, forKey: .axles)
        try c.encode(tongues, forKey: .tongues)
        try c.encode(milesTraveled, forKey: .milesTraveled)
        try c.encode(pace, forKey: .pace)
        try c.encode(rations, forKey: .rations)
        try c.encode(weather, forKey: .weather)
        try c.encode(nextLandmarkIndex, forKey: .nextLandmarkIndex)
        try c.encode(restDaysPlanned, forKey: .restDaysPlanned)
        try c.encode(riverWaitedDays, forKey: .riverWaitedDays)
        try c.encode(message, forKey: .message)
        try c.encode(messageIsDeath, forKey: .messageIsDeath)
        try c.encode(phaseAfterEvent, forKey: .phaseAfterEvent)
        try c.encode(lastHuntMeat, forKey: .lastHuntMeat)
        try c.encode(finalScore, forKey: .finalScore)
        try c.encode(endTitle, forKey: .endTitle)
        try c.encode(endText, forKey: .endText)
        try c.encode(recentRain, forKey: .recentRain)
        try c.encode(currentRiverDepth, forKey: .currentRiverDepth)
    }

    // MARK: Derived values

    var aliveMembers: [Member] { members.filter { $0.alive } }
    var leader: Member? { members.first }
    var leaderAlive: Bool { members.first?.alive ?? false }

    var avgHealth: Double {
        let a = aliveMembers
        guard !a.isEmpty else { return 0 }
        return a.map { $0.health }.reduce(0, +) / Double(a.count)
    }
    var healthStatus: HealthStatus {
        switch avgHealth {
        case 70...: return .good
        case 45...: return .fair
        case 22...: return .poor
        default: return .veryPoor
        }
    }
    var nextLandmark: Landmark { allLandmarks[min(nextLandmarkIndex, allLandmarks.count - 1)] }
    var milesToNextLandmark: Int {
        max(0, Int(ceil(Double(nextLandmark.miles) - milesTraveled)))
    }
    var dateString: String {
        let names = ["January","February","March","April","May","June","July",
                     "August","September","October","November","December"]
        return "\(names[month - 1]) \(day), \(year)"
    }
    var monthName: String {
        let names = ["January","February","March","April","May","June","July",
                     "August","September","October","November","December"]
        return names[month - 1]
    }

    // MARK: Setup

    func startNewGame(profession: Profession, names: [String], month start: Int) {
        self.profession = profession
        let trimmed = names.map { $0.trimmingCharacters(in: .whitespaces) }
        var list: [Member] = []
        for i in 0..<5 {
            let n = i < trimmed.count && !trimmed[i].isEmpty ? trimmed[i] : ["Alex", "Sam", "Jo", "Ruth", "Ben"][i]
            list.append(Member(id: i, name: n))
        }
        members = list
        cash = profession.money
        oxen = 0; food = 0; clothing = 0; bullets = 0
        wheels = 0; axles = 0; tongues = 0
        startMonth = start
        month = start; day = 1; year = 1847
        milesTraveled = 0
        pace = .steady; rations = .filling; weather = .warm
        nextLandmarkIndex = 1
        restDaysPlanned = 0; riverWaitedDays = 0; recentRain = 0
        message = ""; finalScore = 0
        phase = .store
        save()
    }

    // MARK: Buying

    /// Buy at the given price factor. Returns an error message, or nil on success.
    func buy(item: StoreItem, qty: Int, factor: Double) -> String? {
        guard qty > 0 else { return nil }
        let cost = item.basePrice * factor * Double(qty)
        if cost > cash + 0.001 { return "You don't have enough money for that." }
        switch item {
        case .oxen:
            if oxen + qty * 2 > 12 { return "Your wagon can't use more than 6 yoke of oxen." }
            oxen += qty * 2
        case .food:
            if food + qty > 2000 { return "Your wagon can't hold more than 2,000 lbs of food." }
            food += qty
        case .clothing:
            clothing += qty
        case .ammo:
            bullets += qty * 20
        case .wheel:
            if wheels >= 3 { return "You already carry 3 spare wheels." }
            wheels += qty
        case .axle:
            if axles >= 3 { return "You already carry 3 spare axles." }
            axles += qty
        case .tongue:
            if tongues >= 3 { return "You already carry 3 spare tongues." }
            tongues += qty
        }
        cash -= cost
        save()
        return nil
    }

    /// Leave the store and set out. Returns a warning string if the outfit is unwise, nil if fine.
    func finishShopping() -> String? {
        if oxen == 0 {
            phase = .traveling
            save()
            return "You set out without any oxen. The wagon will not move an inch."
        }
        phase = .traveling
        save()
        return nil
    }

    // MARK: Calendar

    func daysInMonth(_ m: Int) -> Int {
        switch m {
        case 1, 3, 5, 7, 8, 10, 12: return 31
        case 4, 6, 9, 11: return 30
        default: return 28
        }
    }

    func advanceCalendar() {
        day += 1
        if day > daysInMonth(month) {
            day = 1
            month += 1
            if month > 12 { month = 1; year += 1 }
        }
    }

    // MARK: Weather

    func rollWeather() {
        let season: [Weather]
        switch month {
        case 3, 4: season = [.cool, .warm, .rainy, .rainy, .cold, .foggy, .warm]
        case 5, 6: season = [.warm, .warm, .hot, .rainy, .cool, .foggy]
        case 7, 8: season = [.hot, .hot, .warm, .rainy, .warm]
        case 9: season = [.warm, .cool, .rainy, .cold, .foggy]
        case 10: season = [.cool, .cold, .cold, .rainy, .snowy, .foggy]
        case 11: season = [.cold, .veryCold, .snowy, .snowy, .verySnowy, .cold]
        case 12: season = [.veryCold, .snowy, .verySnowy, .cold]
        default: season = [.warm]
        }
        var w = season.randomElement() ?? .warm
        // sustained rain sometimes deepens
        if w == .rainy && Double.random(in: 0..<1) < 0.25 { w = .veryRainy }
        if w == .snowy && Double.random(in: 0..<1) < 0.25 { w = .verySnowy }
        weather = w
        if w.isWet { recentRain = min(3, recentRain + 1) } else if recentRain > 0 { recentRain -= 1 }
    }

    // MARK: Main travel action

    func continueOnTrail() {
        guard phase == .traveling else { return }
        if restDaysPlanned > 0 {
            restDaysPlanned -= 1
            restOneDay()
            return
        }
        travelOneDay()
    }

    private func restOneDay() {
        advanceCalendar()
        rollWeather()
        eatAndHealth(resting: true, travelWear: 0)
        if !checkPartyWiped() { save() }
    }

    private func travelOneDay() {
        advanceCalendar()
        rollWeather()

        if oxen <= 0 {
            showEvent("Your wagon cannot move — you have no oxen. Your journey ends here on the prairie.",
                      death: false, then: .gameOver)
            endGame(title: "Stranded", text: "With no oxen to pull the wagon, the party is stranded on the trail.")
            return
        }

        // distance
        var speed = pace.baseMiles
        speed *= weather.speedFactor
        if oxen < 4 { speed *= 0.6 } else if oxen < 6 { speed *= 0.8 }
        if avgHealth < 30 { speed *= 0.85 }
        speed *= Double.random(in: 0.85...1.15)
        milesTraveled += speed

        // trail worn oxen: rare loss on hard days
        if pace == .grueling && Double.random(in: 0..<1) < 0.03 {
            oxen -= 1
            eatAndHealth(resting: false, travelWear: pace.healthWear)
            showEvent("One of your oxen has collapsed and died from the brutal pace.", death: false, then: .traveling)
            if !checkPartyWiped() { save() }
            return
        }

        eatAndHealth(resting: false, travelWear: pace.healthWear)

        // landmark reached?
        if milesTraveled >= Double(nextLandmark.miles) {
            milesTraveled = Double(nextLandmark.miles)
            arriveAtLandmark()
            save()
            return
        }

        // random events
        if Double.random(in: 0..<1) < 0.30 {
            fireRandomEvent()
        }
        if !checkPartyWiped() { save() }
    }

    /// Food consumption + health drift for everyone alive. Returns nothing; deaths handled inside.
    private func eatAndHealth(resting: Bool, travelWear: Double) {
        let eaters = aliveMembers.count
        guard eaters > 0 else { return }
        let need = Double(eaters) * rations.lbsPerPerson
        if food >= Int(ceil(need)) {
            food -= Int(ceil(need))
        } else {
            food = 0
            // starvation
            for i in members.indices where members[i].alive {
                members[i].health -= 4.5
            }
        }
        var delta = rations.healthEffect
        if resting { delta += 1.6 }
        delta -= travelWear
        switch weather {
        case .veryCold, .verySnowy:
            delta -= clothing >= eaters * 2 ? 0.6 : 1.6
        case .cold, .snowy:
            delta -= clothing >= eaters ? 0.3 : 0.9
        case .hot:
            delta -= 0.3
        default: break
        }
        if food == 0 { delta -= 1.0 }
        for i in members.indices where members[i].alive {
            members[i].health += delta * Double.random(in: 0.7...1.3)
            if let a = members[i].ailment {
                members[i].health -= a.severity
                members[i].ailmentDaysLeft -= 1
                if members[i].ailmentDaysLeft <= 0 {
                    members[i].ailment = nil
                }
            }
            members[i].health = min(100, max(0, members[i].health))
        }
        processDeaths()
    }

    // MARK: Landmarks

    var currentLandmark: Landmark {
        allLandmarks[max(0, nextLandmarkIndex - 1)]
    }

    private func arriveAtLandmark() {
        let lm = nextLandmark
        nextLandmarkIndex += 1
        riverWaitedDays = 0
        switch lm.kind {
        case .end:
            winGame()
        case .river:
            rollRiverDepth()
            phase = .river
        default:
            phase = .landmark
        }
    }

    func leaveLandmark() {
        phase = .traveling
        save()
    }

    // MARK: Rivers

    /// Base depth for the river the party is camped at, before wait adjustments.
    func rollRiverDepth() {
        let base: Double
        switch currentLandmark.riverName {
        case "Kansas River": base = 2.8
        case "Big Blue River": base = 3.0
        case "Green River": base = 5.5
        case "Snake River": base = 6.0
        default: base = 3.0
        }
        currentRiverDepth = max(1.2, base + Double(recentRain) * 0.8 + Double.random(in: -0.3...0.3))
    }

    func crossRiver(_ choice: RiverChoice) {
        let lm = currentLandmark
        let depth = currentRiverDepth
        switch choice {
        case .wait:
            riverWaitedDays += 1
            advanceCalendar()
            rollWeather()
            currentRiverDepth = max(1.2, currentRiverDepth - 0.25 + Double.random(in: -0.15...0.2))
            eatAndHealth(resting: true, travelWear: 0)
            if !checkPartyWiped() { save() }
            return
        case .ferry:
            guard let price = lm.ferryPrice else {
                // No ferry here — fall back to caulking the wagon.
                crossRiver(.caulk)
                return
            }
            if cash < price {
                showEvent("You don't have the $\(Int(price)) for the ferry.", death: false, then: .river)
                return
            }
            cash -= price
            advanceCalendar()
            eatAndHealth(resting: true, travelWear: 0)
            showEvent("The ferry carries your wagon across the \(lm.riverName ?? "river") safely. It costs $\(Int(price)).",
                      death: false, then: .traveling)
            if !checkPartyWiped() { save() }
            return
        case .ford, .caulk:
            advanceCalendar()
            let riskBase = choice == .ford ? (depth - 2.5) * 0.16 : 0.10 + Double(recentRain) * 0.03
            let roll = Double.random(in: 0..<1)
            if depth > 2.5 && choice == .ford && roll < riskBase {
                riverDisaster(deep: depth > 4.5)
            } else if choice == .caulk && roll < riskBase {
                riverDisaster(deep: false)
            } else {
                eatAndHealth(resting: false, travelWear: 0.5)
                let how = choice == .ford ? "ford" : "float"
                showEvent("You \(how) the wagon across the \(lm.riverName ?? "river") without mishap.",
                          death: false, then: .traveling)
            }
            if !checkPartyWiped() { save() }
            return
        }
    }

    private func riverDisaster(deep: Bool) {
        let roll = Double.random(in: 0..<1)
        if deep && roll < 0.25 {
            // someone drowns
            if let victim = aliveMembers.randomElement(),
               let idx = members.firstIndex(where: { $0.id == victim.id }) {
                members[idx].alive = false
                showEvent("The wagon tips in the deep current. \(victim.name) is swept away and drowns.",
                          death: true, then: leaderAliveAfter(idx: idx) ? .traveling : .gameOver)
                if !leaderAliveAfter(idx: idx) {
                    endGame(title: "The river claims its toll",
                            text: "\(victim.name) drowned crossing the river, and the journey cannot go on.")
                }
                return
            }
        }
        if roll < 0.55 && oxen > 0 {
            let lost = min(oxen, Int.random(in: 1...2))
            oxen -= lost
            showEvent("The wagon swamps in the crossing. \(lost) ox(en) drowned, but everyone made it to shore.",
                      death: false, then: .traveling)
            return
        }
        let lostFood = min(food, Int.random(in: 20...120))
        food -= lostFood
        let lostClothes = min(clothing, Int.random(in: 0...2))
        clothing -= lostClothes
        showEvent("The wagon floods as you cross. You lose \(lostFood) lbs of food and \(lostClothes) set(s) of clothing to the river.",
                  death: false, then: .traveling)
    }

    private func leaderAliveAfter(idx: Int) -> Bool {
        if idx == 0 { return false }
        return leaderAlive
    }

    // MARK: Hunting

    func goHunting() {
        guard bullets >= 1 else {
            showEvent("You have no bullets to hunt with.", death: false, then: .traveling)
            return
        }
        phase = .hunting
    }

    func returnFromHunt(meat: Int, bulletsUsed: Int) {
        bullets = max(0, bullets - bulletsUsed)
        let carried = min(meat, 200)   // the party can carry back at most ~200 lbs
        lastHuntMeat = carried
        food += carried
        advanceCalendar()
        rollWeather()
        eatAndHealth(resting: false, travelWear: 0.6)
        phase = .traveling
        if meat > 200 {
            showEvent("You shot \(meat) lbs of meat, but your party could only carry 200 lbs back to the wagon. You take \(carried) lbs.",
                      death: false, then: .traveling)
        } else if carried > 0 {
            showEvent("Your hunters return with \(carried) lbs of meat.", death: false, then: .traveling)
        } else {
            showEvent("The hunt comes back empty-handed.", death: false, then: .traveling)
        }
        if phase == .event { phaseAfterEvent = .traveling }
        if !checkPartyWiped() { save() }
    }

    // MARK: Random events

    private func showEvent(_ text: String, death: Bool, then next: GamePhase) {
        message = text
        messageIsDeath = death
        phaseAfterEvent = next
        phase = .event
    }

    func dismissEvent() {
        if phaseAfterEvent == .gameOver {
            phase = .gameOver
        } else {
            phase = phaseAfterEvent
        }
        save()
    }

    private func fireRandomEvent() {
        let roll = Double.random(in: 0..<1)
        switch roll {
        case ..<0.07: // broken part
            let part = ["wheel", "axle", "tongue"].randomElement()!
            let has: Bool
            switch part {
            case "wheel": has = wheels > 0
            case "axle": has = axles > 0
            default: has = tongues > 0
            }
            if has {
                switch part {
                case "wheel": wheels -= 1
                case "axle": axles -= 1
                default: tongues -= 1
                }
                showEvent("A wagon \(part) breaks on a rock. You replace it with a spare and roll on.",
                          death: false, then: .traveling)
            } else {
                advanceCalendar()
                showEvent("A wagon \(part) breaks, and you carry no spare. You spend a day carving a replacement from a cottonwood log.",
                          death: false, then: .traveling)
            }
        case ..<0.12: // ox wanders / injured
            if oxen > 1 && Double.random(in: 0..<1) < 0.5 {
                oxen -= 1
                showEvent("An ox wanders off in the night and is never found.", death: false, then: .traveling)
            } else {
                advanceCalendar()
                showEvent("An ox steps in a prairie-dog hole and goes lame. You lose a day resting it.",
                          death: false, then: .traveling)
            }
        case ..<0.24: // sickness strikes
            strikeSickness()
        case ..<0.30: // bad water
            foodLossEvent(text: "Your party drinks from a stagnant pool. Bad water! Several of you are sick to your stomachs.",
                          healthHit: 6)
        case ..<0.35: // wild fruit
            let gain = Int.random(in: 15...45)
            food += gain
            showEvent("You find wild berries and plums along a creek. You gather \(gain) lbs of fruit.",
                      death: false, then: .traveling)
        case ..<0.40: // abandoned wagon
            let gain = Int.random(in: 20...80)
            food += gain
            showEvent("You pass an abandoned wagon. Its owners left behind \(gain) lbs of usable food, which you take.",
                      death: false, then: .traveling)
        case ..<0.45: // thieves
            let lost = min(food, Int.random(in: 15...60))
            food -= lost
            showEvent("Thieves slip into camp at night and make off with \(lost) lbs of food.",
                      death: false, then: .traveling)
        case ..<0.50: // fire
            let lost = min(food, Int.random(in: 10...50))
            food -= lost
            clothing = max(0, clothing - 1)
            showEvent("A campfire sparks into your supplies. You lose \(lost) lbs of food and a set of clothing.",
                      death: false, then: .traveling)
        case ..<0.56: // storm / heavy weather slowdown
            advanceCalendar()
            let kind = weather.isSnow ? "A blizzard howls for a full day" : "A violent storm batters the wagon for a full day"
            showEvent("\(kind). You stay put and ride it out.", death: false, then: .traveling)
        case ..<0.62: // fog loses the trail
            advanceCalendar()
            showEvent("Thick fog rolls in. You lose the trail and a full day finding it again.",
                      death: false, then: .traveling)
        case ..<0.68: // wrong trail
            milesTraveled = max(0, milesTraveled - Double(Int.random(in: 8...20)))
            showEvent("You follow a wrong trail for miles before realizing the mistake and turning back.",
                      death: false, then: .traveling)
        case ..<0.74: // helpful indians
            let gain = Int.random(in: 20...50)
            food += gain
            showEvent("Friendly Indians trade you \(gain) lbs of dried fish and show you the best water on this stretch.",
                      death: false, then: .traveling)
        case ..<0.80: // rough trail
            advanceCalendar()
            showEvent("The trail turns to deep sand and rock. Progress is painfully slow and the oxen are spent.",
                      death: false, then: .traveling)
        case ..<0.86: // impassable trail without proper parts -> delay
            advanceCalendar()
            showEvent("A washed-out gully blocks the trail. You spend a day building a crossing of logs and stone.",
                      death: false, then: .traveling)
        case ..<0.92: // grave of strangers (flavor)
            let names = ["Mary E. Sloan", "J. W. Harper", "little Anna K.", "T. Brennan"]
            showEvent("You pass a lonely grave by the trail. The board reads: \"Here lies \(names.randomElement()!). 1847.\" Your party walks on in silence.",
                      death: false, then: .traveling)
        default: // lucky find / good grazing
            for i in members.indices where members[i].alive {
                members[i].health = min(100, members[i].health + 3)
            }
            showEvent("Good grazing and clear water. The oxen feed well and everyone feels stronger.",
                      death: false, then: .traveling)
        }
    }

    private func foodLossEvent(text: String, healthHit: Double) {
        for i in members.indices where members[i].alive {
            members[i].health -= healthHit
        }
        processDeaths()
        showEvent(text, death: false, then: .traveling)
    }

    // MARK: Sickness & death

    private func strikeSickness() {
        guard let victim = aliveMembers.randomElement(),
              let idx = members.firstIndex(where: { $0.id == victim.id }) else { return }
        var pool: [Ailment] = [.dysentery, .fever, .typhoid, .measles, .exhaustion]
        if weather.isSnow { pool += [.frostbite, .fever] }
        if weather == .hot { pool += [.cholera, .snakebite, .dysentery] }
        if pace == .grueling { pool += [.brokenArm, .brokenLeg, .exhaustion] }
        if food == 0 { pool += [.dysentery, .exhaustion] }
        let a = pool.randomElement()!
        members[idx].ailment = a
        members[idx].ailmentDaysLeft = Int.random(in: a.recoveryDays)
        members[idx].health -= 8
        showEvent("\(victim.name) has come down with \(a.title).", death: false, then: .traveling)
        processDeaths()
    }

    /// Kills anyone whose health hit zero. Shows a tombstone event for the first death found.
    private func processDeaths() {
        for i in members.indices where members[i].alive && members[i].health <= 0 {
            members[i].alive = false
            members[i].ailment = nil
            let name = members[i].name
            if i == 0 {
                showEvent("Here lies \(name)\n\n\(name), leader of this company, has died on the trail.",
                          death: true, then: .gameOver)
                endGame(title: "The journey ends",
                        text: "\(name) has died. Without its leader, the wagon company breaks up on the trail.")
            } else if aliveMembers.isEmpty {
                showEvent("Here lies \(name)\n\nThe last member of the party has died.",
                          death: true, then: .gameOver)
                endGame(title: "No one left", text: "The entire party has perished on the trail.")
            } else {
                showEvent("Here lies \(name)\n\n\(name) has died. You bury them beside the trail, mark the grave with a stone, and press on.",
                          death: true, then: .traveling)
            }
            return // one death event at a time
        }
    }

    /// Returns true if the game just ended (so callers skip saving a live state over it).
    private func checkPartyWiped() -> Bool {
        if !leaderAlive || aliveMembers.isEmpty {
            if phase != .event && phase != .gameOver {
                endGame(title: "The journey ends", text: "The wagon company has perished on the trail.")
            }
            return phase == .gameOver
        }
        return false
    }

    // MARK: End of game

    func computeScore() -> Int {
        var points = 0
        points += aliveMembers.count * 400
        if leaderAlive { points += 100 } // the leader bonus, folded into headcount below
        points += max(0, Int(cash) * 4)
        points += oxen * 20
        points += (wheels + axles + tongues) * 10
        points += clothing * 5
        points += bullets / 10
        points += food / 5
        if healthStatus == .good { points += aliveMembers.count * 100 }
        if healthStatus == .fair { points += aliveMembers.count * 50 }
        return points * profession.multiplier
    }

    private func winGame() {
        finalScore = computeScore()
        endTitle = "You have reached Oregon!"
        endText = """
        After a journey of \(Int(milesTraveled)) miles, your wagon rolls into the Willamette Valley on \(dateString).

        \(aliveMembers.count) of your party made it through. Your health is \(healthStatus.title.lowercased()).

        Final score: \(finalScore) points
        (profession points multiplier ×\(profession.multiplier))
        """
        phase = .won
        UserDefaults.standard.removeObject(forKey: "oregontrail.save")
    }

    private func endGame(title: String, text: String) {
        endTitle = title
        endText = text
        phase = .gameOver
        UserDefaults.standard.removeObject(forKey: "oregontrail.save")
    }

    // MARK: Trade at landmarks

    struct TradeOffer {
        var giveText: String
        var wantText: String
        var foodDelta: Int
        var cashDelta: Double
        var bulletsDelta: Int
        var clothingDelta: Int
    }

    /// A random trade offer at forts and landmarks (regenerated per call site via seed each visit is fine).
    func makeTradeOffer() -> TradeOffer {
        let options: [TradeOffer] = [
            TradeOffer(giveText: "50 lbs of food", wantText: "$8",
                       foodDelta: -50, cashDelta: 8, bulletsDelta: 0, clothingDelta: 0),
            TradeOffer(giveText: "$10", wantText: "40 lbs of food",
                       foodDelta: 40, cashDelta: -10, bulletsDelta: 0, clothingDelta: 0),
            TradeOffer(giveText: "1 set of clothing", wantText: "60 bullets",
                       foodDelta: 0, cashDelta: 0, bulletsDelta: 60, clothingDelta: -1),
            TradeOffer(giveText: "80 bullets", wantText: "30 lbs of food",
                       foodDelta: 30, cashDelta: 0, bulletsDelta: -80, clothingDelta: 0),
            TradeOffer(giveText: "$15", wantText: "70 lbs of food",
                       foodDelta: 70, cashDelta: -15, bulletsDelta: 0, clothingDelta: 0),
        ]
        return options.randomElement()!
    }

    func canAccept(_ offer: TradeOffer) -> Bool {
        if offer.foodDelta < 0 && food < -offer.foodDelta { return false }
        if offer.cashDelta < 0 && cash < -offer.cashDelta { return false }
        if offer.bulletsDelta < 0 && bullets < -offer.bulletsDelta { return false }
        if offer.clothingDelta < 0 && clothing < -offer.clothingDelta { return false }
        return true
    }

    func acceptTrade(_ offer: TradeOffer) {
        food += offer.foodDelta
        cash += offer.cashDelta
        bullets += offer.bulletsDelta
        clothing += offer.clothingDelta
        save()
    }

    // MARK: Autosave

    private static let saveKey = "oregontrail.save"

    func save() {
        if phase == .gameOver || phase == .won { return }
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Game.saveKey)
        }
    }

    static func loadSaved() -> Game? {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let g = try? JSONDecoder().decode(Game.self, from: data),
              g.phase != .setup else { return nil }
        return g
    }

    static func clearSave() {
        UserDefaults.standard.removeObject(forKey: saveKey)
    }
}

// MARK: - Session helpers

extension Game {
    /// Return to the setup screen for a fresh journey (startNewGame overwrites all run state).
    func backToSetup() {
        Game.clearSave()
        phase = .setup
    }

    /// Rest one day while stopped at a landmark or fort.
    func restDayAtStop() {
        advanceCalendar()
        rollWeather()
        eatAndHealth(resting: true, travelWear: 0)
        if !checkPartyWiped() { save() }
    }
}
