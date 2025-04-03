import SwiftUI
import os.log
import Foundation

extension UIImage: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .png) { image in
            if let data = image.pngData() {
                return data
            } else {
                throw TransferError.conversionFailed
            }
        } importing: { data in
            guard let image = UIImage(data: data) else {
                throw TransferError.importFailed
            }
            return image
        }
    }
}

enum TransferError: Error {
    case conversionFailed
    case importFailed
}

@MainActor
class SharePreviewModel: ObservableObject {
    @Published var generatedShareImage: UIImage?
    
    func generateSharePreview(originalImage: UIImage) -> UIImage? {
        // Create the share preview content
        let content = SharePreviewContent(processedImage: originalImage)
        
        // Render the SwiftUI view to an image
        let renderer = ImageRenderer(content: content)
        renderer.scale = UIScreen.main.scale
        
        // Track that a share image was generated
        Plausible.shared.trackEvent(
            event: "share_image_generated",
            path: "/share/preview_generated"
        )
        
        // Return the rendered image
        return renderer.uiImage
    }
    
    func trackImageSaved() {
        Plausible.shared.trackEvent(
            event: "share_image_saved",
            path: "/share/image_saved"
        )
    }
    
    func trackImageShared() {
        Plausible.shared.trackEvent(
            event: "share_image_shared",
            path: "/share/image_shared"
        )
    }
}

// SwiftUI view that will be converted to an image for sharing
struct SharePreviewContent: View {
    let processedImage: UIImage
    
    var body: some View {
        VStack(spacing: 24) {
            // App Header with Logo
            HStack {
                // App icon with fallback
                Group {
                    if let _ = UIImage(named: "AppIconImage") {
                        Image("AppIconImage")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 4)
                    } else {
                        // Fallback icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 32/255, green: 212/255, blue: 177/255),
                                            Color(red: 32/255, green: 168/255, blue: 217/255)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                                .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 4)
                            
                            Text("A")
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("Anify")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Anime Yourself")
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
            }
            .padding(.top, 20)
            .padding(.horizontal, 20)
            
            // Generated image
            Image(uiImage: processedImage)
                .resizable()
                .scaledToFit()
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                )
                .shadow(radius: 10, x: 0, y: 5)
                .padding(.horizontal, 20)
                // Set a maximum width equal to the screen width minus padding
                .frame(maxWidth: UIScreen.main.bounds.width - 40)
                // Limit maximum height to be reasonable
                .frame(maxHeight: UIScreen.main.bounds.width)
            
            // Watermark/Footer
            HStack {
                Spacer()
                Text("Created with Anify • juli.sh/anify")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        // Instead of fixed aspect ratio, use fit content size with minimum width
        .frame(width: UIScreen.main.bounds.width)
        // Add padding to ensure everything has proper spacing
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color.black.opacity(0.9),
                    Color.accentColor.opacity(0.7)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
} 