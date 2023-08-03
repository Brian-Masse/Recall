//
//  ViewModifiers.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import SwiftUI
import RealmSwift

//MARK: Backgrounds
private struct UniversalBackground: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    let padding: Bool
    
    func body(content: Content) -> some View {
        GeometryReader { geo in
            content
        }
        .background(colorScheme == .light ? Colors.lightGrey : .black)
    }
}

private struct UniversalColoredBackground: ViewModifier {
    
    @Environment(\.colorScheme) var colorScheme
    let color: Color
    
    func body(content: Content) -> some View {
        GeometryReader { geo in
            content
                .background(
                    GeometryReader { geo in
                        VStack {
                            if colorScheme == .dark {
                                LinearGradient(colors: [color.opacity(0.1), .clear], startPoint: .top, endPoint: .bottom )
                                    .frame(maxHeight: 800)
                                Spacer()
                            }
                            else if colorScheme == .light {
                                Spacer()
                                LinearGradient(colors: [color.opacity(0.5), .clear], startPoint: .bottom, endPoint: .top )
                                    .frame(maxHeight: 800)
                            }
                        }
                    }
                        .universalBackground(padding: false)
                        .ignoresSafeArea()
                )
        }
    }
}

private struct UniversalForeground: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let reversed: Bool
    func body(content: Content) -> some View {
            if !reversed { return content.foregroundColor(colorScheme == .light ? .white : Colors.darkGrey) }
        return content.foregroundColor(colorScheme == .light ? Colors.darkGrey : .white )
    }
}

//MARK: TextStyle
private struct UniversalTextStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    func body(content: Content) -> some View {
        content.foregroundColor(colorScheme == .light ? .black : .white)
    }
}

private struct ReversedUniversalTextStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    func body(content: Content) -> some View {
        content.foregroundColor(colorScheme == .light ? .white : .black)
    }
}

private struct UniversalTextField: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .tint(Colors.tint)
            .font(Font.custom(ProvidedFont.renoMono.rawValue, size: Constants.UIDefaultTextSize))
    }
}

//MARK: Rectangular Backgrounds
private struct RectangularBackground: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    let rounded: Bool
    let radius: CGFloat?

    private func getRadius() -> CGFloat {
        if let radius = radius { return radius}
        return rounded ? 100 : Constants.UIDefaultCornerRadius
    }
    
    func body(content: Content) -> some View {
        content
            .background(.thinMaterial)
            .foregroundColor(  ( Colors.tint ).opacity(0.6))
            .foregroundStyle(.ultraThickMaterial)
            .cornerRadius(getRadius())
    }
}

//This is black and white
private struct OpaqueRectangularBackground: ViewModifier {
    
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(colorScheme == .light ? .white : .black )
            .cornerRadius(Constants.UIDefaultCornerRadius)
    }
}

//This is the white accent and dark accent
private struct SecondaryOpaqueRectangularBackground: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background( colorScheme == .dark ? Colors.darkGrey : Colors.lightGrey )
            .cornerRadius(Constants.UIDefaultCornerRadius)
//            .shadow(color: Colors.tint.opacity( colorScheme == .dark ? 0.2 : 0.4), radius: 50)
    }
}

//This is the titn background
private struct TintBackground: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding()
            .foregroundColor(.black)
            .background( Colors.tint )
            .cornerRadius(Constants.UIDefaultCornerRadius)
    }
}

//This adds extra padding to the tint background
private struct AccentBackground: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding(25)
            .foregroundColor(.black)
            .background( Colors.tint )
            .cornerRadius(Constants.UIDefaultCornerRadius)
    }
}


//MARK: Utitilities
private struct BecomingVisible: ViewModifier {
    @State var action: (() -> Void)?

    func body(content: Content) -> some View {
        content.overlay {
            GeometryReader { proxy in
                Color.clear
                    .preference(
                        key: VisibleKey.self,
                        // See discussion!
                        value: UIScreen.main.bounds.intersects(proxy.frame(in: .global))
                    )
                    .onPreferenceChange(VisibleKey.self) { isVisible in
                        guard isVisible, let action else { return }
                        action()
//                        action = nil
                    }
            }
        }
    }

    struct VisibleKey: PreferenceKey {
        static var defaultValue: Bool = false
        static func reduce(value: inout Bool, nextValue: () -> Bool) { }
    }
}

private struct RoundedCorner: Shape {
    
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

private struct Developer: ViewModifier {
    func body(content: Content) -> some View {
        if inDev {
            content
        }
    }
}

private struct ColorChartByTag: ViewModifier {
    
    @ObservedResults(RecallCategory.self) var tags
    
    @State var dictionary: Dictionary<String, Color> = Dictionary()
    
    func body(content: Content) -> some View {
        
        content
            .chartForegroundStyleScale { value in dictionary[value] ?? .red }
            .onAppear {
                var dic: Dictionary<String, Color> = Dictionary()
                if tags.count == 0 { return }
                dic["?"] = .white
                for i in 0..<tags.count  {
                    let key: String =  tags[i].label
                    dic[key] = tags[i].getColor()
                }
                self.dictionary = dic
            }
    }
}

//MARK: Extension
extension View {
    func universalBackground(padding: Bool = true) -> some View {
        modifier(UniversalBackground( padding: padding ))
    }
    
    func universalColoredBackground(_ color: Color) -> some View {
        modifier(UniversalColoredBackground(color: color))
    }
    
    func universalForeground(not reveresed: Bool = false) -> some View {
        modifier(UniversalForeground(reversed: reveresed))
    }
    
    func universalTextStyle() -> some View {
        modifier(UniversalTextStyle())
    }
    
    func reversedUniversalTextStyle() -> some View {
        modifier(ReversedUniversalTextStyle())
    }
    
    func universalTextField() -> some View {
        modifier(UniversalTextField())
    }
    
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
    
//    MARK: Rectangular Backgrounds (extension)
    func rectangularBackgorund(rounded: Bool = false, radius: CGFloat? = nil) -> some View {
        modifier(RectangularBackground(rounded: rounded, radius: radius))
    }
    
    func opaqueRectangularBackground() -> some View {
        modifier(OpaqueRectangularBackground())
    }
    
    func secondaryOpaqueRectangularBackground() -> some View {
        modifier(SecondaryOpaqueRectangularBackground())
    }
    
    func accentRectangularBackground() -> some View {
        modifier(AccentBackground())
    }
    
    func tintRectangularBackground() -> some View {
        modifier(TintBackground())
    }
    
    func onBecomingVisible(perform action: @escaping () -> Void) -> some View {
        modifier(BecomingVisible(action: action))
    }
    
    func colorChartByTag() -> some View {
        modifier(ColorChartByTag())
    }
    
    #if canImport(UIKit)
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    #endif
    
    func delayTouches() -> some View {
        Button(action: {}) {
            highPriorityGesture(TapGesture())
        }
        .buttonStyle(NoButtonStyle())
    }
    
    @ViewBuilder
    func `if`<Content: View>( _ condition: Bool, contentBuilder: (Self) -> Content ) -> some View {
        if condition {
            contentBuilder(self)
        } else { self }
    }
    
    func developer() -> some View {
        modifier( Developer() )
    }
}


struct NoButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
