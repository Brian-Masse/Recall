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
    
    private let title: String = "hello"
    
    private let largeCornerRadius: Double = 50
    
    private var allCases: [Section] { Array( section.allCases ) }
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
                    VStack(spacing: 7) {
                        ForEach( 0..<section.allCases.count, id: \.self ) { i in
                            
                            let section = allCases[i]
                            let cornerRadius: Double = (i == 0 || i == self.section.allCases.count - 1) ? 50 : 0
                            
                            VStack {
                                HStack { Spacer() }
                                contentBuilder( section )
                            }
                            .frame(height: 400)
                            .background {
                                UnevenRoundedRectangle(cornerRadii: .init(topLeading: i == 0 ? largeCornerRadius : Constants.UIDefaultCornerRadius,
                                                                          bottomLeading: i == caseCount - 1 ? largeCornerRadius : Constants.UIDefaultCornerRadius,
                                                                          bottomTrailing: i == caseCount - 1 ? largeCornerRadius : Constants.UIDefaultCornerRadius,
                                                                          topTrailing: i == 0 ? largeCornerRadius : Constants.UIDefaultCornerRadius))
                                .foregroundStyle( Colors.getBase(from: colorScheme) )
                                
                                
                            }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: largeCornerRadius))
                
                LargeRoundedButton("done", icon: "arrow.down") {  }
                    .shadow(radius: 10)
                    .padding(.bottom, 10)
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
            
        CreationFormView( section: DemoSection.self ) { section in
            switch section {
            case .section1 : Text("section 1")
            case .section2 : Text("section 2")
            case .section3 : Text("section 2")
            }
        }
    }
}

#Preview {
    CreationFormDemoView()
}
