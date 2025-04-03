//
//  ConstantRippleModifier.swift
//  watermarkremover
//
//  Created by Julian Beck on 27.03.25.
//


import SwiftUI

struct ConstantRippleModifier: ViewModifier {
    // Time value that will be animated
    @State private var time: Double = 0
    
    // Customizable parameters
    var amplitude: Double = 5
    var frequency: Double = 2
    var speed: Double = 50
    
    func body(content: Content) -> some View {
        let shader = Shader(function: .init(library: .bundle(.main), name: "ConstantRipple"), 
                            arguments: [
                                .float(time),
                                .float(amplitude),
                                .float(frequency),
                                .float(speed)
                            ])
        
        return content
            .layerEffect(shader, maxSampleOffset: CGSize(width: amplitude, height: amplitude))
            .onAppear {
                // Create a continuous animation for the time parameter
                withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                    time = 100 // A large value to ensure continuous animation
                }
            }
    }
}

// Extension to make it easier to apply the effect
extension View {
    func constantRipple(amplitude: Double = 5, frequency: Double = 2, speed: Double = 50) -> some View {
        modifier(ConstantRippleModifier(amplitude: amplitude, frequency: frequency, speed: speed))
    }
}

struct RippleWaveExample: View {
    var body: some View {
        VStack {
            Spacer()
            
            Image("example")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .constantRipple(amplitude: 8, frequency: 3, speed: 60)
                .shadow(radius: 3, y: 2)
            
            Spacer()
            
            // Optional: Add controls to adjust the parameters
            GroupBox {
                Text("Adjust the ripple parameters to customize the effect")
                    .font(.caption)
            }
        }
        .padding()
    }
}

#Preview("Ripple Wave Example") {
    RippleWaveExample()
}
