# CLAUDE.md — Tunnel iOS App

> Brief complet pour le développement de l'app **Tunnel**. À lire avant TOUTE action sur le code.

---

## 1. Produit

### Nom
**Tunnel** — clin d'œil au "tunnel conversationnel" dont l'app permet de s'extraire.

### Pitch
App iPhone qui déclenche un **faux appel entrant** à la demande, pour s'extraire poliment d'une conversation tunnel (collègue relou, oncle bavard, rendez-vous qui s'éternise).

### User story principale
1. L'utilisateur est piégé dans une conversation.
2. Il tapote discrètement l'arrière de son iPhone (geste **Back Tap** natif iOS).
3. Le téléphone sonne comme pour un vrai appel entrant, avec nom, photo, et son système.
4. L'utilisateur "décroche", s'éloigne, s'excuse, et se sauve.

### Ton produit
- Humour assumé, zéro culpabilisation.
- L'app doit être **crédible visuellement** (sinon ça ne marche pas) mais rester **transparente** dans sa description App Store (app de prank, pas d'usurpation).

---

## 2. Stack technique

| Élément | Choix | Raison |
|---|---|---|
| Langage | Swift 5.9+ | Natif Apple |
| UI | SwiftUI | Moderne, concis, idéal pour IA |
| iOS cible | **iOS 17+** | Accès à App Intents, Observation framework |
| Architecture | MVVM léger | Simple pour une app de cette taille |
| Dépendances externes | **Zéro** | Tout en natif Apple |
| Persistance | `@AppStorage` / UserDefaults | Config simple, pas besoin de CoreData |

### Frameworks utilisés
- `SwiftUI` — toute l'UI
- `AppIntents` — pour le déclenchement via Raccourcis/Back Tap
- `AVFoundation` — lecture du son de sonnerie
- `CoreHaptics` — vibrations réalistes
- `UIKit` (minimal) — uniquement pour récupérer la haptique système si besoin

### ⚠️ Pas de CallKit
On NE passe PAS par CallKit (le vrai framework d'appels). Raisons :
- Complexité élevée, permissions CallDirectory.
- Apple refuse presque systématiquement les apps CallKit qui ne sont pas de vrais clients VoIP.
- On recrée l'UI à l'identique en SwiftUI, ça suffit pour l'illusion.

---

## 3. Architecture des fichiers

```
Tunnel/
├── TunnelApp.swift                # Entry point, @main
├── ContentView.swift              # Router : Home ou IncomingCall
│
├── Models/
│   ├── FakeCallConfig.swift       # Struct config : nom, photo, sonnerie, délai
│   └── AppState.swift             # @Observable state global (mode actuel)
│
├── Views/
│   ├── HomeView.swift             # Écran principal : bouton "Déclencher" + réglages
│   ├── IncomingCallView.swift     # ⭐ Écran faux appel (clone iOS)
│   ├── InCallView.swift           # Écran après "décrochage" (timer, mute, etc.)
│   ├── SettingsView.swift         # Config : contact, photo, délai, sonnerie
│   └── Components/
│       ├── CallActionButton.swift # Boutons verts/rouges ronds
│       └── SlideToAnswer.swift    # Slider "glisser pour répondre"
│
├── Services/
│   ├── RingtonePlayer.swift       # AVAudioPlayer + gestion du mode silencieux
│   ├── HapticsManager.swift       # CoreHaptics patterns (vibration d'appel)
│   └── FakeCallScheduler.swift    # Timer pour déclenchement différé
│
├── Intents/
│   ├── TriggerTunnelIntent.swift          # App Intent (Back Tap / Shortcuts)
│   └── TunnelAppShortcuts.swift           # Expose l'intent au système
│
└── Resources/
    ├── Assets.xcassets             # Icône app, couleurs, photo par défaut
    └── Sounds/
        └── default_ringtone.caf    # Sonnerie par défaut (libre de droits)
```

---

## 4. Fonctionnalités — MVP (v1.0)

### 🎯 Must-have
1. **Écran faux appel** visuellement identique à iOS (lockscreen + in-app).
2. **Déclenchement immédiat** depuis un bouton dans l'app.
3. **Déclenchement différé** (3s / 5s / 10s / 30s / 1min) pour laisser le temps de ranger le téléphone.
4. **Déclenchement via App Intent** pour Back Tap et Raccourcis Siri.
5. **Configuration du contact** : nom, photo, numéro factice.
6. **Sonnerie par défaut** + haptique qui imite un appel entrant.
7. **Slide-to-answer** + bouton rouge pour raccrocher.
8. **Écran "in-call"** avec timer qui défile après décrochage.

### 💡 Nice-to-have (v1.1+)
- Plusieurs contacts préconfigurés ("Maman", "Boss", "Médecin")
- Voix pré-enregistrées qui se lancent au décrochage (lip-sync)
- Widget Lock Screen pour trigger en 1 tap
- Apple Watch companion (trigger depuis la montre)
- Mode "FaceTime" en plus de l'appel classique

---

## 5. Spécifications UI — Écran faux appel

### Référence visuelle
Reproduire l'écran d'appel entrant iOS 17/18 à l'identique :
- Fond : blur gradient sombre
- Photo de contact : cercle 120pt, centré, en haut
- Nom du contact : SF Pro Display, 32pt, weight semibold, blanc
- Sous-titre : "mobile" en 17pt, blanc 70%
- Boutons en bas :
  - Rond rouge (decline) : 72pt, icône `phone.down.fill`
  - Rond vert (accept) : 72pt, icône `phone.fill`, anime en pulse
- Si lockscreen-like : remplacer boutons par slide-to-answer

### Animations
- Pulse doux sur bouton vert (scale 1.0 ↔ 1.08, 1.5s ease-in-out infini)
- Vibration haptique en pattern : 1s on / 2s off, répété
- Sonnerie en loop jusqu'à action utilisateur

### Mode lockscreen vs in-app
Commencer simple : UN SEUL écran plein écran qui ressemble à l'appel en in-app. Le "lockscreen mode" viendra plus tard (nécessite Live Activities ou Focus).

### Identité visuelle Tunnel (hors écran faux appel)
Sur les écrans **Home / Settings / Onboarding**, ne PAS reproduire l'UI iOS. Développer une identité propre à Tunnel :
- Direction artistique cohérente avec le nom : sensation d'échappée, de passage, de sortie.
- Palette à définir plus tard — commencer sobre (noir / blanc / un accent de couleur).
- L'écran d'appel reste le seul endroit qui mime iOS, pour le réalisme.

---

## 6. Implémentation critique — App Intent

C'est le point le plus important pour que **Back Tap fonctionne**. Back Tap ne peut pas lancer une app directement ; il passe par un Raccourci Siri qui exécute un App Intent.

```swift
import AppIntents

struct TriggerTunnelIntent: AppIntent {
    static var title: LocalizedStringResource = "Déclencher Tunnel"
    static var description = IntentDescription("Lance immédiatement un faux appel entrant.")
    
    // Important : ouvre l'app au premier plan
    static var openAppWhenRun: Bool = true
    
    @Parameter(title: "Délai (secondes)", default: 0)
    var delay: Int
    
    @MainActor
    func perform() async throws -> some IntentResult {
        AppState.shared.scheduleFakeCall(delay: TimeInterval(delay))
        return .result()
    }
}

struct TunnelAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: TriggerTunnelIntent(),
            phrases: [
                "Lance \(.applicationName)",
                "\(.applicationName) appelle-moi",
                "Sors-moi du tunnel avec \(.applicationName)"
            ],
            shortTitle: "Déclencher Tunnel",
            systemImageName: "phone.fill"
        )
    }
}
```

### Parcours utilisateur pour activer Back Tap
À documenter dans un onboarding in-app :
1. Ouvrir **Réglages > Accessibilité > Toucher > Toucher au dos**
2. Choisir **Double toucher** ou **Triple toucher**
3. Sélectionner **Raccourci** > **Déclencher Tunnel** (qui apparaît automatiquement grâce à `AppShortcutsProvider`)

---

## 7. Implémentation critique — Son + Vibration

### Sonnerie
Utiliser `AVAudioPlayer` en mode `.playback` pour que ça sonne **même en mode silencieux** (important pour le réalisme). Activer la boucle.

```swift
let session = AVAudioSession.sharedInstance()
try session.setCategory(.playback, mode: .default)
try session.setActive(true)

player = try AVAudioPlayer(contentsOf: url)
player?.numberOfLoops = -1 // loop infini
player?.play()
```

⚠️ Ajouter `UIBackgroundModes > audio` dans `Info.plist` si on veut que le son continue si l'écran se verrouille pendant le délai.

### Haptique
CoreHaptics pattern qui imite l'appel :
- Sharp transient toutes les ~200ms pendant 1s
- Pause 2s
- Répéter

Fallback sur `UINotificationFeedbackGenerator` si haptique indisponible.

---

## 8. Conventions de code

- **SwiftUI uniquement**, pas de UIViewRepresentable sauf nécessité absolue.
- **Async/await** pour toute opération asynchrone, pas de completion handlers.
- **`@Observable`** (Swift Observation, iOS 17+) plutôt que `@ObservableObject`.
- **Une view = un fichier**. Décomposer agressivement.
- **Nommage** : anglais pour le code, **français** pour les strings UI (l'app vise un public français d'abord).
- **Pas de print()** : utiliser `Logger` d'OSLog.
- **Previews SwiftUI obligatoires** pour chaque view.

---

## 9. Piège à éviter à la review Apple

Apple est OK avec les fake call apps (il y en a plein sur le store). Pour éviter le rejet :
- **Description App Store honnête** : "Tunnel — app de prank qui simule un appel entrant pour vous sortir de conversations gênantes".
- **Pas de CallKit.**
- **Ne pas imiter un contact réel par défaut** : photo générique et nom "Contact" par défaut, à l'utilisateur de customiser.
- **Mentionner** dans la description que l'app nécessite une action manuelle de l'utilisateur (pas un appel réel).

---

## 10. Roadmap de développement (ordre suggéré pour Cursor)

1. ⚙️ Scaffold : créer le projet Xcode, dossiers, fichiers vides.
2. 🎨 `IncomingCallView` statique (pas de logique, juste l'UI parfaite).
3. 🏠 `HomeView` avec bouton "Déclencher maintenant" qui navigue vers `IncomingCallView`.
4. 🔊 `RingtonePlayer` + son par défaut.
5. 📳 `HapticsManager` + pattern d'appel.
6. ⏱ `FakeCallScheduler` avec délai configurable.
7. 📞 `InCallView` (timer, raccrocher).
8. ⚙️ `SettingsView` + persistance `@AppStorage`.
9. 🤖 `TriggerTunnelIntent` + `TunnelAppShortcuts`.
10. 📖 Onboarding Back Tap (écran explicatif au premier lancement).
11. 🎨 Icône app + polissage final.
12. 🧪 Tests sur device physique (le simulateur ne fait PAS les haptiques).

---

## 11. Ressources

- [Human Interface Guidelines — Phone](https://developer.apple.com/design/human-interface-guidelines/phone)
- [App Intents documentation](https://developer.apple.com/documentation/appintents)
- [Core Haptics patterns](https://developer.apple.com/documentation/corehaptics)
- Sonneries libres de droits : [freesound.org](https://freesound.org) (filtrer par licence CC0)

---

## 12. Instructions pour Cursor

- **Toujours lire ce CLAUDE.md en entier avant d'agir.**
- Travailler fichier par fichier, dans l'ordre de la roadmap (§10).
- Générer les SwiftUI Previews pour chaque view.
- Respecter les conventions §8.
- En cas de doute sur un choix Apple (permissions, Info.plist), DEMANDER plutôt que deviner.
- Vérifier que le code compile sur iOS 17+ minimum.
