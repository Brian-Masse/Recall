//
//  EventCreationView.swift
//  Recall
//
//  Created by Brian Masse on 7/18/23.
//

import Foundation
import SwiftUI
import RealmSwift
import UIUniversals

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
    
//    MARK: Body
    var body: some View {
        HStack {
            UniversalText(goal.label, size: Constants.UIDefaultTextSize, font: Constants.mainFont)

            Spacer()
            
            StyledSlider(minValue: 1, maxValue: 4,
                         binding: makeGoalRatingMultiplier(forKey: goal.key),
                         strBinding: makeGoalRatingMultiplierText(forKey: goal.key),
                         textFieldWidth: 60)
                .frame(width: 150)

            if showToggle {
                RecallIcon("checkmark")
                    .if( Int( goalRatings[goal.key] ?? "0" ) ?? 0 == 0 ) { view in view.rectangularBackground(style: .primary) }
                    .if( Int( goalRatings[goal.key] ?? "0" ) ?? 0 != 0 ) { view in view.rectangularBackground(style: .accent, foregroundColor: .black) }
                
                    .onTapGesture {
                        let rating = Int(goalRatings[goal.key] ?? "0") ?? 0
                        if rating != 0 { goalRatings[goal.key] = "0" }
                        else { goalRatings[goal.key] = "1" }
                    }
            }
        }
        .rectangularBackground(style: .secondary)
    }
}

//MARK: CalendarEventcreationView
struct CalendarEventCreationView: View {
    
    
//    MARK: makeEventCreationView
//    This creates an instance of the calendarEventCreationView
//    it automatically populates the information if you are editting an event
    @ViewBuilder
    static func makeEventCreationView(currentDay: Date, editing: Bool = false, event: RecallCalendarEvent? = nil, favorite: Bool = false) -> some View {
        if !editing {
            let startTime = RecallModel.index.recallEventsAtEndOfLastRecall ? RecallModel.index.getMostRecentRecallEnd(on: currentDay) : .now
            
            CalendarEventCreationView(editing: false,
                                      event: nil,
                                      favorite: favorite,
                                      title: "",
                                      notes: "",
                                      startTime: startTime,
                                      endTime: startTime + RecallModel.index.defaultEventLength,
                                      day: currentDay,
                                      category: RecallCategory(),
                                      goalRatings: Dictionary())
        } else {
            CalendarEventCreationView(editing: true,
                                      event: event,
                                      favorite: false,
                                      title: event!.title,
                                      notes: event!.notes,
                                      link: URL(string: event!.urlString),
                                      location: event!.getLocationResult(),
                                      startTime: event!.startTime,
                                      endTime: event!.endTime,
                                      day: event!.startTime,
                                      category: event!.category ?? RecallCategory(),
                                      goalRatings: RecallCalendarEvent.translateGoalRatingList(event!.goalRatings))
        }
    }
    
    
//    MARK: Vars
    @Environment(\.colorScheme) var colorShcheme
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject private var viewModel = StyledPhotoPickerViewModel.shared
    
    @ObservedResults(RecallCalendarEvent.self,
                     where: { event in event.ownerID == RecallModel.ownerID }) var events
    @ObservedResults(RecallCategory.self,
                     where: { tag in tag.ownerID == RecallModel.ownerID }) var categories
    @ObservedResults(RecallGoal.self,
                     where: { goal in goal.ownerID == RecallModel.ownerID }) var goals
    
    @ObservedRealmObject var index = RecallModel.index
    
    @State private var showingAlert: Bool = false
    @State private var showingError: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showingTagCreationView: Bool = false
    
    @State private var showingAllGoals: Bool = false
    @State private var recallByLength: Bool = !RecallModel.index.recallEventsWithEventTime
    @State private var showingAllTags: Bool = false
    
    let editing: Bool
    let event: RecallCalendarEvent?
    let favorite: Bool
    
//    MARK: Event Properties
//    These are the vars that will be directly or indirectly stored in the event
    @State private var title: String
    @State private var notes: String
    
    @State var link: URL?
    @State private var showingLocationPicker: Bool = false
    @State var location: LocationResult?
    
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var eventLength: Double = RecallModel.index.defaultEventLength
    @State private var day: Date
    
    @State private var category: RecallCategory
    @State private var goalRatings: Dictionary<String, String>

//    MARK: Init
    @MainActor
    private func onAppear() {
        if self.editing {
            Task { viewModel.selectedImages = await event!.decodeImages() }
        }
    }

    
//    MARK: SetDay
//    Makes sure that the start and end times are specifed for the correct day
//    If the end time bleeds into the next day, this handles that
    private func setDay() {
        let requestingNewDay = startTime > endTime ? true : false
        
        let startComps = Calendar.current.dateComponents([.hour, .minute, .second], from: startTime)
        let endComps = Calendar.current.dateComponents([.hour, .minute, .second], from: endTime)
        
        startTime = Calendar.current.date(bySettingHour: startComps.hour!, minute: startComps.minute!, second: startComps.second!, of: day)!
        endTime = Calendar.current.date(bySettingHour: endComps.hour!, minute: endComps.minute!, second: endComps.second!, of: day + ( requestingNewDay ? Constants.DayTime : 0  ) )!
    }
    
//    MARK: CheckCompletion
//    Makes sure a user can't fill out the form until all fields are complete
    private func checkCompletion() -> Bool {
        if endTime < startTime {
            endTime += Constants.DayTime
        }
        
        self.alertTitle = "Incomplete Form"
        self.alertMessage = "Please provide a title, start and end times, and a tag before creating the event"
        
        return !self.title.isEmpty && !self.category.label.isEmpty
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
                                            urlString: link?.absoluteString ?? "",
                                            location: location,
                                            images: viewModel.selectedImages,
                                            startTime: startTime,
                                            endTime: endTime,
                                            categoryID: category._id,
                                            goalRatings: goalRatings)
            RealmManager.addObject(event)
            if favorite { event.toggleFavorite() }
        } else {
            event!.update(title: title,
                          notes: notes,
                          urlString: link?.absoluteString ?? "",
                          startDate: startTime,
                          endDate: endTime,
                          location: location,
                          images: viewModel.selectedImages,
                          tagID: category._id,
                          goalRatings: goalRatings)
        }
        presentationMode.wrappedValue.dismiss()
    }
    
    private func fillInformation(from event: RecallCalendarEvent) {
        self.title = event.title
        self.startTime = event.startTime
        self.endTime = event.endTime
        self.category = event.category ?? RecallCategory()
        self.goalRatings = RecallCalendarEvent.translateGoalRatingList(event.goalRatings)
    }

//    MARK: makeOvervieQuestions
    @ViewBuilder
    private func makeOverviewQuestions() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            StyledTextField(title: "", binding: $title, prompt: "title", clearable: true)
            StyledTextField(title: "", binding: $notes, prompt: "Notes", clearable: true, multiLine: true)
            
            EventCreationViewTabBar(link: $link, location: $location)
        }.padding(.top)
    }
    
    
//    MARK: RecallTypeSelector
    @ViewBuilder
    private func makeRecallTypeSelectorOption( _ label: String, icon: String, option: Bool ) -> some View {
        
        HStack {
            Spacer()
            VStack {
                RecallIcon(icon)
                    .padding(.bottom, 5)
                UniversalText(label, size: Constants.UISmallTextSize, font: Constants.mainFont)
            }.padding(.horizontal, 20)
            
            Spacer()
        }
        .if( recallByLength == option ) { view in view.rectangularBackground(7, style: .accent, foregroundColor: .black) }
        .if( recallByLength != option ) { view in view.rectangularBackground(7, style: .secondary) }
        .onTapGesture { withAnimation { recallByLength = option } }
    }
    
    @ViewBuilder
    private func makeRecallTypeSelector() -> some View {
        HStack {
            makeRecallTypeSelectorOption("Recall with event time", icon: "calendar", option: false)
            makeRecallTypeSelectorOption("Recall with event length", icon: "rectangle.expand.vertical", option: true)
        }
    }
    
//    MARK: TimeSelector
    @ViewBuilder
    private func makeTimeSelector() -> some View {
        if editing {
            StyledDatePicker($day, title: "Change Event Date", fontSize: Constants.formQuestionTitleSize)
                .padding(.bottom)
        }
        
        if recallByLength {
            LengthSelector("How long is this event?", length: $eventLength) { length in
                let maxEndTime = endTime.resetToStartOfDay() + Constants.DayTime
                endTime = min( startTime + length, maxEndTime )
            }
        } else {
            CactusTimeDial(time: $startTime, title: "Event start time")
            CactusTimeDial(time: $endTime, title: "Event end time")
        }
        
        makeRecallTypeSelector()
    }
    
//    MARK: TagSelector
    @ViewBuilder
    private func makeTagSelector(tag: RecallCategory) -> some View {
        HStack {
            
            RecallIcon("tag.fill")
                .foregroundStyle( category.label == tag.label ? .black : tag.getColor() )
            
            UniversalText( tag.label, size: Constants.UIDefaultTextSize, font: Constants.titleFont )
                .foregroundStyle( category.label == tag.label ? .black : ( colorShcheme == .dark ? .white : .black ))
            
            Spacer()
        }
        .padding(.vertical, 3)
        .background {
            RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius)
                .foregroundStyle( category.label == tag.label ? Colors.getAccent(from: colorShcheme) : .clear )
                .padding(-7)
            
        }
        .contentShape(Rectangle())
        .onTapGesture { withAnimation { category = tag }}
    }
    
    @ViewBuilder
    private func makeTagList( _ list: [RecallCategory] ) -> some View {
        VStack {
            ForEach( list, id: \.id ) { tag in
                makeTagSelector(tag: tag)
                
                Divider()
            }
        }
    }
    
    @ViewBuilder
    private func makeTagSelector() -> some View {
        UniversalText("Select a tag", size: Constants.formQuestionTitleSize, font: Constants.titleFont)
        
        let favorites = Array( categories.filter({ tag in tag.isFavorite }) )
        let allTags = Array( categories.filter({ tag in !tag.isFavorite }) )
        
        makeTagList(favorites)
            .padding(.bottom)
        
        HStack {
            UniversalText("All Tags", size: Constants.UIDefaultTextSize, font: Constants.titleFont)
        
            Spacer()
            
            LargeRoundedButton("", to: "", icon: "arrow.down", to: "arrow.up", wide: false, small: true, foregroundColor: nil, style: .secondary) {
                showingAllTags
            } action: { showingAllTags.toggle() }
        }
        
        if showingAllTags {
            makeTagList(allTags)
            LargeRoundedButton("create another tag", icon: "arrow.up", wide: true, foregroundColor: nil, style: .secondary) { showingTagCreationView = true }
        }
        
        makeGoalSelector()
    }
    
//    MARK: GoalSelector
    @ViewBuilder
    private func makeGoalSelector() -> some View {
        if category.label != "" {
            Divider()
            
            UniversalText("Goals", size: Constants.formQuestionTitleSize, font: Constants.titleFont)
            
            if category.goalRatings.count > 0 {
                UniversalText("From Tag", size: Constants.UIDefaultTextSize, font: Constants.titleFont)
                ForEach( Array(goals), id: \.key ) { goal in
                    if category.goalRatings.contains(where: { node in node.key == goal.key }) {
                        GoalMultiplierSelector(goal: goal, goalRatings: $goalRatings, showToggle: true)
                    }
                }
            }
            
            HStack {
                UniversalText("All Goals", size: Constants.UIDefaultTextSize, font: Constants.titleFont)
                Spacer()
                LargeRoundedButton("",
                                   icon: showingAllGoals ? "arrow.up" : "arrow.down",
                                   small: true,
                                   foregroundColor: nil,
                                   style: .secondary) { showingAllGoals.toggle() }
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
    

//    MARK: CreationFormSectionEnum
    private enum EventCreationFormSection : Int, CreationFormEnumProtocol {
        case overview
        case time
        case tags
    }

//    MARK: Body
    var body: some View {
        
        let title = editing ? "Edit Event" : "Create Event"
        
        VStack {
            CreationFormView(title,
                             section: EventCreationFormSection.self,
                             sequence: editing ? [.overview, .tags, .time] : nil,
                             submit: submit) { section in
                switch section {
                case .overview: makeOverviewQuestions()
                case .time: makeTimeSelector()
                case .tags: makeTagSelector()
                }
            }
        }
        .onAppear { onAppear() }
         .onChange(of: category) { goalRatings = RecallCalendarEvent.translateGoalRatingList(category.goalRatings) }
        .sheet(isPresented: $showingTagCreationView) {
            CategoryCreationView(editing: false,
                                 tag: nil,
                                 label: "",
                                 goalRatings: Dictionary())
        }
        .sheet(isPresented: $showingLocationPicker) {
            StyledLocationPicker($location, title: "Event Location")
        }
        .alert(alertTitle,
               isPresented: $showingAlert) {
            Button("dimiss", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
}