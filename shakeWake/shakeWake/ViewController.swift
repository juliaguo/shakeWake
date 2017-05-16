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


class ViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var alarmSetIcon: UIImageView!
    @IBOutlet weak var alarmSetLabel: UILabel!
    @IBOutlet weak var cancelAlarmButton: UIButton!
    @IBOutlet weak var setAlarmButton: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var shakeThresholdLabel: UILabel!
//    @IBOutlet weak var turnOffAlarmButton: UIButton!
    var theTimer: Timer!
    var dateString: String!
    var strDate: String?
    var selectedAlarmTime: String?
    var player: AVAudioPlayer?
    
    @IBOutlet weak var shakeThreshold: UISlider!
    // 3D accel
    var motionManager: CMMotionManager = CMMotionManager()
    var accelAvg = MovingAverage(period: 100)
    
    var alarmRinging = false
    let locationManager = CLLocationManager()
    var threshold: Double = 5.0
    let session: AVAudioSession = AVAudioSession.sharedInstance()
    let center = UNUserNotificationCenter.current()
    let options: UNAuthorizationOptions = [.alert, .sound];
    let notificationDelegate = UYLNotificationDelegate()

    override func viewDidLoad() {
        super.viewDidLoad()
        print("view loading")
        // Initialize strDate value in case user sets alarm on current date selected
        var dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm"
        strDate = dateFormatter.string(from: datePicker.date)
        dateFormatter.dateFormat = "hh:mm a"
        alarmSetLabel.text = dateFormatter.string(from: datePicker.date)
//        turnOffAlarmButton.isEnabled = false
        alarmSetLabel.isHidden = true
        
        setTime()
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self
        // 3D accel
        motionManager.deviceMotionUpdateInterval = 1e-2
        
        motionManager.startDeviceMotionUpdates(
            using: .xArbitraryCorrectedZVertical,
            to: OperationQueue.main) { [weak self] (motion, error) in
                self?.accumulateMotion(motion)
        }
        
        // audio
        setupAudio()
        setupNotifCenter()
    }

    
    func setupAudio() {
        do {
            print("do block")
            try session.setCategory(AVAudioSessionCategoryPlayback)
        }   catch {
            print("catching goldfish")
            
        }
        
        let url = Bundle.main.url(forResource: "1secsilence", withExtension: "wav")!
        //        NSLog(String(describing: url))
        NSLog("playing silence sound")
        do {
            player = try AVAudioPlayer(contentsOf: url)
            guard let player = player else {return }
            player.prepareToPlay()
            player.numberOfLoops = -1
            player.play()
            
        } catch let error as NSError {
            NSLog("in error")
            print(error.description)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        NSLog("in didUpdateLocations")
    }
    
    func makeNotif(alarmDate: Date){
        //NSLog(alarmDate.description)
//        let date = Date(timeIntervalSinceNow: 10)
        let triggerDate = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,], from: alarmDate)
//        NSLog(date.description)
        NSLog("trigger date description")
        NSLog(triggerDate.description)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate,
                                                    repeats: false)
        let content = UNMutableNotificationContent()
        content.title = "Don't forget"
        content.body = "Buy some milk"
//        content.sound = UNNotificationSound(named: "Pop_Sound_Effect.aiff")
        content.sound = UNNotificationSound.default()
        let identifier = "UYLLocalNotification"
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content, trigger: trigger)
        center.add(request, withCompletionHandler: { (error) in
            if let error = error {
                // Something went wrong
            }
        })
    }
    
    func setupNotifCenter(){
        center.delegate = notificationDelegate
        center.requestAuthorization(options: options) {
            (granted, error) in
            if !granted {
                print("Something went wrong")
            }
        }
        
        center.getNotificationSettings { (settings) in
            if settings.authorizationStatus != .authorized {
                // Notifications not allowed
            }
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
        makeNotif(alarmDate: datePicker.date)
//        NSLog("alarm threshold set")
//        NSLog(String(threshold))
        
        
    }
    
    func playSound() {
        let url = Bundle.main.url(forResource: "alarm_sound", withExtension: "mp3")!

        do {
            //print("creating player")
            player = try AVAudioPlayer(contentsOf: url)
            guard let player = player else {return }
            //print("not returned")
            player.prepareToPlay()
            //print("prepped")
            player.numberOfLoops = -1
            player.play()
//            print("playing music")
            
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
        //NSLog("alarm sounding")
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
//        turnOffAlarmButton.isEnabled = false
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
    
   
    @IBAction func updateShakeThresholdVal(sender: AnyObject) {
        threshold = Double(shakeThreshold.value)
        shakeThresholdLabel.text = "Shake Level: " + String(Int(threshold))
//        NSLog(String(threshold))
        
    }
    
    let step: Float = 1
    @IBAction func sliderValueChanged(sender: UISlider) {
        let roundedValue = round(sender.value / step) * step
        sender.value = roundedValue
//        NSLog("sender value")
//        NSLog(String(sender.value))
        shakeThresholdLabel.text = "Shake Level: " + String(Int(sender.value))
        // Do something else with the value
        
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
                //NSLog("TIME TO WAKE!!!!!!")
                soundAlarm()
//                turnOffAlarmButton.isEnabled = true
                cancelAlarmButton.isEnabled = false
                setAlarmButton.isEnabled = false
            }
        }
//        locationManager.requestLocation()
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
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
        print(error.localizedDescription)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("in didChangeAuthorization")
        print(status)
        print(status.rawValue)
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 0
        locationManager.headingOrientation = .portrait
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.startUpdatingHeading()
        locationManager.startUpdatingLocation()

    }
    
}


class UYLNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Play sound and show alert to the user
        completionHandler([.alert,.sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        // Determine the user action
        switch response.actionIdentifier {
        case UNNotificationDismissActionIdentifier:
            print("Dismiss Action")
        case UNNotificationDefaultActionIdentifier:
            print("Default")
            //        case "Snooze":
            //            print("Snooze")
            //        case "Delete":
        //            print("Delete")
        default:
            print("Unknown action")
        }
        completionHandler()
    }
}
