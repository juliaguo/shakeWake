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

    @IBOutlet weak var cancelAlarmButton: UIButton!
    @IBOutlet weak var setAlarmButton: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var turnOffAlarmButton: UIButton!
    var theTimer: NSTimer!
    var dateString: NSString!
    var strDate: String?
    var selectedAlarmTime: String?
    var player: AVAudioPlayer?
    var userAsleep: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Initialize strDate value in case user sets alarm on current date selected
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm"
        strDate = dateFormatter.stringFromDate(datePicker.date)
        turnOffAlarmButton.enabled = false
        setTime()
    }
    
    @IBAction func datePickerAction(sender: AnyObject) {
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm"
        strDate = dateFormatter.stringFromDate(datePicker.date)
    }
    
    @IBAction func setAlarmAction(sender: AnyObject) {
        selectedAlarmTime = strDate
        userAsleep = true
    }
    
    
    func playSound() {
        let url = NSBundle.mainBundle().URLForResource("alarm_sound", withExtension: "mp3")!
        
        do {
            player = try AVAudioPlayer(contentsOfURL: url)
            guard let player = player else { return }
            
            player.prepareToPlay()
            player.play()
            
        } catch let error as NSError {
            print(error.description)
        }

    }
    
    func checkTime(alarmTime: String, currentTime: NSDate) -> Bool {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm"
        var alarmAsDate: NSDate!
        if (alarmTime != ""){
            alarmAsDate = dateFormatter.dateFromString(alarmTime)
            if (alarmAsDate.timeIntervalSinceDate(currentTime) < 1){
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
        userAsleep = false
        selectedAlarmTime = ""
        setAlarmButton.enabled = true
        cancelAlarmButton.enabled = true
        turnOffAlarmButton.enabled = false
    }
    
    @IBAction func cancelAlarmAction(sender: AnyObject) {
        selectedAlarmTime = ""
        userAsleep = false
        
    }

    func setTime() {
        theTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "setTime", userInfo: nil, repeats: false)
        
        let date: NSDate = NSDate()
        
        let dateFormatter: NSDateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "hh:mm:ss: a"
        dateString = dateFormatter.stringFromDate(date)
        timeLabel.text = dateString as String
        if (selectedAlarmTime != nil){
            var timeToWake: Bool = checkTime(selectedAlarmTime!, currentTime: date)
            if(timeToWake){
                soundAlarm()
                turnOffAlarmButton.enabled = true
                cancelAlarmButton.enabled = false
                setAlarmButton.enabled = false
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

