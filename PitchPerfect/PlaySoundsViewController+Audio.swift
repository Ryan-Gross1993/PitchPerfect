//
//  PlaySoundsViewController+Audio.swift
//  PitchPerfect
//
//  Created by Ryan Gross on 4/3/20.
//  Copyright © 2020 Ryan Gross. All rights reserved.
//

import UIKit
import AVFoundation

extension PlaySoundsViewController: AVAudioPlayerDelegate {
    enum ButtonType: Int { case slow = 0, fast, highPitch, lowPitch, reverb, echo }
    enum PlayingState { case playing, notPlaying }
    
    struct Alerts {
        static let DismissAlert = "Dismiss"
        static let RecordingDisabledTitle = "Recording Disabled"
        static let RecordingDisabledMessage = "You've disabled this app from recording your microphone. Check Settings."
        static let RecordingFailedTitle = "Recording Failed"
        static let RecordingFailedMessage = "Something went wrong with your recording."
        static let AudioRecorderError = "Audio Recorder Error"
        static let AudioSessionError = "Audio Session Error"
        static let AudioRecordingError = "Audio Recording Error"
        static let AudioFileError = "Audio File Error"
        static let AudioEngineError = "Audio Engine Error"
        static let AudioSpeakerError = "Audio output could not be configured. Volume will be extremely low."
    }
    
    //MARK: - Audio Related
    func setupAudio() {
        do {
            audioFile = try AVAudioFile(forReading: recordedAudioURL)
        } catch {
            self.showAlert(Alerts.AudioFileError, message: String(describing: error))
        }
    }
    
    func connectAudioNodes(_ nodes: AVAudioNode...) {
        for index in 0..<nodes.count - 1 {
            audioEngine?.connect(nodes[index], to: nodes[index + 1], format: audioFile?.processingFormat)
        }
    }
    
    func generateRatePitchNode(rate: Float? = nil, pitch: Float? = nil) -> AVAudioUnitTimePitch {
        let changeRatePitchNode = AVAudioUnitTimePitch()
        
        if let rate = rate {
            changeRatePitchNode.rate = rate
        } else if let pitch = pitch {
            changeRatePitchNode.pitch = pitch
        }
        
        return changeRatePitchNode
    }
    
    func determineDelayInSeconds(rate: Float? = nil) -> Double {
        guard let lastRenderTime = self.audioPlayerNode?.lastRenderTime else { return 0.0 }
        guard let playerTime = self.audioPlayerNode?.playerTime(forNodeTime: lastRenderTime) else { return 0.0 }
        guard let audioFile = self.audioFile else { return 0.0 }
        
        if let rate = rate {
            return Double(audioFile.length - playerTime.sampleTime) / Double(audioFile.processingFormat.sampleRate) / Double(rate)
        } else {
            return Double(audioFile.length - playerTime.sampleTime) / Double(audioFile.processingFormat.sampleRate)
        }
    }
    
    func playAudio(rate: Float? = nil, pitch: Float? = nil, echo: Bool = false, reverb: Bool = false) {
        audioEngine = AVAudioEngine()
        audioPlayerNode = AVAudioPlayerNode()
        
        if let audioPlayerNode = audioPlayerNode {
            audioEngine?.attach(audioPlayerNode)
        }
        
        let changeRatePitchNode = generateRatePitchNode(rate: rate, pitch: pitch)
        audioEngine?.attach(changeRatePitchNode)
        
        let echoNode = AVAudioUnitDistortion()
        echoNode.loadFactoryPreset(.multiEcho1)
        audioEngine?.attach(echoNode)
        
        let reverbNode = AVAudioUnitReverb()
        reverbNode.loadFactoryPreset(.cathedral)
        reverbNode.wetDryMix = 50
        audioEngine?.attach(reverbNode)
        
        guard let outputNode = audioEngine?.outputNode else { return }
        guard let audioPlayerNode = audioPlayerNode else { return }
        guard let audioFile = audioFile else { return }
        
        
        if echo && reverb {
            connectAudioNodes(audioPlayerNode, echoNode, reverbNode, outputNode)
        } else if echo {
            connectAudioNodes(audioPlayerNode, echoNode, changeRatePitchNode, outputNode)
        } else if reverb {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, reverbNode, outputNode)
        } else {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, outputNode)
        }
        
        audioPlayerNode.stop()
        audioPlayerNode.scheduleFile(audioFile, at: nil) {
            let delayInSeconds = self.determineDelayInSeconds(rate: rate)
            
            self.stopTimer = Timer(timeInterval: delayInSeconds, target: self, selector: #selector(PlaySoundsViewController.stopAudio), userInfo: nil, repeats: false)
            
            if let timer = self.stopTimer {
                RunLoop.main.add(timer, forMode: .default)
            }
        }
        
        do {
            try self.audioEngine?.start()
        } catch {
            self.showAlert(Alerts.AudioEngineError, message: String(describing: error))
            return
        }
        
        self.audioPlayerNode?.play()
    }
    
    @objc func stopAudio() {
        if let audioPlayerNode = self.audioPlayerNode {
            audioPlayerNode.stop()
        }
        
        if let stopTimer = self.stopTimer {
            stopTimer.invalidate()
        }
        
        setUIState(.notPlaying)
        
        if let audioEngine = audioEngine {
            audioEngine.stop()
            audioEngine.reset()
        }
    }
    
    //MARK: - UI Related
    func setButtons(_ isEnabled: Bool) {
           fastButton.isEnabled = isEnabled
           slowButton.isEnabled = isEnabled
           highPitchButton.isEnabled = isEnabled
           lowPitchButton.isEnabled = isEnabled
           echoButton.isEnabled = isEnabled
           reverbButton.isEnabled = isEnabled
           stopButton.isEnabled = !isEnabled
       }
       
       func setUIState(_ state: PlayingState) {
           switch (state) {
           case .playing:
               setButtons(false)
           case .notPlaying:
               setButtons(true)
           }
       }
    
    func showAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Alerts.DismissAlert, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
