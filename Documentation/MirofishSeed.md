# Untunnel — brief produit pour simulation MiroFish

Document destiné à un moteur de simulation multi-agents. L'objectif est d'observer comment une app iOS de "fake call" est perçue par différents profils : utilisateurs potentiels, sceptiques, journalistes tech, régulateurs, parents, professionnels de la santé mentale, App Store Review. Le ton est volontairement honnête : l'app a une posture éthique claire mais soulève des questions légitimes.

---

## 1. Identité

- **Nom commercial** : Untunnel
- **Nom interne / repo** : Tunnel
- **Plateforme** : iOS 26+ uniquement (iPhone)
- **Catégorie App Store** : Utilitaires
- **Modèle économique** : payant (one-shot, pas d'abonnement, pas de pub)
- **Disponibilité** : App Store Union Européenne (compte développeur conformé DSA Trader Information)
- **Langue de l'interface** : français uniquement (v1.0 et v1.1)
- **Développeur** : Nicolas Doucet, indépendant, basé en France
- **Versions** :
  - v1.0 : faux appel basique avec UI custom (limité — ne fonctionne pas écran verrouillé)
  - v1.1 (en cours de submission) : migration sur CallKit, fonctionne lock screen, UI proche de Phone.app iOS 26

## 2. La promesse en une phrase

**« Sortir d'une conversation en un geste, en simulant un appel entrant crédible — sur ton propre iPhone, déclenché par toi-même, sans tromper quelqu'un d'autre que toi. »**

## 3. Le problème humain résolu

Untunnel ne résout pas un problème logiciel — il résout un problème **social**. L'app est née du constat que beaucoup de gens vivent régulièrement des situations où ils veulent partir, mais ne savent pas comment :

- Conversation qui dérape avec une personne intrusive
- Rencard qui ne se passe pas bien
- Réunion familiale étouffante
- Pression sociale dans un groupe (drogues, sextape, harcèlement, racisme, etc.)
- Démarchage en porte-à-porte qu'on n'arrive pas à couper
- Femmes harcelées dans la rue ou dans les transports
- Adolescents en situation d'inconfort (premier rendez-vous, soirée qui dégénère)
- Personnes neuro-atypiques ayant du mal à formuler un "non" social

Le mécanisme social qu'Untunnel exploite : un appel téléphonique entrant est **socialement acceptable** comme raison de partir. "Désolé, ma mère m'appelle" coupe court à n'importe quelle situation sans confrontation.

## 4. Le mécanisme technique

Untunnel utilise le framework **CallKit** d'Apple — le même système qui affiche les vrais appels téléphoniques. Concrètement :

- L'utilisateur arme un déclencheur (Touche au dos / Action Button / Raccourci Siri / minuteur dans l'app)
- Au déclenchement, l'app appelle `CXProvider.reportNewIncomingCall` localement
- iOS affiche **l'écran d'appel système réel** : nom du contact configuré, photo, vibration, sonnerie
- L'utilisateur "décroche" → l'app affiche un écran d'appel qui ressemble à Phone.app (chrono qui tourne, boutons mute/speaker/raccrocher)
- Aucune connexion réseau, aucun serveur, aucun appel sortant, aucun audio routé

**Sept règles de conformité hardcodées** (pas optionnelles, pas désactivables) :

1. `CXHandle.type = .generic` — l'app ne peut pas usurper un numéro de téléphone réel
2. `CXProviderConfiguration.includesCallsInRecents = false` — l'appel n'apparaît jamais dans l'historique Téléphone
3. Aucune session audio activée — l'app n'implémente pas `provider(_:didActivate:)`
4. `ringtoneSound = nil` — c'est la sonnerie système de l'utilisateur qui joue, identique à un vrai appel
5. Pas de PushKit, pas de VoIP server, pas d'entitlement VoIP en production
6. UUID en mémoire seulement, jamais persisté
7. `maximumCallGroups = 1` + debounce 1 seconde — pas de spam d'appels

## 5. Profils utilisateurs cibles (segments probables)


| Segment                                          | Motivation typique                           | Fréquence d'usage |
| ------------------------------------------------ | -------------------------------------------- | ----------------- |
| Femmes 18-35 ans urbaines                        | Sécurité dans les transports / rendez-vous   | Hebdomadaire      |
| Adolescents 14-17 ans                            | Sortir des soirées, refus social             | Mensuel           |
| Travailleurs introvertis                         | Couper les réunions interminables            | Quotidien         |
| Personnes neuro-atypiques (TSA, anxiété sociale) | Avoir un "out" toujours dispo                | Variable          |
| Vendeurs / freelances                            | Couper les démarchages, rendez-vous toxiques | Hebdomadaire      |
| Aidants familiaux                                | Échapper aux conversations envahissantes     | Mensuel           |
| Parents                                          | Cadre de sortie pour leurs ados              | Achat-cadeau      |


## 6. Esthétique et ton

- Design system : **iOS 26 Liquid Glass**, modificateurs natifs (`.glassEffect`, `.glassProminent`)
- Palette : vert profond (`Theme.green`) pour le CTA principal, rouge système pour destructif (raccrocher)
- Hero icon animée : icône téléphone dans cercle glass vert avec halo pulsant
- Écran d'appel : pixel-clone Phone.app iOS 26 (avatar 96pt en haut-gauche, grid 2×3 avec bouton raccrocher rouge intégré)
- Ton éditorial : **français direct, intime, complice**. Pas d'anglicismes, pas de jargon. Ex : "Sortir du tunnel", "Sortir d'une conversation en un geste", "Le nom que verront les autres s'ils jettent un œil à ton écran — choisis quelque chose de crédible".
- Pas de gamification, pas de notifications poussées, pas de social, pas d'achats in-app

## 7. Posture éthique et confidentialité

L'app **assume une position morale** explicite, formulée dans son texte App Review et dans son Privacy Policy :

- **Simulation 100 % locale**. Aucune donnée ne quitte l'iPhone.
- **L'utilisateur ne peut tromper que lui-même**, pas une tierce personne. Il configure le faux contact pour son propre usage et c'est lui qui voit l'écran d'appel.
- **Aucune capacité d'usurpation d'identité** d'un numéro réel (CXHandle.generic uniquement)
- **Pas d'accès au carnet de contacts**, pas de permission réseau, pas d'accès aux SMS
- **Pas de capacité offensive** (pas de spoof à distance, pas de bot, pas de scam tools)

L'app se positionne explicitement comme **outil de protection sociale**, pas outil de tromperie.

## 8. Scénarios d'usage concrets (vignettes)

### Scenario A — Léa, 24 ans, sortie d'un rencard qui vire mal

Léa a configuré "Maman" comme contact dans Untunnel et activé le Touche au dos (3 tapotements). Pendant un dîner de premier rendez-vous, son interlocuteur devient insistant sur le fait de remonter chez elle. Léa tape 3 fois discrètement au dos de l'iPhone posé sur la table. L'iPhone sonne 5 secondes plus tard, écran "Maman appelle", elle décroche, fait semblant de parler 30 secondes ("Ah non c'est grave ? J'arrive"), et part naturellement.

### Scenario B — Karim, 16 ans, soirée qui dérape

Soirée chez un ami. Karim ne veut pas fumer ce qu'on lui propose. Il a programmé un minuteur 15 minutes plus tôt dans Untunnel. Son iPhone sonne, c'est "Papa", il prend l'appel, sort sur le palier, fait semblant de parler, redescend en disant "il faut que je rentre".

### Scenario C — Sophie, freelance, démarcheur en porte-à-porte

Quelqu'un sonne à la porte pour vendre des panneaux solaires. Sophie ne sait pas couper poliment. Elle prend son iPhone "qui sonne" via Action Button, fait semblant que c'est un client urgent, ferme la porte.

### Scenario D — Marc, 45 ans, réunion familiale

Repas du dimanche, sa belle-mère commence à attaquer ses choix de vie. Marc, qui a configuré l'app la veille, déclenche via Raccourci Siri ("Dis Siri, sors-moi du tunnel"). Téléphone sonne, il prend congé.

### Scenario E (limite) — Adolescent malveillant qui essaye d'utiliser l'app pour bizutage

Un ado essaye de faire croire à un copain qu'un faux appel est un vrai appel. Ça ne marche pas longtemps : l'app n'apparaît pas dans Recents, le numéro est `.generic` (pas de numéro réel affiché), et l'audio n'est jamais activé. L'illusion tient 30 secondes max et le complice voit le pot aux roses.

## 9. Risques de réception, controverses possibles

- **« C'est une app pour mentir »** — critique attendue. Réponse de l'app : tu mens à toi-même pour te protéger, pas à autrui. Le mensonge social a une longue tradition de protection (white lies).
- **« C'est dangereux pour les ados »** — critique parentale. Réponse : c'est l'inverse, c'est un outil pour qu'ils sortent de situations dangereuses (alcool, drogue, pression sexuelle).
- **« Apple va refuser »** — critique technique. Réponse : Apple a déjà validé le compte développeur DSA. La compliance CallKit est plus stricte que ce que demandent les guidelines (les 7 règles dépassent le minimum requis).
- **« Pourquoi pas gratuit ? »** — critique économique. Réponse : modèle achat unique, pas de pub, pas de tracking, l'app coûte au prix d'un café.
- **« Ça existe déjà gratuit (Fake Call, etc.) »** — critique concurrentielle. Différence : la plupart des concurrents sont des fake apps qui jouent une vidéo plein écran, ne fonctionnent pas écran verrouillé, et collectent des données. Untunnel utilise le **vrai CallKit système**, fonctionne lock screen, et ne collecte rien.

## 11. Données factuelles utiles à la simulation

- **Pays cible primaire** : France
- **Tarif estimé** : 1,99€ – 2,99€ (one-shot)
- **Concurrents directs** : Fake Call (Lite), Prank Call, Fake Caller, Hide & Seek
- **Différenciateurs** : (1) vrai CallKit (lock screen), (2) iOS 26 natif, (3) déclenchement physique (Touche au dos / Action Button), (4) aucun tracking, (5) UI Phone.app fidèle, (6) minuteur armé persistant (notification locale de fallback)
- **Inspirations design** : Phone.app iOS 26, Apple Human Interface Guidelines pour Liquid Glass
- **Inspirations conceptuelles** : Sortir d'une rave / d'une soirée mal engagée, code social du téléphone qui sonne, droit à l'esquive

