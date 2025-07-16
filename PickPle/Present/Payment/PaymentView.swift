//
//  PaymentView.swift
//  PickPle
//
//  Created by 정인선 on 8/9/25.
//

import SwiftUI
import WebKit
import iamport_ios

struct PaymentView: View {
    @ObservedObject var paymentManager: PaymentManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                if let paymentRequest = paymentManager.paymentRequest {
                    PaymentOnlyWebView(
                        paymentRequest: paymentRequest,
                        onPaymentResult: { result in
                            handlePaymentResult(result)
                        }
                    )
                    .id(paymentRequest.orderCode) // 매번 새로 생성
                } else {
                    Text("결제 정보를 불러오는 중...")
                        .foregroundStyle(.gray)
                }
                
                if paymentManager.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    ProgressView("처리 중...")
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                }
            }
            .navigationTitle("결제")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        paymentManager.cancelPayment()
                        dismiss()
                    }
                }
            }
        }
        .alert("결제 오류", isPresented: .constant(paymentManager.errorMessage != nil)) {
            Button("확인") {
                paymentManager.errorMessage = nil
                dismiss()
            }
        } message: {
            Text(paymentManager.errorMessage ?? "")
        }
    }
    
    private func handlePaymentResult(_ result: IamportResponse) {
        if result.success == true {
            if let impUid = result.imp_uid {
                // merchantUid 매개변수 제거
                paymentManager.validatePayment(impUid: impUid)
            }
        } else {
            paymentManager.errorMessage = result.error_msg ?? "결제에 실패했습니다."
        }
    }
}

// MARK: - 결제 전용 WebView (BridgeWebView와 완전 분리)
struct PaymentOnlyWebView: UIViewRepresentable {
    let paymentRequest: PaymentRequest
    let onPaymentResult: (IamportResponse) -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        // 완전히 새로운 configuration (기존 BridgeWebView와 분리)
        let configuration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        
        // BridgeWebView와 다른 설정 사용
        configuration.userContentController = userContentController
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.backgroundColor = UIColor.clear
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = false
        
        startPayment(webView: webView)
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) { }
    
    private func startPayment(webView: WKWebView) {
        let totalQuantity = paymentRequest.menuItems.reduce(0) { $0 + $1.quantity }
        let name = totalQuantity > 1 ? "\(paymentRequest.menuItems.first?.name ?? "상품") 외 \(totalQuantity - 1)개" : (paymentRequest.menuItems.first?.name ?? "상품")
        let payment = IamportPayment(
            pg: PG.html5_inicis.makePgRawName(pgId: "INIpayTest"),
            merchant_uid: paymentRequest.orderCode,
            amount: "\(paymentRequest.totalPrice)"
        ).then {
            $0.pay_method = PayMethod.card.rawValue
            $0.name = name
            $0.buyer_name = "정인선"
            $0.app_scheme = "sesac"
        }
        
        print("🔵 결제 시작: \(paymentRequest.orderCode), 금액: \(paymentRequest.totalPrice)")
        
        Iamport.shared.paymentWebView(
            webViewMode: webView,
            userCode: "imp14511373",
            payment: payment
        ) { iamportResponse in
            DispatchQueue.main.async {
                print("🔵 결제 응답 받음: \(String(describing: iamportResponse))")
                if let response = iamportResponse {
                    self.onPaymentResult(response)
                }
            }
        }
    }
}
