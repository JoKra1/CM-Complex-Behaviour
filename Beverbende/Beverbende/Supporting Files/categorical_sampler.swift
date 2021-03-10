//
//  categorical_sampler.swift
//  Beverbende
//
//  Created by Joshua Krause on 09.03.21.
//

import Foundation

class CategoricalSampler {
    var categories:[String:[String:Double]]

    var generator = SystemRandomNumberGenerator()
    
    func next() -> Double {
        return Double.random(in: 0.0...1.0, using: &generator)
    }
    
    func sample(for length:Int) -> [String] {
        var data = Array<String>()
        for _ in 0..<length {
            let prob = self.next()
            for (category, cond_pair) in self.categories {
                if !prob.isLessThanOrEqualTo(cond_pair["lower"]!),
                   prob.isLess(than: cond_pair["upper"]!) {
                    data.append(category)
                    break
                }
            }
        }
        return data
    }
    
    init(with categories:[String:[String:Double]]) {
        self.categories = categories
    }
}
