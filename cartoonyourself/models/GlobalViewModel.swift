//
//  GlobalViewModel.swift
//  watermarkremover
//
//  Created by Julian Beck on 23.03.25.
//

import Foundation
import RevenueCat

class GlobalViewModel: ObservableObject {
    @Published var offering: Offering?
    @Published var customerInfo: CustomerInfo?
    @Published var isPurchasing = false
    @Published var errorMessage: String?
    @Published var isShowingPayWall = false
    @Published var isShowingOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(!isShowingOnboarding, forKey: "hasSeenOnboarding")
        }
    }
    @Published var isShowingRatings = false
  
    @Published var isPro: Bool {
        didSet {
            UserDefaults.standard.set(isPro, forKey: "isPro")
        }
    }
    
    // Persistent total usage tracking
    @Published var usageCount: Int {
        didSet {
            UserDefaults.standard.set(usageCount, forKey: featureKey)
        }
    }
    
    @Published var canUseForFree: Bool
    
    private let maxUsageCount: Int = 100
    private let featureKey = "finalUsageCountforReal"
    
    // Track if this is the first launch
    private var isFirstLaunch: Bool {
        return isShowingOnboarding
    }
    
    init() {
        // Initialize all properties from stored values first
        self.isPro = UserDefaults.standard.bool(forKey: "isPro")
        self.isShowingOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        
        // Get usage count from UserDefaults
        let storedUsageCount = UserDefaults.standard.integer(forKey: featureKey)
        
        // Initialize both properties directly
        self.usageCount = storedUsageCount
        self.canUseForFree = storedUsageCount < maxUsageCount || UserDefaults.standard.bool(forKey: "isPro")
        
        setupPurchases()
        fetchOfferings()
        #if DEBUG
        // For testing purposes, reset usage count
        self.usageCount = 0
        self.isPro = true
        self.canUseForFree = true
        self.updateProStatus(true)
        #endif
        
        if !self.isPro && !self.isShowingOnboarding && !self.isFirstLaunch {
            self.isShowingPayWall = true
        }
    }
    
    private func setupPurchases() {
        self.isPro = UserDefaults.standard.bool(forKey: "isPro")
        Purchases.shared.getCustomerInfo { [weak self] (customerInfo, _) in
            DispatchQueue.main.async {
                let isProActive = customerInfo?.entitlements["PRO"]?.isActive == true
                UserDefaults.standard.set(isProActive, forKey: "isPro")
                self?.isPro = isProActive
                #if DEBUG
                self?.isPro = true
                #endif
            }
        }
    }
    
    private func fetchOfferings() {
        Purchases.shared.getOfferings { [weak self] (offerings, error) in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else if let defaultOffering = offerings?.offering(identifier: "non_trail") {
                    self?.offering = defaultOffering
                }
            }
        }
    }
    
    func purchase(package: Package) {
        isPurchasing = true
        Purchases.shared.purchase(package: package) { [weak self] (_, customerInfo, _, userCancelled) in
            DispatchQueue.main.async {
                self?.isPurchasing = false
                if let isProActive = customerInfo?.entitlements["PRO"]?.isActive {
                    self?.updateProStatus(isProActive)
                }
            }
        }
    }
    
    func restorePurchase() {
        Purchases.shared.restorePurchases { [weak self] customerInfo, _ in
            let isProActive = customerInfo?.entitlements["PRO"]?.isActive == true
            self?.updateProStatus(isProActive)
        }
    }
    
    private func updateProStatus(_ isPro: Bool) {
        self.isPro = isPro
        UserDefaults.standard.set(isPro, forKey: "isPro")
        if isPro {
            self.isShowingPayWall = false
        }
    }
    
    func useFeature() {
        usageCount += 1
    }
    
    
    // Return remaining uses
    var remainingUses: Int {
        return max(0, maxUsageCount - usageCount)
    }
}
