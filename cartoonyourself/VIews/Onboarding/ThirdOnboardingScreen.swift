//
//  ThirdOnboardingScreen.swift
//  animeyourself
//
//  Created by Julian Beck on 26.03.25.
//
import SwiftUI

struct ThirdOnboardingScreen: View {
    @State private var selectedStyle = "anime-default-001"
    
    // Available styles
    let animeStyles = [
        ("anime-default-001", "Classic", "Traditional anime look", "sparkles.rectangle.stack"),
        ("shonen-dynamic-005", "Action", "Dynamic battle style", "bolt.shield"),
        ("onepiece-007", "Adventure", "Bold adventure style", "helm"),
        ("naruto-009", "Mystic", "Spiritual warrior style", "flame")
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("Choose Your Style")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.top, 40)
                .padding(.horizontal)
            
            // Anime styles grid
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(animeStyles, id: \.0) { style in
                        StyleButton(
                            icon: style.3,
                            title: style.1,
                            description: style.2,
                            isSelected: selectedStyle == style.0
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedStyle = style.0
                            }
                            // Haptic feedback
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }.padding(.top,3)
                    }
                }
                .padding(.horizontal, 20)
            }
            
            Spacer()
        }
    }
}

// Style button component
struct StyleButton: View {
    let icon: String
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.accentColor, Color.purple.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .gray.opacity(0.5))
                    .font(.title3)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: isSelected ? Color.accentColor.opacity(0.3) : Color.black.opacity(0.05),
                            radius: isSelected ? 8 : 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ThirdOnboardingScreen()
}
