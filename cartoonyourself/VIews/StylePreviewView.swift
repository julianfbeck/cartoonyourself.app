//
//  StylePreviewView.swift
//  cartoonyourself
//
//  Created by Julian Beck on 04.04.25.
//

import SwiftUI

struct StylePreviewView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var model: AnimeViewModel
    
    // List of anime styles matching the IDs in the AnimeViewModel
    let animeStyles = [
        "3d-animation-02",
        "modern-anime-06",
        "cartoon-03",
        "ghibli-05",
        "flat-01",
        "disney-04",
        "simpsons-07",
        "avatar-08",
    ]
    
    // Styles organized in rows (2 rows with 4 styles each)
    var styleRows: [[String]] {
        var result: [[String]] = []
        var row: [String] = []
        
        for (index, style) in animeStyles.enumerated() {
            row.append(style)
            
            if row.count == 4 || index == animeStyles.count - 1 {
                result.append(row)
                row = []
            }
        }
        
        return result
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.8), Color.black]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 15)
                    }
                    
                    Spacer()
                    
                    Text("MAKETOON.COM")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Placeholder to balance the layout
                    Color.clear
                        .frame(width: 70, height: 10)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Main content with style grid
                ScrollView {
                    VStack(spacing: 30) {
                        Text("Choose Your Style")
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 20)
                        
                        // Style grid
                        VStack(spacing: 25) {
                            ForEach(styleRows, id: \.self) { row in
                                HStack(spacing: 20) {
                                    ForEach(row, id: \.self) { style in
                                        Button(action: {
                                            // Set the selected style and go back
                                            model.selectedStyle = style
                                            presentationMode.wrappedValue.dismiss()
                                        }) {
                                            styleCard(style)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func styleCard(_ style: String) -> some View {
        VStack(spacing: 0) {
            // Style preview image
            Image(style.lowercased())
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 170, height: 170)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(model.selectedStyle == style ? Color.accentColor : Color.white.opacity(0.3), 
                                lineWidth: model.selectedStyle == style ? 3 : 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .background(Color.clear)
        .cornerRadius(20)
        .scaleEffect(model.selectedStyle == style ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: model.selectedStyle)
    }
}

// Preview provider
struct StylePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        StylePreviewView(model: AnimeViewModel())
            .preferredColorScheme(.dark)
    }
} 