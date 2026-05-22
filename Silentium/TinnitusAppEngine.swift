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

        var b0: Float = 0.0, b1: Float = 0.0, b2: Float = 0.0
        var b3: Float = 0.0, b4: Float = 0.0, b5: Float = 0.0, b6: Float = 0.0
        var lastOut: Float = 0.0
        var timeElapsed: Float = 0.0
        
        // Mathematical accumulators tracking localized procedural sleep states
        var sleepBrownAccumulator: Float = 0.0
        var sleepDeltaTheta: Float = 0.0
        
        proceduralMaskingNode = AVAudioSourceNode { [weak self] (_, _, frameCount, audioBufferList) -> OSStatus in
            guard let self = self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            guard self.isPlaying else { return noErr }
            
            for frame in 0..<Int(frameCount) {
                timeElapsed += 1.0 / sampleRate
                let white = (Float(arc4random()) / Float(UInt32.max)) * 2.0 - 1.0
                var signal: Float = 0.0
                
                switch self.activeSoundType.lowercased() {
                case "brown_sleep":
                    // Leaky integration loop filter producing raw brown spectrum density (-6dB/octave)
                    sleepBrownAccumulator = (0.992 * sleepBrownAccumulator) + (0.015 * white)
                    signal = sleepBrownAccumulator * 4.0
                    
                case "sub_delta":
                    // Deep brown baseline filtered rumble
                    sleepBrownAccumulator = (0.992 * sleepBrownAccumulator) + (0.015 * white)
                    
                    // Ultra-slow Low-frequency oscillation mapping (0.12 Hz = ~8.33s breathing period cycles)
                    let lfoFrequency: Float = 0.12
                    let phaseIncrement = (Float.pi * 2.0 * lfoFrequency) / sampleRate
                    
                    // Creates a smooth floating sinusoidal respiration envelope amplitude curve
                    let biologicalSwell = sin(sleepDeltaTheta) * 0.325 + 0.675
                    signal = sleepBrownAccumulator * 3.5 * biologicalSwell
                    
                    // Advance internal phase angle pointer safely
                    sleepDeltaTheta += phaseIncrement
                    if sleepDeltaTheta > Float.pi * 2.0 { sleepDeltaTheta -= Float.pi * 2.0 }
                    
                case "wind":
                    signal = (lastOut + (0.02 * white)) / 1.02
                    lastOut = signal
                    signal *= 3.5
                    let gusting = sin(timeElapsed * 0.4) * 0.3 + 0.7
                    signal *= gusting
                    
                case "ocean", "sea_waves":
                    b0 = 0.99886 * b0 + white * 0.0555179
                    b1 = 0.99332 * b1 + white * 0.0750759
                    b2 = 0.96900 * b2 + white * 0.1538520
                    b3 = 0.86650 * b3 + white * 0.3104856
                    b4 = 0.55000 * b4 + white * 0.5329522
                    b5 = -0.7616 * b5 - white * 0.0168980
                    signal = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362
                    b6 = white * 0.115926
                    signal *= 0.11
                    let waveSwell = sin(timeElapsed * (Float.pi * 2.0 / 5.0)) * 0.4 + 0.6
                    signal *= waveSwell
                    
                case "rain":
                    b0 = 0.99886 * b0 + white * 0.0555179
                    b1 = 0.99332 * b1 + white * 0.0750759
                    b2 = 0.96900 * b2 + white * 0.1538520
                    b3 = 0.86650 * b3 + white * 0.3104856
                    b4 = 0.55000 * b4 + white * 0.5329522
                    b5 = -0.7616 * b5 - white * 0.0168980
                    signal = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362
                    b6 = white * 0.115926
                    signal *= 0.12
                    let dropChance = Float(arc4random()) / Float(UInt32.max)
                    if dropChance > 0.993 { signal += white * 0.35 }
                    
                case "white":
                    signal = white * 0.15
                default:
                    signal = 0.0
                }
                
                for buffer in ablPointer {
                    let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                    buf[frame] = signal
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

// MARK: - HealthKit Integration
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
