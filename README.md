# Untunnel (Tunnel)

Faux appel entrant local (CallKit) pour iPhone — code du module d’app dans `Tunnel/`.

## Prérequis

- **Xcode** 26.x (projet généré avec 26.4+)
- **iOS** cible : 26.0+ (`IPHONEOS_DEPLOYMENT_TARGET`)
- **Appareil physique** recommandé pour valider CallKit, raccourcis et sonnerie

## Ouvrir le projet

```text
Tunnel.xcodeproj
```

Cible : **Tunnel** (bundle `rewolf.Tunnel`, nom affiché *Untunnel*).

## Organisation du dépôt

| Emplacement | Contenu |
|-------------|---------|
| `Tunnel/` | Source Swift, assets, plist — **seul ce dossier** est la cible Xcode (synchronisée) |
| `Documentation/` | Notes projet (`CLAUDE.md`), matrice de scénarios, brouillons |
| `Design/` | Fichiers hors bundle : mockups, sources logo, extraits son (non requis pour compiler) |

## Règles d’architecture (résumé)

- **CallKit** : uniquement `Tunnel/Core/Services/CallKitManager.swift`
- **Écrans** : `Tunnel/Features/<écran>/`
- **État + config** : `Tunnel/Core/Models/`
- Détails : `Documentation/CLAUDE.md`
