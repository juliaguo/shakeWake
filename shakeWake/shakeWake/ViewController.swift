//
//  ViewController.swift
//  Simple Alarm Clock
//
//  Created by Daniel Lerner on 5/3/17.
//  Copyright © 2017 Daniel Lerner. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMotion
import GLKit

class ViewController: UIViewController {
    
    @IBOutlet weak var alarmSetIcon: UIImageView!
    @IBOutlet weak var alarmSetLabel: UILabel!
    @IBOutlet weak var cancelAlarmButton: UIButton!
    @IBOutlet weak var setAlarmButton: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var turnOffAlarmButton: UIButton!
    var theTimer: Timer!
    var dateString: String!
    var strDate: String?
    var selectedAlarmTime: String?
    var player: AVAudioPlayer?
    
    // 3D accel
    var motionManager: CMMotionManager = CMMotionManager()
    var accelAvg = MovingAverage(period: 100)
    let threshold: Double = 5.0
    var alarmRinging = false
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Initialize strDate value in case user sets alarm on current date selected
        var dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm"
        strDate = dateFormatter.string(from: datePicker.date)
        dateFormatter.dateFormat = "hh:mm a"
        alarmSetLabel.text = dateFormatter.string(from: datePicker.date)
        turnOffAlarmButton.isEnabled = false
        setTime()
        alarmSetLabel.isHidden = true
        
        // 3D accel
        motionManager.deviceMotionUpdateInterval = 1e-2
        
        motionManager.startDeviceMotionUpdates(
            using: .xArbitraryCorrectedZVertical,
            to: OperationQueue.main) { [weak self] (motion, error) in
                self?.accumulateMotion(motion)
        }
    }
    
    @IBAction func datePickerAction(sender: AnyObject) {
        var dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm"
        strDate = dateFormatter.string(from: datePicker.date)
        dateFormatter.dateFormat = "hh:mm a"
        alarmSetLabel.text = dateFormatter.string(from: datePicker.date)
    }
    
    @IBAction func setAlarmAction(sender: AnyObject) {
        selectedAlarmTime = strDate
        alarmSetLabel.isEnabled = true
        alarmSetLabel.isHidden = false
        alarmSetIcon.isHidden = false
    }
    
    
    func playSound() {
        let url = Bundle.main.url(forResource: "alarm_sound", withExtension: "mp3")!
//        NSLog(String(describing: url))
//        NSLog("playing sound")
        do {
            player = try AVAudioPlayer(contentsOf: url)
            guard let player = player else { return }
            player.prepareToPlay()
            player.numberOfLoops = -1
            player.play()
            
        } catch let error as NSError {
            NSLog("in error")
            print(error.description)
        }
        
    }
    
    func checkTime(alarmTime: String, currentTime: NSDate) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm"
        var alarmAsDate: NSDate!
        if (alarmTime != ""){
            alarmAsDate = dateFormatter.date(from: alarmTime) as NSDate!
            if (alarmAsDate.timeIntervalSince(currentTime as Date) < 1 && alarmAsDate.timeIntervalSince(currentTime as Date) > -1){
                return true
            }
        }
        return false
    }
    
    func soundAlarm(){
        playSound()
        alarmRinging = true
        
        // figure out how to check if button pressed or allow that to happen, maybe just simulator?
    }
    
    @IBAction func turnOffAlarm(sender: AnyObject) {
        player!.stop()
        selectedAlarmTime = ""
        setAlarmButton.isEnabled = true
        cancelAlarmButton.isEnabled = true
        turnOffAlarmButton.isEnabled = false
        alarmSetLabel.isEnabled = false
        alarmSetLabel.isHidden = true
        alarmSetIcon.isHidden = true
        alarmRinging = false
        
    }
    
    @IBAction func cancelAlarmAction(sender: AnyObject) {
        selectedAlarmTime = ""
        alarmSetLabel.isHidden = true
        alarmSetLabel.isEnabled = false
        alarmSetIcon.isHidden = true
        alarmRinging = false
    }
    
    func setTime() {
        theTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: "setTime", userInfo: nil, repeats: false)
        
        var date: NSDate = NSDate()
        
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm:ss a"
        dateString = dateFormatter.string(from: date as Date)
        timeLabel.text = dateString as String
        if (selectedAlarmTime != nil){
            var timeToWake: Bool = checkTime(alarmTime: selectedAlarmTime!, currentTime: date)
            if(timeToWake){
                soundAlarm()
                turnOffAlarmButton.isEnabled = true
                cancelAlarmButton.isEnabled = false
                setAlarmButton.isEnabled = false
            }
        }
    }
    
    
    // 3D accel
    
    private func GLKQuaternionFromCMQuaternion(_ quat: CMQuaternion) -> GLKQuaternion {
        return GLKQuaternionMake(Float(quat.x), Float(quat.y), Float(quat.z), Float(quat.w))
    }
    
    private func GLKVector3FromCMAcceleration(_ acceleration: CMAcceleration) -> GLKVector3 {
        return GLKVector3Make(Float(acceleration.x), Float(acceleration.y), Float(acceleration.z))
    }
    
    
    func accumulateMotion(_ motion: CMDeviceMotion?) {
        guard let motion = motion else {
            return
        }
        
        let dt = motionManager.deviceMotionUpdateInterval
        let attitude = GLKQuaternionFromCMQuaternion(motion.attitude.quaternion)
        let userAcceleration = GLKVector3FromCMAcceleration(motion.userAcceleration)
        
        // -- TASK 2A --
        var acceleration: GLKVector3 = userAcceleration
        // rotate acceleration from instantaneous coordinates into persistent coordinates
        acceleration = GLKQuaternionRotateVector3(attitude, acceleration)
        acceleration = GLKVector3MultiplyScalar(acceleration, -1.0)
        
        let accelMag = GLKVector3Length(acceleration)
        let updatedAvg = accelAvg.addSample(value: Double(accelMag))
        if alarmRinging {
            NSLog(String(accelAvg.getAverage()))
        }
        if (accelAvg.getAverage() > threshold && alarmRinging) {
            turnOffAlarm(sender: self)
            NSLog("ALARM TURNED OFF")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

