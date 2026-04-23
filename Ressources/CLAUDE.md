# CLAUDE.md — Tunnel iOS App

> Brief complet pour le développement de l'app **Tunnel** (nom App Store : **Untunnel**).
> À lire avant TOUTE action sur le code.

---

## 1. Produit

### Nom
**Tunnel** (code) / **Untunnel** (App Store) — clin d'œil au "tunnel conversationnel" dont l'app permet de s'extraire.

### Pitch
App iPhone qui déclenche un **faux appel entrant** à la demande, pour s'extraire poliment d'une conversation tunnel (collègue relou, oncle bavard, rendez-vous qui s'éternise).

### User story principale
1. L'utilisateur est piégé dans une conversation.
2. Il tapote discrètement l'arrière de son iPhone (geste **Back Tap** natif iOS) — **OU** appuie sur l'Action Button (iPhone 15 Pro+), **OU** lance un Raccourci Siri.
3. Le téléphone sonne comme un vrai appel entrant, **même écran verrouillé**, avec le nom configuré, la sonnerie système, et vibration.
4. L'utilisateur décroche (Face ID), s'éloigne, s'excuse, et se sauve.

### Ton produit
- Humour assumé, zéro culpabilisation.
- Positionnement App Store = **outil social** ("sortir d'une conversation en un geste"), pas "prank / trick / fool".
- L'app doit rester **transparente** : aucune capacité à tromper un tiers (impossible d'imiter un vrai numéro).

---

## 2. Stack technique

| Élément | Choix | Raison |
|---|---|---|
| Langage | Swift 5.9+ | Natif Apple |
| UI | SwiftUI | Moderne, concis |
| iOS cible | **iOS 17+** | App Intents, Observation framework |
| Architecture | MVVM léger, compartimentation stricte du CallKit | Simple, testable |
| Dépendances externes | **Zéro** | Tout en natif Apple |
| Persistance | `UserDefaults` via `Codable` | Config simple, pas de CoreData |

### Frameworks utilisés
- `SwiftUI` — UI in-app (Home, Settings, Onboarding, InCall)
- `AppIntents` — déclenchement via Raccourcis / Back Tap / Action Button
- `CallKit` — UI d'appel entrant système (ring phase, lock screen OK)
- `UIKit` (minimal) — `isIdleTimerDisabled`, `UIImpactFeedbackGenerator`
- `OSLog` — logs structurés

### ✅ CallKit — pourquoi, et comment rester compliant
On passe par `CXProvider.reportNewIncomingCall` car c'est la **seule API iOS** qui fonctionne sur un appareil verrouillé pour présenter une UI d'appel entrant avec sonnerie + vibration. Sans CallKit, un App Intent avec `openAppWhenRun = true` n'active pas la scène tant que Face ID n'a pas déverrouillé → pas de son, pas de vibration. C'est le bug central que v1.1 corrige.

Pour éviter un rejet App Store, le code applique **7 règles non négociables** (voir §9).

---

## 3. Architecture des fichiers

```
Tunnel/
├── TunnelApp.swift                # Entry point, @main, warm-up CallKitManager
├── ContentView.swift              # Router 4 écrans (Home / Onboarding / InCall / Settings)
│
├── Models/
│   ├── FakeCallConfig.swift       # Struct Codable : contactName, subtitle, fakePhoneNumber, contactImageData
│   └── AppState.swift             # @Observable, screen state, config persistence, CallKit callbacks
│
├── Views/
│   ├── HomeView.swift             # Bouton "Sortir du tunnel" (déclenchement immédiat)
│   ├── OnboardingView.swift       # Tuto Back Tap / Action Button / Raccourci
│   ├── InCallView.swift           # Écran après décrochage (timer, raccrocher)
│   ├── SettingsView.swift         # Config contact (nom, sous-titre, numéro, photo)
│   └── PrivacyPolicyView.swift    # Politique in-app
│
├── Services/
│   └── CallKitManager.swift       # ⭐ Seul fichier qui importe CallKit, applique les 7 règles
│
├── Intents/
│   ├── TriggerTunnelIntent.swift  # AppIntent (openAppWhenRun = false) → CallKitManager
│   └── TunnelAppShortcuts.swift   # Expose l'intent au système (Siri / Back Tap)
│
└── Resources/
    └── Assets.xcassets            # Icône app, couleurs
```

**Compartimentation stricte :** `CallKit` n'est importé que dans `CallKitManager.swift`. Aucun autre fichier ne touche aux APIs CallKit. Le reste du code passe par les méthodes publiques de `AppState` (`triggerFakeCallNow`, `endCall`) et les callbacks (`didAnswerCallKit`, `didEndCallKit`).

---

## 4. Flux d'appel (référence)

```
Back Tap / Action Button / Raccourci Siri
  → TriggerTunnelIntent.perform() (openAppWhenRun = false)
  → CallKitManager.reportIncomingCall(contactName:)
  → CXProvider.reportNewIncomingCall
  → UI iOS native plein écran (lock screen OK, sonnerie système, vibration)
       │
       ├── Accept → CXAnswerCallAction → AppState.didAnswerCallKit()
       │           → screen = .inCall → iOS ouvre l'app (Face ID si verrouillé)
       │           → InCallView visible
       │
       └── Decline → CXEndCallAction → AppState.didEndCallKit()
                   → app reste fermée / dans son état précédent
```

Le déclenchement **immédiat depuis le bouton HomeView** passe par le même chemin (`AppState.triggerFakeCallNow` → `CallKitManager`) pour éviter deux implémentations divergentes.

---

## 5. Spécifications UI — écrans in-app

### HomeView
Identité propre Tunnel (ne mime PAS iOS). Bouton central "Sortir du tunnel". Lien discret vers Settings.

### InCallView
Affichée après décrochage. Timer qui défile. Bouton "Raccrocher" rouge qui appelle `AppState.endCall()`.

### Écran d'appel entrant
**N'existe plus dans le code.** C'est la UI système CallKit qui est affichée. Rien à styliser.

### Mode lockscreen
Géré nativement par CallKit. Rien à faire côté app.

---

## 6. Conventions de code

- **SwiftUI uniquement**, pas de UIViewRepresentable sauf nécessité absolue.
- **Async/await** pour toute opération asynchrone, pas de completion handlers (sauf là où l'API Apple l'impose, ex. `CXCallController.request`).
- **`@Observable`** (Swift Observation, iOS 17+) plutôt que `@ObservableObject`.
- **Une view = un fichier**. Décomposer agressivement.
- **Nommage** : anglais pour le code, **français** pour les strings UI (public FR d'abord).
- **Pas de `print()`** : `Logger` d'OSLog uniquement (`subsystem: "rewolf.Tunnel"`).
- **Previews SwiftUI** pour chaque view.
- **`@MainActor`** sur tout ce qui touche `AppState` ou l'UI.

---

## 7. Implémentation critique — App Intent

Back Tap passe par un Raccourci Siri → `AppIntent`. Le point-clé :

```swift
struct TriggerTunnelIntent: AppIntent {
    static var title: LocalizedStringResource = "Déclencher Tunnel"
    static var openAppWhenRun: Bool = false    // ⚠️ CRITIQUE — CallKit owns the UI

    @MainActor
    func perform() async throws -> some IntentResult {
        try await CallKitManager.shared.reportIncomingCall(
            contactName: AppState.shared.config.contactName
        )
        return .result()
    }
}
```

`openAppWhenRun = false` est **critique** : si `true`, iOS tenterait d'amener l'app au premier plan en même temps que CallKit présente sa UI, ce qui ferait flasher HomeView derrière la carte CallKit. Ce qui défait tout l'intérêt de la migration.

### Parcours utilisateur Back Tap (à documenter dans OnboardingView)
1. Réglages → Accessibilité → Toucher → Toucher au dos
2. Double toucher OU Triple toucher
3. Raccourci → Déclencher Tunnel

---

## 8. Implémentation critique — CallKit (`CallKitManager`)

Fichier unique : `Tunnel/Services/CallKitManager.swift`. Singleton `@MainActor`.

**Ce qu'il fait :**
- Crée un `CXProvider` au démarrage (warm-up depuis `TunnelApp.init`).
- Expose `reportIncomingCall(contactName:)` et `endActiveCall()`.
- Implémente `CXProviderDelegate` pour router les `CXAnswerCallAction` / `CXEndCallAction` vers `AppState`.

**Ce qu'il ne fait PAS (règles §9) :**
- Aucun `didActivate(audioSession:)` → règle 6
- Aucune persistance de l'UUID (in-memory uniquement) → règle 7
- Aucun ringtone custom → règle 5
- `CXHandle.type = .generic` hardcodé (jamais `.phoneNumber`) → règle 3
- `includesCallsInRecents = false` → règle 4

---

## 9. Compliance App Store — les 7 règles (non négociables)

Apple approuve les fake-call apps qui utilisent CallKit **sans prétendre être un client VoIP**. Chaque règle ci-dessous envoie un signal spécifique au reviewer.

| # | Règle | Où appliquée | Signal |
|---|---|---|---|
| 1 | `UIBackgroundModes = audio` uniquement — **jamais `voip`** | Info.plist | "Pas un VoIP app" |
| 2 | Aucun PushKit, aucun entitlement VoIP | project + entitlements | Idem |
| 3 | `CXHandle(type: .generic, ...)` — **pas `.phoneNumber`** | `CallKitManager.reportIncomingCall` | "On ne spoofe pas de numéro" |
| 4 | `CXProviderConfiguration.includesCallsInRecents = false` | `CallKitManager.init` | "Pas de pollution Phone.app" |
| 5 | `ringtoneSound = nil` (sonnerie système) | `CallKitManager.init` | "On n'imite aucun autre app" |
| 6 | Aucun audio routé via la session CallKit | Pas de `provider(_:didActivate:)` | "Pas de voix réelle" |
| 7 | Aucune persistance du call UUID | `private var currentCallUUID` | "Pas de surface data-privacy" |

Ces règles se traduisent directement dans le code — aucun toggle utilisateur ne peut les contourner.

### Positionnement App Store (description + mots-clés)
- **À utiliser** : "sortir poliment d'une conversation", "outil social", "extraction discrète", "Back Tap"
- **À éviter absolument** : "prank", "trick", "fool", "fake" (dans le marketing — "simulation" est OK)

### Notes for App Review (à coller dans App Store Connect lors de la soumission v1.1)
Voir `/Users/nicolas/.claude/plans/lexical-wobbling-kurzweil.md` section "Notes pour l'App Review".

---

## 10. Ce qui a changé en v1.1 (migration CallKit)

**Supprimés :**
- `IncomingCallView.swift` (remplacé par UI iOS native)
- `SlideToAnswer.swift`, `CallActionButton.swift` (orphelins)
- `HapticsManager.swift` (CallKit gère vibration)
- `RingtonePlayer.swift` (CallKit gère sonnerie — règle 5)
- Champs config `useSlideToAnswer`, `ringtoneName`
- Toggle "Glisser pour répondre" + Picker de sonnerie dans Settings
- Ancienne logique `scenePhase` / `pendingTrigger` / `setSceneActive` dans AppState

**Ajoutés :**
- `Services/CallKitManager.swift` (seul fichier avec `import CallKit`)
- `AppState.didAnswerCallKit()` / `didEndCallKit()` callbacks
- Warm-up `CallKitManager.shared` dans `TunnelApp.init`

**Changé :**
- `TriggerTunnelIntent.openAppWhenRun = false` (était `true`)
- `ContentView` passe de 5 à 4 cases (plus de `.incomingCall`)

---

## 11. Testing (device physique obligatoire)

CallKit **ne tourne pas en simulateur**. Tester sur iPhone physique :

| Scénario | Vérification |
|---|---|
| Lock screen + Back Tap | UI plein écran, sonnerie système, vibration |
| Lock screen + Action Button | Idem |
| Déverrouillé, background | UI plein écran |
| Déverrouillé, foreground | Bannière CallKit (standard iOS) |
| Accept | Face ID si verrouillé → InCallView |
| Decline | App ne s'ouvre pas |
| Raccrocher depuis InCallView | Retour `.home`, rien dans Recents |
| Pendant un vrai appel | CallKit refuse silencieusement |
| Silent switch | Pas de son, vibration OK |

**Smoke test pré-submission :**
1. Build v1.1 sur iPhone physique verrouillé.
2. Back Tap → UI d'appel immédiate.
3. Accept → Face ID → InCallView.
4. Raccrocher → Home.
5. App Téléphone → Recents → doit être vide.

---

## 12. Ressources

- [CallKit documentation](https://developer.apple.com/documentation/callkit)
- [App Intents documentation](https://developer.apple.com/documentation/appintents)
- [Human Interface Guidelines — CallKit](https://developer.apple.com/design/human-interface-guidelines/callkit)
- Apps de référence approuvées en CallKit local : Introscape, Faker 3, Fake Call Pro

---

## 13. Instructions pour Claude / Cursor

- **Toujours lire ce CLAUDE.md en entier avant d'agir.**
- **`import CallKit` uniquement dans `CallKitManager.swift`**. Jamais ailleurs.
- **Ne jamais** proposer de réintroduire `RingtonePlayer`, `HapticsManager`, ou une UI d'appel entrant custom. CallKit gère tout ça.
- **Ne jamais** changer `openAppWhenRun` à `true` dans `TriggerTunnelIntent`.
- **Ne jamais** passer `.phoneNumber` comme `CXHandle.type`.
- **Ne jamais** implémenter `provider(_:didActivate:)` ou `provider(_:didDeactivate:)`.
- En cas de doute sur un choix Apple (permissions, Info.plist, entitlements), DEMANDER plutôt que deviner.
- Vérifier que le code compile sur iOS 17+ minimum.
