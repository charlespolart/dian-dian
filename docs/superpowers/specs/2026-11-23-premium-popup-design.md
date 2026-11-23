# Pop-up premium occasionnelle — design (2026-11-23)

Conversion, à la suite de l'audit `docs/research/audit-2026-11-22.md` et de
`docs/PRICING.md`. Brainstormé le 2026-11-22 ; Charles a validé les
recommandations le 2026-11-23 (« fais selon tes recommandations »). Phase de
documentation : à confirmer puis construire plus tard.

## Objectif

Pousser un peu la conversion en proposant premium de temps en temps, au bon
moment, en donnant envie avec les propres données de l'utilisateur. Les mots
de Charles : « dans certaines conditions… si quelqu'un a déjà 3 trackers, de
lui proposer de temps en temps de passer premium » ; « faut pas non plus
spammer à chaque fois qu'on démarre l'application ».

## Ce que disent les données

Gratuits actifs sur 30 jours (au moins un point modifié), 2026-11-22 :

| Trackers | Comptes | Jours actifs (moyenne) | Ont vu le mur des 3 trackers |
|---|---|---|---|
| 1 | 42 | 2,5 | 1 |
| 2 | 21 | 2,9 | 1 |
| 3 (limite) | 16 | 5,6 | 8 |
| 4+ | 1 | 1,0 | 0 |

- Le déclencheur « 3 trackers » toucherait ≈ 16 personnes, dont la moitié a
  déjà vu le message en voulant créer un 4e tracker. Utile mais petit.
- La plupart des gratuits ont un tracker et viennent 2 ou 3 jours par mois :
  leur proposer premium agacera sans convertir. Seuls 9 ont 8 jours actifs
  ou plus. **Le public grandit avec la rétention** : les rappels
  (`2026-11-23-reminders-design.md`) passent d'abord.
- **Les 3 acheteurs du lifetime avaient exactement 3 trackers** et en ont
  créé d'autres aussitôt (7, 9 et 16 aujourd'hui) ; deux n'avaient posé
  aucun point. Murs juste avant : `list_upgrade`, `tracker_limit`. Le moment
  « 3 trackers » le plus fort existe déjà : le mur du 4e tracker.
- Les 4 essais depuis le 2026-10-29 ont suivi un mur `stats` ou
  `global_stats`. Taux d'achat par mur semblables (≈ 7 à 12 %) : les stats
  gagnent par le trafic (icône très visible), pas par le taux.

## Objectifs, non-objectifs, anti-objectifs

**Objectifs** : montrer premium à un moment de satisfaction ; avec les
données de l'utilisateur ; rarement ; mesurable ; réglable sans mise à jour.

**Non-objectifs** : interstitiel au lancement ; remises et promotions (en
pause, section plus bas) ; changer la limite gratuite (reste à 3) ;
notifications de vente (jamais, voir le spec des rappels).

**Anti-objectifs** : une pop-up à chaque lancement ; une pop-up avant que la
personne ait fait ce qu'elle était venue faire ; une pop-up pour un payant ;
la même pop-up après des refus ; faux compte à rebours, culpabilisation,
bouton de fermeture caché ; quoi que ce soit pendant les premiers jours
(l'activation passe avant).

## Approches

1. **Après le point du jour — retenue.** La pop-up apparaît juste après que
   l'utilisateur a posé le point d'aujourd'hui, si un déclencheur est dû.
   Il a fini ce qu'il était venu faire et vient de voir sa grille avancer.
2. **Au lancement** (l'idée de départ de Charles). Exposition garantie, mais
   la pop-up se met entre l'utilisateur et ce qu'il vient faire, et associe
   l'ouverture de l'app à une contrariété — mauvais quand la rétention est
   le goulot. Écartée, avec l'accord de Charles.
3. **Seulement des emplacements passifs** (bouton « passer premium » de la
   liste, `list_upgrade` ; murs des fonctions premium). Jamais intrusif,
   mais déjà en place : ils restent, en complément.

Choix : **1**, avec les emplacements passifs existants.

## Décisions

### Déclencheurs

Chacun s'affiche **une seule fois par compte**. « Jours remplis » = dates
distinctes coloriées, tous trackers confondus, rattrapages compris (58 % des
points sont saisis plus d'une semaine après leur date).

| Déclencheur | Condition | Message (idée) | Ouvre |
|---|---|---|---|
| `trackers` | 3 trackers (la limite) et un usage régulier : au moins 5 jours avec des points sur les 14 derniers (décidé) | « Vos 3 trackers sont bien remplis. Avec Premium, ajoutez-en autant que vous voulez — pour toujours avec l'achat unique. » | paywall (annuel présélectionné, lifetime visible) |
| `days_7` | 7e jour rempli | aperçu des stats sur ses données : « Cette semaine, votre humeur la plus fréquente : ■ Calme. Premium vous montre toutes vos stats. » | paywall des stats |
| `days_30` | 30e jour rempli | aperçu plus riche (le mois écoulé) | paywall des stats |
| `year_end` | fin décembre / début janvier, avec assez de jours remplis dans l'année (*mon choix* : 30) | « Votre année 2026 est complète — exportez-la en image. » (l'export est premium) | paywall de l'export |

Esquisse (style de l'app, dialogue `AppDialog`) :

```
┌──────────────────────────────┐
│  30 jours remplis ! 🌱        │
│  Ce mois-ci, votre humeur la  │
│  plus fréquente : ■ Calme     │
│                               │
│  Premium vous montre toutes   │
│  vos stats, mois par mois.    │
│  [ Découvrir ]   Plus tard    │
└──────────────────────────────┘
```

L'aperçu est calculé dans l'app à partir des points de l'utilisateur ; une
seule donnée, vraie, pas de fausse stat. Décidé le 2026-11-23 : dévoiler
gratuitement une vraie stat, pour donner envie ; les stats plus poussées
restent premium. Lesquelles : à revoir avec le chantier « stats plus
utiles » (`docs/ROADMAP.md` §10). Une étape « fin de mois » a été
évoquée ; laissée pour plus tard.

### Garde-fous

- **Rien pendant les premiers jours** : *mon choix*, pas avant J+3 après
  l'inscription. Les achats des jours 1 et 2 viennent déjà d'eux-mêmes par
  les murs.
- **Budget commun à toutes les pop-ups** (premium et future pop-up promo) :
  au plus une **toutes les deux semaines**, au plus une par session ; jamais
  la même session que l'écran de demande des rappels (qui a la priorité) ;
  jamais juste après un mur premium vu dans la session.
- **Plus rien après 2 refus de suite** (« Plus tard » ou fermeture) :
  définitif (décidé), réinitialisable à distance. Les emplacements passifs
  (bouton de la liste, murs premium) restent.
- **Jamais pour les payants** (abonnement actif, lifetime, VIP), ni sans
  réseau (le paywall a besoin des offres RevenueCat).

### Réglable à distance

*Mon choix* : un bloc `upsell` dans `GET /api/bootstrap` — interrupteur
général (coupe-circuit), délai après l'inscription, intervalle entre deux
pop-ups, nombre de refus avant l'arrêt, et par déclencheur : actif oui/non
et seuils. Valeurs par défaut dans l'app si le bloc manque. Les textes
restent dans l'app (quatre langues, données insérées).

L'historique par compte vient du serveur, pour qu'un second appareil ne
remontre pas une pop-up déjà vue : le bootstrap renvoie les déclencheurs
déjà montrés, la date de la dernière pop-up et la série de refus, calculés
depuis la table `events`.

### Événements

| Événement | Quand |
|---|---|
| `upsell.<déclencheur>.shown` | pop-up affichée |
| `upsell.<déclencheur>.tapped` | bouton « Découvrir » |
| `upsell.<déclencheur>.dismissed` | « Plus tard » ou fermeture |

Pour relier un achat à une pop-up, il manque les étapes d'achat (audit,
« Trous de mesure ») : ajouter dans la même version au moins
`paywall.purchase_success` avec sa source, et la plateforme sur les
événements.

À surveiller : la part de refus par déclencheur, et si les gens qui l'ont
vue continuent de poser des points les jours suivants. Si un déclencheur se
fait presque toujours refuser, le couper à distance.

### Le mur des 3 trackers

Indépendant de la pop-up, plus simple, et dicté par le profil des acheteurs
du lifetime : sur `PremiumGateDialog` pour `tracker_limit` (et
`locked_tracker`), commencer par « Trackers illimités » et montrer les deux
façons de les avoir (abonnement ou achat unique), l'annuel restant
présélectionné (décidé le 2026-11-23, voir `docs/PRICING.md`, « Relecture »).

## Pop-up promo — en pause

Demandée le 2026-11-22 puis mise en pause le 2026-11-23 avec toutes les
promotions saisonnières. Si elle revient :

- Une annonce pilotée par le serveur : dates de début et de fin, textes dans
  les quatre langues, public (comptes gratuits), affichée une fois par
  annonce ; aucune mise à jour de l'app par promo, une fois le système
  livré. Même budget de pop-ups que ci-dessus.
- Un vrai prix barré : un produit lifetime à prix réduit, créé une fois dans
  les deux stores et réutilisé, rangé dans une offering RevenueCat dédiée ;
  pendant l'annonce, le paywall lit cette offering
  (`Purchases.getOfferings().all[...]`) et affiche « ~~22,99 $~~ 13,99 $ ».
- Jamais par notification (App Store 4.5.4). En Europe, une réduction se
  calcule sur le prix le plus bas des 30 jours précédents.

## Laissé au constructeur

L'interface exacte de la pop-up, le calcul des aperçus, le format du bloc
`upsell` du bootstrap, l'enchaînement avec le morphing et les sons
(`dialogOpen`), les tests (la sélection du déclencheur en fonction pure,
testée unitairement).

## Questions closes le 2026-11-23

Charles : « selon tes recommandations », et oui au teaser.

1. Seuil « usage régulier » du déclencheur `trackers` : **5 jours sur 14**.
2. Après 2 refus : **arrêt définitif** des pop-ups (réinitialisable à
   distance) ; les emplacements passifs restent.
3. L'aperçu **dévoile une vraie stat** gratuitement ; les plus
   intéressantes restent premium.
4. Fenêtre de fin d'année : *mon choix*, du 26 décembre au 7 janvier.

## Relecture du 2026-11-23

1. **Ordre.** La pop-up se construit après le chantier des stats
   (`docs/FABLE.md`) : les aperçus des jalons `days_7` et `days_30`
   montrent une stat choisie par la spec des stats. *Mon choix* : à défaut,
   « la couleur la plus fréquente de la semaine / du mois » du tracker
   qu'on vient de remplir, calculable aujourd'hui.
2. **Déclencheur `trackers`.** *Mon choix* : 3 trackers possédés (la limite)
   et au moins 5 dates coloriées sur les 14 derniers jours, tous trackers
   confondus, rattrapages compris, calculé dans l'app. Le texte ne dit plus
   « vos 3 trackers sont bien remplis » (faux pour la plupart) : « Vous
   avez vos 3 trackers. Avec Premium, ajoutez-en autant que vous voulez —
   pour toujours avec l'achat unique. »
3. **Comptes existants.** *Mon choix* : un jalon de jours ne se déclenche
   que s'il est franchi après la mise à jour, jamais rétroactivement (pas de
   « 7 jours remplis ! » à quelqu'un qui en a 150).
4. **`year_end`.** *Mon choix* : une fois par an (événement nommé avec
   l'année). Texte aligné sur la recherche des stats, où la carte de bilan
   est gratuite : « Votre année 2026 est prête — le bilan complet et l'image
   en haute définition avec Premium. » **Décidé (Charles, 2026-11-23)** :
   pas de jalon ni de bilan pour le Nouvel An 2026 ; avant le Nouvel An, le
   compteur de visites et la refonte du paywall ; les rappels en janvier ;
   `year_end` à partir de fin 2027.
