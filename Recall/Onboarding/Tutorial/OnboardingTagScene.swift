//
//  OnboardingTagScene.swift
//  Recall
//
//  Created by Brian Masse on 12/28/24.
//

import Foundation
import SwiftUI
import UIUniversals

//MARK: - TemplateTag
struct TemplateTag: Equatable, Identifiable {
    var id: String { title }
    
    let title: String
    let color: Color
    let goals: [ String ]
    
    init(
        _ title: String,
        color: Color,
        goals: [ String ]
    ) {
        self.title = title
        self.color = color
        self.goals = goals
    }
}

//MARK: - onboardingTagScene
struct OnboardingTagScene: View {
    
    @ObservedObject private var viewModel: OnboardingViewModel = OnboardingViewModel.shared
    
    private var templateCountString: String {
        "\(viewModel.selectedTemplateTags.count) / \(viewModel.minimumTagTemplates)"
    }
    
    private let tagTemplates: [TemplateTag]
    
    init() {
        self.tagTemplates = TemplateManager().getTagTemplates()
    }
    
//    MARK: makeHeader
    @ViewBuilder
    private func makeHeader() -> some View {
        VStack(alignment: .leading) {
            HStack {
                UniversalText("Tags", size: Constants.UIHeaderTextSize, font: Constants.titleFont)
                
                Spacer()
                
                UniversalText(templateCountString,
                              size: Constants.UIDefaultTextSize,
                              font: Constants.mainFont)
            }
            
            UniversalText(OnboardingSceneUIText.tagSceneInstructionText,
                          size: Constants.UIDefaultTextSize,
                          font: Constants.mainFont)
            .opacity(0.75)
        }
    }
    
//    MARK: makeTemplateTagSelector
    private func templateIsSelected(_ template: TemplateTag) -> Bool {
        viewModel.selectedTemplateTags.firstIndex(of: template) != nil
    }
    
    @ViewBuilder
    private func makeTemplateTagSelector(_ template: TemplateTag) -> some View {
        
        let templateIsSelected = templateIsSelected(template)
        
        HStack {
            RecallIcon("tag.fill")
                .foregroundStyle(template.color)
            
            UniversalText(template.title, size: Constants.UIDefaultTextSize - 1, font: Constants.mainFont)
        }
        .highlightedBackground(templateIsSelected, padding: 11, disabledStyle: .transparent)
        .onTapGesture { withAnimation {
            viewModel.toggleTemplateTag(template)
            
            if viewModel.selectedTemplateTags.count >= viewModel.minimumTagTemplates {
                viewModel.setSceneStatus(to: .complete)
            }
        } }
    }

//    MARK: makeTemplateTagSelectors
    @ViewBuilder
    private func makeTemplateTagSelectors() -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            WrappedHStack(collection: tagTemplates, spacing: 7) { template in
                makeTemplateTagSelector(template)
            }
        }
        .safeAreaPadding(.bottom, 100)
    }
    
//    MARK: Body
    var body: some View {
        
        OnboardingSplashScreenView(icon: "tag",
                                   title: "Tags",
                                   message: OnboardingSceneUIText.tagSceneIntroductionText,
                                   duration: 5.5)
        {
            VStack(alignment: .leading) {
                makeHeader()
                
                makeTemplateTagSelectors()
                
                Spacer()
            }
            .padding(7)
            .overlay(alignment: .bottom) {
                OnboardingContinueButton(preTask: {
                    await viewModel.tagSceneSubmitted(viewModel.selectedTemplateTags)
                })
            }
        }
                                   .onAppear {
                                       viewModel.checkInitialTags()
                                       viewModel.setSceneStatus(to: .complete)
                                   }
    }
}


#Preview {
    OnboardingTagScene()
}
