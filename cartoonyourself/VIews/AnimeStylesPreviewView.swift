//
//  AnimeStylesPreviewView.swift
//  cartoonyourself
//
//  Created by Julian Beck on 30.03.25.
//

import SwiftUI

struct AnimeStylesPreviewView: View {
    // Access the styles from AnimeYourselfView
    let animeStyles = [
        "3d-animation-02",
        "modern-anime-06",
        "cartoon-03",
        "ghibli-05",
        "flat-01",
        "disney-04",
        "simpsons-07",
        "avatar-08"
    ]
    
    // For iPad, we'll use a grid layout with multiple columns
    let columns = [
        GridItem(.adaptive(minimum: 250, maximum: 300), spacing: 20)
    ]
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    Text("Available Cartoon Styles")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    Text("Swipe to explore all available cartoon styles")
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.bottom, 30)
                    
                    LazyVGrid(columns: columns, spacing: 30) {
                        ForEach(animeStyles, id: \.self) { style in
                            styleCard(style)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 50)
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color(#colorLiteral(red: 0.1, green: 0.1, blue: 0.2, alpha: 1))]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.white)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func styleCard(_ style: String) -> some View {
        VStack(spacing: 12) {
            // Style image
            Image(style.lowercased())
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 300)
                .cornerRadius(20)
                .shadow(radius: 8, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.accentColor, lineWidth: 2)
                )
            
            // Style name with pretty formatting
            Text(styleDisplayName(style))
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 8)
            
            // Style description
            Text(styleDescription(style))
                .font(.system(.body, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 12)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.black.opacity(0.6))
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(.ultraThinMaterial)
                )
        )
        .shadow(radius: 10, x: 0, y: 5)
    }
    
    // Helper function to convert style ID to display name
    private func styleDisplayName(_ styleId: String) -> String {
        switch styleId {
        case "3d-animation-02":
            return "3D Animation"
        case "modern-anime-06":
            return "Modern Anime"
        case "cartoon-03":
            return "Cartoon"
        case "ghibli-05":
            return "Ghibli"
        case "flat-01":
            return "Flat Style"
        case "disney-04":
            return "Disney"
        case "simpsons-07":
            return "Simpsons"
        case "avatar-08":
            return "Avatar"
        default:
            return styleId.capitalized
        }
    }
    
    // Helper function to provide descriptions for each style
    private func styleDescription(_ styleId: String) -> String {
        switch styleId {
        case "3d-animation-02":
            return "Modern 3D animation style with detailed rendering and smooth textures"
        case "modern-anime-06":
            return "Contemporary Japanese anime style with vibrant colors and expressive features"
        case "cartoon-03":
            return "Classic cartoon style with exaggerated features and bold outlines"
        case "ghibli-05":
            return "Inspired by Studio Ghibli's iconic hand-drawn animation style"
        case "flat-01":
            return "Minimalist flat design with simple shapes and solid colors"
        case "disney-04":
            return "Magical Disney-inspired style with expressive characters and rich details"
        case "simpsons-07":
            return "Yellow-skinned characters with distinctive overbite in the iconic Simpsons style"
        case "avatar-08":
            return "Inspired by the Avatar: The Last Airbender animation style"
        default:
            return "Transform your photo into this unique artistic style"
        }
    }
}

// Preview for SwiftUI canvas
struct AnimeStylesPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        AnimeStylesPreviewView()
            .previewDevice("iPad Pro (12.9-inch) (6th generation)")
            .previewDisplayName("iPad Pro")
    }
} 