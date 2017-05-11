//
//  MovingAverage.swift
//  shakeWake
//

import Foundation

class MovingAverage {
    var samples: Array<Double>
    var sampleCount = 0
    var period: Int
    
    init(period: Int) {
        self.period = period
        samples = Array<Double>()
    }
    
    var average: Double {
        let sum: Double = samples.reduce(0, +)
        
        if period > samples.count {
            return sum / Double(samples.count)
        } else {
            return sum / Double(period)
        }
    }
    
    func addSample(value: Double) -> Double {
        let pos = Int(fmodf(Float(sampleCount), Float(period)))
        sampleCount += 1
        
        if pos >= samples.count {
            samples.append(value)
        } else {
            samples[pos] = value
        }
        
        return average
    }
    
    func getAverage() -> Double {
        return average
    }
    
}
