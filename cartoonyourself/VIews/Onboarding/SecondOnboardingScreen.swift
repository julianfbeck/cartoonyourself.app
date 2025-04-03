import SwiftUI
import ConfettiSwiftUI

struct SecondOnboardingScreen: View {
    // Animation state
    @State private var animationPhase = 1
    @State private var confettiTrigger = 0
    @State private var scale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.0
    @State private var glowRadius: CGFloat = 0.0
    
    // Haptic feedback generators
    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        VStack(spacing: 24) {
            // Title at the top
            Text("Transform Your Photos")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
            
            // Image container
            ZStack {
                // Original photo
                if animationPhase == 1 || animationPhase == 2 {
                    Image("example-person")  // Replace with your example person image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.accentColor, lineWidth: 1))
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        .scaleEffect(animationPhase == 2 ? 0.9 : 1.0)
                        .modifier(ShakeEffect(animating: animationPhase == 2))
                }
                
                // Anime transformed image with glow effect
                if animationPhase == 3 {
                    Image("example-anime")  // Replace with your example anime transformation
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.accentColor, lineWidth: 1))
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        .scaleEffect(scale)
                        .transition(.scale)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.accentColor, lineWidth: 2)
                                .blur(radius: glowRadius)
                                .opacity(glowOpacity)
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.accentColor)
                                .blur(radius: glowRadius * 2)
                                .opacity(glowOpacity * 0.5)
                                .scaleEffect(1.05)
                        )
                }
            }
            .animation(.easeInOut(duration: 0.5), value: animationPhase)
            .padding(.horizontal)
            .confettiCannon(
                trigger: $confettiTrigger,
                num: 50,
                confettis: [.shape(.circle), .shape(.triangle), .shape(.square)],
                colors: [.blue, .green, .red, .yellow, .purple],
                openingAngle: Angle(degrees: 60),
                closingAngle: Angle(degrees: 120),
                radius: 200
            )
            
            // Example styles grid
            if animationPhase == 3 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        StyleExample(name: "Default", imageName: "anime-default-001")
                        StyleExample(name: "Shonen", imageName: "shonen-dynamic-005")
                        StyleExample(name: "One Piece", imageName: "onepiece-007")
                        StyleExample(name: "Naruto", imageName: "naruto-009")
                    }
                    .padding(.horizontal)
                }
                .frame(height: 120)
            }
            
            // Improved copywriting
            VStack(spacing: 16) {
                Text("Your Anime Journey Begins")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text("Experience the magic of AI-powered anime transformations with multiple unique styles to choose from.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .onAppear {
            startAnimation()
        }
    }
    
    func startAnimation() {
        // Reset animation
        animationPhase = 1
        scale = 1.0
        glowOpacity = 0.0
        glowRadius = 0.0
        
        // After 1 second, start shaking
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                animationPhase = 2
            }
            
            
            // After 2 seconds of shaking, show the clean image
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    animationPhase = 3
                    confettiTrigger += 1
                }
                
                // Success haptic
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                
                // Apply scale animation to the clean image
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                    scale = 1.2
                }
                
                // Animate the glow effect
                withAnimation(.easeIn(duration: 0.4)) {
                    glowOpacity = 0.8
                    glowRadius = 6
                }
                
                // Scale back to normal after a brief moment
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        scale = 1.0
                    }
                    
                    // Pulse the glow effect
                    animateGlowPulse()
                }
                
                // Restart the animation after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    // Fade out glow before restarting
                    withAnimation(.easeOut(duration: 0.3)) {
                        glowOpacity = 0.0
                        glowRadius = 0.0
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        startAnimation()
                    }
                }
            }
        }
    }
    
    func animateGlowPulse() {
        // Create a subtle pulsing glow effect
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            glowOpacity = 0.6
            glowRadius = 4
        }
    }
    
    
}

struct StyleExample: View {
    let name: String
    let imageName: String
    
    var body: some View {
        VStack {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            
            Text(name)
                .font(.caption)
                .foregroundColor(.white)
        }
    }
}

// Custom shake effect modifier
struct ShakeEffect: ViewModifier {
    var animating: Bool
    
    func body(content: Content) -> some View {
        content
            .offset(x: animating ? CGFloat(Int.random(in: -6...6)) : 0)
            .animation(
                animating ?
                .easeInOut(duration: 0.1)
                .repeatForever(autoreverses: true) :
                .default,
                value: animating
            )
    }
}
