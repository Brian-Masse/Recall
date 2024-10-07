//
//  InfiniteScroller.swift
//  Recall
//
//  Created by Brian Masse on 10/6/24.
//

import Foundation
import SwiftUI
import UIKit
import UIUniversals

//MARK: ScrollViewWrapper
struct InfiniteMonthScrollView<Content: View>: View {
    
    @State private var uiScrollView: UIInfiniteMonthScrollView<Content>? = nil
    
    let contentBuilder: (Date) -> Content
    
    init( @ViewBuilder contentBuilder: @escaping (Date) -> Content ) {
        self.contentBuilder = contentBuilder
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let uiScrollView {
                    InfiniteMonthScrollViewWrapper(scrollView: uiScrollView)
                        .border(.blue)
                }
                
                Rectangle()
                    .foregroundStyle(.blue)
                    .opacity(0.1)
                    .onAppear {
                        self.uiScrollView = UIInfiniteMonthScrollView(frame: geo.frame(in: .global))
                        self.uiScrollView?.monthViewBuilder = contentBuilder
                    }
            }
        }
        .border(.red)
    }
}

struct InfiniteMonthScrollViewWrapper<Content: View>: UIViewRepresentable {
    
    private let uiScrollView: UIInfiniteMonthScrollView<Content>
    
    fileprivate init(scrollView: UIInfiniteMonthScrollView<Content>) {
        self.uiScrollView = scrollView
    }
    
    init(frame: CGRect, @ViewBuilder contentBuilder: @escaping (Date) -> Content) {
        self.uiScrollView = UIInfiniteMonthScrollView(frame: frame)
        self.uiScrollView.monthViewBuilder = contentBuilder
    }

    func makeUIView(context: Context) -> UIScrollView {
        return uiScrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        
        print("trying")
        
        if let monthScoller = uiView as? UIInfiniteMonthScrollView<Content> {
            print("success")
        }
    }
}

//MARK: UIInfiniteScrollView
private class UIInfiniteMonthScrollView<Content2: View>: UIScrollView {
    
    private enum Placement {
        case top
        case bottom
    }
    
    var visibleViews: [UIView] = []
    var container: UIView! = nil
    var visibleDates: [Date] = []
    
    var monthViewBuilder: ((Date) -> Content2)? = nil

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
//    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var startDate: Date {
        Calendar.current.date(byAdding: .month, value: -1, to: Date.now) ?? Date.now
    }
    
    //MARK: (*) otherwise can cause a bug of infinite scroll
    
    func setup() {
        contentSize = CGSize(width: frame.width, height: frame.height * 6)
        scrollsToTop = false // (*)
        showsVerticalScrollIndicator = false
        
        print(frame.width, visibleDates.count )
        
        container = UIView(frame: CGRect(x: 0, y: 0, width: contentSize.width, height: contentSize.height))
        container.backgroundColor = .purple
        
        addSubview(container)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        recenterIfNecessary()
        placeViews(min: bounds.minY, max: bounds.maxY)
    }
    
    func recenterIfNecessary() {
        let currentOffset = contentOffset
        let contentHeight = contentSize.height
        let centerOffsetY = (contentHeight - bounds.size.height) / 2.0
        let distanceFromCenter = abs(contentOffset.y - centerOffsetY)
        
        if distanceFromCenter > contentHeight / 3.0 {
            contentOffset = CGPoint(x: currentOffset.x, y: centerOffsetY)
            
            visibleViews.forEach { v in
                v.center = CGPoint(x: v.center.x, y: v.center.y + (centerOffsetY - currentOffset.y) )
            }
        }
    }
    
    func placeViews(min: CGFloat, max: CGFloat) {
        
        // first run
        if visibleViews.count == 0 {
            _ = place(on: .bottom, edge: min)
        }
        
        // place on top
        var topEdge: CGFloat = visibleViews.first!.frame.minY
        
        while topEdge > min {topEdge = place(on: .top, edge: topEdge)}
        
        // place on bottom
        var bottomEdge: CGFloat = visibleViews.last!.frame.maxY
        while bottomEdge < max {bottomEdge = place(on: .bottom, edge: bottomEdge)}
        
        // remove invisible items
        
        var last = visibleViews.last
        while (last?.frame.minY ?? max) > max {
            last?.removeFromSuperview()
            visibleViews.removeLast()
            visibleDates.removeLast()
            last = visibleViews.last
        }
        
        var first = visibleViews.first
        while (first?.frame.maxY ?? min) < min {
            first?.removeFromSuperview()
            visibleViews.removeFirst()
            visibleDates.removeFirst()
            first = visibleViews.first
        }
    }
    
    //MARK: returns the new edge either biggest or smallest
    
    private func place(on: Placement, edge: CGFloat) -> CGFloat {
        switch on {
        case .top:
            let newDate = Calendar.current.date(byAdding: .month, value: -1, to: visibleDates.first ?? Date())!
            let newMonth = makeUIViewMonth(newDate)
            
            visibleViews.insert(newMonth, at: 0)
            visibleDates.insert(newDate, at: 0)
            container.addSubview(newMonth)
            
            newMonth.frame.origin.y = edge - newMonth.frame.size.height
            return newMonth.frame.minY
            
        case .bottom:
            let newDate = Calendar.current.date(byAdding: .month, value: 1, to: visibleDates.last ?? startDate)!
            let newMonth = makeUIViewMonth(newDate)
            
            visibleViews.append(newMonth)
            visibleDates.append(newDate)
            container.addSubview(newMonth)
            
            newMonth.frame.origin.y = edge
            return newMonth.frame.maxY
        }
    }
    
    func makeUIViewMonth(_ date: Date) -> UIView {
        let month = makeSwiftUIMonth(from: date)
        let hosting = UIHostingController(rootView: month)
        
        let key = date.formatted(date: .numeric, time: .omitted)
        let height = swiftUIMonthHeightTable[key] ?? 0
        
        hosting.view.bounds.size = CGSize(width: frame.width, height: max(siwftUIMonthBaseHeight, height))
        hosting.view.clipsToBounds = true
        hosting.view.center.x = container.center.x
        
        return hosting.view
    }
    
    private var siwftUIMonthBaseHeight: Double = 10
    private var swiftUIMonthHeightTable: Dictionary<String, Double> = [:]
    
    @ViewBuilder
    func makeSwiftUIMonth(from date: Date) -> some View {
        if let monthViewBuilder {
            monthViewBuilder(date)
                .overlay {
                    GeometryReader { geo in
                        Rectangle()
                            .foregroundStyle(.clear)
                            .onAppear {
                                let height = geo.size.height
                                let key = date.formatted(date: .numeric, time: .omitted)
                                
                                if self.siwftUIMonthBaseHeight != height { self.siwftUIMonthBaseHeight = height }
                                
                                if self.swiftUIMonthHeightTable[key] == nil {
                                    self.swiftUIMonthHeightTable[key] = height
                                    
                                    let timeInterval = -(Date.now.timeIntervalSince(date))
                                    if timeInterval <= Constants.DayTime * 60 && timeInterval >= 0 {
                                        
                                        self.visibleViews.removeAll()
                                        self.visibleDates.removeAll()
                                        
                                        self.layoutSubviews()
                                }
                            }
                    }
                }
            }
            
            
        } else { EmptyView() }
    }
}

//MARK: PreferenceKey
private struct InfiniteMonthScollViewPreferenceKey: PreferenceKey {
    
    static var defaultValue: Double = .zero
    
    static func reduce(value: inout Double, nextValue: () -> Double) { }
}

struct MonthView: View {
    
    let month: Date
    
    var body: some View {
        
        Rectangle()
            .foregroundStyle(.red)
            .padding()
//            .frame(height: 250)
            .overlay {
                
                let format = Date.FormatStyle().month().day().year()
                
                Text("\(month.formatted(format))")
            }
            .border(.blue)
        
    }
    
}

#Preview {
    InfiniteMonthScrollView { month in
        
        MonthView(month: month)
    }
    .padding(.horizontal, 15)
}
