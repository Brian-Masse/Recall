# Recall

### **Product Description**
Recall is a calendar based app designed around recording daily events to be able to view trends in productivity, goal completion, and time management over time. The core loop has users create personal, time-related **goals** (ie. Stay productive for 40hrs each week), and then each night, log and tag **events** that contribute to those goals.  To automate this process, there is a tag system, where users create **tags** for the various types of events in their life (ie. Going to the gym, working on homework), which will then contribute all events of that tag to their respective goals. All user data is presented in a dedicated data page to show trends in goal completion, frequent / infrequent events, daily averages. These charts are designed to be glanceable to easily give users insights into their daily habits.

### **Developmental process & Problem Identification**
Recall is designed to promote mindful living by encouraging users to reflect on the pace of their daily life. Recognizing the importance of reflection, It was created after identifying a gap between traditional journaling and statistical documentation. Journaling, which offers a very subjective way of reflecting on daily habits and emotions, can both intimidate people because of its lack of structure, and be difficult to return to or make judgements from, while documenting trends with spreadsheets and productivity apps lacks flexibility and fails to capture emotional insights. Recall is built on the foundation of structured journaling, a technique that provides flexibility to recount non-empirical ideas while maintaining organization and technical usability. Every night, users are guided to record the events of their day, with space to reflect on the interpersonal and emotional components of their life. Data insights from those records—ranging from most frequent events over time to goal completion habits—are then designed to provide both an objective look into daily patterns as well as reflect on subjective feelings and emotional trends over time.

### **System Design & Technologies**
Recall is built from Swift and SwiftUI on the front end, and MongoDB and Realm DeviceSync on the back end. The app follows the MVVM model for all of its object modeling and app flow structuring, however, it uses many features from DeviceSync to extend that design to the backend as well. This means that the app is fully reactionary and automatically syncs all user data across devices. User sign in and authentification is the combination of MongoDB account registration, signInWithApple, and userDefaults local storage on iPhone. These technologies provide users with two sign in methods—email + password or signInWithApple—, and using local storage, keeps users signed in between sessions. The app also provides basic account control, including account modification and deletion, both of which are built using swift controllers that process local changes and push them to the back end. Data is processed on device, and works off an index system to have scalable performance. Instead of recomputing user data for any user interaction, the index stores high volumes of user data, formatted in a quick access data structure, that is either appended to or individually modified during user write interactions. This means regardless of how much data is being, or more fittingly has been, processed, the run time for adding / modifying events is constant. The app also uses the UserNotifications API for local notifications, and relies on the async await paradigm for asynchronous work.

### **Role & Responsibilities** 
I independently developed this project, from problem identification, project brainstorming, development, testing, release, and marketing. I used skills in system design, OOP, various Apple frameworks, MongoDB, and backend database management to put together this project. 

## **Version History**

### **Version 1.01**
BUG FIXES:

- Fixed an issue that prevented data created in the tutorial from syncing to the rest of the app
- Fixed an issue that caused the app to crash when clicking on a goal from the tag list

### **Version 1.00**
initial release

## **Developer Notes**
### **Notes on Indexing System**

_Updated on 9/3/23_

One of the most expensive operations in the code is graphing which goals were met over time. This is because the code goes through each day since the creation of the app, then iterates through each goal, and computes whether it was met on that day or not. That operation itself filters all the events downloaded from the realm to manually determine whether the goal was met on a certain day

### **Solutions**

\*Note: All aggregation / date functions are run asyncronously off the main thread to avoid performance bottlenecking.\*\*

#### **Solution 1**

Optimize the `goalWasMet(on: )` function. Instead of receiving all downloaded events, find a more efficient way to query just the events that the goal needs on a given day. Possible solutions include:

- Query Realm directly, effectively outsourcing the work of optimizing the filter process to a third party. Difficult to measure the efficiency of this unkown filtering process, and still likely combing through mass amounts of data for each goal, each day

- Store events in a collection designed for high access. This would likely be a dictionary with the date value of the event as its key. This would eliminate all searching and filtering time, but would either require storing a copy of every event in the index, or re-indexing every event at runtime.

Even with an optimized `goalWasMet(on:)` function, there is still some computation being done for each goal on each day as the history is being constructed

#### **Solution 2 - Implementing**

Store the goalWasMet results in an inexpensive, easily accessible list, and access that when building out the history.

The major downside of this solution is that creates a second data source / source of truth, meaning that this copied data must be rigorously updated to match any changes made on the database

- If the database is updated remotely / in a way that a user's device can not immediately detect, the app must either detect that specific change and update the copied data, or reindex the storage. (which would likely route to solutions mentioned in solution 1)

  #### **Solutions**

  - NEED TO FIND A SOLUTION FOR REMOTE UPDATING

- If the database is updated locally, the only change that would matter is ultimately an update to events. (a tag changing which goals to update would then show up in the events)

  #### **Solutions**

  - store goalWasMet in a dictionary, with the date as the key, and a bool as the data

  - when an event is updated, process it through the RecallIndex

  - the index, for each day starting at the updated event, and ending at the following sunday (this may be redundant for daily goals), checks whether each gaol was met. If it is different from its stored value, update it.
