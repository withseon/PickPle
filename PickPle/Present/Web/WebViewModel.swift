//
//  WebViewModel.swift
//  PickPle
//
//  Created by 정인선 on 8/1/25.
//

import Foundation
import Combine

final class WebViewModel: BaseViewModel, ViewModelType {
    var input = Input()
    @Published var output = Output()
    var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        transform()
    }
}

// MARK: - Input/Output
extension WebViewModel {
    struct Input {
    }

    struct Output {
    }

    func transform() {
    }
}

// MARK: - Action
extension WebViewModel {
    enum Action {
    }

    func action(_ action: Action) {
        switch action {
        }
    }
}
