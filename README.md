# Recall

In the main branch, and the released implementaiton of Recall, much of the data related to RecallGoals is done on the main thread. 

The actualy functions themselves can be transitioned to the async/await infrastructure fairly easily, especially with the added RecallGoalDataModel class which handles updating the information and computing it when neccessary. In the recallDataModel however, there are multiple functions that rely on goal aggergators which cannot be transitioned easily.

In the current commit, it is displaying no data for any of the goal charts, despite apparently awaiting on all goal aggregators.

In the future these functions, and the ones that use them should all be async to avoid sttutering in the UI, however with lower volume data loadss, the unavoidable stutter due to Apple's Chart behavior in a TabView is a large enough margin of delay to arrbitrate doing this work now
