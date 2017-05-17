//

//
//  SensorModel.swift
//  BLE
//
//  Original code created by Justin Anderson on 8/1/16.
//  Copyright © 2016 MIT. All rights reserved.
//
//  Modified by Matt Basile, Julia Guo, and Dan Lerner
//
//

import Foundation
import UIKit
import CoreBluetooth

protocol SensorModelDelegate {
    
    func sensorModel(_ model: SensorModel, didChangeActiveHill hill: Hill?)
    func sensorModel(_ model: SensorModel, didReceiveRange ranges: [Float], forHill hill: Hill?)
    func sensorModel(_ model: SensorModel, didReceiveRSSI rssi: Double)
    
}

extension Notification.Name {
    public static let SensorModelActiveHillChanged = Notification.Name(rawValue: "SensorModelActiveHillChangedNotification")
    public static let SensorModelRangesChanged = Notification.Name(rawValue: "SensorModelHillRangesChangedNotification")
}

struct Hill {
    var range: Float
    var name: String
    
    init(name: String) {
        self.name = name
        self.range = 0
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
    var sensorRanges = [Float]()
    var activeHill: Hill?
    var activePeripheral: CBPeripheral?
    var activeRSSI = 0.0
    let RSSIthreshold: Double
    var thresholdCounter: Double
    var rssiAvg = MovingAverage(period: 5)
    var ble: BLE
    
    
    init() {
        RSSIthreshold = -50.0
        thresholdCounter = 0.0
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
        NSLog("Found peripheral:")
        ble.connectToPeripheral(peripheral)
    }
    
    func ble(didConnectToPeripheral peripheral: CBPeripheral) {
        //Create and save new hill
        var newHill = Hill(name: peripheral.name!)
        activeHill = newHill
        activePeripheral = peripheral
        self.delegate?.sensorModel(self, didChangeActiveHill: activeHill)
        activePeripheral?.readRSSI()
        NSLog("Connected: ")
        
    }
    
    func ble(_ peripheral: CBPeripheral, didUpdateRSSI rssi: NSNumber?) {
        activePeripheral?.readRSSI()
        var currentRSSI = rssi!.doubleValue
        self.delegate?.sensorModel(self, didReceiveRSSI: currentRSSI)
    }
    
    func ble(_ peripheral: CBPeripheral, didReceiveData data: Data?) {
        
        // Convert incoming non-nil Data optional into a String
        let str = String(data: data!, encoding: String.Encoding.ascii)!
        
        
        //TODO
        //Convert sensor to string if necessary
        //let sensorRange = NSString(string: messageData).doubleValue
        //Add the current range to this beacon
        //var newRange =
        //Call didReceiveReadings
        //self.delegate?.sensorModel(self, didReceiveReadings: [newRange], forHill: activeHill)
        //Add to activeHill's array
        //activeHill?.range.append(newRange)
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
