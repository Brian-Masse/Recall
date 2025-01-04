//
//  OnboardingTagScene.swift
//  Recall
//
//  Created by Brian Masse on 12/28/24.
//

import Foundation
import SwiftUI
import UIUniversals

//MARK: - TemplateTagMask
enum TemplateTagMask: Int {
    case productivity
    case reading
    case exercising
}

//MARK: - TemplateTag
struct TemplateTag: Equatable, Identifiable {
    var id: String { title }
    
    let title: String
    let color: Color
    let templateMask: [ TemplateTagMask ]
    
    init(
        _ title: String,
        color: Color,
        templateMask: [ TemplateTagMask ]
    ) {
        self.title = title
        self.color = color
        self.templateMask = templateMask
    }
}

//MARK: templateTags
private let templateTags: [TemplateTag] = [
    .init("programming", color: .blue, templateMask: [.productivity]),
    .init("went to gym", color: .yellow, templateMask: [.productivity, .exercising]),
]

//MARK: - onboardingTagScene
struct OnboardingTagScene: View {
    
    private let minimumTemplates: Int = 5
    
    @ObservedObject private var viewModel: OnboardingViewModel = OnboardingViewModel.shared
    
    private var templateCountString: String {
        "\(viewModel.selectedTemplateTags.count) / \(minimumTemplates)"
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
            
            UniversalText(template.title, size: Constants.UIDefaultTextSize, font: Constants.mainFont)
        }
        .highlightedBackground(templateIsSelected)
        .onTapGesture { withAnimation {
            viewModel.toggleTemplateTag(template)
            
            if viewModel.selectedTemplateTags.count >= minimumTemplates {
                viewModel.setSceneStatus(to: .complete)
            }
        } }
    }

//    MARK: makeTemplateTagSelectors
    @ViewBuilder
    private func makeTemplateTagSelectors() -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            WrappedHStack(collection: templateTags) { template in
                makeTemplateTagSelector(template)
            }
            
        }
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
        }
                                   .onAppear {
                                       viewModel.setSceneStatus(to: .complete)
                                   }
    }
}


#Preview {
    OnboardingTagScene()
}
