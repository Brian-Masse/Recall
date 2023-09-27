# Recall

## **Notes on Indexing System**

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
