# Utiliser l'app sans réseau — design

2026-11-26. Décidé par Charles le même jour, après l'étude
`docs/research/2026-11-25-hors-connexion-et-sans-compte.md`. Ce qui est
*mon choix* (Fable) est marqué. Relu une fois par un autre agent (section
« Relecture » à la fin). Ce document va avec
`2026-11-25-account-later-design.md` (le compte) : les deux se construisent
séparément, et chacun dit où il touche l'autre.

Les cas sont illustrés dans
`2026-11-26-sans-compte-hors-ligne-stories.html`, chapitres « Sans réseau »
et « Sans réseau, avec deux téléphones ». Ils portent ici un numéro en H (H1 à H29),
repris sur la page.

## Pourquoi

Aujourd'hui, hors connexion, l'app s'ouvre sur une copie de l'année en
cours, mais rien de ce qu'on y fait n'est gardé : un jour colorié s'affiche
puis disparaît, sans un mot, et créer un tracker ne fait rien du tout
(lu dans le code, voir « Ce que cela touche »). La recherche de l'étude
montre que les avis en colère des apps de saisie portent sur ce point
précis : des saisies perdues.

## Décisions de Charles

1. **L'app s'utilise sans réseau, avec ou sans compte** (2026-11-26 :
   « il doit aussi pouvoir utiliser l'application hors ligne, qu'il soit
   connecté à un compte ou non »).
2. **Toutes les modifications se synchronisent au retour du réseau**
   (« de tous ces changements. Et je dis bien de tous ces changements ») :
   pas seulement les jours coloriés.
3. **En cas de conflit, le serveur gagne** (2026-11-25 : « Dans le cas où
   c'est en attente de synchronisation et que l'état distant a changé, on
   garde l'état distant qui a changé. Les modifications locales ne sont pas
   prises en compte. »).
4. **Les choix que Fable avait laissés ouverts sont confirmés**
   (2026-11-26 : « tu peux tout faire selon tes recommandations ») : la
   première ouverture sans réseau (H13), la comparaison élément par
   élément (H18), la suppression faite hors ligne (H21), la confirmation
   avant de se déconnecter (H10), les modifications gardées après une
   session fermée (H25). Il a aussi accepté qu'une modification qui a
   attendu ne soit jamais refusée pour la limite gratuite, même si une app
   trafiquée peut s'en servir (« c'est pas dramatique »).
5. Celles du document du compte qui valent ici : personne ne perd ses
   données pour avoir raté une option ; pas de trou, pas de situation
   floue ; tout entre dans la release unique.

Il avait posé la question « est-ce disproportionné ? » ; j'ai répondu oui
aux volumes d'aujourd'hui, il a tranché que non. Ce document ne rouvre pas
la question.

## Vocabulaire

- **Copie du téléphone** : toutes les données du compte, gardées sur le
  téléphone : trackers, légendes, points de toutes les années, réglages,
  état de Premium.
- **Modification** : tout ce que la personne change dans ses données (la
  liste complète est au cas H2).
- **En attente** : une modification écrite sur le téléphone et pas encore
  acceptée par le serveur.
- **File** : les modifications en attente, dans l'ordre où elles ont été
  faites.
- **Hors ligne** : l'app n'arrive pas à joindre le serveur, quelle qu'en
  soit la raison (pas de réseau, serveur en panne).
- **Élément** : ce qui se compare en cas de conflit. Un jour d'un tracker
  (couleur et commentaire ensemble) ; le nom d'un tracker ; une légende
  (son nom, sa couleur) ; l'ordre des trackers ; l'ordre des légendes d'un
  tracker ; le choix des trackers ouverts ; chaque réglage (thème, langue,
  curseur).
- **A attendu** : une modification faite pendant que l'app était hors
  ligne, ou dont le premier envoi a échoué. Une modification faite en
  ligne et partie du premier coup n'a pas attendu.

## Les principes

1. **Le téléphone d'abord.** Toute modification s'écrit dans la copie du
   téléphone avant quoi que ce soit d'autre, et l'écran lit toujours cette
   copie. Le réseau n'est jamais sur le chemin d'un geste.
2. **Ce qui est écrit est gardé.** Une modification en attente survit à la
   fermeture de l'app, à l'extinction du téléphone et à des semaines sans
   réseau. Elle ne quitte la file que quand le serveur a répondu.
3. **Le serveur tranche.** Si l'élément a changé sur le serveur pendant
   qu'une modification attendait, elle n'est pas appliquée (décision 3).
4. **Rien n'est abandonné en silence.** Chaque modification qui n'a pas été
   appliquée est dite, avec l'élément concerné et la raison.
5. **Une modification n'est jamais appliquée deux fois**, même si sa
   réponse s'est perdue et qu'elle est renvoyée.
6. **L'horloge du téléphone ne décide de rien.** Elle peut être fausse :
   l'ordre et les conflits se jugent sur ce que le serveur sait.

## Objectifs, non-objectifs

**Objectifs**

- Tout ce qui se fait dans les trackers avec du réseau se fait sans.
- Savoir en un coup d'œil si je suis hors ligne et si quelque chose attend.
- Deux téléphones sur un même compte finissent toujours identiques.

**Non-objectifs**

- Acheter, restaurer, créer un compte, s'y connecter, en rejoindre un,
  reprendre des trackers, supprimer ses données, écrire au support : ces
  gestes demandent le store ou le serveur (cas H6).
- Fusionner deux versions d'un même élément. Le serveur gagne, entier.
- Montrer l'historique des modifications ou permettre de revenir en
  arrière.
- Chiffrer la copie du téléphone au-delà de ce que fait le système.

## Approches

| | Approche | Ce qu'elle donne | Pourquoi (pas) |
|---|---|---|---|
| A | Dire la vérité : hors ligne, l'app le dit et refuse d'écrire | Plus de perte silencieuse, presque rien à construire | Ne permet pas d'utiliser l'app ; écartée par la décision 1 |
| B | Une file pour les seuls jours coloriés | Le geste de tous les jours marche hors ligne ; trackers et légendes restent en ligne | Écartée par la décision 2 |
| C | **Copie complète sur le téléphone, toute modification passe par une file** | Tout marche hors ligne, avec ou sans compte ; l'app devient aussi plus rapide en ligne | **Retenue.** Son prix : la couche de données de l'app est refaite, et le serveur doit savoir juger une modification qui arrive en retard |
| D | Bibliothèque de synchronisation toute faite (base répliquée) | Moins de code à écrire | Impose son propre serveur ou son format ; la règle « le serveur gagne » et la limite gratuite n'y entrent pas simplement |

## Les cas

### Sans réseau

Le bandeau, pendant tout le temps où l'app est hors ligne :
« Hors ligne · tout est enregistré sur ce téléphone », ou, s'il y a des
modifications en attente, « Hors ligne · 3 modifications à envoyer ». Au
retour : « Synchronisé », ou « Synchronisé · 31 modifications envoyées »
quand il y en avait.

- **H1. Je colorie un jour sans réseau.** Il se colorie tout de suite et
  reste colorié. Le bandeau compte une modification. Au retour du réseau
  elle part seule.
- **H2. Je fais tout le reste aussi.** Colorier ou effacer un jour, écrire
  ou changer un commentaire ; créer, renommer, réordonner, supprimer un
  tracker ; choisir les trackers ouverts ; créer, renommer, recolorier,
  réordonner, supprimer une légende (recolorier une légende recolorie ses
  jours) ; changer de thème, de langue, de curseur. Tout attend dans la
  même file et part dans l'ordre.
- **H3. J'ouvre l'app sans réseau.** Elle s'ouvre sur la copie du
  téléphone, avec toutes mes années. Les stats, y compris « depuis
  toujours », et l'export en image marchent : ils se calculent sur le
  téléphone. La publicité ne s'affiche pas.
- **H4. Je ferme l'app ou j'éteins le téléphone avant le retour du
  réseau.** La file est écrite sur le téléphone : je la retrouve, et elle
  part au premier réseau, que l'app soit rouverte par moi ou non n'y
  change rien (elle part à l'ouverture suivante).
- **H5. Je reste longtemps sans réseau.** Rien ne change, le compteur
  monte. Je ne suis pas déconnecté entre-temps. Au retour, tout part dans
  l'ordre.
- **H6. Je veux faire un geste qui demande le réseau** (liste des
  non-objectifs). « Il faut une connexion. Acheter ou restaurer Premium,
  créer un compte, s'y connecter et supprimer ses données demandent du
  réseau. Vos trackers restent utilisables. » Rien n'est fait à moitié.
- **H7. J'atteins la limite gratuite sans réseau.** Le téléphone connaît
  la limite de 3 trackers et la règle des trackers verrouillés : il les
  applique. Le mur Premium s'affiche, avec « L'achat sera possible au
  retour du réseau. »
- **H8. Je suis Premium et sans réseau.** Le téléphone garde le dernier
  état de Premium que le serveur lui a donné, et s'y tient tant qu'il est
  hors ligne.
- **H9. Mon Premium a pris fin, ou a été restauré ailleurs, pendant que
  j'étais hors ligne.** Je l'apprends au retour, par le message du
  document du compte (cas 43, 44 ou 47). Tout ce que j'ai fait hors ligne
  est gardé, y compris dans un tracker que le serveur verrouille
  désormais et les trackers créés au-delà de 3 ; le verrou vaut pour la
  suite, et l'écran de choix des trackers ouverts s'ouvre.
- **H10. Je me déconnecte alors que des modifications attendent.** « 3
  modifications ne sont pas envoyées. Vous êtes hors ligne. Si vous vous
  déconnectez maintenant, elles seront perdues. », avec « Rester
  connecté » et « Me déconnecter quand même ». Avec du réseau, la question
  ne se pose pas : la file part d'abord, puis la déconnexion a lieu.
  *Mon choix.*
- **H11. Mon téléphone est perdu, réinitialisé, ou l'app désinstallée,
  avant le retour du réseau.** Ce qui était déjà parti est sur le serveur.
  Ce qui attendait encore est perdu : cela n'existait que sur ce
  téléphone, et c'est ce que dit le bandeau.
- **H12. Le serveur refuse une modification pour une raison qui n'est pas
  un conflit** (rare : la 13ᵉ légende d'un tracker qui en a déjà 12
  ailleurs, une donnée invalide). Elle est retirée de la file et dite :
  « 1 modification n'a pas pu être enregistrée : la légende "Très bien"
  de "Humeur" n'a pas été créée. » Les autres partent normalement.
- **H13. J'ouvre l'app pour la première fois sans réseau.** Sans compte,
  tout marche et s'écrit sur le téléphone ; le compte sans identité est
  créé au premier réseau et la file part ensuite (document du compte,
  cas 5). Cela remplace « réseau exigé à la première ouverture ».
- **H14. Je supprime un tracker sans réseau.** Comme en ligne : il
  disparaît, « Annuler » le rend pendant 8 secondes. Passé ce délai la
  suppression est dans la file. Si l'app est fermée pendant les 8
  secondes, la suppression est acquise (aujourd'hui elle est oubliée :
  le tracker revient).
- **H15. Je viens de mettre l'app à jour.** À la première ouverture avec
  du réseau, l'app télécharge la copie complète. Tant que ce n'est pas
  fait, elle s'ouvre sur l'année gardée par l'ancienne version et dit
  « Il faut une connexion pour finir la mise à jour de vos trackers » si
  je tente une modification sans réseau.
- **H16. J'ai du réseau, mais le serveur ne répond pas.** Même
  traitement, même bandeau : pour moi rien ne change.

### Sans réseau, avec deux téléphones

La règle (décision 3) ne joue que si un même compte est ouvert sur deux
appareils et que les deux ont touché au même élément. Elle vaut pour les
modifications qui ont attendu ; deux téléphones en ligne restent sous la
règle d'aujourd'hui (cas H27).

Quand une ou plusieurs modifications ne sont pas appliquées, l'app le dit
une fois par synchronisation, dans un seul message qui les nomme :
« 2 modifications faites hors ligne n'ont pas été gardées », puis la liste
(« Le 12 mars de "Humeur" avait été modifié depuis un autre appareil »,
« "Sport" a été supprimé depuis un autre appareil »).

- **H17. J'ai colorié hors ligne un jour que l'autre téléphone a modifié
  entre-temps.** La version du serveur reste. Message : « Le 12 mars de
  "Humeur" avait été modifié depuis un autre appareil. C'est cette version
  qui est gardée. » Le message donne aussi ce qui n'a pas été gardé (ma
  couleur, mon commentaire), pour que je puisse le refaire si je veux.
- **H18. J'ai colorié hors ligne d'autres jours que ceux modifiés
  ailleurs.** Aucun conflit : tout est gardé des deux côtés. *Mon choix* :
  la comparaison se fait élément par élément, jamais tracker par tracker.
- **H19. Mes deux téléphones étaient hors ligne et ont modifié le même
  jour.** Le premier qui retrouve le réseau envoie sa version. Quand le
  second revient, le serveur a changé : la version du premier reste, et le
  second le dit (H17). C'est la conséquence directe de la règle.
- **H20. J'ai colorié hors ligne dans un tracker que l'autre téléphone a
  supprimé.** Le tracker est supprimé partout. « "Sport" a été supprimé
  depuis un autre appareil. Les 3 jours coloriés hors ligne n'ont pas été
  gardés. »
- **H21. J'ai supprimé hors ligne un tracker que l'autre téléphone a
  modifié entre-temps** (un jour, une légende, son nom). La suppression
  n'est pas appliquée : « "Sport" n'a pas été supprimé : il a été modifié
  depuis un autre appareil pendant que vous étiez hors ligne. Supprimez-le
  de nouveau si vous le voulez toujours. » Pour
  une suppression, l'élément comparé est le tracker entier avec son
  contenu, pour qu'elle n'efface jamais ce qu'un autre téléphone vient
  d'ajouter.
- **H22. J'ai renommé hors ligne un tracker renommé ailleurs.** Le nom du
  serveur reste. « Ce tracker s'appelle "Santé" : il a été renommé depuis
  un autre appareil. » Même traitement pour une légende, pour l'ordre des
  trackers, pour un réglage.
- **H23. Mes deux téléphones ont chacun créé un tracker hors ligne, et le
  compte gratuit dépasse 3 trackers.** Une création n'est jamais en
  conflit : les deux trackers sont gardés. Le dépassement se règle comme
  dans le document du compte : rien n'est effacé, les trackers en trop
  sont verrouillés, l'écran de choix s'ouvre. « Deux trackers ont été
  créés hors ligne sur deux appareils. Votre compte gratuit garde 3
  trackers ouverts : choisissez lesquels. »
- **H24. Mon compte a été supprimé depuis l'autre téléphone pendant que
  j'étais hors ligne.** Au retour : écran d'accueil, « Ce compte a été
  supprimé depuis un autre appareil. Les 2 modifications faites hors ligne
  n'ont pas été envoyées. » La copie du téléphone est effacée : la
  suppression a été demandée.
- **H25. Ma session a été fermée pendant que j'étais hors ligne** (mot de
  passe changé, « Déconnecter mes autres appareils », compte réuni avec un
  autre ou devenu un compte à identité, session refusée pour toute autre
  raison). « Reconnectez-vous : vos 4 modifications en attente seront
  envoyées. » La copie et la file restent sur le téléphone, cachées, et
  attendent ce compte, ou celui qui l'a absorbé : elles partent quand je
  m'y reconnecte. Elles ne deviennent jamais un autre compte, à deux
  exceptions près, écrites dans le document du compte : un appareil qui
  était dans un compte invisible au moment où celui-ci a reçu une identité
  ailleurs peut continuer sans compte avec ses trackers (cas 55), et la
  copie d'un compte effacé par le serveur repart vers lui (cas 61). Hors
  de ces deux cas, si je me connecte à un compte différent, ou si je
  choisis « sans compte », l'app me prévient qu'elles seront perdues et me
  laisse renoncer.
- **H26. L'autre téléphone a une ancienne version de l'app** (1.4.0). Ses
  modifications comptent comme celles de n'importe quel autre appareil :
  elles peuvent faire écarter les miennes faites hors ligne.
- **H27. Deux téléphones en ligne touchent le même jour au même moment.**
  Inchangé : le dernier qui écrit gagne, et les deux affichent la même
  chose dans la seconde, sans message.
- **H28. J'ai modifié plusieurs fois le même élément hors ligne.** Seul le
  dernier état part, comparé à ce que le serveur avait avant ma première
  modification. Mes propres modifications ne comptent jamais comme un
  changement venu d'ailleurs : si la première était déjà partie et que sa
  réponse s'est perdue, la suivante n'est pas écartée à cause d'elle.
- **H29. L'autre téléphone a recolorié une légende pendant que j'étais
  hors ligne.** Recolorier une légende est un seul élément, pas une
  modification de chacun de ses jours. Les jours recoloriés ne comptent
  donc pas comme changés : ce que j'ai fait hors ligne sur ces jours (un
  commentaire, un jour colorié avec cette légende) est gardé, dans la
  nouvelle couleur.

## Règles

- **La copie du téléphone.**
  - Elle contient tout le compte, toutes années comprises, et pas
    seulement l'année affichée.
  - Une modification et son entrée dans la file s'écrivent ensemble, ou
    pas du tout.
  - Ce qui arrive du serveur (en direct ou à la synchronisation) met la
    copie à jour, sauf pour un élément qui a une modification en attente :
    celle-ci reste affichée jusqu'à ce que le serveur ait tranché.
  - Elle est effacée à la déconnexion (cas H10), à la suppression des
    données, et quand le serveur dit que le compte a été supprimé à la
    demande.
- **La file.**
  - Dans l'ordre des gestes. Une modification qui dépend d'une autre (un
    jour colorié dans un tracker créé hors ligne) part donc après elle.
  - Chaque modification porte un identifiant unique ; le serveur retient
    ceux qu'il a traités et répond la même chose à un renvoi (principe 5).
    Il les retient 90 jours (*mon choix*) ; un renvoi plus tardif, venu
    par exemple d'une vieille sauvegarde du téléphone, est jugé par la
    règle du conflit comme n'importe quelle modification qui a attendu.
  - Une panne de réseau arrête l'envoi, qui reprend plus tard au même
    endroit. Un refus (conflit, cas H12) ne l'arrête pas : la modification
    est retirée, notée pour le message, et la suivante part.
  - Si une modification refusée en entraîne d'autres (un tracker supprimé
    ailleurs : tout ce que j'y ai fait), elles sont retirées avec elle et
    comptées dans le même message.
- **Les identifiants.** L'app crée elle-même l'identifiant d'un tracker et
  d'une légende, pour pouvoir s'en servir avant que le serveur réponde.
  Aujourd'hui c'est le serveur qui le crée, et l'app attend sa réponse.
- **Le conflit (principe 3).**
  - Une modification qui a attendu porte ce que le téléphone savait de
    l'élément au moment du geste. Le serveur compare avec ce qu'il a : si
    c'est différent, l'élément a changé ailleurs et la modification n'est
    pas appliquée.
  - Un élément qui n'existe plus a changé. Un tracker supprimé écarte tout
    ce qui le concerne.
  - Une création n'est jamais en conflit. Mais elle ne fait pas revivre
    ce qui a été supprimé depuis : le serveur se souvient des trackers
    supprimés aussi longtemps que des comptes (24 mois, document du
    compte), et une création renvoyée après coup, par exemple par une
    vieille sauvegarde, est écartée comme une modification d'un tracker
    supprimé.
  - Une modification qui n'a pas attendu (voir le vocabulaire) n'est pas
    soumise à cette règle (cas H27).
  - Le serveur sait de quelle file vient chaque modification : ce que ce
    téléphone a changé lui-même ne compte jamais comme un changement venu
    d'ailleurs, ni pour une modification suivante du même élément (cas
    H28), ni pour une suppression (cas H21). Une modification déjà partie,
    dont la réponse n'est pas revenue, n'est pas regroupée avec une
    suivante.
  - Recolorier une légende ne marque pas ses jours comme changés (cas
    H29). Aujourd'hui c'est le cas (`backend/src/routes/cells.ts:165`), et
    l'app l'envoie en deux demandes
    (`flutter_app/lib/widgets/legend_editor_dialog.dart:359`) : ce sera
    une seule modification.
- **La limite gratuite et Premium.**
  - Le téléphone applique hors ligne ce qu'il sait : limite de 3 trackers,
    trackers verrouillés, dernier état connu de Premium.
  - Une modification qui a attendu n'est jamais refusée à cause du verrou
    ou de la limite : elle est gardée, et le verrou s'applique ensuite
    (cas H9 et H23). Il en va de même d'une copie du téléphone renvoyée au
    serveur (document du compte, cas 85). *Mon choix* : la limite gratuite est une règle
    commerciale, pas une protection ; perdre des saisies pour elle
    coûterait plus qu'elle ne rapporte. Son prix : une app modifiée
    pourrait s'en servir pour écrire dans un tracker verrouillé.
- **Le message.** Un seul par synchronisation, qui nomme chaque élément et
  sa raison. Il se montre dès que la synchronisation est finie, et attend
  l'ouverture suivante si l'app n'est pas à l'écran.
- **Les sessions.**
  - Une file ne part que sous le compte qui l'a produite, ou sous celui
    qui l'a absorbé (cas H24 et H25).
  - Rester des semaines hors ligne sans être déconnecté (cas H5) demande
    une session qui dure. Aujourd'hui elle s'éteint après 7 jours
    (`backend/src/routes/auth.ts:42`), l'ancien jeton est supprimé avant
    que la réponse du nouveau soit arrivée (`auth.ts:319`), et tout refus
    efface ce que l'app garde (`flutter_app/lib/services/api_service.dart:184`,
    `main.dart:395`). Ce chantier, construit le premier, apporte donc
    lui-même ce que le document du compte décrit : une session longue, un
    renouvellement qui survit à une réponse perdue, et un refus qui dit
    sa raison. Un refus ne fait jamais effacer la copie ni la file, sauf
    quand sa raison est une suppression demandée (cas H24).
  - **Avant tout geste qui fait juger ou déplacer les données du
    téléphone par le serveur** (créer un compte, en rejoindre un,
    retrouver des trackers par la clé, réunir, reprendre, changer
    d'adresse), l'app envoie d'abord la file. Si elle ne part pas, le
    geste répond « Connexion impossible, réessayez » et rien n'a changé.
    Quand le compte n'existe pas encore sur le serveur (cas H13), il n'y
    a pas de file à envoyer : la copie part avec la création du compte.
- **Les anciennes versions** continuent d'utiliser les routes
  d'aujourd'hui. Toutes leurs écritures doivent être vues comme des
  changements par la règle du conflit, y compris celles qui ne laissent
  aucune trace aujourd'hui : la remise à zéro d'une année et le
  recoloriage en masse (`backend/src/routes/cells.ts:180`,
  `backend/src/routes/legends.ts:101`).

## Ce que cela touche

**App** (lu dans le code le 2026-11-26)

- Il n'y a aujourd'hui aucune base sur le téléphone : seulement un fichier
  de l'année affichée, « jamais source de vérité »
  (`flutter_app/lib/services/snapshot_store.dart:15`), et des préférences.
  Aucun paquet de base locale ni de détection du réseau n'est installé.
- Chaque écriture va droit au serveur. Les jours, l'ordre des trackers et
  le choix des trackers ouverts s'affichent d'abord puis sont annulés si
  le serveur refuse, comme l'ordre des légendes
  (`cells_provider.dart:189-264`, `pages_provider.dart:165-226`,
  `legends_provider.dart:196`) ; créer ou renommer un tracker, créer,
  modifier ou supprimer une légende, attend la réponse et ne fait rien en
  cas d'échec (`pages_provider.dart:71-200`,
  `legends_provider.dart:146-194`). Seul le parcours du premier tracker
  dit une erreur ; aucune autre écriture ratée n'est dite à
  l'utilisateur.
- Une relecture du serveur remplace les trackers, les légendes et les
  jours de l'année (`pages_provider.dart:54`, `legends_provider.dart:57`,
  `cells_provider.dart:100`) : elle effacerait des modifications en
  attente.
- Les stats « depuis toujours » interrogent le serveur
  (`backend/src/routes/stats.ts:16`) ; avec la copie complète elles se
  calculent sur le téléphone.
- Les réglages s'enregistrent sur le téléphone puis partent sans suivi :
  un envoi perdu est écrasé par la valeur du serveur à la connexion
  suivante (`main.dart:349-361`). Ils entrent dans la file.
- La suppression d'un tracker tient à un minuteur en mémoire
  (`pages_provider.dart:247`) : cas H14.
- Le parcours du premier tracker se décide sur une réponse du réseau
  (`data/first_tracker_decision.dart:32`) ; il se décide désormais sur la
  copie du téléphone.
- « Hors ligne » n'existe aujourd'hui que comme « session pas encore
  confirmée » (`auth_provider.dart:17`) et n'est montré nulle part.

**Serveur**

- Accepter l'identifiant choisi par l'app pour un tracker et une légende.
- Savoir si un élément a changé : seuls les jours ont une date de
  modification (`backend/src/db/schema.ts:108`) ; les trackers, les
  légendes et les réglages n'en ont pas.
- Retenir les modifications déjà traitées, juger celles qui ont attendu,
  et répondre pour chacune : appliquée, écartée (changée ailleurs),
  écartée (supprimée ailleurs), refusée (avec la raison).
- Donner la copie complète d'un compte, et ensuite ce qui a changé depuis
  la dernière synchronisation, suppressions comprises (aujourd'hui une
  année à la fois, `routes/bootstrap.ts:34`, et aucune trace de ce qui est
  supprimé).
- Ne pas refuser pour le verrou ou la limite une modification qui a
  attendu (`routes/cells.ts:18`, `routes/pages.ts:102`).
- Pousser aussi les réglages aux autres téléphones
  (`routes/auth.ts:378` n'annonce rien).
- Recevoir une copie entière d'un compte : aujourd'hui une demande est
  limitée à 1 Mo (`backend/src/index.ts:63`).

**Document du compte.** Première ouverture sans réseau (H13) ; la file
avant de créer ou de rejoindre un compte ; la file et les sessions fermées
(H24, H25) ; la copie du téléphone comme moyen de retrouver ses données
(effacement des 12 mois, sauvegarde du téléphone).

**Légal.** Les données sont désormais aussi sur le téléphone : à dire dans
la politique de confidentialité et au registre, avec ce qu'il en advient
dans les sauvegardes du téléphone (voir le document du compte).

## Mesure

Par semaine, sans nommer de compte : synchronisations qui ont envoyé des
modifications en attente, nombre de modifications, nombre écartées par
conflit et par raison. C'est ce qui dira si les conflits sont aussi rares
que l'étude le suppose.

## À vérifier pendant la construction

- La base du téléphone : écrire une modification et sa file ensemble,
  même si l'app est tuée au milieu ; sa taille pour un compte chargé (dix
  trackers sur plusieurs années).
- Que l'app soit bien prévenue du retour du réseau sans attendre que la
  personne fasse un geste.
- La migration depuis 1.4.0 sur un téléphone hors ligne (H15).
- Deux téléphones réels, l'un en mode avion : chaque cas H17 à H29.

## Place dans la construction

*Mon choix* : un chantier à part, le 10, construit **avant** celui du
compte (9), parce que le compte s'appuie sur la copie du téléphone
(première ouverture sans réseau, retour après effacement) et que les deux
refont la façon dont l'app parle au serveur. Ordre proposé : 0, 1,
registre, 3, **10**, **9**, 2, 5 lot 1, 4, 8 lot 1, 5 lots 2 et 3, 6, 7,
8 lot 2.

C'est la plus grosse pièce de la release : toute la couche de données de
l'app est refaite, et chaque route d'écriture du serveur est touchée.
L'estimation viendra du plan.

## Laissé au constructeur

- La base du téléphone et son paquet ; le format de la file.
- Le protocole : comment le téléphone dit ce qu'il savait d'un élément,
  comment le serveur dit ce qui a changé depuis la dernière fois.
- La détection du réseau.
- Les textes en anglais et en chinois ; la forme du bandeau et du message.
- Les tests, y compris une suite de bout en bout pour chaque cas H.

## Relecture du 2026-11-26

Un autre agent a relu ce document avec les nouvelles parties du document
du compte, en cherchant les pertes de données non demandées, les
situations où l'utilisateur ne sait pas ce qui lui arrive, et ce qu'un
constructeur devrait deviner. Il a aussi vérifié dans le code la section
« Ce que cela touche ». Ce qu'il a trouvé ici :

| Trouvé | Réglé par |
|---|---|
| **Grave.** Un geste de compte (rejoindre, réunir) était jugé par le serveur alors que le téléphone avait encore une file : un tracker rempli hors ligne passait pour vide | Règles « Les sessions » : la file part d'abord |
| Les deux documents se contredisaient sur la file d'un compte absorbé | Cas H25, règles « Les sessions » : elle part sous le compte qui l'a absorbé |
| Ma propre modification, partie puis renvoyée, faisait écarter la suivante comme « modifiée ailleurs » | Cas H28, règles « Le conflit » |
| « A attendu » n'était pas défini, alors que tout passe par la file | Vocabulaire |
| Un recoloriage marquait chaque jour comme changé et faisait écarter les commentaires en attente de l'autre téléphone, ce que l'étude demandait d'éviter | Cas H29, règles « Le conflit » |
| Une copie renvoyée au serveur pouvait être refusée pour la limite gratuite | Règles « La limite gratuite et Premium » |
| Rester longtemps hors ligne dépendait d'une session longue décrite dans l'autre document, construit après | Règles « Les sessions » |
| Le message de conflit ne donnait pas ce qui avait été écarté | Cas H17 |
| Écritures des anciennes versions qui ne laissent aucune trace ; limite de 1 Mo ; durée du souvenir des modifications traitées | Règles « Les anciennes versions », « La file » ; « Ce que cela touche » |
| Inexactitudes sur le code d'aujourd'hui (ordre des légendes, erreur du premier tracker, deux numéros de ligne) | « Ce que cela touche » |

Le même agent a ensuite vérifié ces corrections. Ce qu'il a encore
trouvé ici, et qui est réglé : le cas H25 contredisait le cas 55 du
document du compte (les deux exceptions y sont maintenant nommées) ; une
création renvoyée longtemps après faisait revivre un tracker supprimé
(règles « Le conflit ») ; « la file part d'abord » n'avait pas de sens
avant que le compte existe sur le serveur (règles « Les sessions »).

## Ce qui reste incertain

- À quelle fréquence les utilisateurs sont hors ligne, et combien de
  conflits cela produit : mesuré nulle part, la mesure le dira.
- Le risque d'une migration de la couche de données juste avant le Nouvel
  An. Le plan doit prévoir comment revenir en arrière.
- Ce que deviennent la copie du téléphone et sa file dans une sauvegarde
  du téléphone restaurée plus tard : la conception est dans le document
  du compte (cas 84 à 86), et reste à essayer sur de vrais appareils.
