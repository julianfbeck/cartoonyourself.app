import SwiftUI
import AVFoundation
import Photos

// MARK: - Models

/// Defines animation property types
enum AnimationType: String, Codable {
    case caption
    case filter
    case transition
}

/// Represents a single keyframe in an animation sequence
struct AnimationKeyframe: Identifiable {
    let id = UUID()
    var timestamp: Double
    var scale: CGFloat?
    var rotate: CGFloat?
    var opacity: CGFloat?
    var position: CGPoint?
    
    init(timestamp: Double, scale: CGFloat? = nil, rotate: CGFloat? = nil,
         opacity: CGFloat? = nil, position: CGPoint? = nil) {
        self.timestamp = timestamp
        self.scale = scale
        self.rotate = rotate
        self.opacity = opacity
        self.position = position
    }
}

/// Represents a complete animation layer with its properties and keyframes
struct AnimationLayer: Identifiable {
    let id = UUID()
    var type: AnimationType
    var image: UIImage
    var keyframes: [AnimationKeyframe]
    var timestamp: Double
    var duration: Double
    
    init(type: AnimationType, image: UIImage, keyframes: [AnimationKeyframe],
         timestamp: Double = 0, duration: Double? = nil) {
        self.type = type
        self.image = image
        self.keyframes = keyframes
        self.timestamp = timestamp
        
        // Calculate duration if not explicitly provided
        if let duration = duration {
            self.duration = duration
        } else if let lastKeyframe = keyframes.max(by: { $0.timestamp < $1.timestamp }) {
            self.duration = lastKeyframe.timestamp
        } else {
            self.duration = 0
        }
    }
}

/// Represents a complete animation project
class PhotoAnimationProject: ObservableObject {
    @Published var layers: [AnimationLayer] = []
    @Published var duration: Double = 0
    @Published var size: CGSize = CGSize(width: 1080, height: 1920) // Default to portrait 1080p
    
    func addLayer(_ layer: AnimationLayer) {
        layers.append(layer)
        updateDuration()
    }
    
    func updateDuration() {
        // Total duration is determined by the latest ending layer
        duration = layers.map { $0.timestamp + $0.duration }.max() ?? 0
    }
}

// MARK: - Animation Helpers

/// Helper to calculate interpolated values for animations
struct KeyframeInterpolator {
    let layer: AnimationLayer
    
    /// Interpolate between keyframes to get the current scale value
    func interpolatedScale(at time: Double) -> CGFloat {
        return interpolateValue(at: time, keyPath: \.scale) ?? 1.0
    }
    
    /// Interpolate between keyframes to get the current rotation value
    func interpolatedRotation(at time: Double) -> CGFloat {
        return interpolateValue(at: time, keyPath: \.rotate) ?? 0.0
    }
    
    /// Interpolate between keyframes to get the current opacity value
    func interpolatedOpacity(at time: Double) -> CGFloat {
        return interpolateValue(at: time, keyPath: \.opacity) ?? 1.0
    }
    
    /// Interpolate between keyframes to get the current position
    func interpolatedPosition(at time: Double) -> CGPoint {
        let x = interpolateValueForPoint(at: time, keyPath: \.position, component: \.x) ?? 0
        let y = interpolateValueForPoint(at: time, keyPath: \.position, component: \.y) ?? 0
        return CGPoint(x: x, y: y)
    }
    
    /// Generic interpolation function for optional CGFloat keyframe values
    private func interpolateValue<T>(at time: Double, keyPath: KeyPath<AnimationKeyframe, T?>) -> CGFloat? {
        // Filter keyframes to find those before and after the current time
        let sortedKeyframes = layer.keyframes.sorted { $0.timestamp < $1.timestamp }
        
        guard !sortedKeyframes.isEmpty else { return nil }
        
        // Find the nearest keyframes before and after current time
        let beforeKeyframes = sortedKeyframes.filter { $0.timestamp <= time }
        let afterKeyframes = sortedKeyframes.filter { $0.timestamp > time }
        
        guard let beforeKeyframe = beforeKeyframes.last else {
            // If no keyframe before current time, use the first keyframe
            return sortedKeyframes.first?[keyPath: keyPath] as? CGFloat
        }
        
        let beforeValue = beforeKeyframe[keyPath: keyPath] as? CGFloat
        
        guard let afterKeyframe = afterKeyframes.first,
              let afterValue = afterKeyframe[keyPath: keyPath] as? CGFloat,
              let beforeValue = beforeValue else {
            // If no keyframe after current time or values missing, return the before value
            return beforeValue
        }
        
        // Interpolate between before and after keyframes
        let progress = (time - beforeKeyframe.timestamp) / (afterKeyframe.timestamp - beforeKeyframe.timestamp)
        return beforeValue + (afterValue - beforeValue) * CGFloat(progress)
    }
    
    /// Specialized interpolation for CGPoint components
    private func interpolateValueForPoint(at time: Double, keyPath: KeyPath<AnimationKeyframe, CGPoint?>, component: KeyPath<CGPoint, CGFloat>) -> CGFloat? {
        let sortedKeyframes = layer.keyframes.sorted { $0.timestamp < $1.timestamp }
        
        guard !sortedKeyframes.isEmpty else { return nil }
        
        let beforeKeyframes = sortedKeyframes.filter { $0.timestamp <= time }
        let afterKeyframes = sortedKeyframes.filter { $0.timestamp > time }
        
        guard let beforeKeyframe = beforeKeyframes.last,
              let beforePoint = beforeKeyframe[keyPath: keyPath] else {
            return sortedKeyframes.first?[keyPath: keyPath]?[keyPath: component]
        }
        
        let beforeValue = beforePoint[keyPath: component]
        
        guard let afterKeyframe = afterKeyframes.first,
              let afterPoint = afterKeyframe[keyPath: keyPath] else {
            return beforeValue
        }
        
        let afterValue = afterPoint[keyPath: component]
        
        let progress = (time - beforeKeyframe.timestamp) / (afterKeyframe.timestamp - beforeKeyframe.timestamp)
        return beforeValue + (afterValue - beforeValue) * CGFloat(progress)
    }
}

// MARK: - Views

/// Main view for editing and previewing the animation
struct PhotoAnimationView: View {
    @ObservedObject var project: PhotoAnimationProject
    @State private var currentTime: Double = 0
    @State private var isPlaying: Bool = false
    private let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect() // ~60fps
    
    var body: some View {
        VStack {
            // Animation preview
            ZStack {
                Color.black
                
                // Render each animation layer
                ForEach(project.layers) { layer in
                    if isLayerVisible(layer) {
                        AnimationLayerView(layer: layer, currentTime: currentTime)
                    }
                }
            }
            .aspectRatio(project.size.width / project.size.height, contentMode: .fit)
            .clipped()
            
            // Playback controls
            HStack {
                Button(action: {
                    isPlaying.toggle()
                }) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                }
                
                Slider(value: $currentTime, in: 0...max(project.duration, 1))
                    .onChange(of: currentTime) { _, newValue in
                        // If we're at the end, stop playback
                        if newValue >= project.duration {
                            isPlaying = false
                        }
                    }
                
                Text(String(format: "%.1fs", currentTime))
            }
            .padding()
            
            // Export button
            Button("Export MP4") {
                exportAnimation()
            }
            .padding()
        }
        .onReceive(timer) { _ in
            if isPlaying {
                currentTime += 0.016
                if currentTime >= project.duration {
                    currentTime = 0
                }
            }
        }
    }
    
    /// Determines if a layer should be visible at the current time
    private func isLayerVisible(_ layer: AnimationLayer) -> Bool {
        return currentTime >= layer.timestamp && currentTime <= (layer.timestamp + layer.duration)
    }
    
    /// Export the animation as an MP4 file
    private func exportAnimation() {
        // Create a video exporter instance
        let exporter = VideoExporter(project: project)
        
        // Start export process
        exporter.export { result in
            switch result {
            case .success(let url):
                print("Animation exported successfully to: \(url.path)")
                // Save to photo library
                PHPhotoLibrary.requestAuthorization { status in
                    if status == .authorized {
                        PHPhotoLibrary.shared().performChanges {
                            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                        } completionHandler: { success, error in
                            if success {
                                print("Video saved to photo library")
                            } else if let error = error {
                                print("Error saving to photo library: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            case .failure(let error):
                print("Export failed: \(error.localizedDescription)")
            }
        }
    }
}

/// View that renders a single animation layer with its current properties
struct AnimationLayerView: View {
    let layer: AnimationLayer
    let currentTime: Double
    
    var body: some View {
        let relativeTime = max(0, currentTime - layer.timestamp)
        let interpolator = KeyframeInterpolator(layer: layer)
        
        let scale = interpolator.interpolatedScale(at: relativeTime)
        let rotation = interpolator.interpolatedRotation(at: relativeTime)
        let opacity = interpolator.interpolatedOpacity(at: relativeTime)
        let position = interpolator.interpolatedPosition(at: relativeTime)
        
        return Image(uiImage: layer.image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .scaleEffect(scale)
            .rotationEffect(.degrees(Double(rotation)))
            .opacity(Double(opacity))
            .offset(x: position.x, y: position.y)
    }
}

// MARK: - Video Export

/// Error types for video export
enum VideoExportError: Error {
    case failedToCreatePixelBuffer
    case failedToStartSession
    case failedToAddFrame
    case failedToFinishWriting
}

/// Class that handles exporting animations to MP4 video files
class VideoExporter {
    private let project: PhotoAnimationProject
    private let frameRate: Int32 = 60
    
    init(project: PhotoAnimationProject) {
        self.project = project
    }
    
    /// Export the animation as an MP4 file
    func export(completion: @escaping (Result<URL, Error>) -> Void) {
        // Create a temporary file URL for the video
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("animation_\(Date().timeIntervalSince1970).mp4")
        
        // Set up the video writer
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: project.size.width,
            AVVideoHeightKey: project.size.height
        ]
        
        guard let videoWriter = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
            completion(.failure(VideoExportError.failedToStartSession))
            return
        }
        
        let videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoWriterInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                kCVPixelBufferWidthKey as String: project.size.width,
                kCVPixelBufferHeightKey as String: project.size.height
            ]
        )
        
        videoWriterInput.expectsMediaDataInRealTime = true
        videoWriter.add(videoWriterInput)
        
        // Start the writing session
        guard videoWriter.startWriting() else {
            completion(.failure(VideoExportError.failedToStartSession))
            return
        }
        
        videoWriter.startSession(atSourceTime: .zero)
        
        // Calculate total frames
        let totalFrames = Int(project.duration * Double(frameRate))
        var frameCount = 0
        
        // Render and add each frame
        let renderQueue = DispatchQueue(label: "com.animation.renderQueue")
        videoWriterInput.requestMediaDataWhenReady(on: renderQueue) {
            while videoWriterInput.isReadyForMoreMediaData && frameCount < totalFrames {
                let time = Double(frameCount) / Double(self.frameRate)
                
                // Create the frame renderer
                let renderer = FrameRenderer(project: self.project, time: time)
                guard let pixelBuffer = renderer.renderFrame() else {
                    videoWriter.cancelWriting()
                    completion(.failure(VideoExportError.failedToCreatePixelBuffer))
                    return
                }
                
                // Add the frame to the video
                let presentationTime = CMTime(seconds: time, preferredTimescale: self.frameRate)
                if !pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime) {
                    videoWriter.cancelWriting()
                    completion(.failure(VideoExportError.failedToAddFrame))
                    return
                }
                
                frameCount += 1
            }
            
            // Finish writing if all frames have been processed
            if frameCount >= totalFrames {
                videoWriterInput.markAsFinished()
                videoWriter.finishWriting {
                    if videoWriter.status == .completed {
                        completion(.success(outputURL))
                    } else {
                        completion(.failure(VideoExportError.failedToFinishWriting))
                    }
                }
            }
        }
    }
}

/// Renders individual frames for video export
class FrameRenderer {
    let project: PhotoAnimationProject
    let time: Double
    
    init(project: PhotoAnimationProject, time: Double) {
        self.project = project
        self.time = time
    }
    
    /// Render a single frame to a pixel buffer
    func renderFrame() -> CVPixelBuffer? {
        // Create a context to render the frame
        UIGraphicsBeginImageContextWithOptions(project.size, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Fill background with black
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(origin: .zero, size: project.size))
        
        // Render each visible layer
        for layer in project.layers.filter({ time >= $0.timestamp && time <= ($0.timestamp + $0.duration) }) {
            let relativeTime = time - layer.timestamp
            
            // Create a temporary view to render the layer
            let layerView = UIView(frame: CGRect(origin: .zero, size: project.size))
            let imageView = UIImageView(image: layer.image)
            imageView.contentMode = .scaleAspectFit
            imageView.frame = layerView.bounds
            
            // Apply transformations based on keyframes
            let interpolator = KeyframeInterpolator(layer: layer)
            
            // Apply scale
            let scale = interpolator.interpolatedScale(at: relativeTime)
            imageView.transform = imageView.transform.scaledBy(x: scale, y: scale)
            
            // Apply rotation
            let rotation = interpolator.interpolatedRotation(at: relativeTime)
            imageView.transform = imageView.transform.rotated(by: CGFloat(rotation) * .pi / 180)
            
            // Apply opacity
            imageView.alpha = interpolator.interpolatedOpacity(at: relativeTime)
            
            // Apply position
            let position = interpolator.interpolatedPosition(at: relativeTime)
            imageView.center = CGPoint(
                x: layerView.bounds.midX + position.x,
                y: layerView.bounds.midY + position.y
            )
            
            layerView.addSubview(imageView)
            layerView.drawHierarchy(in: layerView.bounds, afterScreenUpdates: true)
        }
        
        // Convert the context to a pixel buffer
        guard let image = UIGraphicsGetImageFromCurrentImageContext(),
              let pixelBuffer = createPixelBuffer(from: image) else {
            return nil
        }
        
        return pixelBuffer
    }
    
    /// Convert a UIImage to a CVPixelBuffer
    private func createPixelBuffer(from image: UIImage) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        
        let width = Int(project.size.width)
        let height = Int(project.size.height)
        
        CVPixelBufferCreate(kCFAllocatorDefault,
                           width,
                           height,
                           kCVPixelFormatType_32ARGB,
                           attrs,
                           &pixelBuffer)
        
        if let pixelBuffer = pixelBuffer {
            CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
            let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
            
            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
            guard let context = CGContext(data: pixelData,
                                         width: width,
                                         height: height,
                                         bitsPerComponent: 8,
                                         bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                         space: rgbColorSpace,
                                         bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
                return nil
            }
            
            context.translateBy(x: 0, y: CGFloat(height))
            context.scaleBy(x: 1.0, y: -1.0)
            
            UIGraphicsPushContext(context)
            image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
            UIGraphicsPopContext()
            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
            
            return pixelBuffer
        }
        
        return nil
    }
}

// MARK: - Example Usage

/// Example of how to use the animation system
struct PhotoPresentationView: View {
    @StateObject private var project = PhotoAnimationProject()
    
    var body: some View {
        PhotoAnimationView(project: project)
            .onAppear {
                setupAnimation()
            }
    }
    
    // Set up an example animation similar to the original code
    private func setupAnimation() {
        // Load example images - Using optional binding correctly
        guard let originalPhoto = UIImage(named: "examplePhoto") else {
            print("Failed to load original photo")
            return
        }
        
        let processedPhoto = UIImage(named: "exampleProcessedPhoto") ?? originalPhoto
        
        // First layer with original photo
        let firstLayer = AnimationLayer(
            type: .caption,
            image: originalPhoto,
            keyframes: [
                AnimationKeyframe(timestamp: 0, scale: 1.1),
                AnimationKeyframe(timestamp: 10, scale: 0.9, rotate: 10),
                AnimationKeyframe(timestamp: 55, scale: 0.9, rotate: 10),
                AnimationKeyframe(timestamp: 55 + 4, scale: 1.3)
            ],
            timestamp: 0,
            duration: 55 + 4
        )
        
        // Second layer with processed photo - Parameter ordering fixed
        let secondLayer = AnimationLayer(
            type: .caption,
            image: processedPhoto,
            keyframes: [
                AnimationKeyframe(timestamp: 0, scale: 0.8, rotate: 10, opacity: 0),
                AnimationKeyframe(timestamp: 4, scale: 1.3)
            ],
            timestamp: 0
        )
        
        // Add layers to project
        project.addLayer(firstLayer)
        project.addLayer(secondLayer)
    }
}

// MARK: - Preview Example
struct AnimationPreviewExample: View {
    // Create a state object to hold our animation project
    @StateObject private var project = PhotoAnimationProject()
    
    var body: some View {
        VStack(spacing: 16) {
            // Title for our demo
            Text("Photo Animation Demo")
                .font(.title)
                .padding(.top)
            
            // The main animation view that displays our project
            PhotoAnimationView(project: project)
                .frame(height: 400)
                .background(Color.black.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal)
            
            // Information about the animation
            VStack(alignment: .leading, spacing: 8) {
                Text("Animation Details:")
                    .font(.headline)
                
                Text("• Duration: \(String(format: "%.1f", project.duration)) seconds")
                Text("• Layers: \(project.layers.count)")
                Text("• Effects: Scale, Rotation, Opacity")
                
                Text("Tap Export to save as MP4")
                    .fontWeight(.medium)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            
            Spacer()
        }
        .onAppear {
            // Set up our animation when the view appears
            setupDemo()
        }
    }
    
    // Set up a sample animation with multiple layers and effects
    private func setupDemo() {
        // Create sample images using SF Symbols
        // In a real app, you would load your own images
        let originalImage = createImage(systemName: "photo", size: CGSize(width: 200, height: 200))
        let processedImage = createImage(systemName: "photo.fill", size: CGSize(width: 200, height: 200))
        let overlayImage = createImage(systemName: "sparkles", size: CGSize(width: 100, height: 100))
        
        // First layer - Main photo that scales and rotates
        let mainLayer = AnimationLayer(
            type: .caption,
            image: originalImage,
            keyframes: [
                // Start slightly larger
                AnimationKeyframe(timestamp: 0, scale: 1.1),
                
                // Shrink and rotate after 1 second
                AnimationKeyframe(timestamp: 1, scale: 0.9, rotate: 10),
                
                // Hold this position for a few seconds
                AnimationKeyframe(timestamp: 3, scale: 0.9, rotate: 10),
                
                // Grow larger at the end
                AnimationKeyframe(timestamp: 4, scale: 1.2)
            ],
            timestamp: 0,
            duration: 5
        )
        
        // Second layer - Processed version that fades in
        let processedLayer = AnimationLayer(
            type: .filter,
            image: processedImage,
            keyframes: [
                // Start invisible
                AnimationKeyframe(timestamp: 0, scale: 0.8, opacity: 0),
                
                // Fade in and grow over 1 second
                AnimationKeyframe(timestamp: 1.5, scale: 1.0, opacity: 0.8),
                
                // Remain visible until the end
                AnimationKeyframe(timestamp: 4, scale: 1.0, opacity: 0.8)
            ],
            timestamp: 0,
            duration: 5
        )
        
        // Third layer - Decorative overlay that moves across the image
        let overlayLayer = AnimationLayer(
            type: .transition,
            image: overlayImage,
            keyframes: [
                // Start in top-left, fully transparent
                AnimationKeyframe(
                    timestamp: 0,
                    scale: 0.5,
                    rotate: 0,
                    opacity: 0,
                    position: CGPoint(x: -50, y: -50)
                ),
                
                // Move to center, become visible
                AnimationKeyframe(
                    timestamp: 2,
                    scale: 1.0,
                    rotate: 45,
                    opacity: 1,
                    position: CGPoint(x: 0, y: 0)
                ),
                
                // Move to bottom-right, spinning
                AnimationKeyframe(
                    timestamp: 4,
                    scale: 0.5,
                    rotate: 90,
                    opacity: 0,
                    position: CGPoint(x: 50, y: 50)
                )
            ],
            timestamp: 0,
            duration: 5
        )
        
        // Add all layers to our project
        project.addLayer(mainLayer)
        project.addLayer(processedLayer)
        project.addLayer(overlayLayer)
    }
    
    // Helper function to create images from SF Symbols for our demo
    private func createImage(systemName: String, size: CGSize) -> UIImage {
        let config = UIImage.SymbolConfiguration(pointSize: size.width * 0.5, weight: .regular)
        let symbolImage = UIImage(systemName: systemName, withConfiguration: config)
        
        // Render the symbol at the desired size
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        // Fill with a light background
        UIColor.systemGray6.setFill()
        UIBezierPath(rect: CGRect(origin: .zero, size: size)).fill()
        
        // Center the symbol in the image
        if let image = symbolImage {
            let rect = CGRect(
                x: (size.width - image.size.width) / 2,
                y: (size.height - image.size.height) / 2,
                width: image.size.width,
                height: image.size.height
            )
            image.draw(in: rect)
        }
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
}

// MARK: - SwiftUI Preview
struct AnimationPreviewExample_Previews: PreviewProvider {
    static var previews: some View {
        AnimationPreviewExample()
    }
}
