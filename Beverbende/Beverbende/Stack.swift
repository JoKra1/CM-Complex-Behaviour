//
//  Stack.swift
//  Beverbende
//
//  Created by Loran on 23/02/2021.
//  Source: https://stackoverflow.com/questions/57059558/is-there-a-built-in-stack-implementation-in-swift//

import Foundation

struct Stack<T> {
    private var array: [T]
    
    init() {
        array = []
    }
    
    init(initialArray: Array<T>) {
        array = initialArray
    }

    mutating func push(_ element: T) {
        array.append(element)
    }

    mutating func pop() -> T? {
        return array.popLast()
    }

    func peek() -> T? {
        guard let top = array.last else { return nil }
        return top
    }
    
    mutating func shuffle() {
        array.shuffle()
    }
}
