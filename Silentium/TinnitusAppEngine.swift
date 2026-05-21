//
//  TinnitusAppEngine.swift
//  Tinnitus
//
//  Created by Souha Aouididi on 07/05/26.
//

import Foundation
import AVFoundation
import Combine
import HealthKit // Import HealthKit

class TinnitusAppEngine: ObservableObject {
    private var engine = AVAudioEngine()
    private var playerNode = AVAudioPlayerNode()
    private var notchFilter = AVAudioUnitEQ(numberOfBands: 1)
    private var sourceNode: AVAudioSourceNode?
    
    // Dedicated native node to compute procedural ambient noise on the fly
    private var proceduralMaskingNode: AVAudioSourceNode?
    private var activeSoundType: String = ""
    
    // Properties to track tone state
    private var currentFrequency: Float = 6800.0
    private var currentAmplitude: Float = 0.0 // Start at 0 to avoid pop
    private var theta: Float = 0.0
    
    @Published var calibratedFrequency: Double = 6800.0
    @Published var isPlaying = false
    
    // --- Biometric States for Adaptive Relief ---
    @Published var currentHeartRate: Int = 0 { // Initialize to 0 or a placeholder
        didSet {
            // Update stress level whenever heart rate changes
            updateStressLevel()
        }
    }
    @Published var stressLevel: String = "Unknown" // Stable, Elevated, Spike, Unknown
    @Published var adaptiveVolumeBoost: Float = 0.0 // Extra masking gain during stress spikes
    
    // HealthKit properties
    private let healthStore = HKHealthStore()
    private let heartRateQuantityType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    private var heartRateQuery: HKObserverQuery?
    private var heartRateAnchor: HKQueryAnchor?
    
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
        
        // --- Pitch Test Tone Node Initialization ---
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

        // --- Procedural Masking Synthesis (Pure Math - No External Packages) ---
        var b0: Float = 0.0, b1: Float = 0.0, b2: Float = 0.0
        var b3: Float = 0.0, b4: Float = 0.0, b5: Float = 0.0, b6: Float = 0.0 // Pink noise filters
        var lastOut: Float = 0.0 // Brown noise filter
        var timeElapsed: Float = 0.0 // LFO tracking for natural wind/wave cycles
        
        proceduralMaskingNode = AVAudioSourceNode { [weak self] (_, _, frameCount, audioBufferList) -> OSStatus in
            guard let self = self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            
            guard self.isPlaying else { return noErr }
            
            for frame in 0..<Int(frameCount) {
                timeElapsed += 1.0 / sampleRate
                
                // Base uniform white noise generation (-1.0 to 1.0)
                let white = Float.random(in: -1.0...1.0) // Fixed: Replaced arc4random()
                var signal: Float = 0.0
                
                switch self.activeSoundType.lowercased() {
                case "wind":
                    // Brown Noise filter matrix attenuation
                    signal = (lastOut + (0.02 * white)) / 1.02
                    lastOut = signal
                    signal *= 3.5
                    
                    // LFO Modulation simulating ambient wind gusts
                    let gusting = sin(timeElapsed * 0.4) * 0.3 + 0.7
                    signal *= gusting
                    
                case "ocean", "sea_waves":
                    // Pink Noise Voss-McCartney Algorithm (-3dB/octave balance)
                    b0 = 0.99886 * b0 + white * 0.0555179
                    b1 = 0.99332 * b1 + white * 0.0750759
                    b2 = 0.96900 * b2 + white * 0.1538520
                    b3 = 0.86650 * b3 + white * 0.3104856
                    b4 = 0.55000 * b4 + white * 0.5329522
                    b5 = -0.7616 * b5 - white * 0.0168980
                    signal = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362
                    b6 = white * 0.115926
                    signal *= 0.11
                    
                    // Tidal wave volume cycles (5-second swells)
                    let waveSwell = sin(timeElapsed * (Float.pi * 2.0 / 5.0)) * 0.4 + 0.6
                    signal *= waveSwell
                    
                case "rain":
                    // Balanced Pink Noise foundation
                    b0 = 0.99886 * b0 + white * 0.0555179
                    b1 = 0.99332 * b1 + white * 0.0750759
                    b2 = 0.96900 * b2 + white * 0.1538520
                    b3 = 0.86650 * b3 + white * 0.3104856
                    b4 = 0.55000 * b4 + white * 0.5329522
                    b5 = -0.7616 * b5 - white * 0.0168980
                    signal = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362
                    b6 = white * 0.115926
                    signal *= 0.12
                    
                    // Transients simulating random raindrop surface impacts
                    let dropChance = Float.random(in: 0.0...1.0) // Fixed: Replaced arc4random()
                    if dropChance > 0.993 {
                        signal += white * 0.35
                    }
                    
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

        // Attach Nodes
        engine.attach(playerNode)
        engine.attach(notchFilter)
        if let sourceNode = sourceNode { engine.attach(sourceNode) }
        if let proceduralMaskingNode = proceduralMaskingNode { engine.attach(proceduralMaskingNode) }
        
        // Configure Notch Filter
        updateNotchFilter(frequency: Float(calibratedFrequency))
        
        // Connect Nodes
        engine.connect(playerNode, to: notchFilter, format: format)
        engine.connect(notchFilter, to: engine.mainMixerNode, format: format)
        
        if let sourceNode = sourceNode {
            engine.connect(sourceNode, to: engine.mainMixerNode, format: format)
        }
        
        if let proceduralMaskingNode = proceduralMaskingNode {
            engine.connect(proceduralMaskingNode, to: engine.mainMixerNode, format: format)
        }
        
        do {
            try engine.start()
        } catch {
            print("Engine failed to start: \(error.localizedDescription)")
        }
    }
    
    // Helper to keep filter and variable in sync
    private func updateNotchFilter(frequency: Float) {
        let filterBand = notchFilter.bands[0]
        filterBand.filterType = .parametric
        filterBand.frequency = frequency
        filterBand.bandwidth = 0.5
        filterBand.gain = -96.0 // This creates the "Notch" (silence at that freq)
        filterBand.bypass = false
    }

    // Deinitializer to stop HealthKit observer queries
    deinit {
        if let query = heartRateQuery {
            healthStore.stop(query)
        }
    }
}

extension TinnitusAppEngine {
    
    func startProceduralSound(type: String) {
        if !engine.isRunning { try? engine.start() }
        self.activeSoundType = type
        self.isPlaying = true
        print("Audio Engine: Synthesizing real-time environment landscape: \(type)")
    }
    
    func stopMaskingSound() {
        self.isPlaying = false
        self.activeSoundType = ""
        print("Audio Engine: Masking synthesizer suspended.")
    }
    
    // --- Function to save the real data from the test ---
    func setFinalCalibratedFrequency(_ freq: Double) {
        DispatchQueue.main.async {
            self.calibratedFrequency = freq
            self.updateNotchFilter(frequency: Float(freq))
            print("Engine: Calibrated frequency saved at \(freq)Hz")
        }
    }
    
    func startTestTone(frequency: Double, volume: Double) {
        if !engine.isRunning { try? engine.start() }
        self.currentFrequency = Float(frequency)
        self.currentAmplitude = Float(volume / 100.0)
        self.isPlaying = true
    }
    
    func updateTestTone(frequency: Double, volume: Double) {
        self.currentFrequency = Float(frequency)
        self.currentAmplitude = Float(volume / 100.0)
    }
    
    func stopTestTone() {
        self.currentAmplitude = 0.0
    }
    
    // MARK: - HealthKit Integration
    
    func startHealthKitMonitoring() {
        requestHeartRateAuthorization { [weak self] success in
            guard let self = self else { return }
            if success {
                print("HealthKit: Authorization granted. Starting heart rate queries.")
                self.queryMostRecentHeartRate()
                self.setupHeartRateObserverQuery()
            } else {
                print("HealthKit: Authorization denied for heart rate.")
                // Potentially update UI to reflect no data
                DispatchQueue.main.async {
                    self.stressLevel = "No Data"
                }
            }
        }
    }
    
    private func requestHeartRateAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit: Health data not available on this device.")
            completion(false)
            return
        }
        
        let typesToRead: Set<HKObjectType> = [heartRateQuantityType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if let error = error {
                print("HealthKit: Error requesting authorization: \(error.localizedDescription)")
            }
            completion(success)
        }
    }
    
    private func queryMostRecentHeartRate() {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: heartRateQuantityType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) {
            [weak self] (query, samples, error) in
            
            if let error = error {
                print("HealthKit: Error querying heart rate samples: \(error.localizedDescription)")
                return
            }
            
            guard let mostRecentSample = samples?.first as? HKQuantitySample else {
                print("HealthKit: No heart rate samples found.")
                DispatchQueue.main.async {
                    self?.currentHeartRate = 0
                    self?.stressLevel = "No Data"
                }
                return
            }
            
            self?.processHeartRateSample(mostRecentSample)
        }
        healthStore.execute(query)
    }
    
    private func setupHeartRateObserverQuery() {
        heartRateQuery = HKObserverQuery(sampleType: heartRateQuantityType, predicate: nil) { [weak self] (query, completionHandler, error) in
            
            if let error = error {
                print("HealthKit: Error observing heart rate changes: \(error.localizedDescription)")
                completionHandler()
                return
            }
            
            self?.fetchHeartRateUpdates(completionHandler: completionHandler)
        }
        
        if let query = heartRateQuery {
            healthStore.execute(query)
            print("HealthKit: Heart rate observer query started.")
        }
    }
    
    private func fetchHeartRateUpdates(completionHandler: @escaping () -> Void) {
        var anchorPredicate: NSPredicate? = nil
        if let anchor = heartRateAnchor {
            anchorPredicate = HKQuery.predicateForSamples(from: anchor)
        }
        
        let anchoredQuery = HKAnchoredObjectQuery(
            type: heartRateQuantityType,
            predicate: anchorPredicate,
            anchor: heartRateAnchor,
            limit: HKObjectQuery.noLimit) { // Fixed: Replaced HKObjectQueryNoLimit
                [weak self] (query, samples, deletedObjects, newAnchor, error) in
                
                if let error = error {
                    print("HealthKit: Error fetching heart rate updates: \(error.localizedDescription)")
                    completionHandler()
                    return
                }
                
                self?.heartRateAnchor = newAnchor
                
                if let newSamples = samples as? [HKQuantitySample], !newSamples.isEmpty {
                    self?.processHeartRateSamples(newSamples)
                } else {
                    print("HealthKit: No new heart rate samples.")
                }
                completionHandler()
            }
        healthStore.execute(anchoredQuery)
    }
    
    private func processHeartRateSamples(_ samples: [HKQuantitySample]) {
        // Sort by end date to get the most recent one if multiple samples are received
        guard let latestSample = samples.sorted(by: { $0.endDate > $1.endDate }).first else { return }
        processHeartRateSample(latestSample)
    }
    
    private func processHeartRateSample(_ sample: HKQuantitySample) {
        let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
        let heartRate = Int(sample.quantity.doubleValue(for: heartRateUnit))
        
        DispatchQueue.main.async { [weak self] in
            print("HealthKit: Received heart rate: \(heartRate) BPM")
            self?.currentHeartRate = heartRate
            // stressLevel is updated by the didSet of currentHeartRate
        }
    }
    
    private func updateStressLevel() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.currentHeartRate == 0 {
                self.stressLevel = "No Data" // Or "Calibrating"
            } else if self.currentHeartRate <= 85 {
                self.stressLevel = "Stable"
                self.adaptiveVolumeBoost = 0.0 // Reset boost
            } else if self.currentHeartRate > 85 && self.currentHeartRate <= 100 {
                self.stressLevel = "Elevated"
                self.adaptiveVolumeBoost = 0.1 // Small boost
            } else { // currentHeartRate > 100
                self.stressLevel = "Spike"
                self.adaptiveVolumeBoost = 0.3 // Significant boost
            }
            print("HealthKit: Stress level updated to: \(self.stressLevel) (HR: \(self.currentHeartRate))")
        }
    }
}
