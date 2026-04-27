# Untunnel — matrice de déclenchement (réaliste)

**But** : lister *tous* les chemins qui mènent à un faux appel, les états d’iPhone qui influencent le résultat, et **ce qu’on peut / ne peut pas** garantir côté app.  
**Code source** : mêmes chemins que l’implémentation actuelle (voir `CLAUDE.md`).

**Important** : l’exigence « l’icône Untunnel au premier plan à *chaque* déclenchement » n’est **pas** le modèle actuel : `TriggerTunnelIntent.openAppWhenRun` est `false` volontairement (CallKit en plein écran, sans forcer l’app).

---

## 1. Les trois chemins d’exécution (code)

| ID | Chemin | Où c’est branché | Ce qui lance vraiment le faux appel |
|----|--------|-------------------|------------------------------------|
| **A** | `TriggerTunnelIntent` (Raccourcis, **Toucher au dos**, **Bouton Action**, phrase Siri) | `Intents/TriggerTunnelIntent.swift` | `CallKitManager.reportIncomingCall` |
| **B** | Bouton **Sortir du tunnel** (app au premier plan) | `AppState.triggerFakeCallNow` | Même `reportIncomingCall` |
| **C** | **Minuteur armé** (échéance atteinte en processus vivant) | `AppState.finishArmedTimerFromSleep` → `triggerFakeCallNow` | Même `reportIncomingCall` |
| **D** | **Notification locale** « touchez pour lancer… » (app possiblement tuée) | `userTappedArmedTimerNotification` | Même `triggerFakeCallNow` après tap utilisateur — **aucun** faux appel sans tap sur la notif |

Les chemins **A–D** convergent sur **le même binaire** ; il n’existe **pas** de branche spéciale « iPhone verrouillé 5 min vs 10 min » (ce n’est nulle part en code).

---

## 2. Dimensions d’état (ce qui change le résultat, hors code app)

Ces cases **ne sont pas** modélisées par Untunnel, mais c’est **iOS** qui gagne en général.

| Dimension | Exemples | Impact typique sur un faux appel |
|-----------|----------|----------------------------------|
| **Écran** | verrouillé, déverrouillé, Face ID en cours, autre app plein écran | CallKit peut s’afficher *par-dessus* ; l’**app** peut rester cachée (`openAppWhenRun: false` pour A). |
| **Process** | app jamais ouverte, suspendue, tuée, cold start, extension App Intents lente | Même *logique* ; le **timing** (premier frame, registration CallKit) peut varier. Le projet *warm* `CallKitManager` au lancement pour limiter un bug « premier declenchement à froid ». |
| **Filtre système** | Ne pas déranger, Focus, etc. | CallKit peut **refuser** l’appel (codes du type *filteredByDoNotDisturb* — mappé en message côté `CallKitManager`). **Pas d’exemption app tierce fiable** pour forcer. |
| **Déclenchements serrés** | double tap, double raccourci en &lt; ~1 s | `CallKitManager` : **debounce** → 2e tentative = erreur « remanie ». |
| **Déjà un faux appel** | 2e lancement avec appel en cours | **Un seul** appel géré : rejet sûr (`.callAlreadyActive`). |
| **Notifications (minuteur)** | permission refusée, pas de « livraison critique » côté notif locale | Si l’app est **tuée** : sans tap sur la notif, **D** ne déclenche rien ; si l’in-app `Task` dort encore, le minuteur disparaît. Il n’y a **pas** de lancement *automatique* CallKit en arrière-plan fiable sans interaction pour une app de ce type. |

Rien dans cette liste ne dépend de « **X minutes** avec le verrou **fermé** » en tant que variable produit : seulement l’**état instantané** (mémoire, droits, Focus, etc.).

---

## 3. Matrice « scénario utilisateur → fiabilité ressentie »

Légende : **OK** = souvent OK en usage normal · **souvent** = dépend iOS / timing / paramètres · **non garanti** = l’exigence est impossible en droit (API) ou rare en pratique.

| Scénario (résumé) | CallKit (sonnerie + carte d’appel) | Icône Untunnel / Home visible au lancement | Tu sais *pourquoi* ça a échoué (post-fix persistance) |
|-------------------|------------------------------------|---------------------------------------------|--------------------------------------------------------|
| Verrouillé longtemps → Bouton Action | **souvent** OK, dépend DnD / 1 fée | **non** (volontaire) | Oui, si l’intent a échoué et prochaine ouverture app **B** / Home |
| Verrouillé longtemps → Toucher au dos | idem (même code **A**) | idem | idem |
| Déverrouillé → ferme l’app → verrou → raccourci | idem | idem | idem |
| App en avant-plan → **Sortir du tunnel** | **souvent** | **Oui** (déjà dedans) | Oui, toast in-app |
| App tuée, minuteur sonné, notif reçue, **l’utilisateur** touche | **souvent** (après le tap) | **Oui** (ouvrir via notif) | Oui, toast in-app |
| Même, mais l’utilisateur ne touche pas la notif | **Échec** (rien ne lance) | n/a | Non — comportement *attendu* : le tap est requis. |
| Raccourci alors qu’un faux appel est déjà actif | Rejet côté app (`.callAlreadyActive` ou similaire) | variable | Oui, si erreur rattachée (intent) ou in-app. |
| Deux lancements en &lt; 1 s (spam raccourci) | 2e **debounce** / erreur | — | Oui, message côté toast si visible. |
| DnD / filtre | CallKit refus | — | Oui, message côté toast si l’intent a persisté. |

**Verdict** : *« Tout le temps, peu importe la situation »* — **faux** pour toute app CallKit de ce type sur l’App Store, parce qu’iOS, les Focus et l’arrière-plan imposent des plafonds. *« Tant que le raccourci a été exécuté et iOS a accepté CallKit »* — **c’est** la cible réaliste, avec les messages d’erreur pour le reste.

---

## 4. Pourquoi ce n’est pas 100 % même avec un « bon » code

1. **CallKit** n’est pas une promesse absolue : *filteredByDoNotDisturb* et d’autres refus **exist** dans l’API publique.
2. **App Intents** s’exécutent souvent en **hors** du processus principal ; l’iPhone peut tuer, retarder ou re-prioriser (système, batterie, thermique) — le projet ne peut pas « réserver du CPU infini ».
3. **Minuteur + notif** : l’iOS n’applique pas *aux notifs standards* les mêmes règles qu’au téléphone (pas de lancement d’**appel entrant** *sans* interaction utilisateur pour notre scénario produit, sans biais App Review en VoIP injustifié).
4. **« Ouvrir l’app UnTuNNel à chaque raccourci »** n’est pas l’**état actuel** de `openAppWhenRun` ; exiger *à la fois* écran d’**appel** plein *et* fenêtre Untunnel immédiate est un conflit UX (voir commentaire dans le source).

---

## 5. Évolutions (hors sujet ici) si le produit change d’objectif

- `openAppWhenRun = true` : plus de chances de *voir* l’app, au prix du flash d’`Home` derrière l’appel.
- Tenter des **hacks** (URL privées Réglages, tâches d’arrière-plan non autorisées) : non alignés store / fragiles.
- Toute **garantie** d’enchaînement (sonnerie + 100 % des écrans) dépasse ce qu’iOS offre en API publique pour une app *non* télécom.

---

*Dernière mise en phase avec l’arbre de code : mêmes points d’entrée que `TriggerTunnelIntent`, `AppState`, `ArmedTimerNotificationScheduler`, `CallKitManager`.*
