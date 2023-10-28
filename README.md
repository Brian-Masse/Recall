# Recall

<picture>
    <!-- <source srcset="./icon_512x512@2x@2x.png" media="(prefers-color-scheme: dark)" alt="Recall by Brian Masse"> -->
    <img src="./icon_512x512@2x@2x.png" alt="Recall by Brian Masse" width='80'>
</picture>

### **Product Description**

Recall is a calendar based app designed around recording daily events to be able to view trends in productivity, goal completion, and time management over time. The core loop has users create personal, time-related **goals** (ie. Stay productive for 40hrs each week), and then each night, log and tag **events** that contribute to those goals. To automate this process, there is a tag system, where users create **tags** for the various types of events in their life (ie. Going to the gym, working on homework), which will then contribute all events of that tag to their respective goals. All user data is presented in a dedicated data page to show trends in goal completion, frequent / infrequent events, daily averages. These charts are designed to be glanceable to easily give users insights into their daily habits.

### **Developmental process & Problem Identification**

Recall is designed to promote mindful living by encouraging users to reflect on the pace of their daily life. Recognizing the importance of reflection, It was created after identifying a gap between traditional journaling and statistical documentation. Journaling, which offers a very subjective way of reflecting on daily habits and emotions, can both intimidate people because of its lack of structure, and be difficult to return to or make judgements from, while documenting trends with spreadsheets and productivity apps lacks flexibility and fails to capture emotional insights. Recall is built on the foundation of structured journaling, a technique that provides flexibility to recount non-empirical ideas while maintaining organization and technical usability. Every night, users are guided to record the events of their day, with space to reflect on the interpersonal and emotional components of their life. Data insights from those records—ranging from most frequent events over time to goal completion habits—are then designed to provide both an objective look into daily patterns as well as reflect on subjective feelings and emotional trends over time.

### **System Design & Technologies**

Recall is built from Swift and SwiftUI on the front end, and MongoDB and Realm DeviceSync on the back end. The app follows the MVVM model for all of its object modeling and app flow structuring, however, it uses many features from DeviceSync to extend that design to the backend as well. This means that the app is fully reactionary and automatically syncs all user data across devices. User sign in and authentification is the combination of MongoDB account registration, signInWithApple, and userDefaults local storage on iPhone. These technologies provide users with two sign in methods—email + password or signInWithApple—, and using local storage, keeps users signed in between sessions. The app also provides basic account control, including account modification and deletion, both of which are built using swift controllers that process local changes and push them to the back end. Data is processed on device, and works off an index system to have scalable performance. Instead of recomputing user data for any user interaction, the index stores high volumes of user data, formatted in a quick access data structure, that is either appended to or individually modified during user write interactions. This means regardless of how much data is being, or more fittingly has been, processed, the run time for adding / modifying events is constant. The app also uses the UserNotifications API for local notifications, and relies on the async await paradigm for asynchronous work.

### **Role & Responsibilities**

I independently developed this project, from problem identification, project brainstorming, development, testing, release, and marketing. I used skills in system design, OOP, various Apple frameworks, MongoDB, and backend database management to put together this project.

## **Version History**

### **Snapshot 1.02**

NEW FEATURES

- added the notes of an event to the preview on the timeline
- added a toggle to view notes on event previews
- added the ability to set the default length of events
- added a toggle to turn on universal fine time selection
- added a toggle to change default event snapping
- added a button to quickly clear the title or description of an event

BUG FIXES:

- expanded the height of certain charts in the data page when viewing this week.

### **Version 1.01**

BUG FIXES:

- Fixed an issue that prevented data created in the tutorial from syncing to the rest of the app
- Fixed an issue that caused the app to crash when clicking on a goal from the tag list

### **Version 1.00**

initial release

---

_for developer notes, look at commit e8c84f6 and prior, [here](https://github.com/Brian-Masse/Recall/commit/e8c84f63f5e9383ed0b837e29f1cf21197cabb4d)_
