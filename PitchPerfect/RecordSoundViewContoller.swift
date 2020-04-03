//
//  ViewController.swift
//  PitchPerfect
//
//  Created by Ryan Gross on 3/30/20.
//  Copyright © 2020 Ryan Gross. All rights reserved.
//

import UIKit
import AVFoundation

class RecordSoundViewContoller: UIViewController, AVAudioRecorderDelegate {
    let audioSession = AVAudioSession.sharedInstance()
    var audioRecorder: AVAudioRecorder?
    
    @IBOutlet var recordButton: UIButton!
    @IBOutlet var stopButton: UIButton!
    @IBOutlet var tapToRecordLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    @IBAction func recordButtonOnClick(_ sender: Any) {
        recordAudio()
    }
    
    @IBAction func stopButtonOnClick(_ sender: Any) {
        stopRecording()
    }
    
    func toggleButtons() {
        self.recordButton.isEnabled = !self.recordButton.isEnabled
        self.stopButton.isEnabled = !self.stopButton.isEnabled
    }
    
    func getLabelText(isRecording: Bool) -> String {
        return isRecording ? "Currently recording" : "Tap to record"
    }
    
    func recordAudio() {
        toggleButtons()
        self.tapToRecordLabel.text = getLabelText(isRecording: true)
        
        let directory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let filePath = "\(directory)/recording.wav"
        
        do {
            try audioSession.setActive(true)
            try audioSession.setCategory(.playAndRecord)
            try audioRecorder = AVAudioRecorder(url: URL(fileURLWithPath: filePath), settings: [:])
        } catch {
            print("Recording Failure: \(error.localizedDescription)")
        }
        
        audioRecorder?.delegate = self
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.prepareToRecord()
        audioRecorder?.record()
    }
    
    func stopRecording() {
        toggleButtons()
        tapToRecordLabel.text = getLabelText(isRecording: false)
        audioRecorder?.stop()
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Recording Stop Failure: \(error.localizedDescription)")
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            performSegue(withIdentifier: "stopRecording", sender: recorder.url)
        } else {
            print("fail")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "stopRecording" {
            if let destination = segue.destination as? PlaySoundsViewController, let recordedAudioURL = sender as? URL {
                destination.recordedAudioURL = recordedAudioURL
            }
        }
    }
}
