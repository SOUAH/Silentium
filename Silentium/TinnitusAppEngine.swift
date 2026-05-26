//
//  TinnitusAppEngine.swift
//  Tinnitus
//
//  Created by Souha Aouididi on 07/05/26.
//

import Foundation
import AVFoundation
import Combine
import HealthKit

class TinnitusAppEngine: ObservableObject {
    private var engine = AVAudioEngine()
    private var playerNode = AVAudioPlayerNode()
    private var notchFilter = AVAudioUnitEQ(numberOfBands: 1)
    private var sourceNode: AVAudioSourceNode?
    
    private var proceduralMaskingNode: AVAudioSourceNode?
    private var activeSoundType: String = ""
    
    private var currentFrequency: Float = 6800.0
    private var currentAmplitude: Float = 0.0
    private var theta: Float = 0.0
    
    private let healthStore = HKHealthStore()
    private var heartRateQuery: HKAnchoredObjectQuery?
    
    @Published var calibratedFrequency: Double = 6800.0
    @Published var isPlaying = false
    
    @Published var currentHeartRate: Int = 0
    @Published var stressLevel: String = "Stable"
    @Published var adaptiveVolumeBoost: Float = 0.0
    
    init() {
        setupAudio()
    }
    
    private func setupAudio() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Failed to configure session: \(error.localizedDescription)")
            return
        }

        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        let sampleRate = Float(format.sampleRate)
        
        sourceNode = AVAudioSourceNode { [weak self] (_, _, frameCount, audioBufferList) -> OSStatus in
            guard let self = self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let phaseIncrement = (Float.pi * 2.0 * self.currentFrequency) / Float(format.sampleRate)
            
            for frame in 0..<Int(frameCount) {
                let value = sin(self.theta) * self.currentAmplitude
                for buffer in ablPointer {
                    let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                    buf[frame] = value
                }
                self.theta += phaseIncrement
                if self.theta > Float.pi * 2.0 { self.theta -= Float.pi * 2.0 }
            }
            return noErr
        }

        // Shared Filter Coefficients & Accumulators across rendering frame cycles
        var b0: Float = 0.0, b1: Float = 0.0, b2: Float = 0.0
        var b3: Float = 0.0, b4: Float = 0.0, b5: Float = 0.0, b6: Float = 0.0
        var lastOut: Float = 0.0
        var timeElapsed: Float = 0.0
        
        var sleepBrownAccumulator: Float = 0.0
        var sleepDeltaTheta: Float = 0.0
        
        proceduralMaskingNode = AVAudioSourceNode { [weak self] (_, _, frameCount, audioBufferList) -> OSStatus in
            guard let self = self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            guard self.isPlaying else { return noErr }
            
            // Capture atomic copy of real-time bio-boost parameter
            let currentBoost = self.adaptiveVolumeBoost
            
            for frame in 0..<Int(frameCount) {
                timeElapsed += 1.0 / sampleRate
                let white = (Float(arc4random()) / Float(UInt32.max)) * 2.0 - 1.0
                var signal: Float = 0.0
                
                let soundSelection = self.activeSoundType
                
                switch soundSelection.lowercased() {
                    
                // =================================================================
                // 1. WHITE NOISE SPECTRUM MATRICES (High-Frequency Intense Profiles)
                // =================================================================
                case "white":
                    signal = white * 0.15
                    
                case "torrential downpour":
                    let dynamicRainSwell = sin(timeElapsed * 0.5) * 0.15 + 0.85
                    signal = white * 0.35 * dynamicRainSwell
                    
                case "up-close waterfall":
                    signal = white * 0.45
                    
                case "high-velocity shallow rapids":
                    let rapidRipple = sin(timeElapsed * 22.0) * 0.05 + 0.35
                    signal = white * rapidRipple
                    
                case "blizzard winds":
                    let windHowl = sin(timeElapsed * 0.3) * 0.2 + 0.4
                    signal = white * windHowl
                    
                case "hailstones on a lake":
                    signal = white * 0.20
                    if Float.random(in: 0...1) > 0.994 {
                        signal += Float.random(in: -0.35...0.35) // Sharp icy stone impact transients
                    }
                    
                case "high-pressure geyser eruption":
                    let steamSwell = sin(timeElapsed * 8.0) * 0.04 + 0.38
                    signal = white * steamSwell
                    
                case "desert sandstorm":
                    let sandSwish = cos(timeElapsed * 1.5) * 0.1 + 0.32
                    signal = white * sandSwish
                    
                case "up-close cicada chorus":
                    let chirpSync = sin(timeElapsed * 45.0) * 0.15 + 0.35
                    signal = white * chirpSync
                    
                case "crashing sea foam":
                    let foamFizz = abs(sin(timeElapsed * 1.8)) * 0.18 + 0.12
                    signal = white * foamFizz
                    
                case "roaring forest fire":
                    signal = white * 0.25
                    if Float.random(in: 0...1) > 0.996 {
                        signal += Float.random(in: 0.4...0.7) // Crackle/snap sparks injection
                    }

                // =================================================================
                // 2. PINK NOISE SPECTRUM MATRICES (Balanced, Balanced 1/f Slopes)
                // =================================================================
                case "rain", "steady canopy rain", "wind through pine needles", "a babbling brook", "swaying meadow grasses", "rustling autumn leaves", "distant ocean waves from a beach", "distant ocean waves", "ocean", "sea_waves", "a distant bird colony", "wind over sand dunes", "a soft winter snowfall", "a gentle waterfall from a quarter-mile away", "distant waterfall":
                    
                    // Voss-McCartney 1/f Pink Cascade Array
                    b0 = 0.99886 * b0 + white * 0.0555179
                    b1 = 0.99332 * b1 + white * 0.0750759
                    b2 = 0.96900 * b2 + white * 0.1538520
                    b3 = 0.86650 * b3 + white * 0.3104856
                    b4 = 0.55000 * b4 + white * 0.5329522
                    b5 = -0.7616 * b5 - white * 0.0168980
                    signal = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362
                    b6 = white * 0.115926
                    signal *= 0.12 // Attenuation scaling factor
                    
                    // Profile-specific wave transformations
                    if soundSelection.lowercased() == "ocean" || soundSelection.lowercased() == "sea_waves" || soundSelection.lowercased() == "distant ocean waves from a beach" || soundSelection.lowercased() == "distant ocean waves" {
                        let waveSwell = sin(timeElapsed * (Float.pi * 2.0 / 5.0)) * 0.4 + 0.6
                        signal *= waveSwell
                    } else if soundSelection.lowercased() == "rain" {
                        let dropChance = Float(arc4random()) / Float(UInt32.max)
                        if dropChance > 0.993 { signal += white * 0.35 }
                    } else if soundSelection.lowercased() == "a babbling brook" {
                        let brookOscillation = sin(timeElapsed * 14.0) * 0.15 + 0.85
                        signal *= brookOscillation
                    } else if soundSelection.lowercased() == "wind through pine needles" {
                        let pineSwell = sin(timeElapsed * 0.4) * 0.2 + 0.8
                        signal *= pineSwell
                    } else if soundSelection.lowercased() == "swaying meadow grasses" {
                        let grassSway = abs(cos(timeElapsed * 0.9)) * 0.25 + 0.75
                        signal *= grassSway
                    } else if soundSelection.lowercased() == "rustling autumn leaves" {
                        let leafFlutter = Float.random(in: 0.7...1.0)
                        signal *= leafFlutter
                    }

                // =================================================================
                // 3. BROWN NOISE SPECTRUM MATRICES (Deep Sub-Bass Planetary Rumbles)
                // =================================================================
                case "wind", "brown_sleep", "sub_delta", "distant rolling thunder", "heavy ocean surf", "niagara-scale waterfall from a distance", "niagara-scale waterfall", "wind in a deep rocky canyon", "subterranean geothermal mud pots", "glacial calving", "an avalanche or landslide", "earthquake tremors", "a distant hurricane wall", "deep ocean undercurrents":
                    
                    // Mathematical 1/f^2 Brown Noise Accumulator
                    signal = (lastOut + (0.02 * white)) / 1.02
                    lastOut = signal
                    signal *= 3.5
                    
                    // Specialized processing overrides
                    if soundSelection.lowercased() == "brown_sleep" {
                        sleepBrownAccumulator = (0.992 * sleepBrownAccumulator) + (0.015 * white)
                        signal = sleepBrownAccumulator * 4.0
                    } else if soundSelection.lowercased() == "sub_delta" {
                        sleepBrownAccumulator = (0.992 * sleepBrownAccumulator) + (0.015 * white)
                        let lfoFrequency: Float = 0.12
                        let phaseInc = (Float.pi * 2.0 * lfoFrequency) / sampleRate
                        let biologicalSwell = sin(sleepDeltaTheta) * 0.325 + 0.675
                        signal = sleepBrownAccumulator * 3.5 * biologicalSwell
                        sleepDeltaTheta += phaseInc
                        if sleepDeltaTheta > Float.pi * 2.0 { sleepDeltaTheta -= Float.pi * 2.0 }
                    } else if soundSelection.lowercased() == "wind" {
                        let gusting = sin(timeElapsed * 0.4) * 0.3 + 0.7
                        signal *= gusting
                    } else if soundSelection.lowercased() == "distant rolling thunder" {
                        if Float.random(in: 0...1) > 0.9994 { b5 = 1.3 } // Strike point dynamic step load
                        b5 *= 0.9992 // Smooth exponential decay envelope
                        signal += b5 * Float.random(in: 0.25...0.5)
                    } else if soundSelection.lowercased() == "heavy ocean surf" {
                        let heavyWaveSwell = sin(timeElapsed * 0.6) * 0.45 + 0.55
                        signal *= heavyWaveSwell
                    } else if soundSelection.lowercased() == "subterranean geothermal mud pots" {
                        let bubbleMod = sin(timeElapsed * 10.0) * 0.3 + 0.7
                        signal *= bubbleMod
                    }

                default:
                    signal = 0.0
                }
                
                // Live Biometric Modulation Hook: Applies HealthKit stress scaling factor instantly to output buffers
                let finalRegulatedSignal = signal * (1.0 + currentBoost)
                
                for buffer in ablPointer {
                    let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                    buf[frame] = finalRegulatedSignal
                }
            }
            return noErr
        }

        engine.attach(playerNode)
        engine.attach(notchFilter)
        if let sourceNode = sourceNode { engine.attach(sourceNode) }
        if let proceduralMaskingNode = proceduralMaskingNode { engine.attach(proceduralMaskingNode) }
        
        updateNotchFilter(frequency: Float(calibratedFrequency))
        
        engine.connect(playerNode, to: notchFilter, format: format)
        engine.connect(notchFilter, to: engine.mainMixerNode, format: format)
        
        if let sourceNode = sourceNode {
            engine.connect(sourceNode, to: engine.mainMixerNode, format: format)
        }
        if let proceduralMaskingNode = proceduralMaskingNode {
            engine.connect(proceduralMaskingNode, to: engine.mainMixerNode, format: format)
        }
        
        try? engine.start()
    }
    
    private func updateNotchFilter(frequency: Float) {
        let filterBand = notchFilter.bands[0]
        filterBand.filterType = .parametric
        filterBand.frequency = frequency
        filterBand.bandwidth = 0.5
        filterBand.gain = -96.0
        filterBand.bypass = false
    }
}

// HealthKit Integration
extension TinnitusAppEngine {
    
    func requestHealthKitPermission(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            let error = NSError(domain: "com.Silentium.HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit storage missing or restricted on this hardware profile."])
            completion(false, error)
            return
        }
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { completion(false, nil); return }
        healthStore.requestAuthorization(toShare: nil, read: [heartRateType]) { success, error in
            DispatchQueue.main.async { completion(success, error) }
        }
    }
    
    func startHealthKitMonitoring() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        stopHealthKitMonitoring()
        
        let predicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictStartDate)
        heartRateQuery = HKAnchoredObjectQuery(type: heartRateType, predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] (_, data, _, _, _) in
            self?.parseMetrics(data)
        }
        heartRateQuery?.updateHandler = { [weak self] (_, data, _, _, _) in
            self?.parseMetrics(data)
        }
        if let query = heartRateQuery { healthStore.execute(query) }
    }
    
    func stopHealthKitMonitoring() {
        if let activeQuery = heartRateQuery {
            healthStore.stop(activeQuery)
            heartRateQuery = nil
        }
        DispatchQueue.main.async {
            self.currentHeartRate = 0
            self.stressLevel = "Stable"
            self.adaptiveVolumeBoost = 0.0
        }
    }
    
    private func parseMetrics(_ samples: [HKSample]?) {
        guard let quantitySamples = samples as? [HKQuantitySample], let dominantSample = quantitySamples.last else { return }
        let unit = HKUnit.count().unitDivided(by: HKUnit.minute())
        let bpm = dominantSample.quantity.doubleValue(for: unit)
        
        DispatchQueue.main.async {
            self.currentHeartRate = Int(bpm)
            if bpm >= 100 {
                self.stressLevel = "Spike"
                self.adaptiveVolumeBoost = 0.15
            } else if bpm >= 85 {
                self.stressLevel = "Elevated"
                self.adaptiveVolumeBoost = 0.05
            } else {
                self.stressLevel = "Stable"
                self.adaptiveVolumeBoost = 0.0
            }
        }
    }
}

// Core Controls
extension TinnitusAppEngine {
    func startProceduralSound(type: String) { if !engine.isRunning { try? engine.start() }; self.activeSoundType = type; self.isPlaying = true }
    func stopMaskingSound() { self.isPlaying = false; self.activeSoundType = "" }
    func setFinalCalibratedFrequency(_ freq: Double) { DispatchQueue.main.async { self.calibratedFrequency = freq; self.updateNotchFilter(frequency: Float(freq)) } }
    func startTestTone(frequency: Double, volume: Double) { if !engine.isRunning { try? engine.start() }; self.currentFrequency = Float(frequency); self.currentAmplitude = Float(volume / 100.0); self.isPlaying = true }
    func updateTestTone(frequency: Double, volume: Double) { self.currentFrequency = Float(frequency); self.currentAmplitude = Float(volume / 100.0) }
    func stopTestTone() { self.currentAmplitude = 0.0 }
}
