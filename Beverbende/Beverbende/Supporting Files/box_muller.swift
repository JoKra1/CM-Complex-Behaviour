//
//  box_muller.swift
//  SwiftUI_playground
//
//  Created by Joshua Krause on 01.03.21.
//  Source: Lecture notes machine learning (2020) and this wikipedia page:
//  https://en.wikipedia.org/wiki/Normal_distribution#Generating_values_from_normal_distribution
//

import Foundation

class BoxMuller {
    var A = SystemRandomNumberGenerator()
    var B = SystemRandomNumberGenerator()
    var mu:Double
    var sd:Double
    
    func next() -> Double {
        let a = Double.random(in: 0.0...1.0, using: &A)
        let b = Double.random(in: 0.0...1.0, using: &B)
        
        let C = (self.sd * ((-2 * log(a)).squareRoot() * cos(2 * Double.pi * b))) + self.mu
        return C
    }
    
    func sample(for length:Int) -> (sample:Array<Double>,mean:Double,sd:Double) {

        var data = Array<Double>()
        var sum:Double = 0
        for _ in 0..<length {
            let sample = self.next()
            data.append(sample)
            sum = sum + sample
        }

        let mean = sum / Double(length)

        var sumOfSquares: Double = 0
        for x in data {
            let diff = x - mean
            let square = diff * diff
            sumOfSquares = sumOfSquares + square
        }

        let sd = (sumOfSquares / (Double(length) - 1)).squareRoot()
        
        return (data,mean,sd)
    }
    
    func castToInt(for data:[Double]) -> [Int] {
        var casted = Array<Int>()
        for x in data {
            casted.append(Int(x))
        }
        return casted
    }
    
    func bin(for data:[Int], with binWidth:Int) ->(values:[Int], frequencies:[Int]) {
        var unique = Array(Set(data))
        unique.sort()
        var frequencies = Array<Int>()
        var binned_values = Array<Int>()
        for index in stride(from: binWidth, to: unique.count - binWidth, by: binWidth) {
            let x = unique[index]
            binned_values.append(x)
            var count = 0
            for y in data {
                if (y >= unique[index - binWidth]) && (y <= unique[index + binWidth]){
                    count = count + 1
                }
            }
            frequencies.append(count)
        }
        return (binned_values,frequencies)
    }
    
    init(mu:Double,sd:Double) {
        self.mu = mu
        self.sd = sd
    }
}
