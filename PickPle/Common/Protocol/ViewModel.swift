//
//  ViewModel.swift
//  PickPle
//
//  Created by 정인선 on 5/11/25.
//

import Foundation
import Combine

protocol ViewModelType: AnyObject, ObservableObject {
    associatedtype Input
    associatedtype Output
    
    var cancellables: Set<AnyCancellable> { get set }
    
    var input: Input { get set }
    var output: Output { get set }
    
    func transform()
}

//final class ViewModel: ViewModelType {
//    var input = Input()
//    @Published var output = Output()
//    var cancellables = Set<AnyCancellable>()
//
//    init() {
//        transform()
//    }
//
//    deinit {
//        print("SearchViewModel deinit")
//    }
//}
//
//// MARK: - Input/Output
//extension ViewModel {
//    struct Input {
//    }
//
//    struct Output {
//    }
//
//    func transform() {
//    }
//}
//
//// MARK: - Action
//extension ViewModel {
//    enum Action {
//    }
//
//    func action(_ action: Action) {
//        switch action {
//        }
//    }
//}
