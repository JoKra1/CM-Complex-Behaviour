//
//  Queue.swift
//  Beverbende
//
//  Created by Chiel Wijs on 09/03/2021.
//  source: https://www.journaldev.com/21355/swift-queue-data-structure

import Foundation

struct Queue<T>{
    
    var items:[T] = []
    
    mutating func enqueue(element: T) {
        items.append(element)
    }
    
    mutating func dequeue() -> T? {
        if items.isEmpty {
            return nil
        }
        else{
            let tempElement = items.first
            items.remove(at: 0)
            return tempElement
        }
    }
    
}
