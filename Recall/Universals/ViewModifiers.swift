//
//  ViewModifiers.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import SwiftUI

//MARK: View Modifiers



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

private struct OpaqueRectangularBackground: ViewModifier {
    
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(colorScheme == .light ? .white : .black )
            .cornerRadius(Constants.UIDefaultCornerRadius)
    }
}

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

private struct RectnagularGlow: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .shadow(color: colorScheme == .dark ? Colors.tint.opacity(0.2) : Colors.tint.opacity(0.5), radius: 50)
    }
    
}

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
    
    func rectangularGlow() -> some View {
        modifier(RectnagularGlow())
    }
    
    func onBecomingVisible(perform action: @escaping () -> Void) -> some View {
        modifier(BecomingVisible(action: action))
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
}


struct NoButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
