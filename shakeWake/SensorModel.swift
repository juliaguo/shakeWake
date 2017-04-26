//

//
//  SensorModel.swift
//  BLE
//
//  Original code created by Justin Anderson on 8/1/16.
//  Copyright © 2016 MIT. All rights reserved.
//
//  Modified by Matt Basile, Julia Guo, and Dan Lerner
//  Copyright © 2017 julia&tara productions
//

import Foundation
import UIKit
import CoreBluetooth

protocol SensorModelDelegate {
    func sensorModel(_ model: SensorModel, didChangeActiveHill hill: Hill?)
    func sensorModel(_ model: SensorModel, didReceiveReadings readings: [Reading], forHill hill: Hill?)
}

extension Notification.Name {
    public static let SensorModelActiveHillChanged = Notification.Name(rawValue: "SensorModelActiveHillChangedNotification")
    public static let SensorModelReadingsChanged = Notification.Name(rawValue: "SensorModelHillReadingsChangedNotification")
}

enum ReadingType: Int {
    case Unknown = -1
    case Humidity = 2
    case Temperature = 1
    case Error = 0
}

struct Reading {
    let type: ReadingType
    let value: Double
    let date: Date = Date()
    let sensorId: String?
    
    func toJson() -> [String: Any] {
        return [
            "value": self.value,
            "type": self.type.rawValue,
            "timestamp": self.date.timeIntervalSince1970,
            "userid": UIDevice.current.identifierForVendor?.uuidString ?? "NONE",
            "sensorid": sensorId ?? "NONE"
        ]
    }
}

extension Reading: CustomStringConvertible {
    var description: String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        guard let numberString = formatter.string(from: NSNumber(value: self.value)) else {
            print("Double \"\(value)\" couldn't be formatted by NumberFormatter")
            return "NaN"
        }
        switch type {
        case .Temperature:
            return "\(numberString)°F"
        case .Humidity:
            return "\(numberString)%"
        default:
            return "\(type)"
        }
    }
}

struct Hill {
    var readings: [Reading]
    var name: String
    
    init(name: String) {
        readings = []
        self.name = name
    }
}

extension Hill: CustomStringConvertible, Hashable, Equatable {
    var description: String {
        return name
    }
    
    var hashValue: Int {
        return name.hashValue
    }
}

func ==(lhs: Hill, rhs: Hill) -> Bool {
    return lhs.name == rhs.name
}

//Set sensor model to be delegate of BLE
class SensorModel: BLEDelegate{
    
    static let kBLE_SCAN_TIMEOUT = 10000.0
    
    static let shared = SensorModel()
    
    var delegate: SensorModelDelegate?
    var sensorReadings: [ReadingType: [Reading]] = [.Humidity: [], .Temperature: []]
    var activeHill: Hill?
    var activePeripheral: CBPeripheral?
    var ble: BLE
    
    //For reading in data
    var pktBuffer = Array<String>()
    
    init() {
        ble = BLE()
        ble.delegate = self
    }
    
    //Check if Bluetooth is powered on
    func ble(didUpdateState state: BLEState) {
        NSLog("Starting up")
        if (state == BLEState.poweredOn) {
            //If powered on, start scanning
            ble.startScanning(timeout: SensorModel.kBLE_SCAN_TIMEOUT)
            NSLog("Scanning")
        }
        else {
            NSLog("BLE not powered")
        }
    }
    
    func ble(didDiscoverPeripheral peripheral: CBPeripheral ) {
        NSLog("Found peripheral")
        ble.connectToPeripheral(peripheral)
    }
    
    func ble(didConnectToPeripheral peripheral: CBPeripheral) {
        //Create and save new hill
        var newHill = Hill(name: peripheral.name!)
        activeHill = newHill
        activePeripheral = peripheral
        self.delegate?.sensorModel(self, didChangeActiveHill: activeHill)
        NSLog("Connected")
    }
    
    func ble(_ peripheral: CBPeripheral, didReceiveData data: Data?) {
        NSLog("Data Incoming")
        
        // Convert incoming non-nil Data optional into a String
        let str = String(data: data!, encoding: String.Encoding.ascii)!
        NSLog("Incoming String: \(str)")
        
        //Both Humidity and Temp readings end with "D" so we can split by that
        //Two potential problems: Error messages mixed up in there and
        //  The last element being cut off
        var readings = str.components(separatedBy: "D")
        var finalEle = readings.last
        
        //Remove the last element from readings since it's incopmlete
        readings.remove(at: readings.count - 1)
        //While the buffer and readings are non-empty,
        if ((pktBuffer.count) > 0 && readings.count > 0) {
            //Set the first element of (new)readings to be the first element of the buffer + first element of readings
            //This adds the left over from the buffer with the beginning of the new packet, ensuring a continuous stream
            readings[0] = (pktBuffer.first)! + (readings.first)!
            //Then clear the buffer so it can accept new data from the current readings
            pktBuffer.removeAll()
        }
        
        //If there was anything in that last element of readings, append it to buffer (for next round)
        if (finalEle != "") {
            pktBuffer.append(finalEle!)
        }
        
        //If there's nothing in first element of readings, remove it
        if (readings.first == "") {
            readings.remove(at: 0)
        }
        
        //Process the Readings (now that we've consolidated messages between pkts
        var dataType: ReadingType?
        var messageData = String()
        for reading in readings {
            //Each element should start with an H or T
            //But it could start with an error message but still contain H/T readings
            //So we'll use contains instead of first
            if (reading.contains("H")) {
                //Separate the H reading from potential error messages
                var message = reading.components(separatedBy: "H")
                dataType = ReadingType.Humidity
                //The actual reading will always be the second element since errors must be before the H
                messageData = message[1]
                NSLog("Humidity: \(messageData)")
                
            }
                
            else if (reading.contains("T")) {
                //Repeat process for T
                var message = reading.components(separatedBy: "T")
                dataType = ReadingType.Temperature
                messageData = message[1]
                NSLog("Temperature: \(messageData)")
            }
            
            //Convert messageData to string
            let readingValue = NSString(string: messageData).doubleValue
            //Create new Reading Object
            var newReadingObject = Reading(type: dataType!, value: readingValue, sensorId: peripheral.name)
            //Call didReceiveReadings
            self.delegate?.sensorModel(self, didReceiveReadings: [newReadingObject], forHill: activeHill)
            //Add to activeHill's array
            activeHill?.readings.append(newReadingObject)
        }
        
        
        
        
        
        
        
        
        
        
        
    }
    
    func ble(didDisconnectFromPeripheral peripheral: CBPeripheral) {
        //Check if current peripheral matches the active peripheral
        if (peripheral == activePeripheral ) {
            //If so, change activeHill to nill
            activePeripheral = nil
            self.delegate?.sensorModel(self, didChangeActiveHill: nil)
        }
        NSLog("Disconnected")
        ble.startScanning(timeout: SensorModel.kBLE_SCAN_TIMEOUT)
    }
    
    
    
    
    
    
}
