//
//  SortBottomView.swift
//  PickPle
//
//  Created by 정인선 on 8/3/25.
//

import SwiftUI

protocol SortType: CaseIterable, Hashable {
    var title: String { get }
}

struct SortBottomView<T: SortType>: View {
    @Environment(\.dismiss) private var dismiss
    let selectedItem: T?
    let completion: ((T) -> Void)?

    private var calculatedHeight: CGFloat {
        let itemHeight: CGFloat = 50
        let separatorHeight: CGFloat = 1
        let padding: CGFloat = 20

        let itemCount = CGFloat(Array(T.allCases).count)
        let separatorCount = itemCount > 1 ? itemCount - 1 : 0

        let totalHeight = (itemHeight * itemCount) + (separatorHeight * separatorCount) + padding

        print(totalHeight)
        return max(totalHeight, 100)
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            ForEach(Array(T.allCases), id: \.self) { item in
                Text(item.title)
                    .font(.pretendard(.body1))
                    .frame(height: 50)
                    .foregroundStyle(isSelected(item) ? .blackSprout : .gray100)
                    .onTapGesture {
                        completion?(item)
                        dismiss()
                    }
                if item != Array(T.allCases).last {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(.gray30)
                        .padding(.horizontal, 20)
                }
            }
        }
        .presentationDetents([.height(calculatedHeight)])
    }
    
    private func isSelected(_ item: T) -> Bool {
        return selectedItem?.hashValue == item.hashValue
    }
}
