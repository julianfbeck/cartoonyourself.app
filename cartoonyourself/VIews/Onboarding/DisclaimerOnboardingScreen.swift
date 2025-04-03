//
//  DisclaimerOnboardingScreen.swift
//  watermarkremover
//
//  Created by Julian Beck on 26.03.25.
//

import SwiftUI

struct DisclaimerOnboardingScreen: View {
    @State private var showAnimation = false
    
    // For haptic feedback
    let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Header with icon
                VStack(spacing: 15) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.accentColor)
                        .padding()
                        .background(
                            Circle()
                                .fill(Color.accentColor.opacity(0.1))
                                .frame(width: 100, height: 100)
                        )
                        .scaleEffect(showAnimation ? 1.0 : 0.6)
                        .opacity(showAnimation ? 1.0 : 0.0)
                    
                    Text("Important Notice")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .opacity(showAnimation ? 1.0 : 0.0)
                }
                .padding(.top, 20)
                
                // Disclaimer content
                VStack(alignment: .leading, spacing: 20) {
                    DisclaimerSection(
                        title: "Copyright Notice",
                        content: "Only remove watermarks from content you own or have permission to modify.",
                        icon: "lock.shield.fill",
                        showAnimation: showAnimation
                    )
                    
                    DisclaimerSection(
                        title: "Ethical Usage",
                        content: "Don't create misleading content or violate creators' rights.",
                        icon: "hand.raised.fill",
                        showAnimation: showAnimation
                    )
                    
                    DisclaimerSection(
                        title: "Personal Use",
                        content: "This app is for personal use on content you legally own or have rights to modify.",
                        icon: "person.fill.checkmark",
                        showAnimation: showAnimation
                    )
                }
                .padding(.horizontal)
                
                // Legal agreement text without checkbox
                Text("By continuing, you agree to use this app responsibly.")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .opacity(showAnimation ? 1.0 : 0.0)
            }
            .padding(.bottom, 80) // Add padding to avoid button overlap
        }
        .onAppear {
            // Start animations when view appears
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                showAnimation = true
            }
            feedbackGenerator.prepare()
        }
    }
}

// Helper component for each disclaimer section
struct DisclaimerSection: View {
    let title: String
    let content: String
    let icon: String
    var showAnimation: Bool
    
    // For staggered animation
    private var animation: Animation {
        .spring(response: 0.6, dampingFraction: 0.7)
        .delay(title.contains("Copyright") ? 0.2 : 
                 title.contains("Ethical") ? 0.3 : 0.4)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.accentColor)
                
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5)
        )
        .scaleEffect(showAnimation ? 1.0 : 0.9)
        .opacity(showAnimation ? 1.0 : 0.0)
        .animation(animation, value: showAnimation)
    }
}

#Preview {
    DisclaimerOnboardingScreen()
} 