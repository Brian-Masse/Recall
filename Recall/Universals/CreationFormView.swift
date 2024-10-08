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
    
    @Binding private var fullScreenSectionId: Int
    
    private let title: String
    private let sequence: [Section]?
    
    init( _ title: String,
          section: Section.Type,
          sequence: [Section]? = nil,
          fullScreenSectionId: Binding<Int> = Binding { -1 } set: { _ in },
          submit: @escaping () -> Void,
          @ViewBuilder contentBuilder: @escaping (Section) -> C ) {
        
        self.title = title
        self.contentBuilder = contentBuilder
        self.submit = submit
        self.section = section
        self.sequence = sequence
        self._fullScreenSectionId = fullScreenSectionId
    }
    
    private let largeCornerRadius: Double = 58
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
                GeometryReader { geo in
                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: Constants.UIFormPagePadding) {
                                ForEach( 0..<section.allCases.count, id: \.self ) { i in
                                    
                                    let section = allCases[i]
                                    
                                    VStack(alignment: .leading) {
                                        HStack { Spacer() }
                                        
                                        contentBuilder( section )
                                        
                                        Spacer()
                                    }
                                    .id(section.rawValue)
                                    .frame(minHeight: section.rawValue == fullScreenSectionId ? geo.size.height : 0)
                                    .padding()
                                    .padding(.bottom, i == caseCount - 1 ? Constants.UIBottomOfPagePadding : 0)
                                    .animation( .easeInOut(duration: 0.25), value: fullScreenSectionId )
                                    .background {
                                        UnevenRoundedRectangle(cornerRadii: .init(topLeading: i == 0 ? largeCornerRadius : smallCornerRadius,
                                                                                  bottomLeading: i == caseCount - 1 ? largeCornerRadius : smallCornerRadius,
                                                                                  bottomTrailing: i == caseCount - 1 ? largeCornerRadius : smallCornerRadius,
                                                                                  topTrailing: i == 0 ? largeCornerRadius : smallCornerRadius))
                                        .foregroundStyle( Colors.getBase(from: colorScheme) )
                                    }
                                }
                            }
                            .onChange(of: fullScreenSectionId) {
                                if fullScreenSectionId != -1 { withAnimation {
                                    proxy.scrollTo(self.fullScreenSectionId, anchor: .top)
                                } }
                            }
                        }
                        .scrollDisabled(fullScreenSectionId != -1)
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
struct CreationFormDemoView: View {
    
    enum DemoSection: Int, CreationFormEnumProtocol {
        case section1
        case section2
        case section3
    }
    
    @State private var text: String = "hi"
    @State private var fullScreenBinding: Int = -1
    
    @ViewBuilder
    private func makeSpacer(_ label: String) -> some View {
        Rectangle()
            .frame(height: 220)
            .foregroundStyle(.clear)
            .contentShape(Rectangle())
            .overlay(Text(label))
            .onTapGesture {
                fullScreenBinding = 1
            }
    }
    
    var body: some View {
            
        CreationFormView("hello", section: DemoSection.self, fullScreenSectionId: $fullScreenBinding) {
            
        } contentBuilder: { section in
            switch section {
            case .section1: makeSpacer("1")
            case .section2: makeSpacer("2")
            case .section3: makeSpacer("3")
            }
        }
    }
}

#Preview {
    CreationFormDemoView()
}
