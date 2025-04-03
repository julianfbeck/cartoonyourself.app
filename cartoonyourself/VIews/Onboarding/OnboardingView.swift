//
//  OnboardingView.swift
//  animeyourself
//
//  Created by Julian Beck on 25.05.25.
//

import SwiftUI
import ConfettiSwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @EnvironmentObject var globalViewModel: GlobalViewModel
    @Environment(\.requestReview) var requestReview
    
    // For haptic feedback
    let lightFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    let mediumFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        VStack {
            ZStack {
                SecondOnboardingScreen()
                    .opacity(currentPage == 0 ? 1 : 0)
                    .animation(.easeInOut(duration: 0.4), value: currentPage)
                
                FirstOnboardingScreen()
                    .opacity(currentPage == 1 ? 1 : 0)
                    .animation(.easeInOut(duration: 0.4), value: currentPage)
                
                ThirdOnboardingScreen()
                    .opacity(currentPage == 2 ? 1 : 0)
                    .animation(.easeInOut(duration: 0.4), value: currentPage)
            }
            
            Button(action: {
                lightFeedbackGenerator.prepare()
                
                if currentPage < 2 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentPage += 1
                    }
                    // Light haptic for page changes
                    lightFeedbackGenerator.impactOccurred()
                } else {
                    // Medium haptic for completion
                    mediumFeedbackGenerator.prepare()
                    mediumFeedbackGenerator.impactOccurred()
                    // We're at the last screen, dismiss the onboarding
                    globalViewModel.isShowingOnboarding = false
                    
                    // Request review after a slight delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        requestReview()
                    }
                }
            }) {
                Text(currentPage == 2 ? "Get Started" : "Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
            
            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(currentPage == index ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 16)
        }
        .onAppear {
            // Prepare the haptic engines when view appears
            lightFeedbackGenerator.prepare()
            mediumFeedbackGenerator.prepare()
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(GlobalViewModel())
} 
