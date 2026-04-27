# Tunnel — notes projet (à jour code)

Référence courte pour humains et agents. **Le code source prime** sur ce fichier si divergence.

## Produit

App iOS qui déclenche un **faux appel entrant** (CallKit) pour sortir d’une conversation. Nom App Store : **Untunnel**. Ton : outil social / poli, pas “arnaque”.

## Stack

- **Swift + SwiftUI**, `@Observable` (`AppState`).
- **iOS déploiement** : 26.0 (voir `project.pbxproj`).
- **CallKit** : uniquement dans `Tunnel/Core/Services/CallKitManager.swift` (`import CallKit` nulle part ailleurs).
- **App Intents** : `TriggerTunnelIntent` + `TunnelAppShortcuts` (Raccourcis, Back Tap, Action Button).
- **Persistance** : `FakeCallConfig` (Codable) dans `UserDefaults`.

## Structure du module `Tunnel/`

| Dossier | Rôle |
|---------|------|
| `App/` | Point d’entrée : `@main`, `AppDelegate`, routage `ContentView` |
| `Core/Models/` | `AppState`, `FakeCallConfig` |
| `Core/Services/` | `CallKitManager`, `ArmedTimerNotificationScheduler` (effets de bord isolés) |
| `Intents/` | App Intents (raccourcis système) |
| `Features/*/` | Écrans par domaine (Home, Onboarding, InCall, Settings, Privacy) |
| `Support/` | Guides partagés (`RingerVolumeGuide`), `Extensions/` |
| `UI/` | Thème / tokens visuels (`Theme`) |
| `Assets.xcassets`, `Info.plist`, `PrivacyInfo.xcprivacy` | Ressources bundle |

## Flux principaux

1. **Bouton « Sortir du tunnel » / minuteur** (`HomeView` → `AppState.triggerFakeCallNow`) : app au premier plan ; erreurs → `lastTriggerError` + toast.
2. **Raccourci / intent** (`TriggerTunnelIntent.perform`, `openAppWhenRun = false`) : même `CallKitManager.reportIncomingCall` ; erreurs → chemin Raccourcis/Siri, **pas** le toast Home.
3. **Sonnerie** : UI système CallKit jusqu’au décrochage ; après acceptation → `InCallView` (SwiftUI).

## CallKit (résumé implémentation)

- `CXProviderConfiguration` : pas de vidéo, handle `.generic`, pas d’entrée dans l’historique Téléphone, pas de sonnerie custom dans le code.
- **Pas** de routage audio (`didActivate` non implémenté — simulation locale).
- Debounce ~1 s et garde **un** appel suivi (`currentCallUUID`) ; doubles déclenchements peuvent être **silencieux**.
- `Info.plist` : `UIBackgroundModes` → `voip` (requis côté projet pour l’enregistrement du provider — voir commentaires dans `CallKitManager`).

## Limites produit documentées dans le code

- **Matrice de déclenchement (fiabilité, scénarios, pourquoi pas 100 %)** : `Documentation/TriggerScenarios.md`
- **Minuteur armé** : date + durée sont persistées (`UserDefaults`) ; une **notification locale** à l’échéance permet de lancer le faux appel après un tap (app tuée ou en arrière-plan possible). Sans autorisation notifications, seul le `Task` in-app déclenche — l’utilisateur doit accepter les alertes pour le filet complet.
- **CallKit** : à tester sur **appareil physique** (simulateur non fiable pour ce flux).
- **Échec d’intention (raccourci)** : `AppState.recordIntentTriggerFailure` persiste le message — toast `HomeView` à la prochaine ouverture.

## Fichiers utiles (chemins actuels)

| Fichier | Rôle |
|--------|------|
| `Tunnel/App/TunnelApp.swift` | Warm-up `CallKitManager.shared` au lancement |
| `Tunnel/App/ContentView.swift` | Route `home` / `onboarding` / `inCall` / `settings` |
| `Tunnel/Core/Models/AppState.swift` | Écran, config, timer armé, callbacks CallKit |
| `Tunnel/Core/Services/CallKitManager.swift` | Tout CallKit |
| `Tunnel/Intents/TriggerTunnelIntent.swift` | Action système |
| `Tunnel/Features/InCall/InCallView.swift` | Après décrochage |

## Règles de travail (code)

- Ne pas étendre CallKit hors `CallKitManager.swift`.
- Garder `TriggerTunnelIntent.openAppWhenRun = false` sauf décision produit explicite.
- Préférer `Logger` (OSLog) à `print`.
