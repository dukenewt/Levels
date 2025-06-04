##6.2.25 - reviewed the calendar screen and finally realized how dumb it was to have it be 1700 lines. Everything was in there the widgets, providers, anything apparently. Decided to learn more about the architecture and created the core app_provider. Now the providers have a heirarchy(?) and the application is not being run on a piece of floss. 
## 6.2.25 - started the work on better error handling and state management. 
## Items to continue working on
 Add Error Handling - Especially in task completion (users could lose XP)
 ##6.3.25 - completed the overhaul on the error handling in taskCompletion widget. Added a test structure to continue to develop the maintainability and help with refactoring in the future. We now have a better template for the error handling in the app. 
 ##6.3.25 - reworked the app_provider into the app_initialization_manager and simple_app_provider. This was due to the race conditions of the providers at start up. 



Week 2: Performance & UX

Optimize TaskDashboard - Move expensive operations out of build method
Add Loading States - Your users need feedback when things are processing
Fix Navigation - Simplify the screen navigation (you have some redundant screens)

Week 3-4: Architecture

Extract Calendar Components - Break up that massive calendar screen
Create Constants - Replace magic numbers
Add Proper State Management - Add loading/error states to providers

##hanging pawns -- 
edit task widget
dropdown selectors
time component for task creation
skills
skill tree
keyboard on text input and time input
xp, difficulty
notifications
avatar photo add/ icon add?
sign out

Storage operations without error handling - If SharedPreferences fails, users lose data
Animation disposal - Some of your animation controllers might not be properly disposed
Null safety issues - Several places where null checks could be improved