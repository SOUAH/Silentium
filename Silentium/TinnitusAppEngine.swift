import Foundation
import UIKit
import AudioKit
import SoundpipeAudioKit
import AVFoundation
import Combine
import HealthKit

// MARK: - Looped File Player
// Wraps AVAudioPlayer so any bundled audio file can loop seamlessly.
private class LoopedFilePlayer {
    private var player: AVAudioPlayer?
    private var fadeTimer: Timer?
    private(set) var currentFilename: String?

    func load(filename: String, ext: String = "mp3") -> Bool {
        let candidates = [ext, "mp3", "wav", "m4a", "caf", "aiff"]
        for candidate in candidates {
            if let url = Bundle.main.url(forResource: filename, withExtension: candidate) {
                do {
                    player = try AVAudioPlayer(contentsOf: url)
                    player?.numberOfLoops = -1   // infinite loop
                    player?.prepareToPlay()
                    self.currentFilename = filename
                    print("✅  LoopedFilePlayer loaded: '\(filename).\(candidate)'")
                    return true
                } catch {
                    print("⚠️  LoopedFilePlayer AVAudioPlayer error for '\(filename).\(candidate)': \(error)")
                    return false
                }
            }
        }
        print("❌  LoopedFilePlayer: '\(filename)' not found in app bundle with any known extension.")
        print("    → Make sure the file is added to the Silentium target in Xcode (Target Membership checkbox).")
        return false
    }

    func play(volume: Float = 0.85, fadeInDuration: TimeInterval = 0, completion: (() -> Void)? = nil) {
        player?.volume = 0.0
        player?.play()
        if fadeInDuration > 0 {
            fade(to: volume, duration: fadeInDuration) {
                completion?()
            }
        } else {
            player?.volume = volume
            completion?()
        }
    }

    func stop(fadeOutDuration: TimeInterval = 0, completion: (() -> Void)? = nil) {
        if fadeOutDuration > 0 && isPlaying {
            fade(to: 0.0, duration: fadeOutDuration) { [weak self] in
                self?.player?.stop()
                self?.player?.currentTime = 0
                self?.fadeTimer?.invalidate()
                completion?()
            }
        } else {
            player?.stop()
            player?.currentTime = 0
            fadeTimer?.invalidate()
            completion?()
        }
    }

    func setVolume(_ v: Float, duration: TimeInterval = 0.0) {
        if duration > 0 {
            fade(to: v, duration: duration)
        } else {
            player?.volume = v
        }
    }

    func fade(to targetVolume: Float, duration: TimeInterval, completion: (() -> Void)? = nil) {
        fadeTimer?.invalidate()
        guard let player = player else {
            completion?()
            return
        }

        let startVolume = player.volume
        let startTime = Date()

        fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                completion?()
                return
            }

            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed >= duration {
                player.volume = targetVolume
                timer.invalidate()
                completion?()
                return
            }

            let progress = Float(elapsed / duration)
            player.volume = startVolume + (targetVolume - startVolume) * progress
        }
    }

    var isPlaying: Bool { player?.isPlaying ?? false }
}

class TinnitusAppEngine: ObservableObject {

    // AudioKit nodes (procedural DSP)
    let engine = AudioEngine()
    private var whiteNoiseSource: WhiteNoise?
    private var pinkNoiseSource: PinkNoise?
    private var brownNoiseSource: BrownianNoise?
    private var diagnosticOscillator: Oscillator?
    private var dynamicFilter: LowPassFilter?
    private var autoWahShifter: AutoWah?
    private var surgicalNotchFilter: EqualizerFilter?
    private var masterDSPGain: Mixer? // FIXED: Use Mixer for master volume / gain control

    // File-based looped players (for the new mixkit assets)
    private var filePlayers: [String: LoopedFilePlayer] = [:]

    private let fileBackedSounds: [String: (file: String, volume: Float)] = [
        "Birds & Jungle Morning":   (file: "mixkit-birds-chirping-in-the-jungle-2433",   volume: 0.80),
        "Dry Autumn Leaves":        (file: "mixkit-dry-leaves-sound-2428",                volume: 0.75),
        "Heavy Rain Storm":         (file: "mixkit-heavy-rain-2403",                      volume: 0.85),
        "Liquid Bubble Flow":       (file: "mixkit-liquid-bubble-3000",                   volume: 0.70),
        "Strong Wild Wind":         (file: "mixkit-strong-wild-wind-in-a-storm-2407",     volume: 0.80),
        "Thunder & Light Rain":     (file: "mixkit-thunder-rumble-and-light-rain-2401",   volume: 0.85),
    ]

    // Published State
    @Published var calibratedFrequency: Double = 4000.0
    @Published var activeSoundscapeName: String = "None"
    @Published var isPlaying: Bool = false
    @Published var isPlayerPresentedFullScreen: Bool = false
    @Published var currentSelectedSoundMetadata: (title: String, subtitle: String, key: String)? = nil

    // Biometric
    @Published var currentHeartRate: Int = 72
    @Published var stressLevel: String = "Stable"
    @Published var isBiometricTrackingEnabled: Bool = false

    // Room Compensation
    @Published var isRoomCompensationActive: Bool = false

    private var naturalMovementTimer: Timer?
    private var lfoPhase: Double = 0.0

    // Fade Management
    private var currentFadeTask: Task<Void, Never>? = nil
    private let fadeDuration: TimeInterval = 0.8

    // Sleep Fade
    private var sleepFadeTimer: Timer?
    private var fadeDurationSeconds: Double = 600.0
    private var secondsRemainingInFade: Double = 600.0
    private var initialFadeFilterCutoff: Float = 20_000.0

    // HealthKit
    private let healthStore = HKHealthStore()
    private var heartRateQuery: HKObserverQuery?

    // Haptic generators
    private let impactHeavy   = UIImpactFeedbackGenerator(style: .heavy)
    private let impactMedium  = UIImpactFeedbackGenerator(style: .medium)
    private let impactLight   = UIImpactFeedbackGenerator(style: .light)
    private let notifFeedback = UINotificationFeedbackGenerator()

    init() {
        impactHeavy.prepare()
        impactMedium.prepare()
        impactLight.prepare()
        notifFeedback.prepare()

        setupAudioKitPipeline()

        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers, .allowBluetooth]
            )
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
            print("AudioKit Engine Active.")
        } catch {
            print("Audio engine startup failed: \(error)")
        }

        for (name, meta) in fileBackedSounds {
            let p = LoopedFilePlayer()
            _ = p.load(filename: meta.file)
            filePlayers[name] = p
        }
    }

    // AudioKit Pipeline
    private func setupAudioKitPipeline() {
        let whiteNode = WhiteNoise()
        let pinkNode  = PinkNoise()
        let brownNode = BrownianNoise()
        let oscNode   = Oscillator()
        oscNode.amplitude = 0.0

        whiteNoiseSource = whiteNode
        pinkNoiseSource  = pinkNode
        brownNoiseSource = brownNode
        diagnosticOscillator = oscNode

        let mixerHub = Mixer(whiteNode, pinkNode, brownNode, oscNode)

        let wahNode = AutoWah(mixerHub)
        wahNode.mix = 0.0
        autoWahShifter = wahNode

        let filterNode = LowPassFilter(wahNode)
        filterNode.cutoffFrequency = 20_000.0
        filterNode.resonance = 0.0
        dynamicFilter = filterNode

        let notchNode = EqualizerFilter(filterNode)
        notchNode.centerFrequency = AUValue(calibratedFrequency)
        notchNode.bandwidth = AUValue(calibratedFrequency * 0.1)
        notchNode.gain = 0.001
        surgicalNotchFilter = notchNode

        // FIXED: Master Mixer controls overall DSP volume
        let masterMixer = Mixer(notchNode)
        masterMixer.volume = 0.0
        masterDSPGain = masterMixer

        engine.output = masterMixer

        whiteNode.stop()
        pinkNode.stop()
        brownNode.stop()
        oscNode.stop()
    }

    // Recommendation Engine
    func getRecommendationReason(for soundName: String) -> String? {
        let freq = calibratedFrequency
        let category = categoryForSound(soundName)
        let recommendedCategory: String
        if freq >= 8000.0 {
            recommendedCategory = "White"
        } else if freq >= 3000.0 {
            recommendedCategory = "Pink"
        } else {
            recommendedCategory = "Brown"
        }
        guard category == recommendedCategory else { return nil }

        switch recommendedCategory {
        case "White":
            return "Recommended: Your high-pitched tinnitus (\(Int(freq)) Hz) is best masked by White Noise's high-frequency saturation."
        case "Pink":
            return "Recommended: Your mid-range tinnitus (\(Int(freq)) Hz) matches Pink Noise's balanced power spectrum."
        case "Brown":
            return "Recommended: Your low-frequency tinnitus (\(Int(freq)) Hz) pairs best with the deep Brownian rumble."
        default:
            return nil
        }
    }

    private func categoryForSound(_ name: String) -> String {
        switch name {
        case "Birds & Jungle Morning", "Dry Autumn Leaves", "Liquid Bubble Flow":
            return "Pink"
        case "Heavy Rain Storm", "Thunder & Light Rain":
            return "White"
        case "Torrential Downpour", "Misty Waterfall Veil":
            return "White"
        case "Rhythmic Ocean Swells", "Wind Through Pine Needles", "Gentle Meadow Stream":
            return "Pink"
        case "Distant Rolling Thunder", "Subterranean Canyon Rift", "Interstellar Cabin Hum":
            return "Brown"
        default:
            return "Pink"
        }
    }

    func startSound(type: String) {
        currentFadeTask?.cancel()
        currentFadeTask = Task {
            await fadeOutCurrentSound()

            await MainActor.run {
                self.activeSoundscapeName = type
                self.isPlaying = true
                self.updateSoundMetadata(for: type)
            }

            if !engine.avEngine.isRunning { try? engine.start() }
            updateNotchFrequency()

            if let meta = fileBackedSounds[type] {
                let p = filePlayers[type] ?? {
                    let newP = LoopedFilePlayer()
                    _ = newP.load(filename: meta.file)
                    filePlayers[type] = newP
                    return newP
                }()
                await withCheckedContinuation { continuation in
                    p.play(volume: meta.volume, fadeInDuration: fadeDuration) {
                        continuation.resume()
                    }
                }
            } else {
                startDSPSound(type: type)
                guard let booster = masterDSPGain else { return }
                let targetGain: AUValue = 1.0
                booster.volume = 0.0
                for i in 0..<Int(fadeDuration / 0.02) {
                    let progress = Float(i) / Float(fadeDuration / 0.02)
                    booster.volume = targetGain * progress
                    try? await Task.sleep(nanoseconds: 20_000_000)
                }
                booster.volume = targetGain
            }
            await MainActor.run {
                impactLight.impactOccurred()
            }
        }
    }

    private func startDSPSound(type: String) {
        switch type {
        case "Torrential Downpour", "white_sleep":
            whiteNoiseSource?.start(); whiteNoiseSource?.amplitude = 0.35
            pinkNoiseSource?.start();  pinkNoiseSource?.amplitude  = 0.15
            startNaturalMovementLFO(speed: 1.2) { [weak self] phase in
                self?.dynamicFilter?.cutoffFrequency = Float(sin(phase) * 800.0 + 2500.0)
            }

        case "Misty Waterfall Veil":
            whiteNoiseSource?.start(); whiteNoiseSource?.amplitude = 0.35
            pinkNoiseSource?.start();  pinkNoiseSource?.amplitude  = 0.15
            dynamicFilter?.cutoffFrequency = 5500.0

        case "Rhythmic Ocean Swells":
            pinkNoiseSource?.start(); pinkNoiseSource?.amplitude = 0.50
            startNaturalMovementLFO(speed: 0.18) { [weak self] phase in
                self?.dynamicFilter?.cutoffFrequency = Float(sin(phase) * 600.0 + 1500.0)
                self?.pinkNoiseSource?.amplitude     = Float(sin(phase) * 0.20 + 0.40)
            }

        case "Wind Through Pine Needles":
            pinkNoiseSource?.start(); pinkNoiseSource?.amplitude = 0.50
            startNaturalMovementLFO(speed: 0.25) { [weak self] phase in
                self?.dynamicFilter?.cutoffFrequency = Float(sin(phase) * 400.0 + 1200.0)
            }

        case "Gentle Meadow Stream":
            pinkNoiseSource?.start();  pinkNoiseSource?.amplitude  = 0.40
            whiteNoiseSource?.start(); whiteNoiseSource?.amplitude = 0.08
            dynamicFilter?.cutoffFrequency = 2900.0

        case "Distant Rolling Thunder", "brown_sleep":
            brownNoiseSource?.start(); brownNoiseSource?.amplitude = 0.65
            dynamicFilter?.cutoffFrequency = 180.0
            startNaturalMovementLFO(speed: 0.15) { [weak self] phase in
                self?.brownNoiseSource?.amplitude = Float(abs(cos(phase * 1.5)) * 0.25 + 0.4)
            }

        case "Subterranean Canyon Rift", "sub_delta":
            brownNoiseSource?.start(); brownNoiseSource?.amplitude = 0.55
            dynamicFilter?.cutoffFrequency = 350.0

        case "Interstellar Cabin Hum":
            brownNoiseSource?.start(); brownNoiseSource?.amplitude = 0.70
            startNaturalMovementLFO(speed: 0.04) { [weak self] phase in
                self?.dynamicFilter?.cutoffFrequency = Float(sin(phase) * 12.0 + 95.0)
            }

        default:
            break
        }
    }

    // MARK: - Stop
    func stopMaskingSound() {
        currentFadeTask?.cancel()
        currentFadeTask = Task {
            await fadeOutCurrentSound()
            await MainActor.run {
                self.isPlaying = false
                impactMedium.impactOccurred()
            }
        }
    }

    func forceQuitEngineTrack() {
        currentFadeTask?.cancel()
        currentFadeTask = Task {
            await fadeOutCurrentSound()
            await MainActor.run {
                self.activeSoundscapeName = "None"
                self.isPlaying = false
                impactMedium.impactOccurred()
            }
        }
    }

    private func _stopAllSourcesImmediately() {
        naturalMovementTimer?.invalidate()
        naturalMovementTimer = nil
        whiteNoiseSource?.stop()
        pinkNoiseSource?.stop()
        brownNoiseSource?.stop()
        diagnosticOscillator?.stop()
        for p in filePlayers.values { p.stop() }
    }

    private func fadeOutCurrentSound() async {
        guard isPlaying else { return }

        naturalMovementTimer?.invalidate()
        naturalMovementTimer = nil

        let soundName = activeSoundscapeName

        if let meta = fileBackedSounds[soundName], let p = filePlayers[soundName] {
            await withCheckedContinuation { continuation in
                p.stop(fadeOutDuration: fadeDuration) {
                    continuation.resume()
                }
            }
        } else {
            guard let booster = masterDSPGain else { return }
            let initialGain = booster.volume
            for i in 0..<Int(fadeDuration / 0.02) {
                let progress = 1.0 - Float(i) / Float(fadeDuration / 0.02)
                booster.volume = initialGain * progress
                try? await Task.sleep(nanoseconds: 20_000_000)
            }
            booster.volume = 0.0
        }
        _stopAllSourcesImmediately()
    }

    // MARK: - Room Compensation
    func setRoomCompensationActive(_ isActive: Bool) {
        isRoomCompensationActive = isActive
        if isActive {
            dynamicFilter?.resonance = 0.3
            dynamicFilter?.cutoffFrequency = min(dynamicFilter?.cutoffFrequency ?? 20_000, 18_000)
            notifFeedback.notificationOccurred(.success)
            print("Room compensation ON – filter resonance shaped for reflective room.")
        } else {
            dynamicFilter?.resonance = 0.0
            notifFeedback.notificationOccurred(.warning)
            print("Room compensation OFF – flat filter restored.")
        }
    }

    // MARK: - Haptic Helpers
    func hapticSelection() { UISelectionFeedbackGenerator().selectionChanged() }
    func hapticImpact(_ s: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: s).impactOccurred()
    }
    func hapticNotification(_ t: UINotificationFeedbackGenerator.FeedbackType) {
        notifFeedback.notificationOccurred(t)
    }

    // MARK: - Notch + LFO
    func updateNotchFrequency() {
        surgicalNotchFilter?.centerFrequency = Float(calibratedFrequency)
        surgicalNotchFilter?.bandwidth       = Float(calibratedFrequency * 0.1)
    }

    private func startNaturalMovementLFO(speed: Double, callback: @escaping (Double) -> Void) {
        lfoPhase = 0.0
        naturalMovementTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.lfoPhase += speed * 0.05
            if self.lfoPhase > .pi * 2 { self.lfoPhase = 0.0 }
            callback(self.lfoPhase)
        }
    }

    // MARK: - Diagnostic Tone
    func startTestTone(frequency: Double, volume: Double) {
        stopMaskingSound()
        if !engine.avEngine.isRunning { try? engine.start() }
        diagnosticOscillator?.frequency = AUValue(frequency)
        diagnosticOscillator?.amplitude = AUValue(volume / 400.0)
        diagnosticOscillator?.start()
    }

    func updateTestTone(frequency: Double, volume: Double) {
        diagnosticOscillator?.frequency = AUValue(frequency)
        diagnosticOscillator?.amplitude = AUValue(volume / 400.0)
    }

    func stopTestTone() {
        diagnosticOscillator?.stop()
        diagnosticOscillator?.amplitude = 0.0
    }

    func setFinalCalibratedFrequency(_ freq: Double) {
        calibratedFrequency = freq
        updateNotchFrequency()
    }

    // MARK: - Sleep Fade
    func startIntelligentSleepFade(durationMinutes: Int) {
        sleepFadeTimer?.invalidate()
        fadeDurationSeconds     = Double(durationMinutes * 60)
        secondsRemainingInFade  = fadeDurationSeconds
        initialFadeFilterCutoff = dynamicFilter?.cutoffFrequency ?? 20_000.0

        if fileBackedSounds[activeSoundscapeName] == nil {
            masterDSPGain?.volume = 1.0
        }
        if let meta = fileBackedSounds[activeSoundscapeName],
           let p = filePlayers[activeSoundscapeName],
           p.isPlaying {
            p.setVolume(meta.volume, duration: 0.0)
        }

        sleepFadeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.secondsRemainingInFade > 0 {
                self.secondsRemainingInFade -= 1
                let ratio = Float(self.secondsRemainingInFade / self.fadeDurationSeconds)

                self.dynamicFilter?.cutoffFrequency = 150.0 + (self.initialFadeFilterCutoff - 150.0) * ratio

                if self.fileBackedSounds[self.activeSoundscapeName] == nil {
                    self.masterDSPGain?.volume = ratio
                } else {
                    if let p = self.filePlayers[self.activeSoundscapeName], p.isPlaying {
                        p.setVolume(self.fileBackedSounds[self.activeSoundscapeName]!.volume * ratio, duration: 1.0)
                    }
                }
            } else {
                self.forceQuitEngineTrack()
                self.stopSleepFadeEngine()
            }
        }
    }

    func stopSleepFadeEngine() {
        sleepFadeTimer?.invalidate()
        sleepFadeTimer = nil
        dynamicFilter?.cutoffFrequency = 20_000.0
        masterDSPGain?.volume = 1.0
        if let meta = fileBackedSounds[activeSoundscapeName],
           let p = filePlayers[activeSoundscapeName],
           p.isPlaying {
            p.setVolume(meta.volume, duration: 0.0)
        }
    }

    // Metadata helper
    private func updateSoundMetadata(for type: String) {
        let sub: String
        switch categoryForSound(type) {
        case "White": sub = "White Masking Soundscape"
        case "Pink":  sub = "Pink Masking Soundscape"
        default:      sub = "Brown Masking Soundscape"
        }
        currentSelectedSoundMetadata = (title: type, subtitle: sub, key: type)
    }

    // HealthKit
    func requestHealthKitPermission(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, NSError(domain: "Silentium", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device."]))
            return
        }
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        healthStore.requestAuthorization(toShare: [], read: [heartRateType]) { success, error in
            DispatchQueue.main.async {
                self.isBiometricTrackingEnabled = success
                if !success {
                    print("HealthKit auth failed: \(error?.localizedDescription ?? "unknown")")
                }
                completion(success, error)
            }
        }
    }

    func startHealthKitMonitoring() {
        guard HKHealthStore.isHealthDataAvailable(), isBiometricTrackingEnabled else { return }

        if let q = heartRateQuery { healthStore.stop(q); heartRateQuery = nil }

        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let query = HKObserverQuery(sampleType: heartRateType, predicate: nil) { [weak self] _, done, error in
            guard let self = self else { done(); return }
            if let error = error { print("HR observer error: \(error)"); done(); return }
            self.fetchLatestHeartRate { ok, rate, _ in
                if ok, let rate = rate {
                    DispatchQueue.main.async {
                        self.currentHeartRate = Int(rate)
                        self.updateStressLevel(for: Int(rate))
                    }
                }
                done()
            }
        }
        healthStore.execute(query)
        heartRateQuery = query

        fetchLatestHeartRate { ok, rate, _ in
            if ok, let rate = rate {
                DispatchQueue.main.async {
                    self.currentHeartRate = Int(rate)
                    self.updateStressLevel(for: Int(rate))
                }
            }
        }
    }

    func stopHealthKitMonitoring() {
        if let q = heartRateQuery { healthStore.stop(q); heartRateQuery = nil }
        DispatchQueue.main.async {
            self.currentHeartRate = 0
            self.stressLevel = "Calibrating..."
        }
    }

    private func fetchLatestHeartRate(completion: @escaping (Bool, Double?, Error?) -> Void) {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let now = Date()
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let pred = HKQuery.predicateForSamples(withStart: weekAgo, end: now, options: .strictEndDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let q = HKSampleQuery(sampleType: heartRateType, predicate: pred, limit: 1, sortDescriptors: [sort]) { _, samples, error in
            if let error = error { completion(false, nil, error); return }
            guard let sample = samples?.first as? HKQuantitySample else { completion(true, nil, nil); return }
            let unit = HKUnit.count().unitDivided(by: .minute())
            completion(true, sample.quantity.doubleValue(for: unit), nil)
        }
        healthStore.execute(q)
    }

    private func updateStressLevel(for heartRate: Int) {
        let level: String
        if heartRate > 100      { level = "Spike" }
        else if heartRate > 80  { level = "Elevated" }
        else                    { level = "Stable" }

        guard level != stressLevel else { return }
        stressLevel = level

        switch level {
        case "Spike":
            surgicalNotchFilter?.gain = 0.05
            if isPlaying { pinkNoiseSource?.amplitude = 0.6 }
            impactHeavy.impactOccurred()
        case "Elevated":
            surgicalNotchFilter?.gain = 0.005
            if isPlaying { pinkNoiseSource?.amplitude = 0.45 }
            impactMedium.impactOccurred()
        default:
            surgicalNotchFilter?.gain = 0.001
            if isPlaying { pinkNoiseSource?.amplitude = 0.35 }
        }
    }
}
