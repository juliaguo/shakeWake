//
//  ViewController.swift
//  Simple Alarm Clock
//
//  Created by Daniel Lerner on 5/3/17.
//  Copyright © 2017 Daniel Lerner. All rights reserved.
//

import UIKit
import AVFoundation

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
        let url = Bundle.main.url(forResource: "Human_Eating_Watermelon", withExtension: "mp3")!
        NSLog(String(describing: url))
        NSLog("playing sound")
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
        
    }
    
    @IBAction func cancelAlarmAction(sender: AnyObject) {
        selectedAlarmTime = ""
        alarmSetLabel.isHidden = true
        alarmSetLabel.isEnabled = false
        alarmSetIcon.isHidden = true
        
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

