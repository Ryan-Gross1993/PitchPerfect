//
//  PlaySoundsViewController.swift
//  PitchPerfect
//
//  Created by Ryan Gross on 3/30/20.
//  Copyright © 2020 Ryan Gross. All rights reserved.
//

import UIKit
import AVFoundation

class PlaySoundsViewController: UIViewController {
    @IBOutlet weak var fastButton: UIButton!
    @IBOutlet weak var slowButton: UIButton!
    @IBOutlet weak var highPitchButton: UIButton!
    @IBOutlet weak var lowPitchButton: UIButton!
    @IBOutlet weak var reverbButton: UIButton!
    @IBOutlet weak var echoButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    
    var recordedAudioURL: URL!
    var audioFile: AVAudioFile?
    var audioEngine: AVAudioEngine?
    var audioPlayerNode: AVAudioPlayerNode?
    var stopTimer: Timer?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupAudio()
        setUIState(.notPlaying)
        
        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
        } catch {
            self.showAlert(Alerts.AudioSpeakerError, message: String(describing: error))
        }
    }
    
    @IBAction func playSoundOnClick(_ sender: UIButton) {
        switch (ButtonType(rawValue: sender.tag)!) {
        case .slow:
            playAudio(rate: 0.5)
        case .fast:
            playAudio(rate: 1.5)
        case .highPitch:
            playAudio(pitch: 1000)
        case .lowPitch:
            playAudio(pitch: -1000)
        case .reverb:
            playAudio(reverb: true)
        case .echo:
            playAudio(echo: true)
        }
        
        setUIState(.playing)
    }
    
    @IBAction func stopButtonOnClick(_ sender: AnyObject) {
        stopAudio()
    }
}
