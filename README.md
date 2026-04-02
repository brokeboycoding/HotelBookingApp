# Hotel Booking Application

A modern, full-stack hotel booking platform built with Flutter, powered by a hybrid backend of Firebase and AWS Lambda, featuring integrated AI assistance.

##  Key Features

###  Multi-Role User System
*   **Customer:** Search for rooms, book stays, manage bookings, chat with owners, and leave reviews.
*   **Hotel Owner:** Post and manage room listings, track revenue statistics, view customer reviews, and confirm bookings.
*   **Admin:** Oversee the platform, approve/reject room listings, monitor all system bookings, and handle reports.

###  AI-Powered Experience
*   **Gemini AI Assistant:** A built-in chatbot that helps users find available rooms using natural language queries.
*   **Hybrid Backend:** The AI agent runs on AWS Lambda, communicating directly with Google's Gemini API and fetching real-time data from Firestore.

###  Advanced Notifications & Communication
*   **Push Notifications:** Real-time device notifications for booking status updates
*   **In-App Chat:** Real-time messaging between customers and hotel owners.

###  Modern UI/UX
*   **Intuitive Search:** Comprehensive filters for room types, price ranges, and amenities.
*   **Google Maps Integration:** View hotel locations directly within the room details.
*   **Responsive Design:** Optimized for a seamless experience across web and mobile.

---

##  Tech Stack

### Frontend
*   **Framework:** [Flutter](https://flutter.dev/)
*   **State Management:** [Provider](https://pub.dev/packages/provider)
*   **Navigation:** Named Routes
*   **Maps:** Google Maps Flutter

### Backend (Hybrid)
*   **Database & Auth:** [Firebase (Firestore, Auth)](https://firebase.google.com/)
*   **Serverless Logic:** [AWS Lambda (Node.js)](https://aws.amazon.com/lambda/)
*   **API Management:** [AWS API Gateway](https://aws.amazon.com/api-gateway/)
*   **Cloud Messaging:** [Firebase Cloud Messaging (FCM)](https://firebase.google.com/docs/cloud-messaging)

### AI
*   **Model:** [Google Gemini Pro](https://deepmind.google/technologies/gemini/)
*   **Integration:** Vertex AI / Google Generative AI SDK

---

##  Architecture Overview
1.  **Flutter App:** Handles the UI and user interactions, using `Provider` to sync state with Firestore.
2.  **AWS Lambda:** Acts as the processing brain for complex tasks like AI reasoning, email composition, and notification triggering.
3.  **API Gateway:** Serves as the secure entry point for the Flutter app to communicate with AWS services, configured with CORS for web compatibility.
##  Security Note
*   Firebase Security Rules are implemented to restrict data access based on user roles and document ownership.
*   AWS credentials and API keys are stored securely in Lambda environment variables and are never exposed in the client-side code.
