//
//  AnimeYourselfView.swift
//  animeyourself
//
//  Created by Julian Beck on 30.03.25.
//


import SwiftUI
import PhotosUI
import Vision

struct AnimeYourselfView: View {
    @StateObject private var model = AnimeViewModel()
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showImagePicker = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    
    // List of anime styles matching the IDs in the AnimeViewModel
    let animeStyles = [
        "anime-default-001",
//        "ghibli-inspired-002",
//        "cyberpunk-anime-003",
//        "chibi-kawaii-004",
        "shonen-dynamic-005",
//        "shoujo-soft-006",
        "onepiece-007",
        "dragonball-008",
        "naruto-009",
//        "titan-dark-010"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Main content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        headerView
                        imageSelectionView
                        
                        if model.isProcessing {
                            processingView
                        }
                        
                        // Add a programmatic navigation link
                        NavigationLink(destination: ResultView().environmentObject(model), isActive: $model.navigateToResult) {
                            EmptyView()
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 40) // Increased top padding since we're hiding the nav bar
                }
            }
            // Remove navigation title and hide the navigation bar
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if model.selectedImage != nil {
                        Button(action: {
                            model.clearImages()
                            photoPickerItem = nil
                        }) {
                            Text("Clear")
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .alert("Success!", isPresented: $showSuccessAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your anime portrait has been saved to the photo library")
                    .font(.system(.body, design: .rounded))
            }
            .alert("Person Detection Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(model.errorMessage ?? "No person detected in the image. This model only works with photos containing people.")
                    .font(.system(.body, design: .rounded))
            }
            .photosPicker(isPresented: $showImagePicker, selection: $photoPickerItem, matching: .images)
            .onChange(of: photoPickerItem) { newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        // Check if the image contains a person
                        let personDetected = await detectPerson(in: uiImage)
                        
                        await MainActor.run {
                            if personDetected {
                                model.selectedImage = uiImage
                                model.errorMessage = nil
                            } else {
                                model.errorMessage = "No person detected in the image. This model only works with photos containing people."
                                showErrorAlert = true
                                photoPickerItem = nil
                            }
                        }
                    }
                }
            }
            .onChange(of: model.navigateToResult) { navigating in
                if navigating {
                    // We'll reset the photoPickerItem after navigation completes
                    // This allows selection of a new image next time
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        photoPickerItem = nil
                    }
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            Text("Anime Yourself")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundColor(.white)
            
            Text("Transform your photos into stunning anime art")
                .font(.system(.subheadline, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.85))
        }
        .padding(.vertical, 10)
    }
    
    private var imageSelectionView: some View {
        VStack(spacing: 16) {
            if let selectedImage = model.selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(16)
                    .shadow(radius: 8, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                    )
                
                Text("Original Image")
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                
                // Show anime style selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose Anime Style:")
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(animeStyles, id: \.self) { style in
                                animeStyleButton(style)
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                    }
                }
                .padding(.top, 8)
                
                if let _ = model.processedImage {
                    // Display Transform and New Image buttons
                    HStack(spacing: 15) {
                        Button {
                            if !self.globalViewModel.isPro && globalViewModel.remainingUses <= 0 {
                               self.globalViewModel.isShowingPayWall = true
                                return
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                if !globalViewModel.isPro {
                                    globalViewModel.isShowingPayWall = true
                                }
                            }
                                
                            if let image = model.selectedImage {
                                model.processImage(image, style: model.selectedStyle)
                                globalViewModel.useFeature()
                                model.navigateToResult = true
                                
                                // Reset photoPickerItem after a slight delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    photoPickerItem = nil
                                }
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: globalViewModel.remainingUses > 0 || globalViewModel.isPro ? "wand.and.stars":"checkmark.seal")
                                    .font(.system(size: 18))
                                Text(globalViewModel.remainingUses > 0 || globalViewModel.isPro ? "Transform" : "Unlock")
                                    .font(.system(.body, design: .rounded, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color.accentColor)
                            )
                            .foregroundColor(.white)
                        }
                        .shadow(radius: 4, x: 0, y: 2)
                        
                        Button {
                            model.clearImages()
                            photoPickerItem = nil
                            showImagePicker = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "photo")
                                    .font(.system(size: 18))
                                Text("New Image")
                                    .font(.system(.body, design: .rounded, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color.black.opacity(0.4))
                            )
                            .foregroundColor(.white)
                        }
                        .shadow(radius: 4, x: 0, y: 2)
                    }
                    .padding(.top, 20)
                    
                    // View Result button below
                    NavigationLink(destination: ResultView().environmentObject(model)) {
                        HStack(spacing: 10) {
                            Image(systemName: "eye")
                                .font(.system(size: 18))
                            Text("View Result")
                                .font(.system(.body, design: .rounded, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.accentColor)
                        )
                        .foregroundColor(.white)
                    }
                    .shadow(radius: 4, x: 0, y: 2)
                    .padding(.top, 12)
                } else {
                    // Transform and New Image buttons
                    HStack(spacing: 15) {
                        Button {
                            if !self.globalViewModel.isPro && globalViewModel.remainingUses <= 0 {
                               self.globalViewModel.isShowingPayWall = true
                                return
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                if !globalViewModel.isPro {
                                    globalViewModel.isShowingPayWall = true
                                }
                            }
                                
                            if let image = model.selectedImage {
                                model.processImage(image, style: model.selectedStyle)
                                globalViewModel.useFeature()
                                model.navigateToResult = true
                                
                                // Reset photoPickerItem after a slight delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    photoPickerItem = nil
                                }
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: globalViewModel.remainingUses > 0 || globalViewModel.isPro ? "wand.and.stars":"checkmark.seal")
                                    .font(.system(size: 18))
                                Text(globalViewModel.remainingUses > 0 || globalViewModel.isPro ? "Transform" : "Unlock")
                                    .font(.system(.body, design: .rounded, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color.accentColor)
                            )
                            .foregroundColor(.white)
                        }
                        .shadow(radius: 4, x: 0, y: 2)
                        
                        Button {
                            model.clearImages()
                            photoPickerItem = nil
                            showImagePicker = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "photo")
                                    .font(.system(size: 18))
                                Text("New Image")
                                    .font(.system(.body, design: .rounded, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color.black.opacity(0.4))
                            )
                            // add accetn border
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.accentColor, lineWidth: 1)
                            )
                            .foregroundColor(.white)
                        }
                        .shadow(radius: 4, x: 0, y: 2)
                    }
                    .padding(.top, 12)
                }
            } else {
                VStack(spacing: 20) {
                    selectImageButton
                    
                    // Show only the first feature card
                    VStack(spacing: 16) {
                        Text("Turn Yourself Into Anime")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 8)
                        
                        // Only the first feature card
                        featureCard(
                            icon: "person.crop.rectangle.stack",
                            title: "Anime Transformation",
                            description: "Convert your selfies into stunning anime portraits"
                        )
                    }
                    
                    // Show anime style selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choose Anime Style:")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(animeStyles, id: \.self) { style in
                                    animeStyleButton(style)
                                }
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.5))
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                )
                .shadow(radius: 8, x: 0, y: 4)
        )
    }
    
    private func animeStyleButton(_ style: String) -> some View {
        Button {
            if style == animeStyles[0] || globalViewModel.isPro {
                model.selectedStyle = style
            } else {
                globalViewModel.isShowingPayWall = true
            }
        } label: {
            ZStack {
                Image(style.lowercased())
                    .resizable()
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .frame(width: 100, height: 110)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(model.selectedStyle == style ? Color.white : Color.red.opacity(0.2), lineWidth: 2)
                    )
                    .shadow(radius: model.selectedStyle == style ? 5 : 0)
                
                if style != animeStyles[0] && !globalViewModel.isPro {
                    ZStack {
                        Color.black.opacity(0.6)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                    .cornerRadius(12)
                }
            }
        }
    }
    
    private var selectImageButton: some View {
        Button {
            showImagePicker = true
        } label: {
            VStack(spacing: 16) {
                Image(systemName: "photo.stack")
                    .font(.system(size: 42))
                    .foregroundColor(.white)
                Text("Select Photo")
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.accentColor, 
                                Color.accentColor.opacity(0.7)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
            )
            .shadow(radius: 8, x: 0, y: 4)
            .overlay(
                VStack {
                    HStack(alignment: .center, spacing: 8) {
                        Text("Tap to Begin")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundColor(.white)
                        
                        Image(systemName: "arrow.down")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.6))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(radius: 4)
                    .offset(y: -20)
                    
                    Spacer()
                }
            )
        }
    }
    
    // New feature cards view
    private var featureCardsView: some View {
        VStack(spacing: 16) {
            Text("Turn Yourself Into Anime")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 8)
            
            // Feature cards
            featureCard(
                icon: "person.crop.rectangle.stack",
                title: "Anime Transformation",
                description: "Convert your selfies into stunning anime portraits"
            )
            
            featureCard(
                icon: "paintpalette",
                title: "Multiple Styles",
                description: "Choose from various popular anime art styles"
            )
            
            featureCard(
                icon: "arrow.triangle.2.circlepath",
                title: "Instant Results",
                description: "Get high-quality anime transformations in seconds"
            )
            
            // Inspirational message at the bottom
            VStack(spacing: 10) {
                Text("Ready to see yourself in anime?")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Select a photo above to begin your transformation")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                
                Image(systemName: "arrow.up")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.accentColor)
                    .padding(.top, 5)
            }
            .padding(.vertical, 20)
        }
    }
    
    private func featureCard(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.accentColor,
                                    Color.purple
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: Color.accentColor.opacity(0.5), radius: 5, x: 0, y: 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.5),
                            Color.black.opacity(0.3)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
    }
    
    // Replace processingView with empty view since we don't need it anymore
    private var processingView: some View {
        EmptyView()
    }
    
    // Person detection function
    private func detectPerson(in image: UIImage) async -> Bool {
        guard let cgImage = image.cgImage else { return false }
        
        let request = VNDetectHumanRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            
            if let results = request.results, !results.isEmpty {
                return true
            } else {
                // Try face detection as a fallback
                return await detectFace(in: image)
            }
        } catch {
            print("Person detection failed: \(error.localizedDescription)")
            // Try face detection as a fallback
            return await detectFace(in: image)
        }
    }
    
    // Face detection as a fallback
    private func detectFace(in image: UIImage) async -> Bool {
        guard let cgImage = image.cgImage else { return false }
        
        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            
            if let results = request.results, !results.isEmpty {
                return true
            } else {
                return false
            }
        } catch {
            print("Face detection failed: \(error.localizedDescription)")
            return false
        }
    }
}
