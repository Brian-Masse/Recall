//
//  CalendarEventCarousel.swift
//  Recall
//
//  Created by Brian Masse on 11/2/24.
//

import Foundation
import SwiftUI

struct CalendarEventCarousel: View {
    
    @State var events: [RecallCalendarEvent]
    let startIndex: Int
    
    var body: some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                
                ScrollView( .horizontal, showsIndicators: false ) {
                    LazyHStack(spacing: 0) {
                        
                        ForEach( 0..<events.count, id: \.self ) { i in
                            
                            let event = events[i]
                            
                            TestCalendarEventView(event: event)
                                .frame(width: geo.size.width)
                            
                        }
                        
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .onAppear {
                    proxy.scrollTo(startIndex)
                }
            }
        }
    }
}

#Preview {
    CalendarEventCarousel(events: [ sampleEventNoPhotos, sampleEvent, sampleEventNoPhotos ], startIndex: 1)
}
