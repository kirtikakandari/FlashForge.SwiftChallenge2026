FLASHFORGE
FlashForge is a SwiftUI-based flashcard learning application created for the Swift Student Challenge. The app helps users create, review, and remember information through interactive flashcards and scheduled reminders.
The main goal of FlashForge is to make revision simple, accessible, and consistent especially for learners who may need more repetition to retain information.

INSPIRATION
Not every learner grasps concepts quickly. Many students fall somewhere in the middle they are not struggling but they also do not retain information easily after studying it once.
FlashForge was created with these learners in mind.
The idea behind the app is inspired by the forgetting curve, which explains how information fades from memory over time without regular revision. FlashForge encourages consistent review by combining flashcards with weekly and monthly reminders, helping users revisit concepts before they forget them.
The goal was to build a simple and accessible study tool that supports memory retention through repetition.

FEATURES
1.Create Flashcards
Users can quickly create flashcards by entering a question and answer. The flashcards are instantly added to the collection.
2.Flashcard Grid View
All flashcards are displayed in a grid layout, allowing users to easily browse and select cards for review.
3.Interactive Flashcard Flip
Flashcards use a 3D flip animation so users can tap a card to switch between the question and the answer.
4.Edit Flashcards
Users can update the question or answer of any existing flashcard.
5.Text-to-Speech Support
Flashcards can be read aloud using AVFoundation, enabling users to revise through audio as well as visual learning.
6.Quiz Mode
Users can test their knowledge through a quiz interface generated from their flashcards, making revision more interactive.
7.Reminder System
FlashForge includes revision reminders to help reinforce learning:
-Weekly reminders
-Monthly reminders
-Custom reminder dates
8.Reminder Dashboard
A dedicated Reminders tab displays all flashcards that have upcoming revision schedules.
9.Accessibility Support
Accessibility labels and hints are included to improve usability with assistive technologies.

TECH STACK
Language: Swift
Framework: SwiftUI
Speech Framework: AVFoundation
Architecture: State-driven UI using SwiftUI bindings

PROJECT STRUCTURE
FlashForge
│
├── FlashForgeApp.swift
│   App entry point
│
├── ContentView.swift
│   Main tab navigation
│
├── HomeView.swift
│   Flashcard creation interface
│
├── FlashcardsView.swift
│   Displays flashcards in a grid layout
│
├── FlashcardDetailSheet.swift
│   Flashcard flip animation, speech, reminders
│
├── EditFlashcardView.swift
│   Allows editing flashcards
│
├── RemindersView.swift
│   Displays upcoming reminder schedules
│
└── Flashcard.swift
    Flashcard data model
    
HOW THE APP WORKS
1.Users create a flashcard from the Home screen by entering a question and answer.
2.The flashcard appears in the Flashcards tab.
3.Tapping a card opens the Flashcard Detail View.
4.Users can:
Flip the card to reveal the answer
Listen to the flashcard using text-to-speech
Edit the flashcard
Set reminder schedules
5.The Reminders tab displays flashcards that have upcoming revision reminders.

DEMO
A video demonstration explaining the app and its features is available on YouTube.
https://youtube.com/shorts/q9gffOI2D8A?si=fkyoebzd7wuBov1e

AUTHOR
Kirtika Kandari
BTech Computer Science Engineering
Galgotias University
