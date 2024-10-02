//
//  CreationFormView.swift
//  Recall
//
//  Created by Brian Masse on 9/11/24.
//

import Foundation
import SwiftUI
import UIUniversals

//MARK: CreationFormEnumProtocol
protocol CreationFormEnumProtocol: CaseIterable, RawRepresentable where Self.AllCases: RandomAccessCollection, Self.RawValue : BinaryInteger, Self.RawValue : Hashable { }

//MARK: CreationFormView
struct CreationFormView<Section: CreationFormEnumProtocol, C: View>: View {

    @Environment(\.colorScheme) var colorScheme
    
    let section: Section.Type
        
    @ViewBuilder var contentBuilder: (Section) -> C
    private let submit: () -> Void
    
    private let title: String
    private let sequence: [Section]?
    
    init( _ title: String, section: Section.Type, sequence: [Section]? = nil, submit: @escaping () -> Void, @ViewBuilder contentBuilder: @escaping (Section) -> C ) {
        self.title = title
        self.contentBuilder = contentBuilder
        self.submit = submit
        self.section = section
        self.sequence = sequence
    }
    
    private let largeCornerRadius: Double = 50
    private let smallCornerRadius: Double = (Constants.UIDefaultCornerRadius - 5)
    
    private var allCases: [Section] {
        if let sequence { return sequence }
        return Array( section.allCases )
    }
    private var caseCount: Int { allCases.count }
    
//    MARK: Header
    @ViewBuilder
    private func makeHeader() -> some View {
        HStack {
            UniversalText(title, size: Constants.UIHeaderTextSize, font: Constants.titleFont)
                .foregroundColor(.black)
                .padding(.top, 7)
            
            Spacer()
        }
    }
    
//    MARK: Body
    var body: some View {
        
        VStack {
            
            makeHeader()
            
            Spacer()
            
            ZStack(alignment: .bottom) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: Constants.UIFormPagePadding) {
                        ForEach( 0..<section.allCases.count, id: \.self ) { i in
                            
                            let section = allCases[i]
                            
                            VStack(alignment: .leading) {
                                HStack { Spacer() }
                                contentBuilder( section )
                            }
                            .padding()
                            .padding(.bottom, i == caseCount - 1 ? Constants.UIBottomOfPagePadding : 0)
                            .background {
                                UnevenRoundedRectangle(cornerRadii: .init(topLeading: i == 0 ? largeCornerRadius : smallCornerRadius,
                                                                          bottomLeading: i == caseCount - 1 ? largeCornerRadius : smallCornerRadius,
                                                                          bottomTrailing: i == caseCount - 1 ? largeCornerRadius : smallCornerRadius,
                                                                          topTrailing: i == 0 ? largeCornerRadius : smallCornerRadius))
                                .foregroundStyle( Colors.getBase(from: colorScheme) )
                            }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: largeCornerRadius))
                
                LargeRoundedButton("done", icon: "arrow.down") { submit() }
                    .padding(.bottom, 35)
            }
            .padding(.bottom, Constants.UIFormPagePadding)
            .ignoresSafeArea()
        }
        .scrollDismissesKeyboard(ScrollDismissesKeyboardMode.immediately)
        .padding([.horizontal], Constants.UIFormPagePadding)
        .universalStyledBackgrond(.accent)
    }
    
}


//MARK: DemoView
private struct CreationFormDemoView: View {
    
    enum DemoSection: Int, CreationFormEnumProtocol {
        case section1
        case section2
        case section3
    }
    
    var body: some View {
            
//        CreationFormView( section: DemoSection.self ) { section in
//            switch section {
//            case .section1 : Text("section 1")
//            case .section2 : Text("section 2")
//            case .section3 : Text("section 2")
//            }
//        }
        
        VStack {}
    }
}
