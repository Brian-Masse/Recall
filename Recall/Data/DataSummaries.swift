//
//  DataSummaries.swift
//  Recall
//
//  Created by Brian Masse on 7/31/23.
//

import Foundation
import SwiftUI

struct ActivityHoursPerDaySummary: View {
    
    private func compressData() -> [DataNode] {
        
        Array( data.reduce(Dictionary<String, DataNode>()) { partialResult, node in
            let key = node.category
            var mutable = partialResult
            if var value = mutable[ key ] {
                mutable[key] = value.increment(by: node.count )
            } else { mutable[key] = .init(date: .now, count: node.count, category: key, goal: "") }
            return mutable
        }.values )
    }
    
    let data: [DataNode]
    let fullBreakdown: Bool
    @State var showingBreakdown: Bool = false
    
    var body: some View {
        
        let compressedData = compressData().sorted { node1, node2 in node1.count < node2.count }
        
        VStack {
            DataSummaryList(content: [
                .init(label: "Most Frequent Event", content: "\( compressedData.last?.category ?? "?") (\( compressedData.last?.count.round(to: 2) ?? 0 ) HR)"),
                .init(label: "Least Frequent Event", content: "\( compressedData.first?.category ?? "?") (\( compressedData.first?.count.round(to: 2) ?? 0 ) HR)")
            
            ])
            
            if fullBreakdown {
                HStack {
                    UniversalText("Full breakdown", size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
                    Spacer()
                    LargeRoundedButton("", icon: showingBreakdown ? "arrow.down" : "arrow.up") { withAnimation { showingBreakdown.toggle() }}
                }
                if showingBreakdown {
                    let dataSummaryListContent = compressedData.compactMap { node in
                        DataSummaryList.Data(label: node.category, content: "\(node.count.round(to: 2)) HR")
                    }
                    
                    DataSummaryList(content: dataSummaryListContent, striped: true)
                }
            }
            
        }.padding(.vertical)
    }
}


struct DataSummaryList: View {
    
    struct Data: Identifiable {
        let label: String
        let content: String
        
        var id: String { label + content }
    }
    
    let content: [Data]
    let striped: Bool
    
    init( content: [Data], striped: Bool = false ) {
        self.content = content
        self.striped = striped
    }
    
    var body: some View {
        
        VStack {
            ForEach(content.indices, id: \.self) { i in
                HStack {
                    UniversalText(content[i].label, size: Constants.UIDefaultTextSize, font: Constants.titleFont)
                        .frame(maxWidth: 130, alignment: .leading)
                    
                    Spacer()
                    UniversalText(content[i].content, size: Constants.UIDefaultTextSize, font: Constants.mainFont)
                }
                .if(!striped) { view in view.padding(.bottom, 5) }
                .if(striped) { view in view.padding(.horizontal, 7) }
                .if(striped && !i.isMultiple(of: 2)) { view in
                    view
                        .padding(7)
                        .background {
                        Rectangle()
                            .foregroundColor(Colors.darkGrey)
                            .cornerRadius(Constants.UIDefaultCornerRadius - 5)
                    }
                    
                }
            }
        }
    }
    
}
