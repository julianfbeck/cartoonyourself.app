import SwiftUI
import Foundation

struct SharePreviewView: View {
    @Environment(\.dismiss) private var dismiss
    let processedImage: UIImage
    @StateObject private var viewModel = SharePreviewModel()
    @State private var shareImage: UIImage?
    @State private var showShareSheet = false
    @State private var showSavedNotification = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("Share Your Creation")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Empty view for symmetry
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.clear)
                }
                .padding(.horizontal)
                
                // Preview image
                if let shareImage = shareImage {
                    Image(uiImage: shareImage)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal)
                } else {
                    ProgressView()
                        .scaleEffect(2)
                        .tint(.white)
                        .frame(height: 300)
                }
                
                // Action buttons
                HStack(spacing: 15) {
                    // Save button
                    Button {
                        if let image = shareImage {
                            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                            // Add feedback and track the save action
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                            viewModel.trackImageSaved()
                            
                            // Show saved notification
                            withAnimation {
                                showSavedNotification = true
                            }
                            
                            // Hide the notification after 2 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    showSavedNotification = false
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Save to Photos")
                        }
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.accentColor)
                        )
                        .foregroundColor(.white)
                    }
                    .disabled(shareImage == nil)
                    .opacity(shareImage == nil ? 0.6 : 1)
                    
                    // Share button
                    Button {
                        showShareSheet = true
                        viewModel.trackImageShared()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.white.opacity(0.2))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                        )
                        .foregroundColor(.white)
                    }
                    .disabled(shareImage == nil)
                    .opacity(shareImage == nil ? 0.6 : 1)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                Spacer()
            }
            .padding(.top, 20)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color.black.opacity(0.9),
                        Color.accentColor.opacity(0.6)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            
            // Saved notification
            if showSavedNotification {
                VStack {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 20))
                        
                        Text("Saved to Photos")
                            .font(.system(.body, design: .rounded, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.8))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(radius: 5)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1)
                .padding(.top, 50)
            }
        }
        .onAppear {
            // Generate the share image when the view appears
            DispatchQueue.main.async {
                self.shareImage = viewModel.generateSharePreview(originalImage: processedImage)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheet(items: [image])
            }
        }
    }
}

#Preview {
    SharePreviewView(processedImage: UIImage(systemName: "photo")!)
}