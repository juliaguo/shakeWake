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
import CoreLocation

import UserNotifications

extension ViewController:UNUserNotificationCenterDelegate{
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        print("Tapped in notification")
    }
    
    //This is key callback to present notification while the app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        print("Notification being triggered")
        //You can either present alert ,sound or increase badge while the app is in foreground too with ios 10
        //to distinguish between notifications
        if notification.request.identifier == "requestIdentifier"{
            
            completionHandler( [.alert,.sound,.badge])
            
        }
    }
}

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
    let locationManager = CLLocationManager()
    
    
    
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
        
        locationManager.requestAlwaysAuthorization()
        
//        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 0
        locationManager.headingOrientation = .portrait
        locationManager.startUpdatingHeading()
        locationManager.startUpdatingLocation()
        
        // 3D accel
        motionManager.deviceMotionUpdateInterval = 1e-2
        
        motionManager.startDeviceMotionUpdates(
            using: .xArbitraryCorrectedZVertical,
            to: OperationQueue.main) { [weak self] (motion, error) in
                self?.accumulateMotion(motion)
        }
    }
    
    func locationManager(_ manager: CLLocationManager) {
        NSLog("hi")
    }
    
    func sendNotif(alarmTime: Date){
        print("sending notif")
        // create a corresponding local notification
        let notification = UILocalNotification()
        notification.alertBody = "Hello"
        notification.alertAction = "open" // text that is displayed after "slide to..." on the lock screen - defaults to "slide to view"
        notification.fireDate = alarmTime // todo item due date (when notification will be fired) notification.soundName = UILocalNotificationDefaultSoundName // play default sound
        UIApplication.shared.scheduleLocalNotification(notification)
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
    
    @IBAction func triggerNotif(){
        print("triggering notif, chill for a sec")
        let content = UNMutableNotificationContent()
        content.title = "Intro to notifs"
        content.subtitle = "Let's code, hi mochi"
        content.body = "s/o shakewake"
        content.sound = UNNotificationSound.default()
        
        let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 5.0, repeats: false)
        let request = UNNotificationRequest(identifier:"requestIdentifier", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().add(request){(error) in
            
            if (error != nil){
                
                print(error?.localizedDescription)
            }
        }
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
        NSLog("alarm sounding")
        playSound()
//        triggerNotif()
        //sendNotif(alarmTime: datePicker.date)
        alarmRinging = true
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
                NSLog("TIME TO WAKE!!!!!!")
                soundAlarm()
                turnOffAlarmButton.isEnabled = true
                cancelAlarmButton.isEnabled = false
                setAlarmButton.isEnabled = false
            }
        }
        locationManager.requestLocation()
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
//        acceleration = GLKVector3MultiplyScalar(acceleration, -1.0)
        
        let accelMag = GLKVector3Length(acceleration)
        let updatedAvg = accelAvg.addSample(value: Double(accelMag))
        if alarmRinging {
            //NSLog(String(accelAvg.getAverage()))
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

