//
//  PayWallView.swift
//  animeyourself
//
//  Created by Julian Beck on 31.03.25.
//


//
//  PayWallView.swift
//  watermarkremover
//
//  Created by Julian Beck on 23.03.25.
//

import RevenueCat
import SwiftUI


struct PayWallView: View {

    
    @EnvironmentObject var globalViewModel: GlobalViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showCloseButton = false
    @State private var closeButtonProgress: CGFloat = 0.0
    private let allowCloseAfter: CGFloat = 4.0
    @State private var animateGradient = false
    @State private var isFreeTrialEnabled: Bool = true
    
    var calculateSavedPercentage: Int {
        let annualPrice = globalViewModel.offering?.annual?.storeProduct.pricePerYear?.doubleValue ?? 0
        let weeklyPrice = globalViewModel.offering?.weekly?.storeProduct.pricePerYear?.doubleValue ?? 0
        return Int((100 - ((annualPrice / weeklyPrice) * 100)).rounded())
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.black, Color.black.opacity(0.9), Color.accentColor.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Gradient orb in background (similar to main view)
            GeometryReader { geometry in
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.accentColor.opacity(0.6),
                                Color.purple.opacity(0.3)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: geometry.size.width * 0.8)
                    .position(x: geometry.size.width * 0.5, y: geometry.size.height * 0.3)
                    .blur(radius: 60)
            }
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Close button with progress circle
                    HStack {
                        Spacer()
                        Button(action: {
                            if showCloseButton {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .stroke(lineWidth: 2)
                                    .opacity(0.3)
                                    .foregroundColor(.white)
                                
                                Circle()
                                    .trim(from: 0, to: closeButtonProgress)
                                    .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                    .foregroundColor(.white)
                                    .rotationEffect(.degrees(-90))
                                
                                Image(systemName: "xmark")
                                    .foregroundColor(showCloseButton ? .white : .white.opacity(0.5))
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .frame(width: 30, height: 30)
                        }
                        .disabled(!showCloseButton)
                    }
                    .padding(.horizontal)
                    
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "sparkles.rectangle.stack")
                            .font(.system(size: 48))
                            .foregroundColor(.white)
                        
                        Text("UNLIMITED")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                    }
                    
                    // Features list
                    VStack(alignment: .leading, spacing: 20) {
                        FeatureRow(icon: "infinity.circle.fill", text: "Unlimited transformations")
                        FeatureRow(icon: "bolt.circle.fill", text: "Priority processing queue")
                        FeatureRow(icon: "paintpalette.fill", text: "Access all anime styles")
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.5))
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                            )
                    )
                    .padding(.horizontal)
                    
                    if let offering = globalViewModel.offering,
                       let annual = offering.annual,
                       let weekly = offering.weekly {
                        
                        VStack(spacing: 12) {
                            // Annual option
                            Button(action: { isFreeTrialEnabled = false }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Premium Annual")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                                        
                                        Text("Most popular option")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.8))
                                        
                                        Text("\(annual.localizedPriceString) per year")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                                    }
                                    Spacer()
                                    
                                    Text("SAVE \(calculateSavedPercentage)%")
                                        .font(.caption.bold())
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.red)
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                                    
                                    Circle()
                                        .stroke(!isFreeTrialEnabled ? Color.white : Color.white.opacity(0.3), lineWidth: 2)
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Circle()
                                                .fill(!isFreeTrialEnabled ? Color.white : Color.clear)
                                                .frame(width: 16, height: 16)
                                        )
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.black.opacity(0.5))
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(.ultraThinMaterial)
                                        )
                                )
                            }
                            
                            // Weekly with trial option
                            Button(action: { isFreeTrialEnabled = true }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("3-Day Free Trial")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                                        
                                        HStack {
                                            Text("Try before you buy")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                        
                                        Text("then \(weekly.localizedPriceString) per week")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                                    }
                                    Spacer()
                                    
                                    Circle()
                                        .stroke(isFreeTrialEnabled ? Color.white : Color.white.opacity(0.3), lineWidth: 2)
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Circle()
                                                .fill(isFreeTrialEnabled ? Color.white : Color.clear)
                                                .frame(width: 16, height: 16)
                                        )
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.black.opacity(0.5))
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(.ultraThinMaterial)
                                        )
                                )
                            }
                            
                            // Free Trial Toggle Section
                            VStack(alignment: .leading, spacing: 3) {
                                
                                Toggle("Enable 3-Day Free Trial", isOn: $isFreeTrialEnabled)
                                    .fontWeight(.bold)
                                    .font(.headline)
                                    .tint(.accentColor)
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.black.opacity(0.5))
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.ultraThinMaterial)
                                    )
                            )
                            
                            // Purchase button
                            Button(action: {
                                let package = isFreeTrialEnabled ? weekly : annual
                                globalViewModel.purchase(package: package)
                            }) {
                                HStack {
                                    if globalViewModel.isPurchasing {
                                        ProgressView()
                                            .tint(.black)
                                            .padding(.trailing, 8)
                                    }
                                    
                                    Text(isFreeTrialEnabled ? "Start Free Trial" : "Upgrade to Premium")
                                        .fontWeight(.semibold)
                                        .font(.system(.body, design: .rounded))
                                    
                                    if !globalViewModel.isPurchasing {
                                        Image(systemName: "chevron.right")
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(25)
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                            .disabled(globalViewModel.isPurchasing)
                            .padding(.top, 2)
                        }
                        .padding(.horizontal)
                    } else {
                        ProgressView()
                            .tint(.white)
                            .padding()
                    }
                    
                    // Error message
                    if let errorMessage = globalViewModel.errorMessage {
                        Text(errorMessage)
                            .font(.callout)
                            .foregroundColor(.red)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.black.opacity(0.5))
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(.ultraThinMaterial)
                                    )
                            )
                            .padding(.horizontal)
                    }
                    
                    // Footer links
                    HStack(spacing: 16) {
                        Button("Restore") {
                            globalViewModel.restorePurchase()
                        }
                        .font(.footnote)
                        .foregroundColor(.white)
                        
                        Divider()
                            .frame(height: 12)
                            .background(Color.white.opacity(0.3))
                        
                        Link("Terms", destination: Helpers.termsOfServiceURL)
                            .font(.footnote)
                            .foregroundColor(.white)
                        
                        Divider()
                            .frame(height: 12)
                            .background(Color.white.opacity(0.3))
                        
                        Link("Privacy", destination: Helpers.privacyPolicyURL)
                            .font(.footnote)
                            .foregroundColor(.white)
                    }
                    .padding(.bottom, 24)
                }
                .padding(.vertical)
                .frame(maxWidth: min(UIScreen.main.bounds.width, 600))
                .padding(.horizontal)
            }
        }
        .onAppear {
            startCloseButtonTimer()
            Plausible.shared.trackPageview(path: "/paywall")
            
        }
        .interactiveDismissDisabled(!showCloseButton)
    }
    
    private func startCloseButtonTimer() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if closeButtonProgress < 1.0 {
                closeButtonProgress += 0.1 / allowCloseAfter
            } else {
                showCloseButton = true
                timer.invalidate()
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.accentColor, Color.purple.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.system(size: 20, weight: .semibold))
            }
            .shadow(color: Color.accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
            
            Text(text)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal)
    }
}

#Preview {
    PayWallView()
        .environmentObject(GlobalViewModel())
}
