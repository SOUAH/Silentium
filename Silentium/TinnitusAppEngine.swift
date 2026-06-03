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
    @Published var calibratedFrequency: Double = 4000.0
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
    
    init() {
        setupAudioKitPipeline()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth])
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
            print("🔊 AudioKit Hardware Master Engine Active.")
        } catch {
            print("❌ Master Audio Engine Startup Failed: \(error.localizedDescription)")
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
            if soundName == "Torrential Downpour" || soundName == "Steam Vent Meditation" {
                return "Highly Recommended: Your high-pitched tinnitus ($>=8\text{ kHz}$) is best masked by White Noise's high-frequency saturation energy."
            }
        } else if freq >= 3000.0 && freq < 8000.0 {
            if soundName == "Wind Through Pine Needles" || soundName == "Steady Canopy Rain" {
                return "Highly Recommended: Your mid-range tinnitus ($3-8\text{ kHz}$) perfectly matches Pink Noise's balanced power distribution."
            }
        } else {
            if soundName == "Distant Rolling Thunder" || soundName == "Subterranean Canyon Rift" || soundName == "brown_sleep" || soundName == "sub_delta" {
                return "Highly Recommended: Low-frequency ringing ($<3\text{ kHz}$) matches best with the deep, acoustic structural depth of Brownian rumbles."
            }
        }
        return nil
    }
    
    func startProceduralSound(type: String) {
        stopMaskingSound()
        activeSoundscapeName = type
        isPlaying = true
        
        switch type {
        case "Torrential Downpour":
            currentSelectedSoundMetadata = (title: "Torrential Downpour", subtitle: "Heavy rain flattening water or striking bare rock surfaces.", key: type)
        case "Steam Vent Meditation":
            currentSelectedSoundMetadata = (title: "Steam Vent Meditation", subtitle: "Warm high-pressure steam hiss for high-frequency relief.", key: type)
        case "Wind Through Pine Needles":
            currentSelectedSoundMetadata = (title: "Wind Through Pine Needles", subtitle: "Steady breeze passing through soft forest pines.", key: type)
        case "Steady Canopy Rain":
            currentSelectedSoundMetadata = (title: "Steady Canopy Rain", subtitle: "Moderate rain filtering through thick protective leaves.", key: type)
        case "Distant Rolling Thunder", "brown_sleep":
            currentSelectedSoundMetadata = (title: "Distant Rolling Thunder", subtitle: "Low-frequency rumble of a remote lightning storm.", key: type)
        case "Subterranean Canyon Rift", "sub_delta":
            currentSelectedSoundMetadata = (title: "Subterranean Canyon Rift", subtitle: "Deep, sweeping sub-bass echoes for low-pitch masking.", key: type)
        default:
            currentSelectedSoundMetadata = (title: type, subtitle: "Custom Masking Calibration Noise Waveform", key: type)
        }
        
        isPlayerPresentedFullScreen = true
        
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
                self?.autoWahShifter?.mix = 10.0
            }
            
        case "Steam Vent Meditation":
            whiteNoiseSource?.start()
            whiteNoiseSource?.amplitude = 0.40
            dynamicFilter?.cutoffFrequency = 6000.0
            
        case "Wind Through Pine Needles":
            pinkNoiseSource?.start()
            pinkNoiseSource?.amplitude = 0.50
            startNaturalMovementLFO(speed: 0.25) { [weak self] phase in
                let windGust = Float(sin(phase) * 400.0 + 1200.0)
                self?.dynamicFilter?.cutoffFrequency = windGust
                self?.autoWahShifter?.mix = 20.0
                self?.autoWahShifter?.wah = Float(abs(sin(phase)) * 0.4)
            }
            
        case "Steady Canopy Rain":
            pinkNoiseSource?.start()
            pinkNoiseSource?.amplitude = 0.45
            dynamicFilter?.cutoffFrequency = 3500.0
            startNaturalMovementLFO(speed: 0.8) { [weak self] phase in
                let volumeSway = Float(abs(sin(phase)) * 0.15 + 0.3)
                self?.pinkNoiseSource?.amplitude = volumeSway
            }
            
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
            startNaturalMovementLFO(speed: 0.08) { [weak self] phase in
                self?.autoWahShifter?.mix = 45.0
                self?.autoWahShifter?.wah = Float(abs(sin(phase)) * 0.3)
            }
            
        default:
            break
        }
    }
    
    func stopMaskingSound() {
        naturalMovementTimer?.invalidate()
        naturalMovementTimer = nil
        whiteNoiseSource?.stop()
        pinkNoiseSource?.stop()
        brownNoiseSource?.stop()
        diagnosticOscillator?.stop()
        activeSoundscapeName = "None"
        isPlaying = false
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
    
    func requestHealthKitPermission(completion: @escaping (Bool, Error?) -> Void) {
        completion(true, nil)
    }
    
    func startHealthKitMonitoring() {
        isBiometricTrackingEnabled = true
    }
    
    func stopHealthKitMonitoring() {
        isBiometricTrackingEnabled = false
    }
}
