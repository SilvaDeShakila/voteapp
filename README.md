<p align="center">
  <strong>A secure and user-friendly digital voting platform built with Flutter and Firebase.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-Framework-02569B?logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-Language-0175C2?logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Firebase-Backend-FFCA28?logo=firebase&logoColor=black" alt="Firebase">
  <img src="https://img.shields.io/badge/Cloud%20Firestore-Database-FFCA28?logo=firebase&logoColor=black" alt="Firestore">
</p>

---

## 📌 Overview

**VoteX** is a Flutter-based digital voting system designed to provide a secure, verified, and convenient voting experience.

The system combines **email OTP verification, fingerprint biometric authentication, Firebase Authentication, Cloud Firestore, and administrative controls** to create a structured digital voting workflow.

VoteX is designed with separate functionality for **voters and administrators**, allowing the system to manage voter verification, elections, candidates, and voting activities in a centralized environment.

---

## 🎯 Objectives

* Provide a secure and convenient digital voting experience.
* Improve voter authentication and verification.
* Reduce manual processes involved in traditional voting.
* Protect voting-related data using Firebase security mechanisms.
* Provide administrators with centralized voter and election management.
* Prevent unauthorized access to voting functionality.
* Provide a structured and user-friendly voting workflow.

---

## ✨ Key Features

### 🔐 Secure Authentication

* User registration and login
* Firebase Authentication
* Email OTP verification
* Fingerprint biometric authentication
* Authenticated access to protected features
* Secure session management

### 👤 Voter Management

* Voter registration
* Voter profile management
* Voter verification
* Verification status
* Admin approval workflow

### 🗳️ Digital Voting

* View available elections
* View election details
* View candidates
* Select candidates
* Cast votes digitally
* Vote confirmation
* Duplicate-vote prevention

### 👨‍💼 Admin Management

* Admin authentication
* Voter management
* Voter approval
* Election management
* Candidate management
* Monitoring voting-related information

### ☁️ Firebase Backend

* Firebase Authentication
* Cloud Firestore
* Real-time cloud data
* Firestore Security Rules
* Secure database access control

---

## 🔄 Voting Workflow

```text
┌─────────────────────┐
│     Registration    │
└──────────┬──────────┘
           ↓
┌─────────────────────┐
│  Email OTP          │
│  Verification       │
└──────────┬──────────┘
           ↓
┌─────────────────────┐
│ Fingerprint         │
│ Biometric Auth      │
└──────────┬──────────┘
           ↓
┌─────────────────────┐
│ Voter Verification  │
└──────────┬──────────┘
           ↓
┌─────────────────────┐
│ Admin Approval      │
└──────────┬──────────┘
           ↓
┌─────────────────────┐
│ Access Election     │
└──────────┬──────────┘
           ↓
┌─────────────────────┐
│ View Candidates     │
└──────────┬──────────┘
           ↓
┌─────────────────────┐
│     Cast Vote       │
└──────────┬──────────┘
           ↓
┌─────────────────────┐
│  Vote Confirmation  │
└─────────────────────┘
```

---

## 🏗️ System Architecture

```text
                         ┌──────────────────────┐
                         │      VoteX App       │
                         │   Flutter + Dart     │
                         └──────────┬───────────┘
                                    │
                 ┌──────────────────┼──────────────────┐
                 │                  │                  │
                 ▼                  ▼                  ▼
       ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
       │ Firebase Auth   │ │ Email OTP       │ │ Fingerprint     │
       │                 │ │ Verification    │ │ Authentication  │
       └────────┬────────┘ └─────────────────┘ └─────────────────┘
                │
                ▼
       ┌─────────────────────────┐
       │     Cloud Firestore     │
       │                         │
       │ • Voters                │
       │ • Elections             │
       │ • Candidates            │
       │ • Voting Data           │
       │ • Verification Status   │
       └────────────┬────────────┘
                    │
                    ▼
       ┌─────────────────────────┐
       │ Firestore Security Rules│
       └─────────────────────────┘
```

---

## 🛠️ Technology Stack

| Technology                   | Purpose                                |
| ---------------------------- | -------------------------------------- |
| **Flutter**                  | Cross-platform application development |
| **Dart**                     | Application programming language       |
| **Firebase Authentication**  | User authentication                    |
| **Email OTP**                | Email-based identity verification      |
| **Fingerprint Biometrics**   | Biometric authentication               |
| **Cloud Firestore**          | Cloud database                         |
| **Firestore Security Rules** | Database access control                |
| **Firebase CLI**             | Firebase project configuration         |

---

## 📱 Application Modules

### 🔑 Authentication Module

Handles:

* User registration
* Login
* Email verification
* OTP verification
* Fingerprint biometric authentication
* Authenticated access

### 👤 Voter Module

Allows voters to:

* Manage their profile
* View verification status
* Access available elections
* View candidates
* Cast votes
* Receive voting confirmation

### 🗳️ Election Module

Manages:

* Elections
* Election details
* Candidates
* Voting availability
* Voting activities

### 👨‍💼 Admin Module

Provides administrators with functionality for:

* Managing voters
* Approving voters
* Managing elections
* Managing candidates
* Monitoring system information

### 🔒 Security Module

The security layer uses:

* Firebase Authentication
* Email OTP verification
* Fingerprint biometric authentication
* Firestore Security Rules
* Authenticated database access
* Validation and access control

---

## 📸 Screenshots

### 🔐 Authentication

| Login                           | Registration                              | Email OTP                   |
| ------------------------------- | ----------------------------------------- | --------------------------- |
| ![Login](screenshots/login.png) | ![Registration](screenshots/register.png) | ![OTP](screenshots/otp.png) |

### 👆 Biometric Verification

| Fingerprint Authentication                  |
| ------------------------------------------- |
| ![Fingerprint](screenshots/fingerprint.png) |

### 🗳️ Voting

| Home                          | Elections                               | Candidates                                |
| ----------------------------- | --------------------------------------- | ----------------------------------------- |
| ![Home](screenshots/home.png) | ![Elections](screenshots/elections.png) | ![Candidates](screenshots/candidates.png) |

### 👨‍💼 Administration

| Admin Dashboard                           | Voter Management                  | Election Management                           |
| ----------------------------------------- | --------------------------------- | --------------------------------------------- |
| ![Admin](screenshots/admin_dashboard.png) | ![Voters](screenshots/voters.png) | ![Elections](screenshots/admin_elections.png) |

> Replace the screenshot paths above with the actual screenshots from the application.

---

## 📂 Project Structure

```text
voteapp/
│
├── android/
├── ios/
├── linux/
├── macos/
├── web/
├── windows/
│
├── lib/
│   ├── screens/
│   ├── services/
│   ├── models/
│   ├── widgets/
│   └── main.dart
│
├── test/
│
├── .firebaserc
├── firebase.json
├── firestore.rules
├── firestore.indexes.json
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites

Make sure you have the following installed:

* [Flutter SDK](https://flutter.dev/)
* Dart SDK
* Android Studio or VS Code
* Git
* A Firebase project

### 1. Clone the Repository

```bash
git clone https://github.com/SilvaDeShakila/voteapp.git
```

### 2. Navigate to the Project

```bash
cd voteapp
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Configure Firebase

Connect the application to your Firebase project and configure the required Firebase services.

The project contains Firebase configuration files including:

```text
firebase.json
.firebaserc
firestore.rules
firestore.indexes.json
```

### 5. Run the Application

```bash
flutter run
```

To check available devices:

```bash
flutter devices
```

---

## 🔐 Security

Security is a core consideration of the VoteX system.

The application uses multiple layers of authentication and access control:

### Email OTP Verification

Email OTP verification adds an additional verification step during the authentication process.

### Fingerprint Authentication

Fingerprint biometric authentication provides an additional device-level identity verification mechanism for supported devices.

### Firebase Authentication

Firebase Authentication manages user identity and authenticated access to application functionality.

### Firestore Security Rules

Firestore Security Rules help control who can read and write protected data.

### Voting Protection

The system is designed to restrict unauthorized voting activity and prevent duplicate voting within an election.

> **Important:** VoteX is an academic/software engineering project. A real-world national or governmental election system would require extensive independent security audits, penetration testing, legal compliance, privacy reviews, accessibility testing, threat modeling, and formal verification.

---

## 🧪 Testing

The application should be tested for:

* User registration
* Login
* Email OTP verification
* Fingerprint authentication
* Voter verification
* Admin approval
* Election management
* Candidate management
* Vote submission
* Duplicate-vote prevention
* Firestore operations
* Security rules
* Invalid input handling
* Loading states
* Error handling

---

## 🗺️ Future Enhancements

Potential future improvements include:

* 📱 QR-based voter verification
* 🔔 Real-time notifications
* 📊 Advanced election analytics
* 🧾 Detailed audit logs
* 🔐 Multi-factor authentication
* 🌐 Multi-election support
* ♿ Enhanced accessibility
* ⛓️ Blockchain-based vote audit trails
* 🛡️ Independent security auditing
* ⚡ Improved scalability and performance
* 📈 Election reporting and visualization

---

## 💡 Project Highlights

VoteX demonstrates the integration of several modern software engineering concepts:

**Mobile Development**

Flutter is used to create a cross-platform mobile application.

**Cloud Computing**

Firebase provides the backend infrastructure and cloud database.

**Authentication**

Multiple authentication and verification mechanisms are incorporated into the system.

**Database Management**

Cloud Firestore is used to manage structured application data.

**Security**

Authentication, biometric verification, access control, and Firestore Security Rules are used to improve system security.

**Role-Based Functionality**

Different workflows are provided for voters and administrators.

---

## 📌 Project Status

🚧 **Active Development**

VoteX is an academic software engineering project currently under development and refinement.

The system is continuously being improved through feature development, testing, UI enhancements, and security improvements.

---

## 👨‍💻 Developer

### Shakila Chamuditha De Silva

**Information Technology Undergraduate | Software Engineering**

Interested in:

* Mobile Application Development
* Frontend Development
* Backend Development
* Full-Stack Development
* Cloud Technologies
* Software Engineering

---

## 📄 License

This project is developed for educational and software engineering purposes.

---

<p align="center">
  <strong>🗳️ VoteX — Building a More Secure Digital Voting Experience</strong>
</p>

<p align="center">
  
</p>
