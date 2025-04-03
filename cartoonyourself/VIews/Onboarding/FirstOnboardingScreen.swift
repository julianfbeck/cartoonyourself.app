//
//  FirstOnboardingScreen.swift
//  animeyourself
//
//  Created by Julian Beck on 26.03.25.
//

import SwiftUI

struct FirstOnboardingScreen: View {
    // Animation states
    @State private var titleOpacity = 0.0
    @State private var imageOpacity = 0.0
    @State private var featuresOpacity = 0.0
    @State private var currentExampleIndex = 0
    
    let examples = [
        ("example1-before", "example1-after"),
        ("example2-before", "example2-after"),
        ("example3-before", "example3-after")
    ]
    
    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 24) {
            // App logo and title
            VStack(spacing: 16) {
                Text("AniFy")
                    .font(.system(size: 42, weight: .bold))
                
                Text("Transform Yourself Into Anime")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)
            }
            .opacity(titleOpacity)
            
            // Example transformations
            HStack(spacing: 20) {
                // Before image
                Image(examples[currentExampleIndex].0)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 150, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
                
                // Arrow
                Image(systemName: "arrow.right")
                    .font(.title)
                    .foregroundColor(.accentColor)
                
                // After image
                Image(examples[currentExampleIndex].1)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 150, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.accentColor, Color.purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                    )
            }
            .shadow(color: Color.black.opacity(0.2), radius: 10)
            .opacity(imageOpacity)
            
            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<examples.count, id: \.self) { index in
                    Circle()
                        .fill(currentExampleIndex == index ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 8)
            
            // Features section
            VStack(alignment: .leading, spacing: 20) {
                Text("Transform any photo into anime art")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                Text("Experience the magic of AI-powered anime transformations with multiple unique styles to choose from.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.vertical, 20)
            .opacity(featuresOpacity)
            
            Spacer()
        }
        .onAppear {
            startAnimations()
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentExampleIndex = (currentExampleIndex + 1) % examples.count
            }
        }
    }
    
    func startAnimations() {
        withAnimation(.easeOut(duration: 0.8)) {
            titleOpacity = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.8).delay(0.4)) {
            imageOpacity = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.8).delay(0.8)) {
            featuresOpacity = 1.0
        }
    }
}

#Preview {
    FirstOnboardingScreen()
}
