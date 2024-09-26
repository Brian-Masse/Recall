# Recall

v2.2.1

<picture>
    <!-- <source srcset="./icon_512x512@2x@2x.png" media="(prefers-color-scheme: dark)" alt="Recall by Brian Masse"> -->
    <img src="./icon_512x512@2x@2x.png" alt="Recall by Brian Masse" width='80'>
</picture>

## **About Recall**

Recall is a calendar based app designed around recording daily events to be able to view trends in productivity, goal completion, and time management over time. It is built natively in swift and swiftUI on the front end, and uses MongoDB and Realm DeviceSync on the backend.

## **Upcoming Features**

- Tap & Hold to create Calendar Events
- Dynamically scaling calendar
- Locations + links for events
- general improvements / bug fixes to the main calendar

## **Package Dependencies**

[**UIUniversals**](https://github.com/Brian-Masse/UIUniversals)

- UIUniversals is a collection of custom swift & swiftUI views, viewModifiers, and extensions. They are designed to be functional and styled views out of the box, however they boast high customization and flexibility to fit into a variety of apps and projects.
- It contains many of the buttons and styles used throughout the app, mostly to ensure the app presentation is consistent

[**RealmSwift**](https://github.com/realm/realm-swift)

- Realm is a mobile database that runs directly inside phones, tablets or wearables. This repository holds the source code for the iOS, macOS, tvOS & watchOS versions of Realm Swift & Realm Objective-C.
- Realm is the primary database manager in Recall. It connects to a MongoDB backend when online, and stores user data locally when offline

## **Product Description**

Recall is a calendar based app designed around recording daily events to be able to view trends in productivity, goal completion, and time management over time. The core loop has users create personal, time-related **goals** (ie. Stay productive for 40hrs each week), and then each night, log and tag **events** that contribute to those goals. To automate this process, there is a tag system, where users create **tags** for the various types of events in their life (ie. Going to the gym, working on homework), which will then contribute all events of that tag to their respective goals. All user data is presented in a dedicated data page to show trends in goal completion, frequent / infrequent events, daily averages. These charts are designed to be glanceable to easily give users insights into their daily habits.

## **Developmental process & Problem Identification**

Recall is designed to promote mindful living by encouraging users to reflect on the pace of their daily life. Recognizing the importance of reflection, It was created after identifying a gap between traditional journaling and statistical documentation. Journaling, which offers a very subjective way of reflecting on daily habits and emotions, can both intimidate people because of its lack of structure, and be difficult to return to or make judgements from, while documenting trends with spreadsheets and productivity apps lacks flexibility and fails to capture emotional insights. Recall is built on the foundation of structured journaling, a technique that provides flexibility to recount non-empirical ideas while maintaining organization and technical usability. Every night, users are guided to record the events of their day, with space to reflect on the interpersonal and emotional components of their life. Data insights from those records—ranging from most frequent events over time to goal completion habits—are then designed to provide both an objective look into daily patterns as well as reflect on subjective feelings and emotional trends over time.

## **Version History**

### **Version 2.2.1**

ADDITIONS
- added controls for calendar density
- added split screen for primary calendar
- added recall button to tool bar

CHANGES

- Redesigned all Forms
- Redesigned Goals Page
- Redesigned Date Selector
- redesigned tab bar

- Fixed various bugs related to the calendar layout


Happy Birthday :)


