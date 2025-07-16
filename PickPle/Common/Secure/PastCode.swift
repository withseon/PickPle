//
//  PastCode.swift
//  PickPle
//
//  Created by 정인선 on 8/21/25.
//
//  초기 네트워킹 문제 발견 당시의 코드 아카이브
//  문제: "서버 통신이 이루어지지 않거나, 데이터 페치가 안 된다"
//

import Foundation
import SwiftUI
import Combine

// MARK: - 문제 발생 당시 StoreDetailViewModel

class ProblemStoreDetailViewModel: ObservableObject {
    @Published var storeDetail: StoreDetail?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let storeRepository: StoreRepository
    private var cancellables = Set<AnyCancellable>()
    
    init(storeId: String, storeRepository: StoreRepository) {
        self.storeRepository = storeRepository
        loadStoreDetail(storeId: storeId)
    }
    
    private func loadStoreDetail(storeId: String) {
        print("🏪 [StoreDetailViewModel] loadStoreDetail 시작")
        isLoading = true
        errorMessage = nil
        
        // ❌ 이 지점에서 요청은 시작되지만 응답이 오지 않음
        storeRepository.storeDetail(storeId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    print("🏪 [StoreDetailViewModel] 요청 완료: \(completion)")
                    self?.isLoading = false
                    switch completion {
                    case .finished:
                        print("🏪 [StoreDetailViewModel] 요청 성공적으로 완료")
                    case .failure(let error):
                        print("❌ [StoreDetailViewModel] 요청 실패: \(error)")
                        self?.errorMessage = "데이터를 불러오는데 실패했습니다."
                    }
                },
                receiveValue: { [weak self] result in
                    print("🏪 [StoreDetailViewModel] 결과 수신: \(result)")
                    switch result {
                    case .success(let response):
                        print("✅ [StoreDetailViewModel] 데이터 로딩 성공")
                        self?.storeDetail = response.asStoreDetail
                    case .failure(let error):
                        print("❌ [StoreDetailViewModel] 네트워크 에러: \(error)")
                        self?.errorMessage = "네트워크 오류가 발생했습니다."
                    }
                }
            )
            .store(in: &cancellables)
        
        // ❌ 문제: 이 지점 이후로 receiveValue나 receiveCompletion이 호출되지 않음
        print("🏪 [StoreDetailViewModel] Repository 호출 완료 - 응답 대기 중...")
    }
}

// MARK: - 문제 발생 당시 StoreDetailView

struct ProblemStoreDetailView: View {
    @StateObject private var viewModel: ProblemStoreDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(storeId: String, storeRepository: StoreRepository) {
        self._viewModel = StateObject(wrappedValue: ProblemStoreDetailViewModel(
            storeId: storeId,
            storeRepository: storeRepository
        ))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    // ❌ 문제: 이 상태에서 무한 로딩에 빠짐
                    VStack {
                        ProgressView("데이터를 불러오는 중...")
                            .padding()
                        Text("잠시만 기다려 주세요...")
                            .foregroundStyle(.secondary)
                    }
                } else if let storeDetail = viewModel.storeDetail {
                    // ✅ 정상: 데이터가 있을 때의 UI
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(storeDetail.storeName)
                                .font(.title2.bold())
                            Text(storeDetail.description)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    }
                } else if let errorMessage = viewModel.errorMessage {
                    // ❌ 문제: 에러 메시지는 나오지만 재시도해도 동일한 문제 발생
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundStyle(.orange)
                        
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        
                        Button("다시 시도") {
                            // 재시도해도 같은 문제 반복
                            print("🔄 [StoreDetailView] 재시도 버튼 클릭")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
            .navigationTitle("매장 상세")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 문제 발생 당시 StoreRepository

class ProblemStoreRepository {
    private let networkManager: NetworkManager
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    func storeDetail(_ storeId: String) -> AnyPublisher<Result<StoreDetailResponse, NetworkError>, Never> {
        print("📦 [StoreRepository] storeDetail 호출 - storeId: \(storeId)")
        
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.success(.failure(.unknown(NSError(domain: "StoreRepository", code: -1)))))
                return
            }
            
            print("📦 [StoreRepository] NetworkManager 호출 시작")
            
            // ❌ 이 Task가 생성되지만 내부 코드가 실행되지 않음
            Task {
                print("📦 [StoreRepository] Task 내부 진입") // ← 이 로그가 안 찍힘
                do {
                    let response = try await self.networkManager.request(
                        target: StoreRouter.storeDetail(storeId: storeId),
                        responseType: StoreDetailResponse.self,
                        errorType: DefaultErrorResponse.self
                    )
                    print("📦 [StoreRepository] NetworkManager 응답 성공") // ← 이 로그도 안 찍힘
                    promise(.success(.success(response)))
                } catch {
                    print("📦 [StoreRepository] NetworkManager 응답 실패: \(error)") // ← 이 로그도 안 찍힘
                    promise(.success(.failure(.unknown(error))))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - 사용자가 경험한 문제 증상

/*
 사용자 관점에서의 문제 증상:
 
 1. StoreDetailView 진입 시:
    - 로딩 스피너만 계속 돌아감
    - "데이터를 불러오는 중..." 메시지가 사라지지 않음
    - 실제로는 네트워크 요청이 시작도 안 됨
 
 2. 로그에서 관찰되는 패턴:
    🏪 [StoreDetailViewModel] loadStoreDetail 시작
    📦 [StoreRepository] storeDetail 호출 - storeId: xxxxx
    📦 [StoreRepository] NetworkManager 호출 시작
    🏪 [StoreDetailViewModel] Repository 호출 완료 - 응답 대기 중...
    
    ← 이후 아무런 로그도 없음
    ← Task 내부 코드가 실행되지 않음
    ← NetworkManager.request()가 호출되지 않음
    ← 결과적으로 receiveValue/receiveCompletion도 호출 안 됨
 
 3. UI 상태:
    - isLoading = true (계속 유지)
    - storeDetail = nil (데이터 없음)
    - errorMessage = nil (에러도 없음)
    - 결과: 무한 로딩 상태
 
 4. 사용자 액션:
    - 뒤로가기로 나갔다가 다시 들어와도 동일한 문제
    - 앱을 완전히 종료하고 재시작하면 잠시 작동
    - 하지만 몇 번 사용하다 보면 다시 같은 문제 발생
 
 5. 문제의 범위:
    - StoreDetail뿐만 아니라 다른 화면들도 동일한 증상
    - 모든 네트워크 요청이 영향을 받음
    - 사실상 앱 전체가 사용 불가능한 상태
*/

// MARK: - 디버깅 시도했던 방법들

/*
 문제 해결을 위해 시도했던 방법들:
 
 1. 네트워크 연결 상태 확인
    - WiFi, 셀룰러 모두 정상
    - 다른 앱들은 네트워크 정상 작동
 
 2. Alamofire Session 상태 확인
    - Session 객체는 정상적으로 존재
    - Configuration 설정도 문제없음
 
 3. 로깅 추가
    - Repository, ViewModel, View 각 단계별 로그 추가
    - Task 내부 진입 여부 확인을 위한 로그 추가
    - 결과: Task가 생성되지만 내부 코드 실행 안 됨
 
 4. 다른 네트워크 라이브러리 시도 고려
    - URLSession 직접 사용 고려
    - 하지만 Alamofire 자체 문제는 아닌 것으로 판단
 
 5. 메모리 누수 체크
    - Instruments로 메모리 사용량 확인
    - 특별한 메모리 문제는 발견되지 않음
*/