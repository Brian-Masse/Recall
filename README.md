# Recall

view Recall on the [App Store](https://apps.apple.com/us/app/recall/id6466136108)

## **About Recall**

Recall is a calendar based app designed around recording daily events to be able to view trends in productivity, goal completion, and time management over time. It is built natively in swift and swiftUI on the front end, and uses MongoDB and Realm DeviceSync on the backend.

## **Upcoming Features**

New Features:
- Locations + links for events
- Photos Galleries for Events
- Automatic Daily Log + image Generation

New Ways to Browse:

- Puts photo gallery, search, favorites, and templates on the same page
- Ability to search through events
- Event Caoursel on the main Calendar Page
- Redesigned Calendar Page + Tool Bar
- Redesigned Monthly Calendar View
- Redesigned Data page

New Ways to Customize:

- Home Screen Widgets
- Personalized Color Pallets
- More Event, Goal, and Data settings

## **Known Bugs**

- Updating the goal contributions of tags causes every event to individually recompile its goal contributions, which takes over 4 minutes on the main thread
> This is a symptom of a large issue: Events independently count their goal contirbutions (so that they can be custom), meaning it can't just read the contributions from the tag

- Updating goal target hours or goal frequency has undefined behavior.
- GoalViews do not have an edit / action buttons
- GoalDataStore does not compile, store, and update goal completion history. 
- The Data page does not show any information related to goals

- Signning Out and signing back in does not redownload events
- Signning Out does not clear the data stored on widgets

## **Package Dependencies**

[**UIUniversals**](https://github.com/Brian-Masse/UIUniversals)

- UIUniversals is a collection of custom swift & swiftUI views, viewModifiers, and extensions. They are designed to be functional and styled views out of the box, however they boast high customization and flexibility to fit into a variety of apps and projects.
- It contains many of the buttons and styles used throughout the app, mostly to ensure the app presentation is consistent

[**RealmSwift**](https://github.com/realm/realm-swift)

- Realm is a mobile database that runs directly inside phones, tablets or wearables. This repository holds the source code for the iOS, macOS, tvOS & watchOS versions of Realm Swift & Realm Objective-C.
- Realm is the primary database manager in Recall. It connects to a MongoDB backend when online, and stores user data locally when offline

## **Product Description**

Recall is a calendar based app designed around recording daily events to be able to view trends in productivity, goal completion, and time management over time. The core loop has users create personal, time-related **goals** (ie. Stay productive for 40hrs each week), and then each night, log and tag **events** that contribute to those goals. To automate this process, there is a tag system, where users create **tags** for the various types of events in their life (ie. Going to the gym, working on homework), which will then contribute all events of that tag to their respective goals. All user data is presented in a dedicated data page to show trends in goal completion, frequent / infrequent events, daily averages. These charts are designed to be glanceable to easily give users insights into their daily habits.

### **Version 2.2.1**

**ADDITIONS**

**Onboarding**

- Added a new onboarding experience
- Added a new authentication / login flow
- Added new "About Recall" introduction screen 

**Calendar Page**

- Added controls for calendar density
- Added split screen for primary calendar
- Added Event Caoursel to main calendar
- Added recall button to tool bar
- Added daily summaries
- Added the ability to create events in between days
- Changed the scroll direction of the calendar
- Added a monthly calendar page view

**Events**

- Added location data to events
- Added hyperlinks to events
- Added photo carousel to events
- Added a rich event view

**Other**

- Added Calendar Widget
- Added Events Widget
- Added Favorites Event Widget

**CHANGES**

- Redesigned all Forms
- Redesigned Goals Page
- Redesigned Date Selector
- Redesigned tab bar
- Redesigned text fields
- Changed main font across app
- Reversed the scroll direction of the day calendar view and monthly calendar view


**BUG FIXES**

- Improved performance throughout the app
- Fixed a bug that prevented event charts from loading on appear
- Fixed various bugs related to the calendar layout

Happy Birthday :)
Happy Thanksgiving :)
Happy Christmas :)
