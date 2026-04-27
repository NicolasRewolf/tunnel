# Checklist avant build / TestFlight / soumission

À cocher sur **iPhone réel** (le simulateur ne valide pas correctement CallKit, raccourcis, sonnerie).

| # | Scénario | OK |
|---|----------|---|
| 1 | Lancer le faux appel avec **Sortir du tunnel** (app au 1er plan) | [ ] |
| 2 | Déverrouillé : **Raccourci** « Déclencher Untunnel » (Raccourcis / Touche au dos / Bouton Action selon config) | [ ] |
| 3 | **Écran verrouillé** : même raccourci → l’**interface d’appel entrant** s’affiche (CallKit) | [ ] |
| 4 | Sonnerie **haut** : vérifier que c’est entendu ou que le retour d’erreur a du sens (silencieux muet = voir guide volume) | [ ] |
| 5 | (Optionnel) **Ne pas déranger** activé : un échec contrôlé / message d’erreur explicite est acceptable | [ ] |
| 6 | **Re-déclenchement** &lt; 1 s après le précédent → debounce (pas de double appel silencieux incompris) | [ ] |

Détails théoriques : [TriggerScenarios.md](TriggerScenarios.md).

## Rituel documentation (obligatoire quand le comportement user change)

Après toute modification de :

- `Tunnel/Core/Services/CallKitManager.swift` (`reportIncomingCall`, règles, messages d’erreur),
- `Tunnel/Intents/` (App Intents, raccourcis),

faire **au moins** :

1. [ ] Revoir **« CallKit (résumé implémentation) »** et **Limites** dans [CLAUDE.md](CLAUDE.md) — mettre à jour si le flux ou le libellé utilisateur change.
2. [ ] Mettre à jour [TriggerScenarios.md](TriggerScenarios.md) si un **scénario de fiabilité** change (nouvel échec, nouveau chemin, limitation iOS).
3. [ ] Ajuster **cette checklist** si un nouveau scénario smoke devient critique.

*Pas de checklist obligatoire pour du pur refactor interne qui ne change ni le flux ni le texte d’erreur — mais vérifier quand même le build.*
