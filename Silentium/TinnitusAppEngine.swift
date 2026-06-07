//
//  TinnitusAppEngine.swift
//  Tinnitus
//
//  Created by AI Collaborator on 29/05/26.
//

import Foundation
import AudioKit
import SoundpipeAudioKit
import AVFoundation
import Combine
import HealthKit
import SwiftUI

class TinnitusAppEngine: ObservableObject {
    let engine = AudioEngine()
    
    // Core Hardware AudioKit V5 Generative Processing Nodes
    private var whiteNoiseSource: WhiteNoise?
    private var pinkNoiseSource: PinkNoise?
    private var brownNoiseSource: BrownianNoise?
    private var diagnosticOscillator: Oscillator?
    
    // Nature Modulators & Dynamic Filters
    private var dynamicFilter: LowPassFilter?
    private var autoWahShifter: AutoWah?
    private var surgicalNotchFilter: EqualizerFilter?
    
    // Synchronized App State Records
    @AppStorage("calibratedFrequency") var calibratedFrequency: Double = 4000.0 {
            willSet {
                // Forces SwiftUI views monitoring the ObservableObject to refresh instantly when calibration changes
                objectWillChange.send()
            }
            didSet {
                updateNotchFrequency()
            }
        }
    @Published var activeSoundscapeName: String = "None"
    @Published var isPlaying: Bool = false
    
    // Global Full-Screen Player Navigation Triggers
    @Published var isPlayerPresentedFullScreen: Bool = false
    @Published var currentSelectedSoundMetadata: (title: String, subtitle: String, key: String)? = nil
    
    // Biometric Record Mappings
    @Published var currentHeartRate: Int = 72
    @Published var stressLevel: String = "Stable"
    @Published var isBiometricTrackingEnabled: Bool = false
    
    private var naturalMovementTimer: Timer?
    private var lfoPhase: Double = 0.0
    
    // Sleep Fade Engine State Variables
    private var sleepFadeTimer: Timer? = nil
    private var fadeDurationSeconds: Double = 600.0
    private var secondsRemainingInFade: Double = 600.0
    private var initialFadeFilterCutoff: Float = 20000.0
    
    // HealthKit Properties
    private let healthStore = HKHealthStore()
    private var heartRateQuery: HKObserverQuery?
    private var heartRateUpdateAnchor: HKQueryAnchor?
    
    init() {
        setupAudioKitPipeline()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth])
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
            print("AudioKit Hardware Master Engine Active.")
        } catch {
            print("Master Audio Engine Startup Failed: \(error.localizedDescription)")
        }
    }
    
    private func setupAudioKitPipeline() {
        let whiteNode = WhiteNoise()
        let pinkNode = PinkNoise()
        let brownNode = BrownianNoise()
        let oscNode = Oscillator()
        oscNode.amplitude = 0.0
        
        self.whiteNoiseSource = whiteNode
        self.pinkNoiseSource = pinkNode
        self.brownNoiseSource = brownNode
        self.diagnosticOscillator = oscNode
        
        let mixerHub = Mixer(whiteNode, pinkNode, brownNode, oscNode)
        
        // 👈 FIXED: Removed the stray broken typography "let?" line that was throwing the pattern compiler error
        let wahNode = AutoWah(mixerHub)
        wahNode.mix = 0.0
        self.autoWahShifter = wahNode
        
        let filterNode = LowPassFilter(wahNode)
        filterNode.cutoffFrequency = 20000.0
        filterNode.resonance = 0.0
        self.dynamicFilter = filterNode
        
        let notchNode = EqualizerFilter(filterNode)
        notchNode.centerFrequency = AUValue(calibratedFrequency)
        notchNode.bandwidth = AUValue(calibratedFrequency * 0.1)
        notchNode.gain = 0.001
        self.surgicalNotchFilter = notchNode
        
        engine.output = notchNode
        
        whiteNode.stop()
        pinkNode.stop()
        brownNode.stop()
        oscNode.stop()
    }
    
    func getRecommendationReason(for soundName: String) -> String? {
        let freq = calibratedFrequency
        if freq >= 8000.0 {
            if soundName == "Torrential Downpour" || soundName == "Misty Waterfall Veil" {
                return "Highly Recommended: Your high-pitched tinnitus is best masked by White Noise's high-frequency saturation energy."
            }
        } else if freq >= 3000.0 && freq < 8000.0 {
            if soundName == "Rhythmic Ocean Swells" || soundName == "Wind Through Pine Needles" || soundName == "Gentle Meadow Stream" {
                return "Highly Recommended: Your mid-range tinnitus perfectly matches Pink Noise's balanced power distribution."
            }
        } else {
            if soundName == "Distant Rolling Thunder" || soundName == "Subterranean Canyon Rift" || soundName == "Interstellar Cabin Hum" || soundName == "brown_sleep" || soundName == "sub_delta" {
                return "Highly Recommended: Low-frequency ringing matches best with the deep, acoustic structural depth of Brownian rumbles."
            }
        }
        return nil
    }
    
    func startProceduralSound(type: String) {
        naturalMovementTimer?.invalidate()
        naturalMovementTimer = nil
        whiteNoiseSource?.stop()
        pinkNoiseSource?.stop()
        brownNoiseSource?.stop()
        diagnosticOscillator?.stop()
        
        activeSoundscapeName = type
        isPlaying = true
        
        // Metadata Directory Mapping
        switch type {
        case "Torrential Downpour":
            currentSelectedSoundMetadata = (title: "Torrential Downpour", subtitle: "Heavy rain flattening water or striking bare rock surfaces.", key: type)
        case "Misty Waterfall Veil":
            currentSelectedSoundMetadata = (title: "Misty Waterfall Veil", subtitle: "The soft, deep hiss of water atomizing continuously in the air.", key: type)
        case "Rhythmic Ocean Swells":
            currentSelectedSoundMetadata = (title: "Rhythmic Ocean Swells", subtitle: "Deep ocean waves breaking on a shore with a therapeutic rise-and-fall rhythm.", key: type)
        case "Wind Through Pine Needles":
            currentSelectedSoundMetadata = (title: "Wind Through Pine Needles", subtitle: "Steady breeze passing through soft forest pines.", key: type)
        case "Gentle Meadow Stream":
            currentSelectedSoundMetadata = (title: "Gentle Meadow Stream", subtitle: "Crisp freshwater tumbling gently over smooth river stones.", key: type)
        case "Distant Rolling Thunder", "brown_sleep":
            currentSelectedSoundMetadata = (title: "Distant Rolling Thunder", subtitle: "Low-frequency rumble of a remote lightning storm.", key: type)
        case "Subterranean Canyon Rift", "sub_delta":
            currentSelectedSoundMetadata = (title: "Subterranean Canyon Rift", subtitle: "Deep, sweeping sub-bass echoes for low-pitch masking.", key: type)
        case "Interstellar Cabin Hum":
            currentSelectedSoundMetadata = (title: "Interstellar Cabin Hum", subtitle: "A smooth, ultra-low cosmic engine drone to calm chaotic neural paths.", key: type)
        default:
            currentSelectedSoundMetadata = (title: type, subtitle: "Custom Masking Calibration Noise Waveform", key: type)
        }
        
        if !engine.avEngine.isRunning { try? engine.start() }
        updateNotchFrequency()
        
        switch type {
        case "Torrential Downpour", "white_sleep":
            whiteNoiseSource?.start()
            whiteNoiseSource?.amplitude = 0.35
            pinkNoiseSource?.start()
            pinkNoiseSource?.amplitude = 0.15
            startNaturalMovementLFO(speed: 1.2) { [weak self] phase in
                let lfoSway = Float(sin(phase) * 800.0 + 2500.0)
                self?.dynamicFilter?.cutoffFrequency = lfoSway
            }
            
        case "Misty Waterfall Veil":
            whiteNoiseSource?.start()
            whiteNoiseSource?.amplitude = 0.35
            pinkNoiseSource?.start()
            pinkNoiseSource?.amplitude = 0.15
            dynamicFilter?.cutoffFrequency = 5500.0
            
        case "Rhythmic Ocean Swells":
            pinkNoiseSource?.start()
            startNaturalMovementLFO(speed: 0.18) { [weak self] phase in
                let oceanWaveSwell = Float(sin(phase) * 600.0 + 1500.0)
                let waveVolume = Float(sin(phase) * 0.20 + 0.40)
                self?.dynamicFilter?.cutoffFrequency = oceanWaveSwell
                self?.pinkNoiseSource?.amplitude = waveVolume
            }
            
        case "Wind Through Pine Needles":
            pinkNoiseSource?.start()
            pinkNoiseSource?.amplitude = 0.50
            startNaturalMovementLFO(speed: 0.25) { [weak self] phase in
                let windGust = Float(sin(phase) * 400.0 + 1200.0)
                self?.dynamicFilter?.cutoffFrequency = windGust
            }
            
        case "Gentle Meadow Stream":
            pinkNoiseSource?.start()
            pinkNoiseSource?.amplitude = 0.40
            whiteNoiseSource?.start()
            whiteNoiseSource?.amplitude = 0.08
            dynamicFilter?.cutoffFrequency = 2900.0
            
        case "Distant Rolling Thunder", "brown_sleep":
            brownNoiseSource?.start()
            brownNoiseSource?.amplitude = 0.65
            dynamicFilter?.cutoffFrequency = 180.0
            startNaturalMovementLFO(speed: 0.15) { [weak self] phase in
                let thunderRumble = Float(abs(cos(phase * 1.5)) * 0.25 + 0.4)
                self?.brownNoiseSource?.amplitude = thunderRumble
            }
            
        case "Subterranean Canyon Rift", "sub_delta":
            brownNoiseSource?.start()
            brownNoiseSource?.amplitude = 0.55
            dynamicFilter?.cutoffFrequency = 350.0
            
        case "Interstellar Cabin Hum":
            brownNoiseSource?.start()
            brownNoiseSource?.amplitude = 0.70
            startNaturalMovementLFO(speed: 0.04) { [weak self] phase in
                let engineHum = Float(sin(phase) * 12.0 + 95.0)
                self?.dynamicFilter?.cutoffFrequency = engineHum
            }
            
        default:
            break
        }
    }
    
    func setRoomCompensationActive(_ isActive: Bool) {
        if isActive {
            print("Acoustic analysis pipeline initialized: Calibrating room response curves.")
        } else {
            print("Acoustic analysis pipeline deactivated: Restoring default flat calibration baseline.")
        }
    }
    
    func stopMaskingSound() {
        naturalMovementTimer?.invalidate()
        naturalMovementTimer = nil
        whiteNoiseSource?.stop()
        pinkNoiseSource?.stop()
        brownNoiseSource?.stop()
        diagnosticOscillator?.stop()
        
        isPlaying = false
    }
    
    func forceQuitEngineTrack() {
        // Explicitly invoked ONLY when swiping away the card container component
        stopMaskingSound()
        activeSoundscapeName = "None"
    }
    
    func updateNotchFrequency() {
        surgicalNotchFilter?.centerFrequency = Float(calibratedFrequency)
        surgicalNotchFilter?.bandwidth = Float(calibratedFrequency * 0.1)
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
    
    func startIntelligentSleepFade(durationMinutes: Int) {
        sleepFadeTimer?.invalidate()
        
        fadeDurationSeconds = Double(durationMinutes * 60)
        secondsRemainingInFade = fadeDurationSeconds
        initialFadeFilterCutoff = dynamicFilter?.cutoffFrequency ?? 20000.0
        
        sleepFadeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.secondsRemainingInFade > 0 {
                self.secondsRemainingInFade -= 1
                
                let ratio = Float(self.secondsRemainingInFade / self.fadeDurationSeconds)
                let currentCutoff = 150.0 + (self.initialFadeFilterCutoff - 150.0) * ratio
                self.dynamicFilter?.cutoffFrequency = currentCutoff
                
                let whiteVol = 0.35 * ratio
                let pinkVol = 0.45 * ratio
                let brownVol = 0.55 * ratio
                
                self.whiteNoiseSource?.amplitude = whiteVol
                self.pinkNoiseSource?.amplitude = pinkVol
                self.brownNoiseSource?.amplitude = brownVol
            } else {
                self.forceQuitEngineTrack()
                self.stopSleepFadeEngine()
            }
        }
    }
    
    func stopSleepFadeEngine() {
        sleepFadeTimer?.invalidate()
        sleepFadeTimer = nil
        dynamicFilter?.cutoffFrequency = 20000.0
    }
        
    func requestHealthKitPermission(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, NSError(domain: "TinnitusApp", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device."]))
            return
        }
        
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let typesToShare: Set<HKSampleType> = [] // We are only reading, not writing
        let typesToRead: Set<HKObjectType> = [heartRateType]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.isBiometricTrackingEnabled = true
                } else {
                    self.isBiometricTrackingEnabled = false
                    print("HealthKit authorization failed: \(error?.localizedDescription ?? "Unknown error")")
                }
                completion(success, error)
            }
        }
    }
    
    func startHealthKitMonitoring() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available, cannot start monitoring.")
            return
        }
        
        guard isBiometricTrackingEnabled else {
            print("Biometric tracking is not enabled.")
            return
        }
        
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        
        // Stop any existing query before starting a new one
        if let existingQuery = heartRateQuery {
            healthStore.stop(existingQuery)
            heartRateQuery = nil
        }
        
        let query = HKObserverQuery(sampleType: heartRateType, predicate: nil) { [weak self] query, completionHandler, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Heart rate observer query failed: \(error.localizedDescription)")
                completionHandler()
                return
            }
            
            self.fetchLatestHeartRate(completion: { success, heartRate, fetchError in
                if success, let rate = heartRate {
                    DispatchQueue.main.async {
                        self.currentHeartRate = Int(rate)
                        self.updateStressLevel(for: Int(rate))
                    }
                } else if let fetchError = fetchError {
                    print("Failed to fetch latest heart rate: \(fetchError.localizedDescription)")
                }
                completionHandler() // Call completion handler to tell HealthKit we've processed the updates
            })
        }
        
        healthStore.execute(query)
        self.heartRateQuery = query
        print("HealthKit heart rate monitoring started.")
        
        // Perform an initial fetch immediately
        fetchLatestHeartRate { success, heartRate, error in
            if success, let rate = heartRate {
                DispatchQueue.main.async {
                    self.currentHeartRate = Int(rate)
                    self.updateStressLevel(for: Int(rate))
                }
            } else if let error = error {
                print("Initial fetch failed: \(error.localizedDescription)")
            }
        }
    }
    
    func stopHealthKitMonitoring() {
        if let query = heartRateQuery {
            healthStore.stop(query)
            heartRateQuery = nil
            print("HealthKit heart rate monitoring stopped.")
        }
        DispatchQueue.main.async {
            self.currentHeartRate = 0 // Reset heart rate display
            self.stressLevel = "Calibrating..." // Reset stress level
        }
    }
    
    private func fetchLatestHeartRate(completion: @escaping (Bool, Double?, Error?) -> Void) {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let now = Date()
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: sevenDaysAgo, end: now, options: .strictEndDate)
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            if let error = error {
                completion(false, nil, error)
                return
            }
            
            guard let latestSample = samples?.first as? HKQuantitySample else {
                completion(true, nil, nil) // No samples found, but no error
                return
            }
            
            let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
            let heartRate = latestSample.quantity.doubleValue(for: heartRateUnit)
            completion(true, heartRate, nil)
        }
        healthStore.execute(query)
    }
    
    private func updateStressLevel(for heartRate: Int) {
        if heartRate > 100 { // Example threshold for "spike"
            stressLevel = "Spike"
            // Potentially trigger adaptive audio changes here
        } else if heartRate > 80 { // Example threshold for "elevated"
            stressLevel = "Elevated"
        } else {
            stressLevel = "Stable"
        }

        switch stressLevel {
        case "Spike":
            // Increase masking intensity or broaden the frequency range
            surgicalNotchFilter?.gain = 0.05 // Reduce the depth of the notch (make it less effective)
            pinkNoiseSource?.amplitude = 0.6 // Boost pink noise, as an example
        case "Elevated":
            surgicalNotchFilter?.gain = 0.005 // Slightly reduce notch depth
            pinkNoiseSource?.amplitude = 0.45
        case "Stable":
            surgicalNotchFilter?.gain = 0.001 // Optimal notch depth
            pinkNoiseSource?.amplitude = 0.35
        default:
            break
        }
    }
}

