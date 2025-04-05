//
//  MainView.swift
//  animeyourself
//
//  Created by Julian Beck on 30.03.25.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var globalViewModel: GlobalViewModel
    
    var body: some View {
        Group {
            if globalViewModel.isShowingOnboarding {
                OnboardingView()
            } else {
                AnimeYourselfView()
                    .fullScreenCover(isPresented: $globalViewModel.isShowingPayWall) {
                        PayWallView()
                    }
                .preferredColorScheme(.dark)
            }
        }
    }
}

#Preview {
    MainView()
}
