# PickPle (픽플)

> 주변 음식점 정보를 확인하고, 음식을 픽업 주문하는 위치 기반 주문 앱

<p align="center">
<img width="150" height="325" alt="Image" src="https://github.com/user-attachments/assets/04f01f4e-f7ba-4aea-81df-2e27a8ffcab4" />
<img width="150" height="325" alt="Image" src="https://github.com/user-attachments/assets/3fe44d38-93c9-49d4-a08e-90177bdfa02d" />
<img width="150" height="325" alt="Image" src="https://github.com/user-attachments/assets/1c749430-1355-4893-aceb-2fa0fa98739e" />
<img width="150" height="325" alt="Image" src="https://github.com/user-attachments/assets/8b1f7e06-487a-41e4-a9c3-092206d89931" />



<p align="center">
<img width="150" height="325" alt="Image" src="https://github.com/user-attachments/assets/978f4c48-5432-43e1-bf66-6bcc851279bb" />
<img width="150" height="325" alt="Image" src="https://github.com/user-attachments/assets/54263dd2-eb8c-4213-83ff-e4bf338b155e" />
<img width="150" height="325" alt="Image" src="https://github.com/user-attachments/assets/3691cd1a-9397-4630-a5fb-44558c476210" />
<img width="150" height="325" alt="Image" src="https://github.com/user-attachments/assets/eb7d9ad5-2c4c-413d-9ca6-e033ea5b20c7" />
</p>

<br></br>
## 프로젝트 소개

PickPle은 사용자의 위치를 기반으로 주변 음식점 정보를 제공하고, 픽업 주문 및 커뮤니티 기능을 통합한 플랫폼입니다.
<br/>
<br/>

### 개발 기간
2025.05.10 ~ 2025.07.22 / iOS 개발 담당 (팀 구성: 기획 1명, 서버 1명, 디자이너 1명)
<br/>
<br/>

### 개발 환경
- iOS 16.0+
- Swift 5
- Xcode 16.2
- SwiftUI
<br/>

### 주요 기능

- **위치 기반 음식점 검색**: 지도 기반 주변 음식점 탐색
- **픽업 주문**: 간편한 메뉴 선택 및 결제 프로세스
- **주문 내역**: 주문 상태 추적 및 이력 관리
- **실시간 채팅**: Socket.IO 기반 실시간 메시징
- **커뮤니티**: 게시글 작성, 댓글, 사진/동영상 공유
- **사용자 프로필**: 개인 프로필 및 게시글 관리
</br>

### 프레임워크 & 라이브러리

- **UI**: SwiftUI
- **네트워킹**: Alamofire
- **데이터베이스**: RealmSwift
- **실시간 통신**: Socket.IO
- **소셜 로그인**: KakaoSDK, Apple Login
- **지도 및 위치 서비스**: CoreLocation, NMap
- **보안**: Keychain
- **미디어**: AVFoundation, AVKit, ImageIO, PhotosUI
- **캐싱**: NSCache
</br>

## 아키텍처
MVVM + Coordinator + DI Container도입
<p align="center">
<img width="303" height="312" alt="Image" src="https://github.com/user-attachments/assets/2e166d6e-43b3-4b12-92e3-ef7c6d78f3d3" />
</p>
<br/>
<br/>

### 디자인 패턴
- **MVVM (Model-View-ViewModel)**: 비즈니스 로직과 UI 분리
- **Coordinator Pattern**: 화면 전환 및 네비게이션 관리
- **Repository Pattern**: 데이터 소스 추상화
- **Dependency Injection**: DIContainer를 통한 의존성 관리

</br>

### 프로젝트 구조

<details>
  <summary>접기/펼치기</summary> 
  
  ```
  PickPle/
  ├── App/                    # 앱 진입점 및 코디네이터
  │   ├── PickPleApp.swift
  │   ├── AppDelegate.swift
  │   ├── Coordinator.swift
  │   └── DIContainer.swift
  │
  ├── Present/                # UI Layer (View + ViewModel)
  │   ├── Home/              # 홈 화면
  │   ├── Order/             # 주문 관리
  │   ├── Community/         # 커뮤니티
  │   ├── Chatting/          # 채팅
  │   ├── Profile/           # 프로필
  │   ├── SignIn/            # 로그인
  │   ├── SignUp/            # 회원가입
  │   ├── Payment/           # 결제
  │   └── Component/         # 재사용 컴포넌트
  │
  ├── Core/                   # 데이터 Layer
  │   ├── Network/           # 네트워크 통신
  │   │   ├── NetworkManager.swift
  │   │   ├── Router/        # API 라우터
  │   │   ├── DTO/           # 데이터 전송 객체
  │   │   └── Repository/    # 데이터 저장소
  │   ├── Database/          # 로컬 데이터베이스 (Realm)
  │   └── Socket/            # 소켓 통신
  │
  ├── Common/                 # 공통 모듈
  │   ├── Entity/            # 도메인 모델
  │   ├── Modifier/          # SwiftUI 커스텀 Modifier
  │   └── Secure/            # 보안 (Keychain, Secure Enclave)
  |
  ├── Util/                   # 유틸리티
  │   ├── ImageCacheManager.swift
  │   ├── PaymentManager.swift
  │   ├── CartManager.swift
  │   └── UserDefaultsManager.swift
  │
  └── Resource/               # 리소스
    └── Assets.xcassets    # 이미지 및 색상
```

</details>
</br>

## 🔑 주요 기능 상세

### 1. 위치 기반 서비스

- CoreLocation을 통한 사용자 위치 추적
- 지도 기반 음식점 탐색
- 위치 기반 음식점 정렬 및 필터링

### 2. 픽업 주문 시스템

- 장바구니 관리 (CartManager)
- PG사 연동 결제
- 주문 상태 추적 (접수, 준비중, 완료)

### 3. 실시간 채팅

- Socket.IO 기반 실시간 메시징
- 파일 업로드 (이미지, PDF)
- 안읽은 메시지 배지 표시
- Realm 기반 채팅 내역 저장

### 4. 커뮤니티

- 게시글 CRUD (생성, 읽기, 수정, 삭제)
- 댓글 기능
- 이미지/동영상 업로드

### 5. 보안

- Keychain을 통한 토큰 저장
- 자동 로그인 및 토큰 갱신
