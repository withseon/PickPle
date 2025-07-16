//
//  BannerView.swift
//  PickPle
//
//  Created by 정인선 on 8/1/25.
//

import SwiftUI

struct BannerView: View {
    @State private var timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    @State private var currentIndex: Int = 0
    @State private var isDragging = false
    @State private var isInitialized = false
    
    @State var items: [BannerItem]
    var size: CGSize
    var onBannerTap: (URL) -> Void
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $currentIndex) {
                ForEach(-1..<items.count + 1, id: \.self) { idx in
                    let item = items[getActualIndex(from: idx)]
                    CachedImageView(imagePath: item.imageUrl, size: size, showRetry: false)
                        .onTapGesture {
                            timer.upstream.connect().cancel()
                            if let url = URL(string: APIURL.PICKUP + item.value) {
                                onBannerTap(url)
                            }
                        }
                        .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(width: size.width, height: size.height)
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in // 드래그 중 타이머 중지
                        isDragging = true
                        timer.upstream.connect().cancel()
                    }
                    .onEnded { _ in // 드래그 종료 타이머 활성화
                        isDragging = false
                        getInfiniteScrollIndex()
                        timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
                    }
            )
            .onChange(of: currentIndex) { _ in
                if !isDragging && isInitialized {
                    getInfiniteScrollIndex()
                }
            }
            .onReceive(timer) { _ in
                if isInitialized {
                    withAnimation(.easeIn) {
                        currentIndex += 1
                    }
                }
            }
            .onAppear {
                // 초기화 완료 후 타이머 시작
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isInitialized = true
                }
            }
            
//            // 페이지 인디케이터
//            HStack(spacing: 2) {
//                Text("\(getCurrentDisplayIndex())")
//                    .font(.pretendard(.caption2))
//                    .foregroundStyle(.gray0)
//                
//                Text("/")
//                    .font(.pretendard(.caption2))
//                    .foregroundStyle(.gray0)
//                
//                Text("\(items.count)")
//                    .font(.pretendard(.caption2))
//                    .foregroundStyle(.gray0)
//            }
//            .padding(.horizontal, 10)
//            .padding(.vertical, 4)
//            .background(
//                Color.gray100.opacity(0.3)
//                    .clipShape(RoundedRectangle(cornerRadius: 12))
//            )
//            .padding(.trailing, 20)
//            .padding(.bottom, 12)
        }
    }
    
    // 무한 스크롤
    private func getInfiniteScrollIndex() {
        if currentIndex == items.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                currentIndex = 0
            }
        } else if currentIndex < 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                currentIndex = items.count - 1
            }
        }
    }
    
    // 실제 인덱스
    private func getActualIndex(from idx: Int) -> Int {
        if idx < 0 {
            return items.count - 1
        } else if idx >= items.count {
            return 0
        } else {
            return idx
        }
    }
    
    // 페이지 번호
    private func getCurrentDisplayIndex() -> Int {
        if currentIndex < 0 {
            return items.count
        } else if currentIndex >= items.count {
            return 1
        } else {
            return currentIndex + 1
        }
    }
}
