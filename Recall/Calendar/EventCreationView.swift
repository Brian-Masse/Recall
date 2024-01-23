//
//  EventCreationView.swift
//  Recall
//
//  Created by Brian Masse on 7/18/23.
//

import Foundation
import SwiftUI
import RealmSwift
//import FlowGrid

//MARK: GoalMultiplierSelector
struct GoalMultiplierSelector: View {
    
    
    private func makeGoalRatingMultiplier(forKey key: String) -> Binding<Float> {
        Binding { Float(goalRatings[ key ] ?? "0") ?? 0 }
        set: { newValue, _ in goalRatings[key] = "\(Int(newValue))" }
    }
    
    private func makeGoalRatingMultiplierText(forKey key: String) -> Binding<String> {
        Binding { "x\(goalRatings[ key ] ?? "0")" }
        set: { newValue, _ in goalRatings[key] = newValue.removeFirst(of: "x") }
    }
    
    let goal: RecallGoal
    @Binding var goalRatings: Dictionary<String, String>
    
    let showToggle: Bool
    
    var body: some View {
        HStack {
            UniversalText(goal.label, size: Constants.UISubHeaderTextSize, font: Constants.titleFont)

            Spacer()
            
            StyledSlider(minValue: 1, maxValue: 4,
                         binding: makeGoalRatingMultiplier(forKey: goal.key),
                         strBinding: makeGoalRatingMultiplierText(forKey: goal.key),
                         textFieldWidth: 60)
                .frame(width: 150)

            if showToggle {
                Image(systemName: "checkmark")
                    .if( Int( goalRatings[goal.key] ?? "0" ) ?? 0 == 0 ) { view in view.opaqueRectangularBackground() }
                    .if( Int( goalRatings[goal.key] ?? "0" ) ?? 0 != 0 ) { view in view.tintRectangularBackground() }
                
                    .onTapGesture {
                        let rating = Int(goalRatings[goal.key] ?? "0") ?? 0
                        if rating != 0 { goalRatings[goal.key] = "0" }
                        else { goalRatings[goal.key] = "1" }
                    }
            }
        }
        .secondaryOpaqueRectangularBackground()
    }
    
}

//MARK: Creation View
struct CalendarEventCreationView: View {
    
    @ViewBuilder
    static func makeEventCreationView(currentDay: Date, editing: Bool = false, event: RecallCalendarEvent? = nil, template: Bool = false, favorite: Bool = false) -> some View {
        if !editing {
            let startTime = RecallModel.index.recallEventsAtEndOfLastRecall ? RecallModel.index.getMostRecentRecallEnd(on: currentDay) : .now
            
            CalendarEventCreationView(editing: false,
                                      event: nil,
                                      title: "",
                                      notes: "",
                                      startTime: startTime,
                                      endTime: startTime + RecallModel.index.defaultEventLength,
                                      day: currentDay,
                                      category: RecallCategory(),
                                      goalRatings: Dictionary(),
                                      template: template,
                                      favorite: favorite)
        } else {
            CalendarEventCreationView(editing: true,
                                      event: event,
                                      title: event!.title,
                                      notes: event!.notes,
                                      startTime: event!.startTime,
                                      endTime: event!.endTime,
                                      day: event!.startTime,
                                      category: event!.category ?? RecallCategory(),
                                      goalRatings: RecallCalendarEvent.translateGoalRatingList(event!.goalRatings),
                                      template: false,
                                      favorite: false)
        }
    }
    
//    MARK: Vars
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedResults(RecallCalendarEvent.self) var events
    @ObservedResults(RecallCategory.self) var categories
    @ObservedResults(RecallGoal.self) var goals
    @ObservedRealmObject var index = RecallModel.index
    
    @State var showingAlert: Bool = false
    @State var alertTitle: String = ""
    @State var alertMessage: String = ""
    @State var showingTagCreationView: Bool = false
    
    let editing: Bool
    let event: RecallCalendarEvent?
    
    @State var title: String
    @State var notes: String
    @State var startTime: Date
    @State var endTime: Date
    @State var eventLength: Double = RecallModel.index.defaultEventLength
    @State var day: Date
    
    @State var category: RecallCategory
    @State var goalRatings: Dictionary<String, String>
    
    let template: Bool
    let favorite: Bool

    @State var showingAllGoals: Bool = false
    @State var recallByLength: Bool = !RecallModel.index.recallEventsWithEventTime
    
//    MARK: Helper Functions
    
//    Makes sure that the start and end times are specifed for the correct day
//    If the end time bleeds into the next day, this handles that
    private func setDay() {
        let requestingNewDay = startTime > endTime ? true : false
        
        let startComps = Calendar.current.dateComponents([.hour, .minute, .second], from: startTime)
        let endComps = Calendar.current.dateComponents([.hour, .minute, .second], from: endTime)
        
        startTime = Calendar.current.date(bySettingHour: startComps.hour!, minute: startComps.minute!, second: startComps.second!, of: day)!
        endTime = Calendar.current.date(bySettingHour: endComps.hour!, minute: endComps.minute!, second: endComps.second!, of: day + ( requestingNewDay ? Constants.DayTime : 0  ) )!
    }
    
    @ViewBuilder
    private func makeTagSelector(tag: RecallCategory) -> some View {
        HStack {
            Image(systemName: "tag")
            UniversalText(tag.label, size: Constants.UIDefaultTextSize, font: Constants.mainFont)
        }
        .onTapGesture { category = tag }
        .if(category.label == tag.label) { view in view.tintRectangularBackground()  }
        .if(category.label != tag.label) { view in view.secondaryOpaqueRectangularBackground() }
    }
    
//    MARK: Submit
    private func submit() {
        setDay()
        if !checkCompletion() {
            showingAlert = true
            return
        }
        
        if !editing {
            let event = RecallCalendarEvent(ownerID: RecallModel.ownerID,
                                            title: title,
                                            notes: notes,
                                            startTime: startTime,
                                            endTime: endTime,
                                            categoryID: category._id,
                                            goalRatings: goalRatings)
            RealmManager.addObject(event)
            if template { event.toggleTemplate() }
            if favorite { event.toggleFavorite() }
        } else {
            event!.update(title: title,
                          notes: notes,
                          startDate: startTime,
                          endDate: endTime,
                          tagID: category._id,
                          goalRatings: goalRatings)
        }
        presentationMode.wrappedValue.dismiss()
    }
    
    private func checkCompletion() -> Bool {
        if endTime < startTime {
            self.alertTitle = "Incomplete Form"
            self.alertMessage = "make sure the event end time is after the event start time"
            return false
        }
        
        self.alertTitle = "Incomplete Form"
        self.alertMessage = "Please provide a title, start and end times, and a tag before creating the event"
        
        return !self.title.isEmpty && !self.category.label.isEmpty
    }
    
    private func fillInformation(from event: RecallCalendarEvent) {
        self.activeTempalte = event
        self.title = event.title
        self.startTime = event.startTime
        self.endTime = event.endTime
        self.category = event.category ?? RecallCategory()
        self.goalRatings = RecallCalendarEvent.translateGoalRatingList(event.goalRatings)
    }
    
//    MARK: Bindings
    private var startTimeBinding: Binding<Float> {
        Binding { Float(startTime.getHoursFromStartOfDay().round(to: 2)) }
        set: { newValue, _ in
            startTime = startTime.dateBySetting(hour: Double(newValue)).round(to: index.dateSnapping)
        }
    }
    
    private var startTimeLabel: Binding<String> {
        Binding { startTime.formatted(date: .omitted, time: .shortened) }
        set: { newValue, _ in }
    }
    
    private var endTimeBinding: Binding<Float> {
        Binding { Float(endTime.getHoursFromStartOfDay().round(to: 2)) }
        set: { newValue, _ in
            endTime = endTime.dateBySetting(hour: Double(newValue)).round(to: index.dateSnapping)
        }
    }
    
    private var endTimeLabel: Binding<String> {
        Binding { endTime.formatted(date: .omitted, time: .shortened) }
        set: { newValue, _ in }
    }
    
    
//    MARK: SectionBuilders
    
    @ViewBuilder
    private func makeTemplateSelector() -> some View {
        HStack {
            UniversalText("templates", size: Constants.UIHeaderTextSize, font: Constants.titleFont)
            Spacer()
            LargeRoundedButton("", icon: showingTemplates ? "arrow.up" : "arrow.down", small: true) { withAnimation {
                showingTemplates.toggle()
            } }
        }
        if showingTemplates {
            WrappedHStack(collection: RecallModel.getTemplates(from: Array(events))) { template in
                HStack {
                    Image(systemName: "arrow.up.right")
                    UniversalText(template.title, size: Constants.UIDefaultTextSize, font: Constants.mainFont)
                }
                .if( (activeTempalte?.title ?? "") == template.title ) { view in view.tintRectangularBackground() }
                .if( (activeTempalte?.title ?? "") != template.title ) { view in view.secondaryOpaqueRectangularBackground() }
                .onTapGesture {
                    if (activeTempalte?.title ?? "") == template.title { activeTempalte = nil }
                    else { fillInformation(from: template) }
                }
            }
        }
    }
    
    @ViewBuilder
    private func makeRecallTypeSelectorOption( _ label: String, icon: String, option: Bool ) -> some View {
        
        HStack {
            Spacer()
            VStack {
                Image(systemName: icon)
                    .padding(.bottom, 5)
                UniversalText(label, size: Constants.UISmallTextSize, font: Constants.mainFont)
            }.padding(.horizontal, 15)
            
            Spacer()
        }
        .if( recallByLength == option ) { view in view.tintRectangularBackground(7) }
        .if( recallByLength != option ) { view in view.secondaryOpaqueRectangularBackground(7) }
        .onTapGesture { withAnimation { recallByLength = option } }
    }
    
    @ViewBuilder
    private func makeRecallTypeSelector() -> some View {
        HStack {
            makeRecallTypeSelectorOption("Recall with event time", icon: "calendar", option: false)
            makeRecallTypeSelectorOption("Recall with event length", icon: "rectangle.expand.vertical", option: true)
        }
    }
    
    @ViewBuilder
    private func makeOverviewQuestions() -> some View {
        TextFieldWithPrompt(title: "What is the name of this event?", binding: $title, clearable: true)
        TextFieldWithPrompt(title: "Leave an optional note", binding: $notes, clearable: true)
            .padding(.bottom)
    
        makeRecallTypeSelector()
        if recallByLength {
            LengthSelector("How long is this event?", length: $eventLength) { length in
                let maxEndTime = endTime.resetToStartOfDay() + Constants.DayTime
                endTime = min( startTime + length, maxEndTime )
            }
        } else {
            TimeSelector(label: "When did this event start?", time: $startTime)
            TimeSelector(label: "When did this event end?", time: $endTime)
        }
    }
    
    @ViewBuilder
    private func makeTagSelector() -> some View {
        UniversalText("Select a tag", size: Constants.UIHeaderTextSize, font: Constants.titleFont)
        UniversalText("Favorites", size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
        
        WrappedHStack(collection: Array( categories.filter { tag in tag.isFavorite} )) { tag in
            makeTagSelector(tag: tag)
        }
        .padding(.bottom)
        UniversalText("All Tags", size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
        WrappedHStack(collection: Array( categories.filter { tag in !tag.isFavorite} )) { tag in
            makeTagSelector(tag: tag)
        }.padding(.bottom)
        
        LargeRoundedButton("create another tag", icon: "arrow.up", wide: true) { showingTagCreationView = true }
    }
    
    @ViewBuilder
    private func makeGoalSelector() -> some View {
        VStack(alignment: .leading) {
            UniversalText("Goals", size: Constants.UIHeaderTextSize, font: Constants.titleFont)
            
            if category.goalRatings.count > 0 {
                UniversalText("From Tag", size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
                ForEach( Array(goals), id: \.key ) { goal in
                    if category.goalRatings.contains(where: { node in node.key == goal.key }) {
                        GoalMultiplierSelector(goal: goal, goalRatings: $goalRatings, showToggle: true)
                    }
                }
            }
            
            HStack {
                UniversalText("All Goals", size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
                Spacer()
                LargeRoundedButton("", icon: showingAllGoals ? "arrow.up" : "arrow.down") { showingAllGoals.toggle() }
            }.padding(.top)
            
            VStack {
                if showingAllGoals {
                    ForEach( Array(goals), id: \.key ) { goal in
                        GoalMultiplierSelector(goal: goal, goalRatings: $goalRatings, showToggle: true)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func makeDateChanger() -> some View {
        
        VStack(alignment: .leading) {
            if editing {
                StyledDatePicker($day, title: "Change Event Date", fontSize: Constants.UIHeaderTextSize)
            }
            
        }
        
    }
    
    @State var showingTemplates: Bool = false
    @State var activeTempalte: RecallCalendarEvent? = nil
    @State var showingError: Bool = false

//    MARK: Body
    var body: some View {
        VStack(alignment: .leading) {
            
            UniversalText(editing ? "Edit Event" : "Create Event", size: Constants.UITitleTextSize, font: Constants.titleFont)
                .foregroundColor(.black)
            
            ZStack(alignment: .bottom) {
                ScrollView(.vertical) {
                    VStack(alignment: .leading) {
                        
                        makeTemplateSelector()
                            .padding(.bottom)

                        makeOverviewQuestions()
                            .padding(.bottom)
                        
                        makeDateChanger()
                            .padding(.bottom)
                        
                        makeTagSelector()
                            .padding(.bottom)
                        
                        makeGoalSelector()
                            .padding(.bottom, 100)
                    }
                }
                
                LargeRoundedButton("done", icon: "arrow.down") { submit() }
            }
            .opaqueRectangularBackground()
        }
        .scrollDismissesKeyboard(ScrollDismissesKeyboardMode.immediately)
        .padding([.top, .horizontal], Constants.UIFormPagePadding)
        .background(Colors.tint)
        
        .onChange(of: category) { newValue in goalRatings = RecallCalendarEvent.translateGoalRatingList(newValue.goalRatings) }
        .sheet(isPresented: $showingTagCreationView) {
            CategoryCreationView(editing: false,
                                 tag: nil,
                                 label: "",
                                 goalRatings: Dictionary(),
                                 color: Colors.tint)
        }
    
        .alert(alertTitle,
               isPresented: $showingAlert) {
            Button("dimiss", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }

    }
}
