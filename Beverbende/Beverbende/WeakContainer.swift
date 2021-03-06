//
//  Weak.swift
//  Beverbende
//
//  Created by Loran on 06/03/2021.
//  Source: https://stackoverflow.com/questions/32807948/using-as-a-concrete-type-conforming-to-protocol-anyobject-is-not-supported

import Foundation

struct WeakContainer<T> {
  private weak var _value:AnyObject?
  var value: T? {
    get {
      return _value as? T
    }
    set {
      _value = newValue as AnyObject
    }
  }
}
