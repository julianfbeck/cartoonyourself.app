import SwiftUI
import CoreHaptics

#Preview("Continuous Random Ripple") {
    ContinuousRippleImageView()
}

struct ContinuousRippleImageView: View {
    @State private var origin: CGPoint = .zero
    @State private var counter: Int = 0
    @State private var timer: Timer? = nil
    
    // Bounds for random ripple generation
    @State private var viewBounds: CGRect = .zero
    
    // Haptic engine
    @State private var hapticEngine: CHHapticEngine?
    
    var body: some View {
        VStack {
            Spacer()
            
            Image("example")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .modifier(RippleEffect(at: origin, trigger: counter))
                .shadow(radius: 3, y: 2)
                .background(GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            // Store the view bounds for random point generation
                            viewBounds = geometry.frame(in: .local)
                            // Start the continuous ripple timer
                            startContinuousRipple()
                            // Initialize haptic engine
                            prepareHaptics()
                        }
                })
            
            Spacer()
        }
        .padding()
        .onDisappear {
            // Clean up the timer when view disappears
            timer?.invalidate()
            timer = nil
        }
    }
    
    // Function to create ripples at random positions
    private func startContinuousRipple() {
        // Cancel any existing timer
        timer?.invalidate()
        
        // Create a new timer that triggers ripples randomly
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            // Generate random position within the view bounds
            let randomX = CGFloat.random(in: viewBounds.minX...viewBounds.maxX)
            let randomY = CGFloat.random(in: viewBounds.minY...viewBounds.maxY)
            
            // Update origin and counter to trigger new ripple
            origin = CGPoint(x: randomX, y: randomY)
            counter += 1
            
            // Play haptic feedback for each ripple
            playHapticFeedback()
        }
    }
    
    // Initialize the haptic engine
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
            
            // The engine may stop when the app goes to the background, so restart it here
            hapticEngine?.resetHandler = { [ self] in
                do {
                    try self.hapticEngine?.start()
                } catch {
                    print("Failed to restart haptic engine: \(error)")
                }
            }
            
            // If the app goes to background, the engine stops automatically
            hapticEngine?.stoppedHandler = { reason in
                print("Haptic engine stopped for reason: \(reason.rawValue)")
            }
            
        } catch {
            print("Failed to prepare haptic engine: \(error)")
        }
    }
    
    // Play haptic feedback
    private func playHapticFeedback() {
        // If device doesn't support haptics, use UIFeedbackGenerator
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            return
        }
        
        // For devices that support advanced haptics, create a custom pattern
        guard let engine = hapticEngine else { return }
        
        do {
            // Create a pattern of haptic events
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
            
            // Create a gentle water ripple feel with a quick fade
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0, duration: 0.1)
            
            // Create a pattern from the event
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            
            // Create a player from the pattern
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play haptic pattern: \(error)")
        }
    }
}
