# 🎬 Which Movie Tonight? (WMT)

Une application iOS moderne qui utilise l'IA pour recommander des films personnalisés selon vos envies et préférences.

## 🎯 Objectif

WMT est une application iOS qui révolutionne la façon de choisir un film à regarder. En utilisant l'intelligence artificielle (OpenAI), l'application analyse vos préférences et vous suggère des films parfaitement adaptés à vos envies du moment.

### Fonctionnalités principales
- Recommandations personnalisées via IA
- Informations détaillées sur les films (affiche, résumé, note, bande-annonce, acteurs)
- Gestion de votre watchlist
- Système de notation des films vus
- Historique des recommandations
- Intégration des plateformes de streaming disponibles

## 🛠️ Stack Technique

### Frontend
- **Framework**: SwiftUI
- **Architecture**: MVVM (Clean Architecture)

### Backend & Services
- **IA & Recommandations**: OpenAI API
- **Données Films**: OMDb API
- **Authentification**: Firebase Auth (Apple/Google Sign-in)
- **Base de données**: Firestore
- **Monétisation**: RevenueCat

## 🚀 MVP Features

### Phase 1: Onboarding & Authentification
- [ ] Onboarding visuel
- [ ] Authentification Apple/Google
- [ ] Gestion des profils utilisateurs

### Phase 2: Core Features
- [ ] Interface de saisie des préférences
- [ ] Intégration OpenAI pour les recommandations
- [ ] Récupération des données via OMDb
- [ ] Affichage des MovieCards (design VisionPro/glassmorphisme)

### Phase 3: Gestion des Films
- [ ] Watchlist personnelle
- [ ] Historique des recommandations
- [ ] Système de notation
- [ ] Stockage Firestore

### Phase 4: Monétisation
- [ ] Intégration RevenueCat
- [ ] Période d'essai de 7 jours
- [ ] Gestion des abonnements premium

## 📁 Structure du Projet

```
WMTApp/
├── App/
│   └── WMTApp.swift
├── Data/
│   ├── DTO/
│   ├── Services/   (OpenAIService, OMDBService, FirebaseService, RevenueCatService)
│   └── Repositories/
├── Domain/
│   ├── Models/
│   ├── UseCases/
│   └── Repositories/
├── Presentation/
│   ├── Onboarding/
│   ├── Auth/
│   ├── Home/
│   ├── MovieDetails/
│   └── Components/
└── Resources/
    └── Assets, Fonts, Localization
```

## 🔐 Configuration Requise

### Prérequis
- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+
- Swift Package Manager

### API Keys Nécessaires
- OpenAI API Key
- OMDb API Key
- Firebase Configuration
- RevenueCat API Key

## 📱 Screenshots

*À venir*

## 📄 Licence

*À définir*

---

Développé avec ❤️ pour les cinéphiles 