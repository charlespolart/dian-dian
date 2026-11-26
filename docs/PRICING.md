# Prix — décisions et recommandations

Livrable du point 8 de `docs/ROADMAP.md`. Mise à jour le 2026-11-23.
Sources : la recherche `docs/research/reports/Prix abonnement et achat à vie.md`
(notes dans `docs/research/notes/Prix abonnement et achat à vie/`, marché
occidental, relevé de 36 apps le 2026-11-22) et l'audit de prod
`docs/research/audit-2026-11-22.md`.

**État** : grille décidée le 2026-11-23, à appliquer dans les stores par
Charles le 1er décembre. Dans les stores, seule la configuration Android a
changé (essais ajoutés le 2026-11-23) ; aucun prix n'a bougé.

## En bref

Garder la formule hybride, abonnement plus achat à vie, et monter les prix :
le point faible n'est pas la conversion mais le revenu par payant. Mêmes
prix sur iOS et Android, abonnés actuels protégés, changement pour tous avant
le pic du Nouvel An, relecture début mars.

| Formule | Aujourd'hui | Nouveau | Statut |
|---|---|---|---|
| Mensuel (essai 7 j) | 2,99 $ · 1,99 € | **2,99 $ · 2,99 €** | décidé |
| Annuel (essai 7 j) | 8,99 $ · 9,99 € | **14,99 $ · 14,99 €** | décidé |
| Lifetime | 22,99 $ · 24,99 € | **29,99 $ · 29,99 €** | décidé le 2026-11-23 (le rapport disait 34,99 $) |

**Euros.** Prix français relevés par Charles le 2026-11-23, TVA comprise :
1,99 € / 9,99 € / 24,99 €. Le mensuel en euros est sous le dollar (1,99 €
pour 2,99 $), quand l'annuel et le lifetime suivent l'égalisation d'Apple.
*Mon choix* : dans la zone euro, les mêmes chiffres qu'en dollars, 2,99 € /
14,99 € / 29,99 €, réglés à la main plutôt que l'égalisation d'Apple
(≈ 16,99 € et 32,99 €). Ils restent sous 15 € et 30 €, et l'annuel vaut
toujours 5 fois le mensuel, donc le même badge « −58 % ». Le mensuel passe
de 1,99 € à 2,99 € pour les nouveaux abonnés seulement (un seul essai
mensuel à ce jour). Ailleurs (GB, CA, AU…), l'égalisation d'Apple, recopiée
à la main sur Google Play.

## Pourquoi monter

- **L'annuel à 8,99 $ est vers le 5e centile** des 19 apps d'humeur,
  d'habitudes et de journal relevées (médiane 35,99 $ ; médiane des petits
  trackers indépendants en pixels ou en grille : 14,99 $). Seul un tracker
  coûte moins cher.
- **Le lifetime à 22,99 $ est vers le 20e centile** des offres à vie des
  apps hybrides (médiane ≈ 49,99 $).
- **La conversion n'est pas le problème** : si environ 4 % des utilisateurs
  récents paient, Dian Dian est près du quartile supérieur du freemium
  (médiane 2,1 %, quartile supérieur 4,5 %, RevenueCat SOSA 2026).
- **Nos acheteurs n'ont pas été freinés par le prix** : 3 des 9 achats sont
  des lifetime à 22,99 $, choisis à côté d'un annuel à 8,99 $ (voir l'audit).
- **Une hausse p reste rentable tant que la conversion baisse de moins de
  p / (1 + p)** : 8,99 → 14,99 $ supporte une baisse de 40 % ; 22,99 →
  29,99 $ une baisse de 23 % ; 22,99 → 34,99 $ une baisse de 34 %.

## Le modèle : abonnement et lifetime

- Le rejet de l'abonnement est le fait le mieux établi : seuls 16 % des
  Américains préfèrent payer un logiciel au mois (YouGov 2022).
- HabitKit, le comparable le plus proche (tracker en grille d'un développeur
  seul), tire près de la moitié de son revenu du lifetime.
- Chez nous : personne ne s'abonne sans essai ; le lifetime est le seul
  achat direct et fait ≈ 73 % du revenu.
- Un abonné annuel vaut en moyenne 2 à 3,5 annuités, soit 30 à 52 $ à
  14,99 $ : un lifetime à 29,99 $ en vaut le bas de la fourchette. Il ne
  cannibalise rien d'important, puisque ses acheteurs ne se seraient pas
  abonnés. Seul vrai
  coût : la synchronisation serveur d'un client à vie, chaque année.

## Le lifetime : 29,99 $ plutôt que 34,99 $

Décidé le 2026-11-23. Charles a demandé le prix le plus cohérent avec la
recherche et l'audit (la grille du rapport lui semblait « un peu chère ») ;
c'est 29,99 $, pour ces raisons :

- Avec 3 ventes, rien ne départage 29,99 $ et 34,99 $ : l'écart est plus
  petit que l'incertitude.
- Le lifetime fait ≈ 73 % du revenu : sur le produit principal, prendre le
  pas le plus petit (+30 % au lieu de +52 %).
- Il vaut 2 fois l'annuel à 14,99 $ : l'annuel garde son intérêt (médiane des
  indépendants : 2,5 fois).
- C'est réversible vers le haut : en mars, si les ventes tiennent, passer à
  34,99 $ ne touche que les nouveaux acheteurs.
- Un prix intermédiaire (32,99 $) n'apporte rien : plus sous 30 $, et pas le
  revenu de 34,99 $.
- En euros, 24,99 → 29,99 € : +20 %, le plus petit pas des trois formules.

Rapports de la grille : annuel = 5 fois le mensuel (badge « −58 % » au lieu
de « −75 % » aujourd'hui ; les concurrents sont à 4 à 10 fois, 5,6 en
médiane) ; un an de mensuel (35,88 $) coûte à peu près le lifetime.

## L'essai : 7 jours sur le mensuel et l'annuel

- Stats publiques (RevenueCat SOSA 2026, médianes) : part des essais qui
  deviennent payants 25,5 % pour 4 jours ou moins, **37,4 % pour 5 à 9
  jours**, 42,5 % pour 17 à 32 jours (comparaison entre apps, pas un test).
  Santé-forme : 37,7 %. 82 % des essais démarrent le jour de l'installation
  (SOSA 2025, toutes apps ; SOSA 2026 donne 82,1 % pour la santé-forme).
- Nos essais : 2 conversions sur 5 annuels. Les 3 qui ont expiré avaient
  quitté l'app en 1 à 3 jours : un essai plus long n'aurait fait que
  retarder leur résiliation. Le problème est la rétention de la première
  semaine (d'où le rappel du soir de J1), pas la durée.
- On reconsidère 14 jours si un jour on voit des essais actifs jusqu'aux
  jours 6–7 qui résilient quand même.
- Plus tard, avec le nouveau paywall : réserver l'essai à l'annuel est une
  option de clarté (pratique courante, non prouvée). Cela voudrait dire
  retirer l'offre Play `monthly-free-trial` et l'essai mensuel côté App
  Store Connect.

## Android : mêmes prix, entonnoir réparé

- Mêmes prix : la commission est de 15 % sur les deux stores (Small Business
  Program Apple **actif** ; Google 10 % de service + 5 % de facturation aux
  États-Unis, au Royaume-Uni et dans l'EEE depuis le 30 juin 2026). Le
  premium est lié au compte et synchronisé : un lifetime moins cher sur
  Android servirait aussi sur iOS.
- L'écart Android vient de l'entonnoir : sur Google Play, 0,9 % des
  installations deviennent payantes à 35 jours contre 2,6 % sur iOS, avec le
  même passage essai → payant (32,5 % contre 32,6 %).
- **Fait le 2026-11-23** : offres `monthly-free-trial` et `yearly-free-trial`
  (7 jours, nouveaux clients, 175 pays) sur l'abonnement `dian_dian_premium`.
  Il n'y avait aucun essai sur Android — cause probable des 0 ventes.
- **Reste** : vérifier la bannière d'essai sur un téléphone ; renommer
  l'abonnement « Premium Yearly » en « Dian Dian Premium » ; vérifier que
  chaque package de l'offering RevenueCat courante porte son produit Play ;
  activer le délai de grâce (les échecs de paiement font 31 % des
  résiliations sur Play contre 14 % sur l'App Store). Pas de rappel de fin
  d'essai par l'app (décidé le 2026-11-23 : aucun gain démontré) ; Google
  Play prévient déjà par e-mail quand un essai va finir, Apple ne documente
  aucun rappel (vérifié le 2026-11-23).
- Google Play génère les prix locaux une fois, au taux du jour, et ne les
  réajuste jamais (les modèles de prix, retirés le 2025-10-27, partageaient
  un prix entre produits, ils ne suivaient pas le change) : recopier à la
  main les prix locaux d'Apple. Apple ne réajuste jamais les prix des
  abonnements ; ses réajustements ne touchent que le lifetime, à recopier
  sur Play quand il en annonce un. Sur l'App Store, le prix se fixe pays par
  pays (pas de groupe « zone euro »).

## Changer les prix

- **Abonnés actuels** : leur laisser leur prix. Apple : option « conserver le
  prix actuel » ; Google : ancien prix par défaut. L'enjeu ne dépasse pas une
  douzaine de dollars par an, une hausse imposée coûterait en confiance.
  Les acheteurs du lifetime ne sont pas concernés.
- **Quand** : avant le pic du Nouvel An (une année en pixels commence le
  1er janvier ; les acheteurs du lifetime testent de 2 jours à un mois avant
  de payer). *Mon choix* : **mardi 1er décembre 2026**, après la semaine du
  Black Friday, avec quatre semaines de recul avant janvier. Les deux stores
  le même jour : App Store Connect permet de programmer la date d'effet
  (à faire au plus tard le 28 ou le 29 novembre, il demande en général un
  à deux jours d'avance), Google Play se change à la main ce jour-là.
- **Pas de test A/B** : détecter un écart de 20 % demanderait ≈ 21 000
  utilisateurs par variante. On change pour tous et on suit trois
  indicateurs : revenu par nouvel utilisateur qui voit le paywall, taux de
  démarrage d'essai, part du lifetime. Règle de retour en arrière écrite
  d'avance (par exemple aucune vente sur plusieurs centaines d'affichages du
  paywall). Relecture **début mars**, en sachant que l'afflux de janvier
  brouille l'avant / après.

## Le paywall (pour Fable)

Aujourd'hui (`flutter_app/lib/widgets/custom_paywall_dialog.dart`) : trois
cartes dans l'ordre mensuel, annuel, lifetime (`_orderedPackages`), annuel
présélectionné (`_defaultSelection`) et affiché par an (`_packageDetail`),
badge « économisez X % » (`_yearlySavingsPercent`), bannière d'essai lue
dans `storeProduct.introductoryPrice` (`_introTrial`).

À faire :

1. **Annuel présélectionné, affiché par mois** : « 1,25 $/mois, 14,99 $
   facturés par an », badge « −58 % », essai écrit en clair dans la carte
   (« 7 jours gratuits, puis 14,99 $ par an »). Jamais d'interrupteur
   d'essai : Apple rejette ces paywalls depuis janvier 2026.
2. **Lifetime visible en permanence**, deuxième carte : « payez une fois,
   gardez tout ». Contraire au conseil des vendeurs, mais c'est ce que nos
   clients achètent.
3. **Mensuel en lien discret** sous les cartes : « ou 2,99 $ par mois ». Il
   continue de justifier le pourcentage d'économie.
4. **Mur des 3 trackers** (`PremiumGateDialog`, événement `tracker_limit`) :
   commencer par « trackers illimités » et montrer les deux façons de les
   avoir ; l'annuel reste présélectionné (voir « Relecture »). Les 3
   acheteurs du lifetime sont tous passés par la limite des 3 trackers pour
   en créer d'autres.
5. **Aide à la résiliation après un achat lifetime** : si un abonnement est
   encore actif, dire de le résilier (Customer Center RevenueCat), pour ne
   pas payer deux fois.
6. Pas d'offre « leurre » : l'effet disparaît dès que les options sont
   décrites par des mots.

Mesure : les événements du parcours d'achat manquent (voir l'audit, « Trous
de mesure ») ; les ajouter avec cette refonte.

### Relecture du 2026-11-23

- **Mur des 3 trackers — décidé le 2026-11-23 : l'annuel reste
  présélectionné partout**, ce mur compris ; le lifetime reste visible en
  deuxième carte. Charles : trois acheteurs ne suffisent pas à changer
  l'ordre, et on préfère les abonnements. Le calcul le confirme à peu près :
  un annuel à 14,99 $ ne dépasse le lifetime à 29,99 $ qu'à partir de sa
  deuxième année (2 annuités = 29,98 $), et la recherche situe la valeur
  moyenne d'un abonné annuel entre 2 et 3,5 annuités ; les deux se valent,
  donc on garde l'ordre habituel et on relit en mars avec les événements du
  parcours d'achat. Première proposition, écartée : lifetime en premier et
  présélectionné sur ce mur.
- **Annuel affiché** : *mon choix*, le prix facturé en premier sur iOS
  (« 14,99 $ par an, soit 1,25 $ par mois ») : Apple refuse les paywalls où
  le prix mensuel ressort plus que le prix réellement facturé.
- **Lifetime pour les abonnés et les essais — décidé le 2026-11-23 : non
  pour l'instant.** Un premium, essai compris, n'atteint jamais le paywall,
  et ça reste ainsi. Le point 5 se réduit à un contrôle après un achat
  lifetime et au lancement : si un abonnement est encore actif (deuxième
  compte, paiement en reprise), dire de le résilier.
- **Base légale des événements du parcours d'achat — décidé le
  2026-11-23 : intérêt légitime.** Ils restent liés au compte
  (`events.user_id`), comme les `paywall.*` d'aujourd'hui. À faire : une
  section dans la politique de confidentialité (`legal.ts`, quatre langues,
  qui dit aujourd'hui « pas d'analytics » et ne mentionne aucun événement),
  conservation 13 mois, aucun partage ; Charles met à jour les étiquettes de
  confidentialité de l'App Store et la section « sécurité des données » de
  Google Play avant la sortie. Même lot que le registre RGPD. **Fait le
  2026-11-26** (plan `docs/superpowers/plans/2026-11-26-rgpd-register.md`) :
  section 7 de la politique (`/privacy#events`), fiche 7 de
  `docs/REGISTRE.md`, purge à 13 mois, et un moyen de tenir une opposition
  (`users.events_opt_out`). Chaque nouvel événement du parcours d'achat
  s'ajoute à la fiche 7.

### Passe de confirmation du 2026-11-25

Comparé à `master` (app 1.4.0). Détail : `docs/CONFIRMATION.md`, points 8
à 11.

- **Un seul écran par mur** (*mon choix*, Charles ayant répondu « fais
  selon tes recommandations » ; à relire). Aujourd'hui chaque mur a deux
  étapes : `PremiumGateDialog` (la raison, la liste des avantages, un
  bouton), puis `CustomPaywallDialog` (les cartes). Toucher une fonction
  Premium ouvre désormais le paywall directement : en titre la raison
  (« Trackers illimités » pour `tracker_limit` et `locked_tracker`, le nom
  de la fonction ailleurs), une liste courte des avantages, puis les
  cartes des points 1 à 3. Le mur `locked_tracker` garde son lien
  « choisir les trackers gardés ». L'événement `paywall.<mur>` garde son
  nom : il dit maintenant que le paywall s'est affiché.
- **L'essai selon l'éligibilité.** `_introTrial` lit
  `storeProduct.introductoryPrice`, qui décrit le produit et non le droit
  de la personne : sur iOS, quelqu'un qui a déjà eu son essai verrait
  encore « 7 jours gratuits ». Demander l'éligibilité à RevenueCat
  (`checkTrialOrIntroductoryPriceEligibility`) avant d'écrire l'essai dans
  la carte ; sinon, le prix seul. Sur Android, à vérifier au plan (Google
  ne renvoie en principe que les offres auxquelles la personne a droit).
  Même règle pour le bouton de la pop-up premium.
- **Les événements du parcours d'achat** : après `paywall.<mur>`, la
  formule choisie, l'achat lancé, puis réussi, annulé ou en erreur, avec
  le mur et la formule dans le nom (la table `events` ne garde qu'un nom,
  de 64 caractères au plus). `PurchaseService.purchasePackage` ne renvoie
  qu'un booléen : il lui faut trois issues. Noms exacts au plan. La
  plateforme et la version arrivent avec le chantier 0 de
  `docs/FABLE.md`.
- **Le prix par mois de l'annuel** se calcule (prix ÷ 12, dans la devise
  du store) ; le projet n'a pas le paquet `intl` : l'ajouter, ou reprendre
  la mise en forme de `priceString`. Au plan.
- **Conservation** : construit le 2026-11-26 avec le registre
  (`backend/src/lib/retention.ts`) : le mois en cours et les 12 précédents
  sont gardés, la purge tourne au démarrage puis chaque jour.

### Trouvé pendant le chantier 0 (2026-11-25), pour ce chantier

En refaisant le webhook RevenueCat (`docs/superpowers/plans/2026-11-25-purchase-measurement.md`), cinq points côté app ou achat sont restés ouverts ; ils se traitent avec la refonte du paywall :

- **`PurchaseService.logIn` ne fait rien si le SDK n'est pas encore initialisé** (`purchase_service.dart`), et `_onAuthChange` l'appelle dès la restauration de la session. Si l'appel arrive avant la fin de `init()`, la session reste anonyme pour RevenueCat jusqu'au prochain changement d'authentification : un achat fait à ce moment-là part sous un identifiant anonyme, que le serveur ne rattache à personne. À faire : `logIn` attend `init()`. Lu dans le code, pas reproduit.
- **Un achat arrivé par un identifiant anonyme** (cas ci-dessus, ou reçu traité pendant que l'app est déconnectée) ne rejoint le compte, côté serveur, qu'au prochain événement d'achat à son nom ; pour un achat à vie il n'y en a pas. Le remède sûr est de demander l'état du client à RevenueCat (API REST) quand un transfert arrive, ce que sa documentation recommande. À décider ici.
- **Le remboursement d'un achat à vie** : rien ne dit qu'une EXPIRATION suit le CANCELLATION `CUSTOMER_SUPPORT`. La table `subscription_events` montrera ce que RevenueCat envoie ; d'ici là un achat à vie remboursé peut rester Premium côté serveur.
- **Un événement d'abonnement sans date de fin donne un Premium sans fin.** Le webhook lit « pas de `expiration_at_ms` » comme un achat à vie, quel que soit le type d'événement ; c'est déjà le cas en production (backend 1.2.1). RevenueCat envoie toujours ce champ pour un abonnement, donc le cas ne s'est sans doute jamais produit, mais rien ne l'empêche. Le resserrer (« sans fin » seulement pour un achat non renouvelable) demande de savoir sous quel type arrive l'achat à vie : `subscription_events` le dira dès la sortie.
- **La mémoire des événements déjà appliqués part avec le compte.** Un événement livré deux fois n'est appliqué qu'une fois parce que sa ligne existe ; supprimer le compte efface la ligne. Il faut trois coïncidences en 80 minutes pour que cela compte (une expiration dont la réponse se perd, un renouvellement qui déplace l'abonnement vers un autre compte, puis la suppression du premier) : l'abonnement déplacé serait alors fermé jusqu'à son prochain renouvellement. Laissé tel quel ; à revoir si la suppression de compte devait garder les événements d'achat sans leur compte.

## Message à la résiliation (App Store)

App Store Connect → abonnements → « Messages de fidélisation » : un message
affiché quand un abonné choisit de résilier. Rédigé le 2026-11-23, **à
soumettre par Charles**. Nom de référence `Cancel - keep pixels` ; rattaché
à Premium Monthly et Premium Yearly ; **sans image** (le visuel universel
était trop grand et c'est une image de présentation) ; **sans offre** (les
promos sont en pause, et une remise demanderait un produit de plus pour deux
abonnés). Ni l'en-tête ni le corps ne doivent citer d'offre, de remise ou de
prix (règle d'Apple). Limites : 66 caractères pour l'en-tête, 144 pour le
corps ; les quatre messages ci-dessous les respectent (vérifié le
2026-11-23). Nom officiel : « Retention messages », disponibles depuis le
4 novembre 2026.

| Langue | En-tête | Corps |
|---|---|---|
| en-US | Keep every tracker, stat and theme | If you cancel, trackers beyond 3 get locked, stats, themes and image export turn off, and ads come back. Your data always stays saved. |
| fr-FR | Gardez tous vos trackers, stats et thèmes | En résiliant, vos trackers au-delà de 3 seront verrouillés, stats, thèmes et export coupés, et la pub reviendra. Vos données sont conservées. |
| zh-Hans | 保留所有追踪器、统计和主题 | 取消后，超过 3 个的追踪器将被锁定，详细统计、所有主题和导出为图片将关闭，广告也会回来。你的数据会一直保留。 |
| zh-Hant | 保留所有追蹤器、統計和主題 | 取消後，超過 3 個的追蹤器將被鎖定，詳細統計、所有主題和匯出為圖片將關閉，廣告也會回來。你的資料會一直保留。 |

## Promotions : en pause

Décidé le 2026-11-22 : pas de Black Friday 2026, pas de Noël ni
d'Halloween pour l'instant. Une baisse de prix réglée dans les stores reste
invisible (le paywall affiche juste le prix du store, sans « −X % ») et on
n'a aucun canal pour l'annoncer. La pop-up promo pilotée par le serveur est
décrite, en pause, dans
`docs/superpowers/specs/2026-11-23-premium-popup-design.md`. Si les promos
reprennent : lifetime seulement, janvier en priorité (+14 % de nouveaux
payants par jour au Nouvel An avec promotion, d'après RevenueCat), et la
règle européenne sur les réductions (prix de référence = le plus bas des 30
jours précédents) à vérifier avant d'afficher un « −X % ».

**E-mails promotionnels** : l'inscription n'a pas de case d'accord pour les
offres commerciales (vérifié dans le code le 2026-11-23). On peut envoyer
les e-mails techniques, pas de promo. Il faudrait une case à l'inscription
et un réglage pour en envoyer un jour.

## Questions closes le 2026-11-23

1. Lifetime : **29,99 $** (29,99 €), voir plus haut.
2. Date du changement : **1er décembre 2026** (*mon choix*).
3. Prix français actuels : 1,99 € / 9,99 € / 24,99 € (voir « Euros »). En
   changeant les prix, vérifier que Google Play affiche les mêmes que l'App
   Store dans chaque pays.
4. On ne sollicite pas les trois acheteurs du lifetime.
