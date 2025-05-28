//
//  BaseViewModel.swift
//  PickPle
//
//  Created by 정인선 on 5/18/25.
//

import Foundation

class BaseViewModel {
    init() {
        print(String(describing: self), "Init")
    }
    
    deinit {
        print(String(describing: self), "Deinit")
    }
}
