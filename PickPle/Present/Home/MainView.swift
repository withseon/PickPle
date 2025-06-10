//
//  MainView.swift
//  PickPle
//
//  Created by 정인선 on 5/20/25.
//

import SwiftUI

struct MainView: View {
    @StateObject var viewModel: MainViewModel
    var body: some View {
        if let _ = UserDefaultsManager.selectedLocation {
            MainContentView(viewModel: viewModel)
                .onAppear {
                    viewModel.action(.onAppear)
                }
        } else {
            InitialLocationSettingView()
        }
    }
}

struct MainContentView: View {
    @ObservedObject var viewModel: MainViewModel
    @State var searchText = ""
    
    var body: some View {
        VStack(spacing: 8) {
            VStack(spacing: 8) {
                HStack {
                    LocationButton(address: viewModel.output.address)
                        .wrapToButton {
                            
                        }
                        .buttonStyle(.plain)
                    Spacer()
                }
                SearchTextField("검색어를 입력해주세요", text: $searchText)
                SearchListView()
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            
            ScrollView {
                StoreListView()
                    .frame(maxWidth: .infinity)
                    .edgesIgnoringSafeArea(.bottom)
            }
            .refreshable {
                print("새로고침")
            }
        }
        .background(.brightSprout)
    }
}

// MARK: - 현재 위치 선택 버튼
private struct LocationButton: View {
    let address: String
    
    var body: some View {
        HStack {
            Image("location")
                .iconFrame(24)
            Text(address)
                .font(.pretendard(.body1))
            Image("detail")
                .iconFrame(24)
        }
        .foregroundStyle(.black)
    }
}

// MARK: - 인기검색어 뷰
private struct SearchListView: View {
    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 0) {
                Image("sparkle")
                    .iconFrame(12)
                Text("인기검색어")
                    .font(.pretendard(.caption1))
            }
            .foregroundStyle(.deepSprout)
            Text("1 스타벅스")
                .font(.pretendard(.caption1))
                .foregroundStyle(.blackSprout)
            Spacer()
        }
        .wrapToButton {
            // TODO: 검색 결과 이동
        }
    }
}

// MARK: - 픽업 가게 리스트
struct StoreListView: View {
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                ForEach(StoreCategory.allCases, id: \.self) {
                    CategoryButton(icon: $0.icon, title: $0.title)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            
            VStack {
                HStack {
                    Text("실시간 인기 맛집")
                        .font(.pretendard(.body2))
                    Spacer()
                }
                .padding(.horizontal, 20)
                
                ScrollView(.horizontal) {
                    HStack {
                        PopularStoreView()
                        PopularStoreView()
                        PopularStoreView()
                        PopularStoreView()
                    }
                    .padding(.horizontal, 20)
                }
                .scrollIndicators(.never)
            }
            
            VStack(spacing: 8) {
                HStack(alignment: .center) {
                    Text("픽업 가게")
                        .font(.pretendard(.body2))
                    Spacer()
                    HStack {
                        Text("거리순")
                            .font(.pretendard(.caption1))
                        Image("list")
                            .iconFrame(16)
                    }
                    .foregroundStyle(.blackSprout)
                }
                
                HStack(spacing: 12) {
                    PickStoreFilterButton(isSelected: true, title: "픽슐랭")
                    PickStoreFilterButton(isSelected: false, title: "My Pick")
                    Spacer()
                }
                
                VStack {
                    ForEach(1...20, id: \.self) { item in
                        StoreView()
                        if item != 20 {
                            Rectangle()
                                .frame(height: 1)
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(.gray30)
                                .padding(.vertical, 4)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
        .background(.gray15)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 20,
                topTrailingRadius: 20
            )
        )
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 카데고리 버튼
private struct CategoryButton: View {
    var icon: String
    var title: String
    @State var isSelected = false
    
    var body: some View {
        VStack(alignment: .center) {
            Image(icon)
                .renderingMode(.original)
                .frame(width: 56, height: 56)
                .background(.gray0)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? .blackSprout : .gray30, lineWidth: isSelected ? 1.5 : 1)
                )
            
            Text(title)
                .font(.pretendard(.body3))
                .foregroundStyle(isSelected ? .blackSprout : .gray60)
        }
        .frame(maxWidth: .infinity)
        .wrapToButton {
            isSelected.toggle()
        }
    }
}

// MARK: - 픽업 가게 필터 버튼
struct PickStoreFilterButton: View {
    @State var isSelected = false
    var title: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isSelected ? "checkmark.square.fill" : "checkmark.square")
            Text(title)
                .font(.pretendard(.caption1))
        }
        .foregroundStyle(isSelected ? .blackSprout : .brightSprout)
        .wrapToButton {
            isSelected.toggle()
        }
    }
}

// MARK: - 실시간 인기 가게 셀
private struct PopularStoreView: View {
    @State var isLiked = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            AsyncImageView(url: "https://picsum.photos/id/237/200/300", width: 240, height: 176)
                .clipShape(TopLeftInverseCurveRectangle(cornerRadius: 16))
                .overlay(alignment: .topLeading) {
                    Image(isLiked ? "like.fill" : "like")
                        .iconFrame(24)
                        .padding(4)
                        .foregroundStyle(isLiked ? .blackSprout : .gray45)
                        .wrapToButton {
                            print("TODO: 가게: 좋아요")
                            isLiked.toggle()
                        }
                        .buttonStyle(.plain)
                }
                .overlay(alignment: .topTrailing) {
                    PickChelinTagView()
                        .padding(8)
                }
            VStack {
                HStack {
                    Text("가게 이름이 엄청나게 길어용ㅇㅇㅇ")
                        .lineLimit(1)
                        .font(.pretendard(.body3))
                    HStack(spacing: 0) {
                        Image("like.fill")
                            .iconFrame(16)
                            .foregroundStyle(.brightForsythia)
                        Text("NNN개")
                            .font(.pretendard(.body3))
                        
                    }
                    Spacer()
                }
                HStack {
                    detailInfoText(icon: "distance", text: "N.Nkm")
                    detailInfoText(icon: "time", text: "NPM")
                    detailInfoText(icon: "run", text: "NNN회")
                    Spacer()
                }
            }
            .padding(.horizontal, 10)
            .frame(width: 240, height: 56)
            .background(.gray0)
        }
        .frame(width: 240, height: 176)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func detailInfoText(icon: String, text: String) -> some View {
        HStack(spacing: 0) {
            Image(icon)
                .iconFrame(16)
                .foregroundStyle(.blackSprout)
            Text(text)
                .font(.pretendard(.body3))
                .foregroundStyle(.gray75)
        }
    }
    
    private struct TopLeftInverseCurveRectangle: Shape {
        var cornerRadius: CGFloat = 0
        
        func path(in rect: CGRect) -> Path {
            var path = Path()
            
            let width = rect.size.width
            let height = rect.size.height
            let corner = cornerRadius
            
            path.move(to: CGPoint(x: 0, y: corner * 2))
            
            // 왼쪽 아래로
            if corner > 0 {
                path.addLine(to: CGPoint(x: 0, y: height - corner * 2))
                path.addQuadCurve(
                    to: CGPoint(x: corner * 2, y: height),
                    control: CGPoint(x: 0, y: height)
                )
            } else {
                path.addLine(to: CGPoint(x: 0, y: height))
            }
            
            // 아래쪽 오른쪽으로
            if corner > 0 {
                path.addLine(to: CGPoint(x: width - corner * 2, y: height))
                path.addQuadCurve(
                    to: CGPoint(x: width, y: height - corner * 2),
                    control: CGPoint(x: width, y: height)
                )
            } else {
                path.addLine(to: CGPoint(x: width, y: height))
            }
            
            // 오른쪽 위로
            if corner > 0 {
                path.addLine(to: CGPoint(x: width, y: corner))
                path.addQuadCurve(
                    to: CGPoint(x: width - corner, y: 0),
                    control: CGPoint(x: width, y: 0)
                )
            } else {
                path.addLine(to: CGPoint(x: width, y: 0))
            }
            
            // 안으로 들어가는 라운드
            if corner > 0 {
                path.addLine(to: CGPoint(x: corner * 3, y: 0))
                path.addQuadCurve(
                    to: CGPoint(x: corner * 2, y: corner),
                    control: CGPoint(x: corner * 2, y: 0)
                )
                path.addQuadCurve(
                    to: CGPoint(x: corner, y: corner * 2),
                    control: CGPoint(x: corner * 2, y: corner * 2)
                )
                path.addQuadCurve(
                    to: CGPoint(x: 0, y: corner * 3),
                    control: CGPoint(x: 0, y: corner * 2)
                )
            } else {
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: corner))
            }
            
            return path
        }
    }
}

// MARK: - 가게 리스트 셀
private struct StoreView: View {
    @State var isLiked = false
    
    var body: some View {
        VStack {
            StoreGalleryImageView(
                imageUrls: [
                    "https://picsum.photos/id/10/400/300",
                    "https://picsum.photos/id/20/400/300",
                    "https://picsum.photos/id/30/400/300"
                ],
                ratio: 5/2,
                isPickchelin: true
            )
            .overlay(alignment: .topLeading) {
                Image(isLiked ? "like.fill" : "like")
                    .iconFrame(24)
                    .padding(8)
                    .foregroundStyle(isLiked ? .blackSprout : .gray45)
                    .wrapToButton {
                        print("TODO: 가게: 좋아요")
                        isLiked.toggle()
                    }
                    .buttonStyle(.plain)
            }
            VStack {
                HStack {
                    Text("가게 이름이 진짜 긴 경우ㅇㅇㅇㅇㅇㅇㅇ")
                        .lineLimit(1)
                        .font(.pretendard(.body1))
                    mainInfoText(icon: "like.fill", text: "NNN개")
                    mainInfoText(icon: "like.fill", text: "N.N", subText: "(NNN)")
                    Spacer()
                }
                HStack {
                    detailInfoText(icon: "distance", text: "N.Nkm")
                    detailInfoText(icon: "time", text: "NPM")
                    detailInfoText(icon: "run", text: "NNN회")
                    Spacer()
                }
            }
            HStack {
                ForEach(1...2, id: \.self) { item in
                    Text("#태그이름")
                        .font(.pretendard(.caption1))
                        .foregroundStyle(.gray0)
                        .padding(4)
                        .background(.deepSprout)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                Spacer()
            }
        }
    }
    
    private func mainInfoText(icon: String, text: String, subText: String? = nil) -> some View {
        HStack(spacing: 0) {
            Image(icon)
                .iconFrame(20)
                .foregroundStyle(.brightForsythia)
            Text(text)
                .font(.pretendard(.body1))
            if let text = subText {
                Text(text)
                    .font(.pretendard(.body1))
                    .foregroundStyle(.gray60)
            }
        }
    }
    
    private func detailInfoText(icon: String, text: String) -> some View {
        HStack(spacing: 0) {
            Image(icon)
                .iconFrame(20)
                .foregroundStyle(.blackSprout)
            Text(text)
                .font(.pretendard(.body2))
                .foregroundStyle(.gray60)
        }
    }
}

// MARK: - 

#Preview {
    MainView(viewModel: MainViewModel(storeRepository: DefaultStoreRepository.shared))
}
