# Entrer sans mur : le compte invisible — design

2026-11-25. Né des questions de Charles sur l'usage sans compte
(`docs/research/2026-11-25-hors-connexion-et-sans-compte.md`, avec les deux
recherches et la mesure). Décidé avec lui au fil de la conversation du même
jour ; ce qui est *mon choix* (Fable) est marqué.

Cinquième version. Les quatre premières ont été relues deux fois par un
autre agent, puis vérifiées ; ce que la cinquième ajoute a été relu une
fois (section « Relectures »).

- La première permettait d'acheter sans compte ; la première relecture y a
  trouvé des trous graves.
- La deuxième exigeait un compte pour Premium. La recherche sur la revue
  d'Apple (`docs/research/reports/Compte exigé avant l'achat et revue
  Apple.md`) a montré que c'est exactement ce qu'Apple refuse.
- La troisième revenait à l'achat sans compte et ajoutait deux idées de
  Charles : l'achat qui sert de clé pour retrouver ses trackers, et le cas
  de deux téléphones sur un même compte. La seconde relecture y a trouvé
  deux chemins vers une perte de trackers.
- La quatrième les fermait (section « Relectures » à la fin). Son
  changement le plus visible : reprendre ses trackers par l'achat en donne
  une **copie**, et ne touche jamais au téléphone d'origine.
- Celle-ci (2026-11-26) ajoute trois décisions de Charles : le compte par
  e-mail passe par un code, la clé d'un compte invisible va dans le
  trousseau iCloud pour suivre la personne, et les réglages disent où en
  sont ses données. Elle s'appuie sur le document du hors-ligne
  (`2026-11-26-offline-sync-design.md`) et sur la recherche
  `docs/research/reports/Garder l'accès sans compte en changeant de
  téléphone.md`.

## Pourquoi

Aujourd'hui l'app s'ouvre sur un écran de connexion et rien n'est utilisable
avant d'avoir un compte. Mesuré du 28 septembre au 22 novembre 2026 : 219
installations (104 premiers téléchargements iOS, 115 acquisitions Android)
pour 152 comptes créés. **Environ 31 % des personnes qui installent l'app
ne créent jamais de compte**, et 36 % des comptes créés ne colorient jamais
un point. Ce chiffre contient aussi ceux qui n'ouvrent jamais l'app et ceux
qui avaient déjà un compte ; les volumes sont petits.

Les deux craintes de Charles, auxquelles le design répond :

- sans obligation, beaucoup de gens ne verront pas l'intérêt de créer un
  compte, et le nombre de comptes baissera ;
- au mur Premium, il faudrait créer un compte, revenir au mur, puis payer.

Aucune étude ne mesure la taille de ces effets (voir la recherche) ; on en
connaît le sens.

## Décisions de Charles (2026-11-25)

1. **Le compte invisible.** À la première ouverture, l'app peut créer en
   coulisse un compte sans e-mail ni mot de passe, attaché au téléphone.
   Tout marche comme avec un compte gratuit : données sur le serveur,
   limite de 3 trackers (« pas mal »).
2. **Un écran d'accueil qui propose le compte dès le début, avec la
   possibilité de passer** (son idée) : Apple, Google, e-mail et
   « Continuer sans compte », quatre boutons de même taille.
3. **Sur les recommandations de Fable** (« fais selon tes
   recommandations ») : effacement d'un compte invisible après 12 mois
   sans ouverture ; réseau exigé à la première ouverture.
4. **On peut acheter Premium sans compte.** Charles avait d'abord tranché
   l'inverse (« trop d'incompréhension, de problèmes potentiels »). Deux
   choses l'ont fait changer d'avis : la recherche sur la revue d'Apple
   (un refus bloquerait toute la release), et le fonctionnement des
   stores, où c'est Apple ou Google qui prouve l'achat : « on peut
   effectivement proposer de passer premium même si on a pas de compte ».
   Le compte est proposé après l'achat, jamais exigé.
5. **L'achat sert de clé pour retrouver ses trackers** (son idée). Quand
   quelqu'un restaure son achat sur un autre téléphone, le serveur
   reconnaît l'achat et lui propose les trackers du compte invisible qui
   l'avait fait. Celui qui détient le compte du store de l'acheteur peut
   donc les obtenir, y compris un proche qui partage cet identifiant ;
   Charles l'a pesé et l'accepte : « c'est logique, il peut reprendre les
   trackers, c'est leur responsabilité ».
6. **Deux téléphones sur un même compte doivent marcher sans bug**, y
   compris tenus par deux personnes différentes (« il faut penser comment
   gérer ce cas-là, faut pas que ça crée des bugs ou des problèmes »).
7. **Ce chantier entre dans la release unique** (« on peut ajouter ça au
   chantier »).
8. **Personne ne perd ses données pour avoir raté une option** (« faut pas
   que l'user perde ses données car il a raté une option à la synchro »).
9. **Pas de trou, pas de situation floue pour l'utilisateur** : c'est la
   consigne donnée aux relectures, et la raison des messages de ce
   document.
10. **Le compte par e-mail passe par un code** (2026-11-26). Aujourd'hui
    l'adresse n'est jamais vérifiée : une faute de frappe à l'inscription
    ferme le compte à son propriétaire le jour où il change de téléphone.
    Charles : « la confirmation par mail, ça fait sens », puisque créer un
    compte n'est plus une obligation. Sur ma recommandation, qu'il a
    acceptée : un compte par e-mail se crée par code, sans mot de passe à
    inventer, et le mot de passe s'ajoute dans les réglages pour qui en
    veut un. Charles a précisé ensuite : « Le code n'est pas censé
    remplacer le mot de passe, c'est juste une option supplémentaire de
    connexion. […] Si aujourd'hui je vais me connecter par code, demain
    par mot de passe, ça doit être possible. » Les deux coexistent : se
    connecter par l'un ne retire jamais l'autre. Les comptes e-mail d'aujourd'hui ne sont pas invités à
    confirmer leur adresse (« on va pas leur rajouter une friction alors
    qu'ils ont déjà un compte »).
11. **L'app s'utilise sans réseau, avec ou sans compte, et tout se
    synchronise** (2026-11-26). C'est l'objet du document du hors-ligne.
    Ce qu'il change ici : le téléphone garde une copie complète des
    données, et cette copie devient un moyen de plus de ne pas les perdre.
12. **La clé d'un compte invisible suit la personne** (2026-11-26). Sur
    iPhone, la ranger dans le trousseau iCloud, pour qu'un autre appareil
    du même compte Apple retrouve les trackers sans compte ni achat :
    « ça va faire un cas supplémentaire pour éviter de perdre des données,
    donc c'est bon à prendre », avec la consigne de bien peser les
    problèmes que cela peut apporter. Sur Android, chercher l'équivalent.
13. **Les réglages disent où en sont mes données** (2026-11-26) : si elles
    sont sauvegardées, synchronisées, et comment les emmener sur un autre
    téléphone selon qu'il est sous iOS ou Android. « Pas non plus un
    tuto », mais l'état et les options.
14. **Les choix que Fable avait laissés ouverts sont confirmés**
    (2026-11-26 : « tu peux tout faire selon tes recommandations, donc il
    n'y a plus besoin d'attendre ma réponse ») : la première ouverture
    marche sans réseau ; un téléphone qui a encore sa copie la renvoie
    après l'effacement des 12 mois ; le thème et la langue suivent le
    compte ; changer d'adresse réunit deux comptes quand la nouvelle
    adresse appartient déjà à l'un des miens ; et, dans le document du
    hors-ligne, la finesse des conflits, la suppression faite hors ligne,
    la confirmation avant de se déconnecter et les modifications gardées
    après une déconnexion forcée.
15. **La clé de restauration Android entre dans cette release**
    (2026-11-26 : « Ok on inclut le lot Android dans cette release »).
    J'avais proposé de la livrer après ; Charles a demandé pourquoi ne pas
    la faire aussi, et les raisons de la faire maintenant l'emportent :
    une seule release, un seul passage sur le code des sessions, et
    aucune course contre l'échéance de Google (avril 2027).

## Vocabulaire

- **Compte invisible** : un compte sans identité (ni Apple, ni Google, ni
  e-mail). Il s'ouvre avec la clé du téléphone qui l'a créé.
- **Compte attaché** : un compte qui a au moins une identité. Tous les
  comptes d'aujourd'hui le sont.
- **Clé** : un secret long, créé avec le compte invisible, qui rouvre ce
  compte. Elle est rangée dans le coffre du téléphone ; sur un appareil
  Apple, ce coffre (le trousseau) peut la recopier sur les autres
  appareils de la même personne.
- **Copie du téléphone** : toutes les données du compte, gardées aussi
  sur le téléphone (document du hors-ligne).
- **Attacher** : donner une identité à son compte invisible.
- **Rejoindre** : depuis le téléphone d'un compte invisible, prouver
  l'identité d'un compte attaché qui existe déjà. Le compte invisible est
  alors absorbé : ses trackers s'ajoutent au compte, son achat suit, lui
  disparaît.
- **Reprendre** : copier dans son compte les trackers d'un compte
  invisible qui a porté le même achat. L'original n'est pas touché.
- **Point** : une case coloriée. « Aucun point » veut dire aucune case
  coloriée, dans aucun tracker du compte.
- **Achat** : un abonnement (essai compris) ou un achat à vie. Un compte
  **porte un achat** quand il a un abonnement en cours ou un achat à vie.
- **Compte du store** : l'identifiant Apple ou le compte Google avec
  lequel on achète.

## Les sept principes

Tout le reste en découle ; un cas que ce document n'a pas prévu se règle
avec eux.

1. **Rien ne s'efface par un choix de connexion.** Aucun écran de
   connexion, de restauration, de reprise ou pour rejoindre un compte ne
   propose d'effacer. Les seules suppressions sont : « Supprimer mes
   données » (demandé, confirmé, et seulement si le serveur a répondu), la
   suppression d'un tracker (avec son annulation de 8 secondes), et les
   deux effacements automatiques annoncés (cas 61 et 62).
2. **Rien ne se passe en silence.** Chaque refus, chaque effacement,
   chaque déplacement de Premium, chaque arrivée de trackers a son
   message, sur chaque téléphone concerné. Un bouton qui n'a rien pu faire
   le dit.
3. **Un achat est sur un seul compte à la fois, et c'est le serveur qui
   sait lequel.** Ce compte peut être invisible. Le serveur ne croit pas
   l'app sur parole : il demande à RevenueCat, et lui seul éteint Premium.
   Quand un compte est absorbé, son achat suit, chez nous et chez
   RevenueCat.
4. **Un compte invisible ne se perd pas par accident technique** : ni par
   une session expirée, ni par une réponse perdue en route, ni par une
   restauration de la base. Et il n'est jamais effacé tant qu'un achat
   qu'il a porté est en cours, sur lui ou ailleurs.
5. **Invisible ou attaché, c'est le serveur qui le dit.** L'app ne le
   déduit jamais de ce qu'elle a gardé en mémoire.
6. **Le compte n'est jamais exigé pour acheter ni pour restaurer.** Il est
   proposé, avec ses raisons, et l'on peut toujours passer.
7. **Chaque compte a sa porte, et une seule.** On entre dans un compte
   attaché en prouvant son identité ; dans un compte invisible, avec sa
   clé, et jamais sans que la personne l'ait demandé sur l'appareil qui
   la trouve. Prouver un achat n'ouvre aucun compte : cela
   donne Premium, et une copie des trackers des comptes invisibles qui ont
   porté cet achat. Personne ne modifie ni n'efface les trackers d'un
   compte sans y être entré par sa porte.

## Objectifs, non-objectifs, anti-objectifs

**Objectifs**

- Arriver dans l'app et colorier son premier point sans créer de compte.
- Acheter Premium en une étape, avec ou sans compte.
- Proposer le compte à tout le monde dès l'accueil, puis aux moments où il
  a du sens, sans jamais bloquer.
- Qu'une personne qui a payé retrouve Premium et ses trackers en changeant
  de téléphone, même sans compte, tant qu'elle reste sur la même
  plateforme.
- Que deux téléphones sur un même compte montrent toujours la même chose,
  et que chacun sache ce que l'autre a fait.
- Savoir, après la sortie, quelle part entre sans compte, quelle part
  achète sans compte et quelle part s'attache ensuite.

**Non-objectifs**

- Le hors-ligne lui-même : il a son document.
- Sauvegarder nous-mêmes les trackers dans iCloud ou Google Drive. Seule
  la clé va dans le trousseau ; la copie du téléphone suit les sauvegardes
  du système, sans que l'app s'en mêle.
- Dire dans l'app si une sauvegarde a eu lieu : ni iOS ni Android ne le
  permettent (cas 79).
- Fusionner les points de deux trackers. Réunir deux comptes attachés,
  sauf quand un changement d'adresse prouve qu'ils sont à la même personne
  (cas 77).
- Partager un compte invisible entre deux appareils autrement que par la
  clé du trousseau, donc entre appareils Apple d'une même personne. Entre
  deux Android, ou d'une plateforme à l'autre, il faut un compte attaché.
- Faire passer un achat d'iPhone à Android sans compte : les stores ne
  savent pas le faire, seul le compte le permet.
- D'autres méthodes de connexion. *Mon choix* : Instagram n'en propose
  plus aux apps grand public depuis décembre 2024 ; Facebook et TikTok
  sont possibles mais ajoutent un SDK, une revue et des déclarations pour
  des gens qui ont déjà Apple ou Google, et « Continuer sans compte »
  enlève l'obstacle. À rouvrir si la mesure montre que beaucoup entrent
  sans compte et ne s'attachent jamais.
- Limiter le nombre de téléphones d'un compte.
- Donner à chaque téléphone son thème et sa langue : ils suivent le
  compte (cas 54).

**Anti-objectifs** : tout ce qui viole un des sept principes ; un écran
d'accueil qui se lit comme un mur (« Continuer sans compte » en petit, en
gris, ou sous la ligne de flottaison) ; une invitation à créer un compte
qu'on ne peut pas refuser. Ne jamais relier un compte invisible à une
personne ou à un appareil par un identifiant publicitaire ou une empreinte.

## Approches

**Pour entrer dans l'app**

| | Approche | Ce qu'elle donne | Pourquoi (pas) |
|---|---|---|---|
| A | Mur reculé : le compte reste obligatoire, demandé juste après le premier point | Le plus petit changement | Le mur arrive avant l'attachement ; ne règle pas l'achat du premier jour |
| B | Mur plus tard (après quelques jours), données gardées sur le téléphone entre-temps | Plus d'attachement au moment de la demande | Oblige à stocker les données sur le téléphone |
| C | **Compte invisible sur le serveur, compte proposé à l'accueil et plus tard** | Aucun mur à l'entrée, le serveur connaît tout le monde et garde les données (avec le hors-ligne, le téléphone en a une copie) | **Retenue.** Son prix : qui ne s'attache jamais et n'achète jamais perd tout en changeant de téléphone |
| D | Invité purement local, compte comme sauvegarde facultative (ce que font la plupart des apps comparables) | Marche hors connexion | Toute la couche de données à refaire ; le serveur ne sait plus qui est Premium ; limite gratuite et mesure à repenser |

**Pour acheter Premium**

| | Approche | Risque à la revue d'Apple | Pourquoi (pas) |
|---|---|---|---|
| 1 | Compte exigé pour acheter, avec l'explication « retrouvé sur tous vos appareils » | Modéré à élevé à chaque soumission : c'est mot pour mot ce que vise un message de refus type, encore envoyé en 2026 ; le cas le plus proche du nôtre a été refusé en mai 2026 | Le plus simple à construire. Écarté : un refus bloquerait toute la release, et une approbation ne protège pas la mise à jour suivante |
| 2 | **Achat sans compte, puis compte proposé avec insistance mais refusable ; restauration sans connexion** | Le plus faible : c'est la forme que décrivent le message de refus et les conférences d'Apple, aucun refus trouvé | **Retenue.** Son prix : le serveur doit suivre un achat fait par un compte sans identité, et quelques situations rares sont à expliquer (cas 42 à 47) |

Google Play n'a aucune règle sur ce point.

**Pour reprendre ses trackers par l'achat**

| | Approche | Ce qu'elle donne | Pourquoi (pas) |
|---|---|---|---|
| i | Le téléphone qui restaure **entre** dans le compte invisible d'origine ; les deux téléphones partagent ensuite le même compte | Un iPhone et un iPad sans compte partagent leurs trackers | Écartée après la seconde relecture : celui qui détient le compte du store pourrait alors modifier ou effacer les trackers de l'acheteur, ou le laisser à la porte en créant un compte le premier |
| ii | **Le téléphone qui restaure reçoit une copie** ; le compte d'origine n'est pas touché | L'acheteur qui change de téléphone retrouve tout ; personne d'autre ne peut toucher à ses trackers | **Retenue**, *mon choix*. Son prix : deux appareils sans compte ne partagent pas leurs trackers ; pour cela il faut un compte |

## Les cas

Numérotés pour pouvoir s'y référer. Les textes entre guillemets sont le
français ; le constructeur écrit l'anglais et les deux chinois. Là où un
texte dit « compte Apple » ou « App Store », l'app dit le store concerné.

### L'écran d'accueil

Quatre boutons de même taille et de même poids visuel : « Continuer avec
Apple » (iPhone seulement, comme aujourd'hui), « Continuer avec Google »,
« Continuer avec un e-mail », « Continuer sans compte ». Dessous : « Avec
un compte, vous retrouvez vos points sur un autre téléphone. Sans compte,
ils restent liés à cette installation de l'app. »

1. **Nouveau, « sans compte ».** Un compte invisible est créé ; la personne
   arrive sur la création de son premier tracker (le parcours d'aujourd'hui).
2. **Nouveau, Apple, Google ou e-mail.** Un compte attaché est créé ; même
   arrivée.
3. **Déjà un compte, méthode habituelle.** La personne retrouve ses
   trackers. Apple et Google connectent ou créent selon que l'identité est
   connue ; « e-mail » mène au parcours par code (cas 70).
4. **Fenêtre Apple ou Google annulée.** Retour à l'écran d'accueil, sans
   message d'erreur.
5. **Pas de réseau.** « Continuer sans compte » marche tout de suite :
   tout s'écrit sur le téléphone, et le compte invisible est créé au
   premier réseau, sans rien demander (document du hors-ligne, cas H13).
   Les trois autres boutons répondent : « Il faut une connexion pour se
   connecter à un compte. Vous pouvez commencer sans compte et le créer
   plus tard. » Cela remplace « réseau exigé à la première ouverture » de
   la décision 3 (confirmé, décision 14).
6. **Trop de comptes créés depuis le même réseau** (cas 63). « Continuer
   sans compte » marche quand même : tout s'écrit sur le téléphone, et la
   création du compte invisible est retentée plus tard, sans rien dire.
   Les trois autres boutons marchent.
7. **L'écran d'accueil revient alors que la personne avait des données.**
   L'app ne montre pas un premier lancement muet : elle dit pourquoi,
   d'après la raison que le serveur lui a donnée (voir « Règles,
   session ») :
   - le compte a été supprimé depuis un autre appareil : cas 50 ;
   - le mot de passe a changé, ou la personne a été déconnectée depuis un
     autre appareil : cas 51 et 52 ;
   - le compte invisible a reçu un identifiant, ou a rejoint un compte,
     depuis un autre appareil : cas 55 ;
   - le serveur avait effacé le compte (cas 61 et 62) : si le téléphone a
     encore sa copie, elle repart vers le serveur et rien n'est dit,
     puisque rien n'est perdu ; s'il ne l'a plus (app réinstallée), « Les
     trackers liés à cet appareil ont été effacés après 12 mois sans
     ouverture de l'app. » ;
   - les données avaient été supprimées à la demande, et une sauvegarde
     du téléphone les ramène : cas 86 ;
   - sinon : « Ce téléphone ne retrouve pas vos données. Si vous aviez créé
     un compte, connectez-vous. Si vous aviez acheté Premium, entrez sans
     compte puis touchez "Restaurer les achats". »
   Avec la copie du téléphone, l'app affiche les trackers sans attendre
   le serveur. Si le serveur répond ensuite que le compte n'existe plus,
   elle le dit avec l'une de ces raisons, jamais par un écran qui se vide
   sans un mot.

### Sans compte attaché

8. Tout marche comme avec un compte gratuit : trackers, points, légendes,
   limite de 3 trackers, publicité, rappels, thème et langue. Et l'on peut
   acheter Premium (cas 28).
9. **Retour après des semaines.** Les points sont là : la session d'un
   compte invisible ne s'éteint jamais d'elle-même (principe 4).
10. **Réglages.** Là où un compte attaché voit son e-mail et « Se
    déconnecter », un compte invisible voit « Créer mon compte », « J'ai
    déjà un compte », « Mes données » (cas 79), et une phrase toujours
    visible : « Sans compte, vos trackers peuvent ne pas vous suivre sur
    un autre téléphone. "Mes données" dit ce qu'il en est. »
    Pas de « Se déconnecter » : il n'y aurait aucun moyen sûr de revenir.
    « Restaurer les achats » est dans les réglages de tous les comptes
    (aujourd'hui il n'existe que derrière un mur Premium).

### Quand le compte est proposé

| | Moment | Ce qui est montré | On peut passer |
|---|---|---|---|
| a | Première ouverture | L'écran d'accueil | « Continuer sans compte » |
| b | Après le 3ᵉ jour colorié, puis le 7ᵉ | L'invitation (cas 11) | « Plus tard » |
| c | Juste après un achat ou un début d'essai | L'écran du cas 12 | « Plus tard » |
| d | Ensuite, tant qu'un payeur n'a pas de compte | La ligne du cas 13 | Elle reste, sans bloquer |
| e | En permanence | Les réglages (cas 10) | — |
| f | Quand Premium arrive, part ou prend fin sur un téléphone sans compte | Dans le message (cas 32 à 34, 40, 43, 47) | — |

11. **L'invitation.** À la première ouverture qui suit le 3ᵉ jour colorié,
    puis le 7ᵉ, un écran propose : « Créez votre compte pour retrouver vos
    points si vous changez de téléphone », avec les trois boutons
    d'identité et « Plus tard ». « Jour colorié » : une date du calendrier
    qui porte au moins un point, tous trackers confondus ; le compte
    passe donc de 2 à 3 dates coloriées, quel que soit le jour où il les a
    posées. Chaque invitation ne se montre qu'une fois, et c'est le serveur
    qui retient qu'elle l'a été (une réinstallation ne la remontre pas).
12. **Juste après un achat sans compte.** Un écran plein : « Votre Premium
    est actif. Créez votre compte pour retrouver vos points et votre
    Premium sur un autre téléphone, y compris d'iPhone à Android. Avec un
    compte, vous seul ouvrez vos trackers. », avec les trois boutons
    d'identité et « Plus tard ». Il ne se montre qu'une fois par achat.
13. **Tant qu'un payeur n'a pas de compte.** Une ligne discrète en haut de
    la liste des trackers : « Premium actif sans compte · Créer mon
    compte ». *Mon choix* : une ligne qui reste plutôt qu'un écran qui
    revient à chaque ouverture, pour ne pas harceler quelqu'un qui vient
    de payer. Elle disparaît quand le compte est attaché ou que l'achat a
    pris fin.

### Attacher, ou rejoindre

Depuis un compte invisible, la personne choisit une identité. Deux portes,
qui ne font pas la même promesse :

- **« Créer mon compte »** (réglages, invitation, écran d'après-achat,
  ligne du cas 13, messages du tableau ci-dessus) ;
- **« J'ai déjà un compte »** (réglages, messages de restauration).

| | Porte | L'identité choisie | Ce qui se passe |
|---|---|---|---|
| 14 | Créer | N'a pas de compte | Le compte invisible devient ce compte. Message : « Compte créé. Vos trackers sont maintenant liés à ce compte. » |
| 15 | Créer | A déjà un compte | L'app le dit avant tout : écran « Ce compte existe déjà » (ci-dessous). |
| 16 | J'ai déjà | A un compte | Écran « Ce compte existe déjà ». |
| 17 | J'ai déjà | N'a pas de compte | « Aucun compte trouvé avec cette identité. » Deux boutons : « Créer mon compte avec elle » (cas 14) et « Essayer autrement ». Rien n'est attaché sans ce second geste. |

**L'écran « Ce compte existe déjà »** se montre toujours avant de
rejoindre, même si le téléphone est vide : il n'y a pas de bascule
silencieuse. Le téléphone envoie d'abord ce qu'il avait en attente
(document du hors-ligne) : le serveur ne le juge jamais sur un état
incomplet. Si cela ne part pas, « Connexion impossible, réessayez », et
rien n'a changé. Il dit ce qu'il y a des deux côtés et ce qui va se passer ; il
n'a que « Continuer » et « Annuler ».

```
Ce compte existe déjà

  Sur ce téléphone     2 trackers · 14 points · Premium
  Dans votre compte    3 trackers · 210 points

  Les 2 trackers de ce téléphone seront ajoutés
  à votre compte. Rien n'est effacé.
  Votre Premium suit dans votre compte.

  [ Continuer ]
  [ Annuler ]
```

Ce qui est ajouté, *mon choix* :

- **le téléphone a au moins un point** : tous ses trackers sont ajoutés,
  ceux sans point compris ;
- **le téléphone n'a aucun point** : rien n'est ajouté, et l'écran le dit
  à la place de la phrase d'ajout : « Le tracker commencé sur ce
  téléphone, encore vide, ne sera pas gardé. » (rien à dire s'il n'y a
  aucun tracker) ;
- **un tracker du téléphone est identique à un tracker qui est dans le
  compte à ce moment-là** (même nom, mêmes légendes, mêmes points : une
  copie du cas 38 restée telle quelle, d'un côté ou de l'autre) : il
  n'est pas ajouté en double, et l'écran le compte à part : « 1 tracker,
  identique à un tracker de votre compte, n'est pas ajouté en double. » ;
- **un tracker du téléphone porte le nom d'un tracker du compte sans lui
  être identique** : il est ajouté, et l'écran le dit : « 1 tracker porte
  le nom d'un tracker de votre compte : vous aurez les deux. »

Les lignes qui dépendent de la situation :

- « Premium » et « Votre Premium suit dans votre compte » seulement si le
  compte invisible porte un achat ;
- « Votre compte gratuit garde 3 trackers ouverts : vous choisirez
  lesquels » seulement si, une fois réunis, le compte est gratuit et
  dépasse la limite ;
- « Le thème et la langue de votre compte s'appliqueront » seulement
  s'ils diffèrent de ceux du téléphone.

18. **« Continuer ».** Les trackers ajoutés rejoignent le compte, à la
    suite des siens. Deux trackers du même nom restent côte à côte ; aucun
    point n'est fusionné. Message : « 2 trackers ajoutés à votre compte. »
    Les autres téléphones du compte le disent une fois aussi : « 2
    trackers ont été ajoutés à votre compte depuis un autre appareil. »
19. **L'ajout dépasse 3 trackers en gratuit.** Les trackers en trop sont
    verrouillés, pas effacés. L'écran de choix des trackers ouverts
    s'ouvre juste après, même si un choix avait déjà été fait sur ce
    compte ; il se refait ensuite quand la personne veut.
20. **Elle ne voulait pas de ces trackers.** Elle les supprime ensuite
    comme n'importe quel tracker, avec l'annulation de 8 secondes qui
    existe déjà.
21. **« Annuler ».** La personne reste sur son compte invisible, intact ;
    elle peut recommencer plus tard. Tant qu'elle n'a pas touché
    « Continuer », rien n'a changé nulle part.
22. **La réponse se perd au milieu** (réseau coupé après « Continuer »).
    L'app repose la même demande, sous le même numéro, jusqu'à obtenir une
    réponse. Le serveur reconnaît une demande déjà traitée et répond la
    même chose, sans rien doubler ni redemander de preuve : un code déjà
    utilisé n'a pas à être ressaisi. La personne voit « Connexion impossible, réessayez », puis le
    résultat.
23. **L'adresse e-mail saisie appartient à un compte créé avec Apple ou
    Google.** Le code reçu prouve que l'adresse est la mienne : je suis
    connecté à ce compte, et l'e-mail en devient une façon de plus de s'y
    connecter. Il n'y a rien à expliquer.
24. **Apple ou Google donne l'adresse d'un compte qui existe sans cette
    identité.** L'identité n'y est pas reliée d'office (voir « Règles,
    identité ») : « Cette adresse a déjà un compte. Pour y relier Apple,
    saisissez le code que nous venons d'envoyer à m•••@exemple.fr. », une
    fois. « Annuler » ramène à l'écran précédent, rien n'est créé.
25. **Le compte invisible porte un achat.** En attachant (cas 14), rien ne
    bouge : c'est le même compte, il est Premium. En rejoignant (cas 18),
    l'achat suit dans le compte rejoint, dans la même opération que les
    trackers : la personne n'est jamais gratuite entre les deux.
26. **Le compte rejoint était déjà Premium.** Il y a alors deux achats
    pour un seul compte. L'app le dit une fois, en nommant celui qui est
    de trop, son store, et où le résilier : par exemple « Votre compte a
    maintenant deux achats Premium. Un seul suffit : résiliez
    l'abonnement mensuel pris dans l'App Store. », avec le lien vers la
    gestion des abonnements de ce store. Celui qui est de trop : un
    abonnement face à un achat à vie ; entre deux abonnements, celui qui
    se renouvelle le plus tôt. Un achat à vie de trop ne se résilie pas :
    rien n'est dit.

Après 14 ou 18, la personne est sur un compte attaché : ses réglages
montrent son e-mail et « Se déconnecter ». Un compte attaché ne peut pas
en rejoindre un autre.

### Le compte par e-mail

« Continuer avec un e-mail » ne distingue plus créer un compte et s'y
connecter : c'est le même parcours, et l'adresse est vérifiée à chaque
fois.

70. **Je saisis mon adresse, je reçois un code, je le tape.** « Nous avons
    envoyé un code à 6 chiffres à moi@exemple.fr. » Si l'adresse a un
    compte, j'y suis connecté ; sinon il est créé, et l'app le dit pour
    qu'un compte neuf ne passe pas pour le mien : « Nouveau compte créé
    pour moi@exemple.fr. Si vous aviez déjà un compte, il est peut-être à
    une autre adresse. » Avant le code, l'écran ne dit jamais si l'adresse
    a déjà un compte.

    **Les comptes créés avant la mise à jour** sont les seuls dont
    l'adresse n'a jamais été vérifiée (après elle, aucun compte ne se crée
    sans code, voir « Ce que cela touche »). Se connecter par code à un
    tel compte ne lui retire rien : son mot de passe reste valable
    (décision 10). La première fois seulement, l'app dit ce qu'elle voit :
    « Ce compte a aussi un mot de passe : vous pouvez vous connecter avec
    le code ou avec lui. », avec « OK », et un lien discret « Ce n'est pas
    moi qui l'ai créé », qui retire ce mot de passe et ferme les autres
    sessions (clé de restauration Android comprise, cas 89). Cet avis se
    montre la première fois qu'un code prouve l'adresse d'un tel compte,
    par quelque chemin que ce soit (connexion, cas 15, 16, 24 ou 77), et
    toujours avant « Continuer » ou « Réunir » : personne n'ajoute ses
    trackers à un compte sans savoir que quelqu'un d'autre peut encore y
    entrer. *Mon choix* : c'est une information d'un toucher
    pour le propriétaire, et la seule protection de celui qui découvre
    qu'un compte existait déjà à son adresse, créé par quelqu'un d'autre
    avant la mise à jour. Depuis un téléphone sans
    compte, la suite est celle des cas 14 à 17 : « Créer mon compte » avec
    une adresse qui a un compte mène à l'écran « Ce compte existe déjà »,
    « J'ai déjà un compte » avec une adresse qui n'en a pas à « Aucun
    compte trouvé ».
71. **J'ai fait une faute de frappe dans l'adresse.** Le code ne m'arrive
    pas, donc aucun compte n'est créé à une adresse qui n'est pas la
    mienne. « Changer d'adresse » me ramène à la saisie.
72. **Le code n'arrive pas.** L'écran propose « Renvoyer le code » après
    30 secondes, rappelle de regarder les courriers indésirables, et
    garde « Changer d'adresse ». Trop de demandes : « Trop de codes
    demandés. Réessayez dans 15 minutes. »
73. **Je tape un mauvais code, ou trop tard.** « Code incorrect. » Après 5
    erreurs : « Trop d'essais. Demandez un nouveau code. » Après 10
    minutes : « Ce code a expiré. Demandez-en un nouveau. »
74. **J'ai un mot de passe** (un compte d'aujourd'hui, ou je l'ai ajouté).
    Sous la saisie de l'adresse, « Utiliser mon mot de passe » ouvre la
    connexion par mot de passe. Les deux façons valent toujours : par
    code un jour, par mot de passe le lendemain. « Mot de passe oublié »
    envoie un code, me connecte, puis me propose d'en choisir un nouveau,
    ce que je peux passer.
75. **J'ajoute, je change ou je retire un mot de passe.** Dans les
    réglages d'un compte qui a une adresse. L'app demande d'abord un code
    envoyé à cette adresse. Le mot de passe doit avoir au moins 8
    caractères et 3 types parmi majuscule, minuscule, chiffre et caractère
    spécial ; sinon l'écran dit ce qui manque. Changer le mot de passe
    ferme les autres sessions (cas 51).
76. **Trop d'essais de mot de passe sur mon compte.** « Trop d'essais.
    Réessayez dans une minute, ou recevez un code par e-mail. » La limite
    porte sur le compte, pas seulement sur le réseau d'où viennent les
    essais.
77. **Je change d'adresse e-mail.** Dans les réglages : la nouvelle
    adresse, puis le code qui lui est envoyé. C'est la façon, sans rien
    imposer, de corriger une adresse mal tapée à l'inscription tant qu'on
    est encore connecté (accepté par Charles le 2026-11-26, « si t'as une
    solution pour un mail déjà utilisé par un autre compte »). Le code
    vient toujours d'abord : avant lui, l'écran ne dit pas si l'adresse
    est déjà prise. Ensuite, trois issues :
    - **personne ne l'utilise** : « Adresse changée. » ;
    - **un autre compte l'utilise, et il est vide** (aucun point, aucun
      achat) : ce compte vide est retiré et l'adresse passe sur le mien.
      « Adresse changée. Un compte vide existait à cette adresse : il a
      été remplacé. » C'est le cas de qui s'est inscrit avec une faute de
      frappe, puis a essayé de se connecter ailleurs avec la bonne
      adresse, ce qui a créé un compte vide ;
    - **un autre compte l'utilise, et il a des données** : l'écran « Ce
      compte existe déjà » montre les deux et propose de les réunir. Je
      viens de prouver que les deux sont à moi, l'un par ma session,
      l'autre par le code. « Réunir » ajoute ses trackers aux miens sans
      rien effacer, avec son achat et ses autres façons de se connecter ;
      ses autres téléphones doivent se reconnecter et le disent : « Ce
      compte a été réuni avec un autre. Reconnectez-vous. » « Annuler »
      garde mon adresse actuelle.
    *Mon choix* : c'est le seul cas où deux comptes attachés se
    réunissent. Un compte vide remplacé est absorbé comme les autres : sa
    trace est gardée, pour que ce qu'un de ses téléphones avait encore en
    attente ne soit pas perdu.

    Deux protections, pour qu'un téléphone resté connecté ne suffise pas
    à s'emparer d'un compte :
    - **une preuve que le compte est à moi, avant tout.** Si l'adresse
      actuelle a déjà été vérifiée : un code envoyé à cette adresse-là.
      Si elle ne l'a jamais été (un compte d'avant la mise à jour, le cas
      de la faute de frappe) : le mot de passe du compte, puisqu'un tel
      compte en a toujours un. Si le compte n'a qu'Apple ou Google : une
      nouvelle connexion par ce fournisseur ;
    - **un e-mail à l'ancienne adresse, seulement si elle avait été
      vérifiée** : « L'adresse de votre compte a été remplacée par
      n•••@exemple.fr. Si ce n'est pas vous, annulez ce changement. »,
      avec un lien valable 7 jours qui rétablit l'ancienne adresse et
      ferme toutes les sessions. Une adresse jamais vérifiée ne reçoit
      rien : c'est peut-être la boîte d'un inconnu, à qui ce lien
      donnerait le compte. Le lien ne vaut plus si le changement a réuni
      deux comptes, ou si l'ancienne adresse a été reprise entre-temps ;
      l'e-mail dit alors seulement d'écrire au support.

    La même entrée des réglages sert à **ajouter une adresse** à un compte
    qui n'en a pas d'utilisable (créé avec Apple et son adresse masquée) :
    c'est ce qui lui ouvre une porte sur Android, où « Continuer avec
    Apple » n'existe pas. La preuve demandée est alors une nouvelle
    connexion par Apple, pas un code à l'adresse masquée.

    Quand deux comptes sont réunis ici, celui qui reste garde son propre
    mot de passe ; celui de l'autre est abandonné, et seules ses
    connexions Apple ou Google passent sur le compte qui reste.
78. **J'ai un compte e-mail d'aujourd'hui.** Rien ne m'est demandé
    (décision 10). Mon mot de passe marche comme avant, même s'il ne suit
    pas le nouveau format, qui ne vaut que pour un mot de passe posé ou
    changé. Je peux aussi me connecter par code si mon adresse est la
    bonne, et mon mot de passe reste valable (cas 70).

### Premium : acheter

27. **Devant un mur Premium** (4ᵉ tracker, thème, stats…). Le paywall
    s'ouvre avec ses offres et ses prix, pour tout le monde.
28. **Achat sans compte attaché.** Une seule étape : la fenêtre du store.
    Apple ou Google confirme, et le serveur note l'achat sur le compte
    invisible. Puis l'écran du cas 12.
29. **Le serveur n'a pas encore confirmé** (l'achat vient d'avoir lieu).
    L'app est Premium tout de suite, sur la parole du store, et demande au
    serveur de vérifier. Tant qu'il ne sait pas, un geste qu'il refuserait
    (créer un 4ᵉ tracker) répond « Votre achat est en cours de validation.
    Réessayez dans un instant. » : jamais un geste annulé sans un mot.
30. **Compte attaché.** Il achète comme aujourd'hui.
31. **Premium arrive sans rien payer.** Deux chemins, traités ensuite
    comme une restauration (cas 32 à 34) :
    - la personne touche une offre alors que ce compte du store a déjà
      l'achat : « Vous aviez déjà Premium avec ce compte Apple : il est
      restauré, rien n'a été débité. » ;
    - le store rend l'achat à l'ouverture de l'app, sans aucun geste (à
      vérifier sur Android) : « Premium retrouvé avec votre compte
      Google. »

### Premium : restaurer

« Restaurer les achats » est sur le paywall, sur la fenêtre des fonctions
Premium et dans les réglages. Il ne demande jamais de se connecter
(principe 6), et il a toujours une réponse :

32. **Un achat est retrouvé** : « Premium restauré. », ou « Premium est
    déjà actif ici. » s'il était déjà sur ce compte. Sur un compte
    invisible, la ligne du cas 13 apparaît. Dans les deux cas le serveur
    cherche de nouveau s'il y a des trackers à reprendre (cas 33).
33. **Un achat est retrouvé, et des trackers peuvent être repris** (un
    compte invisible qui a porté cet achat en a : un autre téléphone, ou
    ce téléphone avant une réinstallation) : Premium est restauré, puis
    l'offre du cas 37.
34. **Un achat est retrouvé, et il était sur un compte attaché** :
    « Premium restauré. Cet achat était lié à un compte Dian Dian :
    connectez-vous-y pour retrouver ses trackers. », avec « J'ai déjà un
    compte » si le téléphone est sur un compte invisible. Le compte qui
    perd Premium est prévenu (cas 44).
35. **Rien n'est trouvé** : « Aucun achat en cours trouvé avec ce compte
    Apple. Un achat fait sur Android, ou avec un autre compte Apple, ne se
    restaure pas ici. S'il a été fait avec un compte Dian Dian,
    connectez-vous-y. S'il a été fait sans compte, créez d'abord votre
    compte sur le téléphone qui l'a acheté. » Avant de répondre cela à un
    compte attaché, le serveur regarde si un achat que ce compte a fait
    est parti ailleurs : si oui, c'est le cas 44 et son bouton.
36. **Échec** : « Restauration impossible, réessayez. »

### Reprendre ses trackers par l'achat

L'idée de Charles. Le serveur garde le numéro de chaque achat et retient
quels comptes invisibles l'ont porté. Quand cet achat arrive sur un autre
compte, son téléphone vient de prouver, par le store, qu'il détient le
même compte du store : il peut recevoir une copie de leurs trackers
(principe 7).

37. **L'offre.** Elle est faite chaque fois que le serveur trouve l'achat
    sur un compte et qu'il reste des trackers à reprendre, quel que soit
    le chemin par lequel l'achat est arrivé : « Restaurer les achats », un
    achat que le store dit déjà fait, une arrivée sans geste (cas 31).
    Seule exception : un achat revenu par « Reprendre mon Premium »
    (cas 44), qui ne prouve rien auprès du store.

    ```
    Premium restauré

      Cet achat vient d'un autre téléphone, utilisé sans compte :
          3 trackers · 210 points

      En reprendre une copie ici ? Elle s'ajoute aux trackers de
      ce téléphone, rien n'est effacé. L'autre téléphone garde
      les siens.

      [ Reprendre mes trackers ]
      [ Non, Premium seulement ]
    ```

    Sont proposés les trackers dont le contenu diffère de ce que le
    compte a déjà : un tracker identique (même nom, mêmes légendes, mêmes
    points) à un tracker déjà présent n'est pas proposé, et deux trackers
    identiques entre eux ne comptent qu'une fois. L'offre revient donc
    quand le téléphone d'origine a continué de servir après une première
    copie. Si certains portent le nom de trackers déjà présents, l'offre
    le dit : « 2 d'entre eux portent le nom de trackers que vous avez
    déjà : vous aurez les deux. » Si plusieurs comptes invisibles ont
    porté l'achat, l'offre les additionne.

    Celui qui détient le compte du store peut donc lire une copie des
    trackers d'un compte invisible ; accepté par Charles (décision 5). Il
    ne peut ni les modifier ni les effacer là où ils sont.
38. **« Reprendre mes trackers ».** Une copie des trackers, avec leurs
    légendes et leurs points, s'ajoute à la suite de ceux du compte.
    Message : « 3 trackers repris. » Les autres téléphones du compte le
    disent une fois (comme au cas 18). Le compte est Premium, donc rien
    n'est verrouillé ; si l'offre est acceptée plus tard, alors qu'il ne
    l'est plus et dépasse 3 trackers, c'est le cas 19.
39. **« Non, Premium seulement ».** Rien n'est copié. L'offre ne se perd
    pas (décision 8) : les réglages gardent la ligne « Des trackers d'un
    autre téléphone sont liés à votre achat · Les reprendre », y compris
    après avoir créé un compte ou en avoir rejoint un, et après la fin de
    l'achat. Elle a deux fins, dites toutes les deux :
    - le compte d'origine est effacé. Il ne l'est jamais tant que l'achat
      est en cours ; ensuite il a encore 12 mois (cas 61), et la ligne
      porte alors la date : « à reprendre avant le 3 mars 2028 » ;
    - le compte d'origine reçoit une identité (son téléphone crée un
      compte ou en rejoint un). Ses trackers ne s'ouvrent plus que par ce
      compte (principe 7) : la ligne est remplacée une fois par « Les
      trackers liés à votre achat sont maintenant dans un compte Dian
      Dian. Connectez-vous-y pour les retrouver. »
40. **Le téléphone d'origine**, s'il sert encore, garde ses trackers et
    continue comme avant. Il a perdu Premium (cas 43), et il dit une
    fois : « Une copie de vos trackers a été reprise sur un autre
    appareil, avec votre compte Apple. Pour que vous seul puissiez les
    ouvrir, créez votre compte. » *Mon choix* : c'est l'avertissement
    qu'on attend quand quelqu'un d'autre a pu lire ses données.
41. **Réinstallation sur le même téléphone, sans compte, avec un achat.**
    Si la clé ou la copie du téléphone sont encore là, ce sont les cas 87
    et 85. Sinon, même chemin qu'un nouveau téléphone : « Restaurer les
    achats » rend Premium et propose les trackers d'avant.

L'offre n'est jamais faite pour un achat reçu par le partage familial
d'Apple (voir « À vérifier »), ni quand il n'y a aucun tracker à
reprendre.

### Premium qui change de compte

Un achat est sur un seul compte à la fois : celui où il est arrivé en
dernier (principe 3). On peut donc déplacer son Premium, jamais le
multiplier.

42. **Le compte qui reçoit l'achat** voit le message du cas 31, 32, 33
    ou 34.
43. **Un compte invisible perd Premium**, tout de suite si l'app est
    ouverte et sinon à l'ouverture suivante : « Votre Premium a été
    restauré sur un autre appareil. Pour le reprendre ici, touchez
    "Restaurer les achats". » Puis, selon l'endroit où il est allé :
    - sur un téléphone sans compte : « Pour l'avoir sur vos deux
      appareils, créez un compte ici et connectez-vous-y sur l'autre. » ;
    - sur un compte attaché : « Il est maintenant sur un compte Dian
      Dian : touchez "J'ai déjà un compte" pour le retrouver ici, avec vos
      trackers. »
    Ses trackers au-delà de 3 sont verrouillés, pas effacés, et l'écran de
    choix des trackers ouverts s'ouvre.
44. **Un compte attaché perd Premium**, sur chacun de ses téléphones :
    « Votre Premium a été restauré sur un autre appareil. » Mêmes
    trackers verrouillés d'ici là. La suite dépend de la façon dont ce
    compte avait eu l'achat :
    - **il l'avait fait lui-même** (acheté sous ce compte, ou sous un
      compte invisible devenu ce compte ou absorbé par lui, à condition
      que l'identité ait été posée depuis l'appareil qui avait acheté) :
      le bouton
      « Reprendre mon Premium ». Le serveur le lui rend, quelle que soit
      la plateforme du téléphone : un achat fait sur iPhone se reprend
      aussi depuis l'Android du même compte. Réponse : « Premium
      repris. » ;
    - **il l'avait eu par une restauration, ou l'identité a été posée
      depuis un autre appareil que celui qui avait acheté** (un compte
      invisible trouvé par sa clé, cas 80 et 90) : pas de bouton, puisque
      rien ne prouve que l'achat est le sien. « Pour le reprendre, touchez
      "Restaurer les achats" sur un appareil Apple connecté à ce
      compte. »
    Une app 1.4.0 ne montre rien.
45. **Deux téléphones sans compte, même compte du store.** Premium est
    sur un seul des deux ; le restaurer sur l'un le retire à l'autre, et
    chacun le sait par le cas 43, qui dit la sortie : un compte.
46. **Un compte attaché a perdu Premium au profit d'un téléphone sans
    compte, puis ce téléphone rejoint le compte** (« J'ai déjà un
    compte ») : l'achat y retourne avec lui (cas 25).
47. **L'achat prend fin** (abonnement terminé, remboursement).
    « Votre Premium a pris fin le 3 mars. » (ou « Votre achat Premium a
    été annulé par le store. »), tout de suite si l'app est ouverte et
    sinon à l'ouverture suivante. Les trackers au-delà de 3 sont
    verrouillés, pas effacés, et l'écran de choix s'ouvre. Un compte
    invisible lit en plus : « Sans compte ni Premium, vos trackers ne
    pourront plus être repris sur un autre téléphone, et seront effacés
    après 12 mois sans ouverture de l'app. Créez votre compte pour les
    garder. », avec les trois boutons d'identité et « Plus tard ». Seul
    un achat en cours fait naître une offre de reprise ; une offre déjà
    faite reste (cas 39), et le message le rappelle s'il y en a une :
    « Des trackers d'un autre téléphone restent à reprendre avant le 3
    mars 2028. » Les délais des cas 61 et 62 partent de ce jour.

### Deux téléphones sur un même compte

Un compte attaché ouvert sur deux téléphones. C'est déjà en grande partie
réglé aujourd'hui ; ce chantier ferme ce qui ne l'est pas.

48. **Ce qui marche déjà** (lu dans le code) :
    - chaque téléphone a sa propre session ; se déconnecter de l'un ne
      touche pas l'autre (`backend/src/routes/auth.ts:400`) ;
    - chaque changement est poussé en direct aux autres téléphones du
      compte : point posé ou effacé, tracker créé, renommé, supprimé,
      réordonné, légendes, choix des trackers ouverts
      (`backend/src/lib/ws.ts`) ;
    - un téléphone qui revient au premier plan relit sur le serveur
      l'année affichée, donc rattrape ce qu'il a manqué
      (`flutter_app/lib/services/sync_service.dart:165`) ;
    - deux téléphones touchent le même jour au même moment : le dernier
      qui écrit gagne, pour la case entière (couleur et commentaire), et
      les deux affichent la même chose dans la seconde. Il n'y a ni
      doublon ni mélange (`backend/src/routes/cells.ts:94`) ;
    - la limite de 3 trackers est tenue par le serveur, pas par chaque
      téléphone (`backend/src/routes/pages.ts:99`).
49. **Premium gagné ou perdu** (à ajouter). Aujourd'hui l'autre téléphone
    ne demande au serveur qu'à son lancement (`main.dart:380`), et se fie
    entre-temps à ce que dit le SDK de RevenueCat, dans les deux sens
    (`premium_provider.dart:49`) : il peut montrer des fonctions qu'il
    n'a plus, et ses gestes sont alors annulés sans un mot. Désormais le
    changement est poussé en direct comme le reste, relu à chaque retour
    au premier plan, et c'est le serveur qui décide.
50. **Le compte est supprimé depuis un téléphone** (à ajouter).
    Aujourd'hui l'autre affiche une liste vide ou voit ses gestes annulés
    pendant un quart d'heure, puis retombe sur la connexion sans
    explication. Désormais il revient tout de suite à l'écran d'accueil
    avec : « Ce compte a été supprimé depuis un autre appareil. »
51. **Le mot de passe est changé** (à ajouter). Aujourd'hui « mot de passe
    oublié » ne ferme aucune session : quelqu'un qui avait le mot de passe
    reste connecté (`auth.ts:226`). Désormais changer le mot de passe
    ferme les sessions de tous les autres téléphones, qui disent : « Le
    mot de passe de ce compte a changé. Reconnectez-vous. »
52. **« Déconnecter mes autres appareils »** (à ajouter, *mon choix*).
    Dans les réglages d'un compte attaché, avec confirmation. C'est la
    seule réponse à un téléphone perdu ou prêté pour un compte Apple ou
    Google, qui n'a pas de mot de passe à changer, et elle compte
    davantage maintenant que les sessions ne s'éteignent plus au bout de 7
    jours. Les téléphones déconnectés disent : « Vous avez été déconnecté
    de ce compte depuis un autre appareil. »
53. **Un tracker est supprimé depuis l'autre téléphone** (à ajouter).
    Aujourd'hui celui qui l'avait ouvert est renvoyé à la liste sans un
    mot (`tracker_screen.dart:284`). Désormais il dit : « Ce tracker a
    été supprimé depuis un autre appareil. » La suppression emporte les
    points que l'autre téléphone venait d'y poser : c'est ce que veut
    dire supprimer un tracker du compte.
54. **Deux personnes sur le même compte.** Elles voient et modifient les
    mêmes trackers ; chacune voit en direct ce que fait l'autre ; chacune
    peut supprimer un tracker (annulable 8 secondes sur son téléphone) ou
    le compte. Rien ne l'empêche et rien ne casse : c'est ce que veut
    dire partager un compte. Celle à qui le compte appartient reprend la
    main par les cas 51 et 52. Premium est partagé avec le compte. Le
    thème, la langue et le curseur sont ceux du compte : changés sur un
    téléphone, ils s'appliquent à l'autre (document du hors-ligne ;
    confirmé, décision 14).
55. **Un compte invisible ouvert sur deux appareils.** Cela arrive entre
    les appareils Apple d'une même personne, par la clé du trousseau
    (cas 80 à 84). Tout ce qui précède vaut : mêmes trackers en direct,
    Premium partagé, mêmes règles de conflit hors ligne. Avec deux
    précisions :
    - « Supprimer mes données » le dit dans sa confirmation : « Ces
      données sont aussi ouvertes sur un autre appareil : elles y seront
      effacées aussi. » (cas 91) ;
    - créer un compte ou en rejoindre un depuis l'un des deux efface la
      clé. L'écran le dit avant : « Votre autre appareil devra se
      connecter à ce compte, ou continuera à part avec ses trackers. »
      Et l'autre appareil après : « Ce compte a maintenant un
      identifiant, créé depuis un autre appareil. », avec deux boutons :
      « Me connecter à ce compte », et « Continuer sans compte avec les
      trackers de cet appareil », qui fait de sa copie un nouveau compte
      invisible. Personne n'est laissé à la porte de ce qu'il avait, même
      si celui qui a créé le compte est quelqu'un d'autre (compte Apple
      partagé, téléphone cédé) ;
    - quand deux comptes invisibles sont réunis par la clé (cas 81), les
      autres appareils de celui qui disparaît le disent une fois, « Vos
      trackers ont été réunis avec ceux d'un autre de vos appareils. », et
      continuent sur le compte qui reste.

### Changer de téléphone

| | Ma situation | Ce qui revient | Comment |
|---|---|---|---|
| 56 | J'ai un compte | Tout, d'iPhone à Android aussi | Je me connecte. C'est la seule voie sûre |
| 57 | Sans compte, vers un autre appareil Apple | Trackers et Premium **si** la clé arrive : par le trousseau iCloud activé sur les deux appareils, ou par un transfert direct de l'ancien vers le nouveau. Sinon les trackers seuls, tels qu'à la dernière sauvegarde, **si** le nouveau est restauré depuis elle | Tout seul, ou d'un toucher (cas 80 et 84) ; sinon cas 85, et Premium par « Restaurer les achats » |
| 58 | Sans compte, vers un autre Android | Les trackers, **si** le nouveau téléphone est copié depuis l'ancien (transfert direct) ou restauré depuis la sauvegarde Google | Tout seul (cas 88) ; Premium par « Restaurer les achats » |
| 59 | Sans compte, d'iPhone à Android ou l'inverse | Rien | Il faut un compte (cas 60) |

Quand rien de cela n'a marché et que j'ai un achat, « Restaurer les
achats » me rend Premium et une copie de mes trackers sur la même
plateforme (cas 33 et 37). Sans achat, mes trackers ne reviennent pas
(dernier message du cas 7).

60. **J'ai encore l'ancien téléphone.** Y créer mon compte, puis m'y
    connecter sur le nouveau : je retrouve tout, d'iPhone à Android aussi.
    C'est ce que disent « Mes données » (cas 79) et le message du cas 35.

### Garder ses données sans compte

Trois choses peuvent ramener les données d'un compte invisible sur un
autre appareil, et aucune n'est sûre : la clé recopiée par le trousseau
iCloud, la copie du téléphone portée par une sauvegarde du système, et un
achat (cas 37). L'app ne peut vérifier ni si le trousseau iCloud est
activé, ni si une sauvegarde a eu lieu : ni Apple ni Google ne le lui
disent. Elle ne promet donc jamais ce qu'elle ne sait pas.

79. **L'écran « Mes données »**, dans les réglages de tous les comptes. Il
    a trois parties, et ne dit que ce que l'app sait :

    ```
    Mes données

    Où elles sont
      Sur cet iPhone               oui
      Sur le serveur               à jour
      Compte                       sans compte

    Mes appareils
      Cet iPhone
      iPad                         ouvert hier

    Si je change de téléphone
      Avec un compte               tout revient, iPhone ou Android
                                   [ Créer mon compte ]
      Vers un autre iPhone         vos trackers suivent si « Mots de
                                   passe » est activé dans Réglages ›
                                   votre nom › iCloud, ou si le nouvel
                                   iPhone est installé par transfert
                                   direct depuis celui-ci.
                                   L'app ne peut pas le vérifier.
      Vers un Android              il faut un compte
      Premium                      « Restaurer les achats », sur iPhone
    ```

    - « Sur le serveur » dit « à jour », « 3 modifications à envoyer »,
      ou « dernière synchronisation il y a 2 heures » quand l'app est
      hors ligne.
    - « Mes appareils » liste ceux qui ont ouvert ce compte, d'après le
      serveur, avec la date de leur dernière ouverture. L'écran n'en tire
      aucune conclusion : un appareil de la liste a pu être vendu, ou
      avoir reçu les données autrement que par le trousseau.
    - « Si je change de téléphone » dépend du compte et de la plateforme.
      Avec un compte attaché, une seule ligne : « Connectez-vous sur le
      nouveau téléphone : tout revient, iPhone ou Android. » Un compte
      qui n'a qu'Apple pour se connecter lit à la place : « Pour vous
      connecter sur Android, ajoutez une adresse e-mail à votre compte. »
      (cas 77). Sur Android
      sans compte : « Vers un autre Android : vos trackers suivent si la
      sauvegarde Google est activée et que le nouveau téléphone est
      restauré depuis elle, ou s'il est copié directement depuis
      celui-ci. L'app ne peut pas le vérifier. » et « Vers un iPhone : il
      faut un compte ».
    - La ligne « Premium » n'apparaît que s'il y a un achat sans compte.
80. **J'ouvre l'app sur un appareil Apple qui a une clé, mais pas la
    copie des données.** L'app n'entre pas d'elle-même (principe 7).
    Au-dessus des quatre boutons de l'écran d'accueil, elle dit ce
    qu'elle a trouvé, sans prétendre savoir par où c'est arrivé :
    - la clé est dans l'entrée propre à cet appareil (app réinstallée,
      cas 87) : « Des trackers ont déjà été utilisés sur cet appareil : 3
      trackers · 210 points, ouverts hier. » ;
    - elle n'est que dans l'entrée synchronisée : « Des trackers d'un
      autre de vos appareils Apple ont été retrouvés : 3 trackers · 210
      points, ouverts hier sur un iPhone. »
    Et le bouton « Les retrouver ici ». Je le touche : mes trackers
    s'affichent, et les deux appareils partagent désormais le même compte
    (cas 55). S'il y a plusieurs clés, chacune a sa ligne et son bouton.
    Sans réseau : « Il faut une connexion pour les retrouver. » L'app
    demande d'abord au serveur ce que vaut chaque clé. Celle d'un compte
    devenu attaché depuis : « Des trackers utilisés sur cet appareil sont
    maintenant dans un compte. Connectez-vous pour les retrouver. » Celle
    d'un compte supprimé ou effacé : rien n'est montré, et l'entrée est
    retirée du trousseau.
81. **Je préfère commencer à part.** Les quatre boutons sont toujours là.
    « Continuer sans compte » crée un compte invisible distinct, avec sa
    propre clé. L'autre reste proposé dans « Mes données » : « D'autres
    trackers ont été retrouvés · Les voir ». Les
    retrouver plus tard réunit les deux, par l'écran « Ce compte existe
    déjà » : les trackers de cet appareil s'ajoutent, rien n'est effacé,
    les trackers identiques ne sont pas doublés.
82. **La clé arrive après** (j'ai ouvert l'app avant que le trousseau ait
    fini de se synchroniser, et j'ai commencé sans compte). L'app relit
    le trousseau à chaque ouverture. Quand la clé apparaît, elle le dit
    une fois : « Des trackers d'un autre de vos appareils Apple viennent
    d'être retrouvés : 3 trackers · 210 points. », avec « Les retrouver
    ici » et « Plus tard ». Ensuite c'est le cas 81. Si ces trackers sont
    ceux dont la copie de ce téléphone est issue, c'est le cas 85 : ils
    ne sont pas doublés.
83. **Mes deux appareils Apple sont sur le même compte invisible.** Ce
    que je fais sur l'un apparaît sur l'autre, Premium vaut pour les
    deux. « Mes données » les montre tous les deux.
84. **Mon nouveau téléphone a été copié depuis l'ancien** (transfert
    direct d'iPhone à iPhone, sauvegarde chiffrée sur ordinateur). La
    copie du téléphone et la clé arrivent ensemble, par l'entrée propre à
    l'appareil : l'app s'ouvre comme sur l'ancien, sans rien demander. Si
    l'ancien sert encore, c'est le cas 55.
85. **La copie du téléphone arrive sans la clé** (iPhone restauré depuis
    iCloud sans trousseau synchronisé ; Android copié, restauré, ou app
    réinstallée). L'app s'ouvre sur la copie, et demande au serveur ce
    qu'est devenu le compte dont elle vient. Elle ne fait jamais d'une
    copie un compte sans cette réponse :
    - **un compte invisible qui existe toujours** : l'app crée un compte
      invisible provisoire avec la copie, et le dit une fois : « Ces
      trackers viennent d'une sauvegarde, à jour au 12 mars. Ce qui a été
      fait ensuite sur un autre appareil n'y est pas. », avec ce qui
      permet de retrouver la suite : un compte créé sur l'autre appareil,
      ou « Restaurer les achats ». Si la clé du compte d'origine arrive
      plus tard (trousseau admis après coup), le compte provisoire se
      replie dedans, et aucun tracker n'est doublé. Ce repli est une
      absorption comme une autre : tout ce que le compte d'origine n'a
      jamais reçu est rejoué dessus comme des modifications qui ont
      attendu (document du hors-ligne), c'est-à-dire la file que la copie
      portait déjà dans la sauvegarde, puis ce que j'ai fait depuis ; un
      achat restauré entre-temps sur le compte provisoire suit, avec ses
      événements et ses offres de reprise. Tant qu'il est provisoire, ce
      compte n'a pas d'entrée synchronisée dans le trousseau : un autre
      appareil ne peut pas le trouver et le réunir de travers avec son
      original ;
    - **un compte attaché, ou un compte invisible devenu attaché ou
      absorbé depuis** : la copie n'est pas affichée. « Ces trackers sont
      ceux d'un compte. Connectez-vous pour les retrouver. » Elle attend
      cette connexion, et ce qu'elle avait en attente part alors. Cela
      vaut pour une copie restaurée, qui n'a jamais eu de session sur cet
      appareil ; un appareil qui était dans le compte invisible au moment
      où il a reçu une identité ailleurs a les deux boutons du cas 55 ;
    - **un compte supprimé à la demande** : cas 86 ;
    - **un compte effacé par le serveur** (cas 61) : la copie repart vers
      le serveur, sous sa clé si elle est encore là.
    Un compte recréé depuis une copie n'est jamais refusé pour la limite
    gratuite : au-delà de 3 trackers, les autres sont verrouillés
    (cas 19). Deux appareils qui tiennent la même copie donnent deux
    comptes séparés s'ils n'ont pas la clé, un seul s'ils l'ont. Les
    trackers d'une copie gardent les identifiants du compte d'origine,
    qui peut exister encore : le serveur leur en donne de nouveaux dans le
    compte provisoire et garde la correspondance, pour le repli.
86. **La copie restaurée est celle de données que j'avais supprimées.**
    Le serveur se souvient des comptes supprimés à la demande, sans rien
    garder d'autre. Il refuse de les faire revivre : « Ces trackers
    avaient été supprimés à votre demande le 3 mars. Ils ne sont pas
    rétablis. » La copie est effacée du téléphone.
87. **Je réinstalle l'app sur mon iPhone.** La copie est partie avec
    l'app, mais la clé est le plus souvent restée dans le trousseau :
    c'est le cas 80. Apple ne le garantit pas ; si la clé n'y est plus,
    c'est le cas 41.
88. **Android.** Rien ne recopie une clé entre deux Android : le coffre
    d'Android ne quitte pas l'appareil. Ce qui suit, c'est la copie du
    téléphone, dans la sauvegarde Google ou dans le transfert d'un
    téléphone à l'autre : cas 85. Deux Android en même temps demandent un
    compte.
89. **Android : ma session est rétablie sur mon nouveau téléphone**
    (décision 15). Google fournit une clé de restauration, que le
    téléphone crée en silence quand je me connecte et qu'il emporte vers
    le suivant, par transfert direct ou par la sauvegarde chiffrée. Sur
    le nouvel Android, l'app s'ouvre déjà connectée à mon compte, sans
    rien me demander. Google Play l'exige à partir d'avril 2027 de toute
    app qui propose une connexion, facultative ou non.
    - Tout ce qui ferme la session de ce téléphone fait oublier sa clé
      au serveur, qui la refusera même si Google l'a déjà emportée : me
      déconnecter, « Déconnecter mes autres appareils », un mot de passe
      changé, « Ce n'est pas moi qui l'ai créé », l'annulation d'un
      changement d'adresse, un compte réuni, un compte supprimé. Un
      téléphone volé ou prêté ne peut donc pas s'en servir pour ouvrir le
      compte sur un autre.
    - Désinstaller l'app l'efface aussi : une réinstallation sur le même
      téléphone demande de se reconnecter.
    - Si la clé n'a pas suivi (sauvegarde coupée, pas de verrouillage
      d'écran), j'arrive sur l'écran d'accueil comme aujourd'hui.
    - Google ne prévoit rien pour qui n'est pas connecté. S'en servir
      aussi pour un compte invisible, afin que changer d'Android donne le
      cas 84 au lieu du cas 85, est à vérifier ; ce document ne le promet
      pas.
90. **Un téléphone cédé sans avoir été effacé.** Celui qui y réinstalle
    l'app trouve la clé : l'écran du cas 80 lui dit que des trackers ont
    été utilisés sur cet appareil, et il les voit s'il touche « Les
    retrouver ici ». S'il crée ensuite un compte avec, l'ancien
    propriétaire garde les siens (cas 55). Risque connu et non couvert
    pour la lecture : un téléphone se réinitialise avant d'être cédé, ce
    qui efface le trousseau.
91. **Je supprime mes données.** La clé est effacée du trousseau, donc de
    tous mes appareils, et le serveur retient que ce compte a été
    supprimé à la demande (cas 86).
92. **Le trousseau iCloud n'est pas activé, ou je me déconnecte
    d'iCloud.** Rien ne casse : la clé reste sur l'appareil, et « Mes
    données » continue de dire qu'il ne peut pas le vérifier.

### Effacements automatiques

61. **Compte invisible que l'app n'a pas rouvert depuis 12 mois** :
    effacé avec ses trackers. « Rouvert » veut dire que l'app a parlé au
    serveur. Le délai ne court pas tant qu'un achat que ce compte a porté
    est en cours, sur lui ou sur un autre compte : celui qui paie n'est
    jamais effacé, même si son Premium a été restauré ailleurs. Il part
    du plus tardif de deux jours : la dernière ouverture, et le jour où
    cet achat a pris fin. Si le téléphone a encore sa copie quand l'app
    est rouverte, elle repart vers le serveur : l'effacement ne coûte ses
    données qu'à celui qui n'a plus ce téléphone (confirmé, décision 14).
62. **Compte invisible sans aucun point, que l'app n'a pas rouvert depuis
    30 jours** : effacé. Même règle et même point de départ. Un compte en
    cours d'usage n'est jamais concerné.

Pour un achat à vie, le compte invisible qui l'a porté n'est donc effacé
qu'à la demande (principe 4).

Les deux effacements sont dits dans les réglages (cas 10), dans la
politique de confidentialité, à la fin d'un achat (cas 47) et au retour
(cas 7).

### Partir

63. **Robots.** La création de comptes invisibles est limitée par adresse,
    assez large pour un réseau partagé (cas 6).
64. **Se déconnecter d'un compte attaché.** Retour à l'écran d'accueil.
    La copie du téléphone est effacée, après l'envoi de ce qui attendait
    (document du hors-ligne, cas H10). Si la personne choisit alors « sans
    compte », c'est un nouveau compte invisible, vide ; son compte attaché
    n'est pas touché.
65. **Supprimer.** Le libellé dit ce qu'il fait : « Supprimer mes
    données » pour un compte invisible, « Supprimer mon compte et mes
    données » pour un compte attaché. La confirmation dit ce qui part
    (trackers, points, et le compte) et, s'il y a un achat : « Un
    abonnement se résilie dans le store, pas ici. Votre achat reste lié à
    votre compte Apple : "Restaurer les achats" le rendra. » Elle dit
    toujours que la suppression vaut partout, y compris là où le serveur
    ne peut pas le savoir : « Vos 3 trackers et leurs 210 points seront
    effacés du serveur, de cet appareil, et de tout autre appareil ou
    sauvegarde qui les contient. Pour vider seulement cet appareil,
    désinstallez l'app. » Sans cette phrase, quelqu'un qui vide son ancien
    téléphone avant de le céder effacerait ce que son nouveau téléphone
    s'apprêtait à retrouver (cas 86).
66. **Suppression sans réponse du serveur** (hors connexion, erreur).
    « Suppression impossible pour l'instant, réessayez. » Rien ne change
    sur le téléphone : la personne n'est pas déconnectée d'un compte qui
    existerait encore. Si la suppression avait eu lieu et que seule la
    réponse s'est perdue, réessayer répond « Vos données ont été
    supprimées », pas le message du cas 7.

### Les utilisateurs d'aujourd'hui

67. **Connecté, mise à jour de l'app.** Rien ne change.
68. **Déconnecté, ouverture de la nouvelle version.** Écran d'accueil ; la
    personne se connecte. Si elle touche « sans compte » par erreur, ses
    réglages montrent bien un compte invisible (principe 5, même si le
    téléphone a gardé son ancienne adresse) et « J'ai déjà un compte » la
    ramène à son compte par l'écran « Ce compte existe déjà ».
69. **App non mise à jour (1.4.0).** Elle continue de marcher telle
    quelle, y compris sur un compte qu'une app nouvelle utilise aussi ;
    elle ne montre aucun des messages nouveaux. Seule chose qu'elle ne
    peut plus faire : créer un compte par e-mail et mot de passe (voir
    « Ce que cela touche »).

## Règles

- **Session (principes 4 et 7).**
  - Un compte invisible a une **clé**, créée avec lui. Elle ne change
    jamais et rouvre une session quand le jeton de rafraîchissement est
    refusé, perdu en route ou oublié par une restauration de la base.
  - **Où elle est rangée.** Sur iPhone et iPad, dans le trousseau, en
    deux entrées : une propre à l'appareil, qui suit un transfert direct
    et reste le plus souvent après une réinstallation, et une marquée « à
    synchroniser », que les autres appareils Apple de la personne
    reçoivent si le trousseau iCloud y est activé. Les deux entrées ont
    des noms différents : sous un même nom, écrire l'une effacerait
    l'autre sur tous les appareils. Une entrée propre à l'appareil ne
    peut pas être effacée de loin : c'est le serveur qui dit ce que vaut
    la clé qu'on lui présente (cas 80). Sur Android, dans le coffre du
    téléphone, qui ne quitte pas l'appareil. Elle n'est jamais
    écrite dans un fichier que les sauvegardes emportent, et ne sert
    jamais d'identifiant, ni auprès de RevenueCat ni ailleurs : c'est un
    secret.
  - **Une entrée par compte.** Chaque compte invisible a sa propre entrée
    dans le trousseau, sous un nom qui lui est propre. Deux appareils qui
    créent chacun un compte avant de se synchroniser n'écrasent donc pas
    la clé l'un de l'autre (pour une même entrée, le trousseau en garde
    une seule sans prévenir).
  - **Trouver une clé ne fait jamais entrer en silence** (principe 7). Si
    le téléphone a déjà la copie de ce compte, l'app continue (cas 84).
    Sinon elle propose (cas 80 à 82).
  - L'app relit le trousseau à chaque lancement et à chaque retour au
    premier plan : rien ne la prévient qu'une clé est arrivée.
  - La clé n'existe que pour un compte invisible : attacher, rejoindre ou
    supprimer l'efface, et l'effacement d'une entrée synchronisée vaut
    sur tous les appareils. Le téléphone qui a prouvé l'identité reçoit
    une session ordinaire dans la même réponse.
  - **La copie du téléphone sait de quel compte elle vient**, et n'est
    jamais affichée ni réutilisée que selon ce que le serveur dit de ce
    compte (cas 85). Une session fermée exprès (mot de passe changé,
    « Déconnecter mes autres appareils ») laisse la copie sur le
    téléphone, cachée, pour la seule reconnexion à ce compte : elle ne
    devient jamais un autre compte.
  - **Ce que le serveur retient après coup.** Pour un compte supprimé à
    la demande ou absorbé : son identifiant et ce qu'il est devenu, rien
    d'autre, pendant 24 mois (*mon choix*) : assez pour qu'une sauvegarde
    de téléphone restaurée longtemps après ne fasse pas revivre des
    données supprimées. Au-delà, une copie restaurée est traitée comme
    celle d'un compte effacé par le serveur.
  - Le jeton de rafraîchissement dure plus longtemps que les 12 mois du
    cas 61. *Mon choix* : la même durée longue pour tous les comptes ; un
    compte attaché n'est plus déconnecté après 7 jours (aujourd'hui
    `backend/src/routes/auth.ts:42`).
  - Un jeton ou une clé illisible sur le téléphone n'est pas un compte
    effacé : seul un refus du serveur mène à l'écran d'accueil, et alors
    avec le message du cas 7.
  - **Une session fermée l'est tout de suite, et dit pourquoi.**
    Aujourd'hui le serveur ne vérifie que la signature du jeton d'accès,
    valable 15 minutes (`middleware/auth.ts:20`, `lib/jwt.ts:11`) : un
    téléphone déconnecté lit et écrit encore un quart d'heure, et celui
    d'un compte supprimé reçoit une liste vide (`routes/bootstrap.ts`).
    Désormais chaque requête vérifie que la session existe encore, et un
    refus porte sa raison : compte supprimé, mot de passe changé,
    déconnecté depuis un autre appareil, identifiant ajouté ou compte
    rejoint (les deux se lisent comme au cas 55, avec ses deux boutons),
    comptes invisibles réunis par la clé (cas 81 : l'appareil continue
    sur le compte qui reste, avec le message du cas 55), compte réuni
    avec un autre par un changement d'adresse (cas 77 : « Reconnectez-
    vous »). Le canal en
    direct se ferme en même temps (aujourd'hui une connexion ouverte
    reste abonnée au compte tant qu'elle ne tombe pas).
- **Premium (principe 3).**
  - L'app s'identifie toujours auprès de RevenueCat avec l'identifiant du
    compte, invisible ou attaché, une fois celui-ci connu, et jamais comme
    client anonyme. Aujourd'hui le SDK démarre sans identifiant et y
    revient à chaque déconnexion (`purchase_service.dart:41`,
    `main.dart:346`) : un achat fait à ce moment n'est rattaché à
    personne. Cela règle les deux premiers points de « Trouvé pendant le
    chantier 0 » dans `docs/PRICING.md`. Avant qu'un compte existe (écran
    d'accueil), le SDK n'est pas configuré et rien ne peut s'acheter.
  - **Seul le serveur éteint Premium.** Le « oui » du SDK allume Premium
    à titre provisoire, le temps que le serveur vérifie (cas 29) ; son
    « non » n'éteint rien.
  - **Le serveur vérifie auprès de RevenueCat.** Quand l'app signale un
    achat ou une restauration, et quand RevenueCat annonce qu'un achat a
    changé de compte (l'annonce ne nomme que les deux comptes, ni le
    produit ni l'achat), le serveur demande à RevenueCat qui porte quoi
    et s'y tient. C'est ce qui lui manquait pour un achat à vie restauré,
    dont il ne reçoit aucun événement. Il lui faut une clé d'API
    RevenueCat, que Charles crée.
  - Le réglage RevenueCat de restauration doit être « Transfer to new App
    User ID » : RevenueCat l'exige dès qu'on peut acheter sans compte. Il
    vaut aussi quand un compte touche une offre déjà achetée (cas 31).
  - Le serveur reconnaît un achat à son numéro de transaction d'origine,
    qu'il garde déjà et qui est unique
    (`subscriptions.original_transaction_id`).
  - **Le serveur retient quels comptes invisibles ont porté chaque
    achat**, même après que l'achat est parti ou a pris fin, et quel
    compte l'a fait. La mémoire d'un compte invisible disparaît avec lui,
    et aussi le jour où il reçoit une identité (attaché, ou absorbé par
    un compte) : ses trackers ne se reprennent plus par l'achat.
  - **L'offre de reprise** (cas 37) est cherchée chaque fois que le
    serveur trouve un achat en cours sur un compte, par quelque chemin que
    ce soit sauf « Reprendre mon Premium », et à chaque « Restaurer les
    achats ». Une offre trouvée est gardée : elle suit le compte qui l'a
    reçue quand il est attaché ou absorbé, et dure tant que le compte
    d'origine existe et reste invisible (cas 39).
  - **Quand un compte est absorbé, son achat suit** dans la même
    opération, chez nous et chez RevenueCat (le serveur le lui demande,
    ou l'app synchronise ses achats juste après s'être identifiée sous le
    nouveau compte). Le serveur garde la trace de qui a absorbé qui. Tant
    que RevenueCat n'a pas suivi, un événement d'achat qui nomme encore
    l'ancien compte est appliqué au compte qui l'a absorbé, et une
    vérification ne retire jamais un achat que cette trace explique :
    personne ne redevient gratuit en payant. Les événements d'achat du
    compte absorbé sont déplacés avec lui, pas supprimés (aujourd'hui ils
    partiraient avec le compte, `schema.ts:153`).
  - **« Reprendre mon Premium »** (cas 44) : le serveur demande à
    RevenueCat de remettre l'achat sur le compte attaché qui l'a fait, et
    sur lui seul. Un compte qui n'a eu l'achat que par une restauration
    n'a pas ce bouton : sans cela, il garderait à vie le moyen de le
    reprendre sans rien prouver.
- **Reprendre (principe 7).**
  - C'est une copie : trackers, légendes et points. Le compte d'origine
    n'est ni modifié ni prévenu autrement que par le cas 40.
  - **La règle des doubles**, la même pour reprendre et pour rejoindre :
    on compare les contenus, pas les origines. Un tracker identique (même
    nom, mêmes légendes, mêmes points) à un tracker présent dans le
    compte à ce moment-là n'est pas ajouté ; tout autre l'est, même s'il
    porte le même nom. L'écran dit les deux.
  - Une seule opération côté serveur, tout ou rien, qui reconnaît une
    demande rejouée.
- **Identité.**
  - Apple et Google : une identité déjà connue du serveur est un compte
    existant.
  - **L'e-mail se prouve par un code** (décision 10) : 6 chiffres,
    valable 10 minutes, 5 essais, un seul code actif par adresse, gardé
    haché. C'est le mécanisme de « mot de passe oublié » d'aujourd'hui
    (`auth.ts:196-269`), étendu à la création et à la connexion. La
    demande de code répond toujours la même chose, que l'adresse ait un
    compte ou non. Les envois sont limités par adresse et par réseau, pour
    que le serveur ne serve pas à inonder la boîte de quelqu'un.
  - **Le mot de passe est une option.** Un compte créé par code n'en a
    pas. Quand il y en a un, son format et la limite d'essais par compte
    suivent la recommandation de la CNIL de 2022 (cas 75 et 76) ;
    aujourd'hui la règle est de 8 caractères quelconques, avec une limite
    par réseau seulement (`auth.ts:58`, `index.ts:84`).
  - *Mon choix, pour la sécurité* : le serveur relie aujourd'hui une
    connexion Apple ou Google à tout compte de même adresse e-mail, sans
    que personne ait prouvé quoi que ce soit (`auth.ts:159-166`, qui
    ignore aussi si le fournisseur a vérifié l'adresse). Quelqu'un qui
    s'inscrit avec l'adresse d'un autre pourrait donc recevoir ses
    trackers au moment où celui-ci rejoint « son » compte. Désormais une
    identité nouvelle n'est reliée à un compte de même adresse qu'après
    le code envoyé à cette adresse, une fois (cas 24), que le fournisseur
    dise l'adresse vérifiée ou non. Les identités déjà reliées
    aujourd'hui le restent.
  - Une adresse d'aujourd'hui qui n'a jamais été vérifiée ouvre son compte
    à celui qui en reçoit le courrier. Ce n'est pas nouveau : « mot de
    passe oublié » le permet déjà. Le mot de passe d'origine y reste
    valable, puisque le code ne remplace rien : d'où l'avis du cas 70, la
    première fois. Le serveur sait déjà si une adresse a été vérifiée
    (`users.email_verified`).
  - Changer d'adresse demande la preuve de l'adresse actuelle quand elle a
    été vérifiée, et prévient toujours l'ancienne (cas 77).
  - Attacher puis rejouer la même demande (réponse perdue) retombe sur le
    compte lui-même : c'est une réussite, pas un « compte existant ».
  - La première étape pour rejoindre (savoir ce qu'il y a des deux côtés)
    n'ouvre pas de session sur le compte existant et ne touche pas à celle
    du compte invisible (cas 21).
- **Réunir deux comptes invisibles** (cas 81 et 82) suit les règles de
  « Rejoindre » ci-dessous : celui du téléphone est absorbé par celui dont
  le téléphone détient la clé, ses trackers s'ajoutent, son achat suit, sa
  clé est effacée.
- **Rejoindre** est une seule opération côté serveur, tout ou rien : les
  trackers s'ajoutent, l'achat et ses événements suivent, les offres de
  reprise en attente suivent, le compte invisible disparaît, la trace est
  gardée. La même opération sert au cas 77, où le compte absorbé est
  attaché : ses identités passent alors sur le compte qui reste. Une
  modification faite hors ligne sous un compte absorbé part vers le compte
  qui l'a absorbé (document du hors-ligne) ; si elle vise un tracker qui
  n'avait pas été gardé parce qu'il paraissait vide (un autre appareil du
  même compte invisible y avait des points pas encore partis), ce tracker
  est recréé dans le compte. Une demande rejouée (cas 22) porte le même
  numéro et la clé du téléphone, et reçoit pendant quelques minutes la
  réponse déjà donnée, sans nouvelle preuve d'identité. Le téléphone prend
  le thème, la langue et le curseur du compte rejoint.
- **Quand le compte invisible n'existe pas encore sur le serveur** (cas 5
  et 6 : première ouverture sans réseau, ou création retardée), « Créer
  mon compte » crée directement le compte attaché et y envoie la copie du
  téléphone : il n'y a pas de file à faire partir d'abord.
- **Écrans demandés et écrans proposés.** Un écran qui répond à un geste
  que la personne vient de faire se montre tout de suite : écran
  d'après-achat, « Ce compte existe déjà », offre de reprise, choix des
  trackers ouverts, messages de restauration. Un message qui annonce ce
  qui s'est passé ailleurs (cas 18, 40, 43, 44, 47, 50 à 53, 55) se
  montre dès qu'il est connu. La règle « un seul par ouverture » ne vaut
  que pour ce que l'app propose d'elle-même au lancement, dans cet ordre :
  nouveautés de la version, demande des rappels, invitation (cas 11),
  pop-up Premium. *Mon choix.*
- **Limite gratuite.** Elle s'applique aux comptes invisibles comme aux
  autres, sur le serveur et dans l'app. Un compte gratuit peut dépasser 3
  trackers chaque fois que des trackers lui arrivent autrement que par le
  bouton de création : rejoindre, reprendre, réunir, une copie renvoyée
  au serveur, des créations faites hors ligne. Rien n'est alors refusé
  ni effacé : les trackers en trop sont verrouillés (cas 19). Deux téléphones qui créent un tracker au même instant ne
  doivent pas la dépasser : aujourd'hui le contrôle n'est pas verrouillé
  (`pages.ts:99-106`).

## Ce que cela touche

**Serveur**

- `users.email` devient facultatif ; le serveur dit pour chaque compte
  s'il est invisible ou attaché, et par quelles méthodes (réponses de
  connexion, de rafraîchissement, `/api/auth/me`).
- Opérations nouvelles : créer un compte invisible ; rouvrir une session
  par la clé d'appareil ; attacher une identité ; rejoindre, en deux temps
  (ce qu'il y a des deux côtés, puis l'ajout) ; reprendre des trackers ;
  vérifier un achat auprès de RevenueCat ; reprendre son Premium ; fermer
  les autres sessions d'un compte ; relier une identité après preuve.
- La vérification de la session à chaque requête, avec la raison du refus.
- Annonces nouvelles sur le canal en direct : Premium changé, compte
  supprimé, session fermée, trackers ajoutés.
- La mémoire des achats portés par chaque compte invisible et du compte
  qui a fait chaque achat, les offres de reprise en attente, la
  comparaison de deux trackers par leur contenu.
- La date du dernier contact de chaque compte et celle où il a cessé de
  porter un achat ; les deux purges, à la façon de celle des jetons
  (`index.ts`).
- Une limite de débit sur la création de comptes invisibles.
- Créer un compte et s'y connecter par un code envoyé à l'adresse ; mot de
  passe facultatif, avec son format et sa limite d'essais par compte ;
  changer d'adresse (cas 70 à 78). Les e-mails de code existent en quatre
  langues comme celui d'aujourd'hui.
- La liste des appareils qui ont ouvert un compte, avec leur type et la
  date de leur dernière ouverture (cas 79).
- Réunir deux comptes invisibles par la clé (cas 81).
- La clé de restauration Android (cas 89) : enregistrer la clé publique
  que le téléphone crée à la connexion, vérifier sa signature sur le
  nouveau téléphone et ouvrir une session, l'oublier chaque fois que la
  session de ce téléphone est fermée, pour quelque raison que ce soit.
- Recevoir une copie du téléphone pour en faire un compte (cas 85), et se
  souvenir des comptes supprimés à la demande pour ne pas les faire
  revivre (cas 86) : leur identifiant seul, sans aucune donnée.
- Changer le mot de passe ferme les autres sessions (`auth.ts:226`).
- **Les scripts `prod-*.sql`** écartent les comptes de test par un filtre
  sur l'e-mail ; avec un e-mail absent, ce filtre vaut « inconnu » et
  écarterait en silence tous les comptes invisibles. À corriger dans chaque
  script. `prod-purchases.sql` distingue les achats faits par un compte
  invisible.
- **La mesure survit aux suppressions.** Les événements produit partent
  avec leur compte (`schema.ts:129`), et ce design supprime des comptes
  tous les jours (comptes rejoints, purges). Les faits à compter (voir
  « Mesure ») sont gardés dans une table à part, sans identifiant de
  compte.
- Les apps 1.4.0 continuent d'appeler les routes d'aujourd'hui, à une
  exception près : **l'inscription par e-mail et mot de passe sans
  vérification est fermée le jour de la mise à jour**
  (`routes/auth.ts:66`). Charles, 2026-11-26 : « il ne faut jamais pouvoir
  créer un compte sans que l'adresse mail soit vérifiée ». Une ancienne
  version qui tente de créer un compte par e-mail reçoit un refus qu'elle
  affiche tel quel : « Mettez l'app à jour pour créer un compte par
  e-mail. », dans la langue que l'app demande, sinon en anglais. Elle
  peut toujours se connecter, et créer un compte avec Apple ou Google.
  Deux autres choses changent pour toutes les versions, anciennes
  comprises : une connexion Apple ou Google n'est plus reliée d'office à
  un compte de même adresse (`auth.ts:159-166` ; une ancienne version
  reçoit « Cette adresse a déjà un compte. Mettez l'app à jour pour y
  relier Apple. »), et une adresse que le fournisseur ne dit pas vérifiée
  n'est jamais gardée comme adresse du compte (`auth.ts:176-180`).

**App**

- L'écran de connexion devient l'écran d'accueil ; l'inscription par
  e-mail reste derrière « Continuer avec un e-mail ».
- Le parcours du premier tracker démarre pour tout nouveau compte,
  invisible ou attaché.
- Réglages : les deux formes (cas 10), d'après la réponse du serveur ;
  « Restaurer les achats » ; « Déconnecter mes autres appareils » ; la
  ligne du cas 39. Une adresse restée dans le coffre du téléphone est
  effacée à toute fin de session.
- Écrans et messages nouveaux : invitation, écran d'après-achat, ligne du
  payeur sans compte, « Ce compte existe déjà », « Aucun compte trouvé »,
  relier une identité, les réponses de « Restaurer les achats », l'offre
  de reprise, Premium déplacé et repris, fin de l'achat, deux achats,
  achat en cours de validation, retour après effacement, suppression
  impossible, et les messages de ce qui s'est passé sur un autre
  téléphone.
- « Restaurer les achats » dit toujours ce qu'il a trouvé (aujourd'hui il
  ne dit rien quand il ne trouve rien, `custom_paywall_dialog.dart:131`).
- La suppression ne déconnecte que si le serveur a confirmé (aujourd'hui
  l'app se déconnecte quelle que soit la réponse,
  `settings_screen.dart:381`).
- Premium : relu à chaque retour au premier plan, et éteint seulement par
  le serveur (`main.dart:380`, `premium_provider.dart:49`).
- Un refus de session affiche le message de sa raison (cas 7).
- L'écran par e-mail devient saisie de l'adresse puis du code ; les écrans
  d'inscription et de mot de passe oublié disparaissent
  (`register_screen.dart`, `forgot_password_screen.dart`). Réglages :
  mot de passe, adresse e-mail.
- La clé passe du coffre par défaut (`services/storage_service.dart`) à
  deux entrées du trousseau sur iOS, l'une propre à l'appareil, l'autre
  synchronisée, sous deux noms, écrites et lues avec les précautions de
  « À vérifier ».
- L'écran « Mes données » (cas 79), la proposition de l'écran d'accueil
  (cas 80), les messages des cas 82, 85 et 86.
- Android : les règles de sauvegarde de l'app (aucune aujourd'hui dans le
  manifeste) incluent la base du téléphone et excluent le fichier du
  coffre.
- Android : la clé de restauration (cas 89), créée à la connexion, lue à
  la première ouverture après une restauration, effacée à la déconnexion.
  Du code natif, ou un paquet à choisir avec prudence : ceux qui existent
  sont récents et tenus par une seule personne.
- Le compte invisible n'a pas d'e-mail : tout ce qui l'affiche ou le
  préremplit (réglages, formulaire de contact) doit s'en passer.

**Légal.** Un compte invisible est un compte : ce chantier ajoute sa ligne
au registre (`docs/REGISTRE.md`, que le lot « registre » aura complété
avant lui) et met à jour la politique de confidentialité : ce qu'est un
compte sans identité, la clé rangée dans le trousseau de la personne et
recopiée par Apple sur ses autres appareils, la copie gardée sur le
téléphone et emportée par les sauvegardes du système (Apple, Google), le
souvenir des comptes supprimés à la demande, les deux effacements et ce
qui les suspend (un
compte invisible est gardé tant qu'un achat qu'il a porté est en cours,
donc sans limite pour un achat à vie, sauf suppression demandée), la
reprise des trackers par l'achat (qui détient le compte du store peut en
obtenir une copie), la suppression. La suppression dans l'app vaut aussi pour les comptes créés
automatiquement, comme Apple le demande.

**Ce que Charles fait** : créer la clé d'API RevenueCat et la poser sur le
serveur ; vérifier dans RevenueCat le réglage de restauration et que
l'achat à vie Android est « non-consumable » ; vérifier dans App Store
Connect si le partage familial est activé pour les produits (une fois
activé, Apple ne permet plus de le retirer) ; donner aux relecteurs
d'Apple et de Google un compte de test dont le code de connexion est
fixe ; déclarer le domaine du site auprès de Google si la clé de
restauration le demande (à vérifier).

## Mesure

- Par semaine, dans une table qui ne nomme aucun compte : comptes
  retrouvés par la clé sur un second appareil, comptes créés depuis une
  copie restaurée, copies refusées parce que supprimées à la demande,
  comptes créés et connexions par code, codes jamais saisis ; comptes
  invisibles créés, comptes attachés créés directement, comptes invisibles
  attachés ensuite (et après combien de jours, avant ou après un achat),
  comptes rejoints, reprises de trackers, comptes effacés à 30 jours et à
  12 mois, comptes supprimés à la demande.
- La mesure d'avant et d'après reste celle d'aujourd'hui : installations
  (stores) face aux comptes, où « compte » compte désormais les invisibles.
- Événements produit (liés au compte, comme les autres) : invitation
  montrée, passée, acceptée ; achat fait sans compte attaché ; écran
  d'après-achat montré, passé, accepté ; écran « Ce compte existe déjà »,
  continué ou annulé ; chaque réponse de « Restaurer les achats » ; offre
  de reprise montrée, acceptée, refusée ; Premium déplacé, repris. Le
  chantier du paywall (2) s'en sert.

## À vérifier pendant la construction

**RevenueCat, en bac à sable, avant d'écrire le reste.** Ce que la
seconde relecture a relevé dans la documentation, à confirmer par
l'essai :

- Une restauration depuis un autre compte déplace l'achat, et un achat
  tenté par un compte identifié aussi ; RevenueCat l'annonce par un
  événement qui ne porte que les deux comptes
  ([Restore Behavior](https://www.revenuecat.com/docs/projects/restore-behavior),
  [événements](https://www.revenuecat.com/docs/integrations/webhooks/event-types-and-fields)).
- Les réglages de restauration : « Transfer to new App User ID » (celui
  qu'il nous faut), « Transfer if there are no active subscriptions » (qui
  bloquerait le déplacement d'un abonnement en cours), « Keep with
  original App User ID », et l'ancien « Share between App User IDs ».
- Ce que le serveur peut lire. L'API v2 donne par client le store, la fin
  de période et l'accès, mais l'identifiant qu'elle renvoie est celui de
  la dernière transaction, pas de la première. Dans l'autre sens, sa
  recherche accepte un identifiant passé et renvoie le client qui porte
  l'achat aujourd'hui, pour un abonnement comme pour un achat unique
  ([clients](https://www.revenuecat.com/docs/api-v2/customer/resources),
  [abonnements](https://www.revenuecat.com/docs/api-v2/subscription),
  [achats](https://www.revenuecat.com/docs/api-v2/purchase)). L'API v1 ne
  documente pas d'identifiant d'origine.
- Le déplacement d'un achat demandé par le serveur existe dans l'API v2
  ([clients](https://www.revenuecat.com/docs/api-v2/customer)) : c'est ce
  dont ont besoin les cas 25 et 44.
- Le partage familial se distingue (`is_family_share` dans l'événement,
  `ownership_type` côté client), et Apple donne à chaque membre ses
  propres transactions
  ([RevenueCat](https://www.revenuecat.com/docs/platform-resources/apple-platform-resources/apple-family-sharing),
  [Apple](https://developer.apple.com/documentation/storekit/supporting-family-sharing-in-your-app)).
  Non vérifié : que le numéro d'origine d'un membre diffère de celui de
  l'acheteur.
- Un code d'offre utilisé dans le store demande que l'app synchronise ses
  achats au retour
  ([offres](https://www.revenuecat.com/docs/subscription-guidance/subscription-offers/ios-subscription-offers)).
- Non vérifié : si, sur Android, le SDK déplace un achat dès la première
  ouverture sans aucun geste (second chemin du cas 31).
- Un achat à vie se restaure après la suppression du compte qui l'avait
  fait, et l'achat à vie Android est bien « non-consumable ».

**Si l'une de ces vérifications échoue**, ce qui en dépend sort du
chantier sans emporter le reste :

- le serveur ne peut pas savoir de façon sûre qui portait un achat : la
  reprise des trackers sort, et le cas 33 devient le cas 32 ;
- le serveur ne peut pas déplacer un achat lui-même : au cas 25 l'app
  synchronise ses achats après avoir rejoint le compte, et au cas 44 le
  bouton laisse la place à une phrase qui nomme le store : « Pour le
  reprendre, touchez "Restaurer les achats" sur un appareil Apple connecté
  à ce compte. »

**La clé et la copie du téléphone, sur de vrais appareils.** La
recherche du 2026-11-26 dit ce que les documentations promettent ; plusieurs
points ne se vérifient qu'en les essayant.

Ce qu'elle établit :

- Aucune API ne dit si le trousseau iCloud est activé ni si une entrée a
  été synchronisée ; sur Android, aucune ne dit si la sauvegarde est
  activée ni si elle a eu lieu. L'app peut seulement détecter, sur
  Android, qu'elle vient d'être restaurée.
- Sur un nouvel appareil, la clé peut manquer au premier lancement :
  l'appareil doit d'abord être admis dans le trousseau de la personne
  (une seule mesure trouvée : 30 secondes d'iPhone à iPhone, 30 minutes
  vers un Mac).
- Une restauration iCloud sur un autre iPhone rend les fichiers de l'app
  mais pas une clé non synchronisée ; un transfert direct et une
  sauvegarde chiffrée sur ordinateur rendent les deux. La copie et la clé
  peuvent donc arriver séparément (cas 84 et 85).
- Sur Android, la sauvegarde copie le fichier du coffre mais jamais ce
  qui le déchiffre : sur le nouveau téléphone le paquet de stockage
  échoue, efface tout, et l'app repart sans session. Ce fichier doit être
  exclu des sauvegardes, et la base du téléphone incluse.
- Le paquet `flutter_secure_storage` (11.2.0 dans l'app) a trois pièges
  avec une entrée synchronisée : sa lecture par défaut ne la voit pas ;
  une écriture de la même entrée sans l'option, ou son « tout effacer »,
  la supprime sur tous les appareils ; l'option a été ignorée sans erreur
  dans d'anciennes versions. La clé doit donc passer par un code qui
  précise l'option à chaque appel, ou par quelques lignes écrites pour
  iOS, et jamais par « tout effacer ».
- Apple déconseille son autre mécanisme simple (le magasin clé-valeur
  iCloud) pour un secret : il n'y est pas chiffré.
- Google Play exigera à partir d'avril 2027 que toute app qui propose une
  connexion rétablisse la session sur un nouvel Android
  ([Play Console](https://support.google.com/googleplay/android-developer/answer/17492799),
  [blog Android](https://android-developers.googleblog.com/2026/08/app-quality-memory-optimization-secure-onboarding.html)) :
  cas 89.

À essayer avant d'écrire le reste :

- une clé écrite alors que le trousseau iCloud est éteint part-elle quand
  on l'allume ensuite ;
- une entrée synchronisée suit-elle un transfert direct ou une sauvegarde
  sur ordinateur (la recherche ne l'établit que pour une entrée propre à
  l'appareil, d'où les deux entrées) ;
- les e-mails de code arrivent-ils à une adresse masquée d'Apple ;
- le délai réel d'arrivée de la clé sur un second iPhone et sur un iPad ;
- ce que devient une entrée synchronisée quand on se déconnecte d'iCloud
  en choisissant de garder ou d'effacer ;
- la clé survit-elle à la désinstallation sur les iOS d'aujourd'hui (cas
  87 ; Apple dit de ne pas compter dessus) ;
- le transfert d'iPhone à iPhone qui télécharge depuis iCloud, et la
  restauration iCloud avec la protection avancée des données ;
- sur Android : restauration depuis le nuage, transfert direct, et
  réinstallation, avec la sauvegarde activée puis coupée ;
- la clé de restauration Android de bout en bout sur deux téléphones : ce
  qu'elle demande exactement au serveur, si le domaine du site doit être
  déclaré auprès de Google (les témoignages se contredisent), et si elle
  peut porter un compte invisible.

Si le trousseau synchronisé se révèle trop peu fiable à l'essai, seule
l'entrée propre à l'appareil est gardée : les cas 81 à 83 sortent, le
cas 80 ne garde que sa première forme (cas 87 et 90), et les cas 84 à 88
tiennent sans le reste.

**La revue d'Apple.** Ce design est la forme pour laquelle la recherche
n'a trouvé aucun refus : tout le gratuit sans compte, achat sans compte,
restauration sans connexion, compte proposé ensuite et refusable,
suppression possible dans l'app. Le réviseur parcourt le chemin sans
compte : acheter et restaurer doivent y marcher de bout en bout.

## Place dans la construction

*Mon choix* : chantier 9, construit **après le hors-ligne (10)**, dont il
utilise la copie du téléphone, et **avant le paywall (2)**, parce que le
paywall refait le mur Premium et que ses écrans doivent connaître le compte
invisible (cas 27 à 36). Ordre proposé : 0, 1, registre, 3 (outillage
Android), **10**, **9**, 2, 5 lot 1, 4, 8 lot 1, 5 lots 2 et 3, 6, 7, 8
lot 2.

C'est un gros chantier : il refait la tenue des sessions, la connexion par
e-mail, la suppression de compte, la façon dont l'app s'identifie auprès
de RevenueCat, et il ajoute la vérification des achats par le serveur, la
reprise des trackers, la clé dans le trousseau, l'écran « Mes données » et
les annonces entre téléphones. L'achat sans compte en est la part la plus
délicate ; c'est aussi celle qui évite un refus d'Apple. L'estimation
viendra du plan, qui commencera par les vérifications en bac à sable et
sur appareils.

**La clé de restauration Android (cas 89) est le dernier lot du
chantier** (décision 15). Elle demande un serveur d'un genre nouveau pour
le projet (vérifier une clé cryptographique créée par Google) et du code
Android natif. Rien d'autre n'en dépend : si ce lot se révèle plus dur
que prévu, Charles pourra encore décider de sortir sans lui et de le
livrer avant avril 2027. Changer d'Android sans compte passe, lui, par
la copie du téléphone (cas 88).

## Laissé au constructeur

- Le schéma exact et les routes.
- La forme des écrans, dans le style des écrans existants ; les textes en
  anglais et en chinois.
- Les seuils techniques : durée exacte des jetons, limite de débit.
- Comment la session est vérifiée à chaque requête sans alourdir chaque
  appel.
- Les tests, y compris la suite de bout en bout pour chaque cas numéroté.

## Ce qui reste incertain

- La taille du gain : aucune étude ne la donne. La mesure d'avant et
  d'après dira ce qu'il en est.
- La part des personnes sans compte et sans achat qui perdront leurs
  points en changeant de téléphone, et ce que cela coûtera en avis.
- Le comportement exact de RevenueCat, tant que le bac à sable n'a pas
  parlé ; la reprise des trackers en dépend.
- Combien de personnes partagent un compte du store, et donc à quelle
  fréquence une copie sera proposée à quelqu'un d'autre que l'acheteur.
  Le risque est accepté (décision 5), l'acheteur est prévenu (cas 40), la
  politique de confidentialité le dit.
- Combien de personnes ont le trousseau iCloud ou la sauvegarde Google
  activés : aucun chiffre n'existe. La mesure dira combien de comptes
  invisibles sont retrouvés sur un second appareil.
- La fiabilité du trousseau synchronisé à l'usage : aucun retour
  d'expérience trouvé sur une app qui y garde une identité sans compte.
- Ce qu'un code qui tarde ou finit dans les courriers indésirables coûte
  en connexions ratées.
- Combien de payeurs resteront sans compte, et combien écriront au
  support en passant d'iPhone à Android ou en voulant Premium sur deux
  appareils. Les événements de la mesure le diront.

## Relectures

Un autre agent a relu la première version, puis la troisième, avec trois
consignes : tout chemin vers une perte de données ou d'achat non demandée,
toute situation où l'utilisateur ne saurait pas ce qui lui arrive, ce
qu'un constructeur devrait deviner. La seconde fois, il a aussi vérifié
dans le code ce que ce document dit de l'app d'aujourd'hui, et dans la
documentation de RevenueCat et d'Apple ce sur quoi le design repose.

**Première relecture**

| Trouvé | Réglé par |
|---|---|
| Rejoindre un compte supprimait le compte invisible avec ses lignes d'achat : le payeur devenait gratuit pour le serveur, pour toujours s'il avait acheté à vie | Principe 3, cas 25, règles « Premium » : l'achat suit chez nous et chez RevenueCat, et la trace rattrape le reste |
| Un abonné annuel qui n'ouvre pas l'app pendant 12 mois était effacé en payant | Principe 4 : un compte qui porte un achat n'est jamais effacé |
| Un compte en cours d'usage pouvait être effacé à 30 jours après avoir vidé ses points | Cas 62 : sans point, sans achat **et** non rouvert |
| L'app démarre RevenueCat sans identifiant : un achat du premier jour pouvait n'être rattaché à personne | Règles « Premium » : toujours l'identifiant du compte (apps nouvelles) |
| Premium passait d'un téléphone sans compte à un autre à chaque restauration, sans rien dire | Cas 43 et 45 : chacun est prévenu et connaît la sortie |
| « J'ai déjà un compte » avec une identité inconnue attachait en silence | Cas 17 |
| Un tracker sans point disparaissait sans un mot, et l'écran disait « rien n'est effacé » | Écran toujours montré ; règle d'ajout |
| Compte effacé ou session refusée : les trackers s'affichaient une seconde, puis un premier lancement muet | Cas 7, et la session vérifiée à chaque requête |
| Premium déplacé : rien n'était dit sur l'appareil qui le perd | Cas 43 et 44 |
| « Restaurer les achats » ne disait rien quand il ne trouvait rien | Cas 32 à 36 |
| « Supprimer mes données » déconnectait même si le serveur n'avait rien effacé | Cas 66 |
| La réponse perdue en rejoignant un compte laissait le téléphone sur un compte supprimé | Cas 22, règle « Rejoindre » |
| Une ancienne adresse gardée par le téléphone faisait passer un compte invisible pour un compte attaché | Principe 5 |
| Session perdue par d'autres causes que l'expiration (restauration de la base, coffre Android) | Clé d'appareil ; ce qu'elle ne couvre pas est dit dans les règles |
| Les chiffres de la mesure disparaissaient avec les comptes supprimés | « Ce que cela touche », mesure ; événements d'achat déplacés |
| Le serveur rattache une connexion Apple ou Google à tout compte de même adresse, jamais vérifiée | Cas 24, règles « Identité » |
| Les effacements n'étaient annoncés que dans une invitation que peu de gens voient | Cas 10 (phrase permanente), cas 47, cas 7 |
| Restaurer un achat à vie après avoir supprimé son compte : le serveur ne le voyait pas | Règles « Premium » : le serveur vérifie auprès de RevenueCat |

**Seconde relecture**

| Trouvé | Réglé par |
|---|---|
| **Grave.** Avec un compte du store partagé, quelqu'un pouvait prendre les trackers d'un autre et le laisser à la porte : en les reprenant dans son propre compte, ou en créant un compte le premier sur un compte invisible devenu commun | Reprendre donne une copie (approche ii, principe 7) : plus de compte invisible commun, le téléphone d'origine garde tout |
| **Grave.** Le lien entre un achat et les trackers à reprendre se perdait si l'achat arrivait autrement que par « Restaurer », ou après un refus suivi d'une réinstallation | Le serveur retient quels comptes ont porté chaque achat ; l'offre est cherchée par tous les chemins et gardée (cas 37 et 39, règles « Premium ») ; le compte d'origine n'est pas effacé pendant ce temps (cas 61) |
| Rejoindre un compte ne déplaçait l'achat que chez nous ; chez RevenueCat il restait sous l'ancien compte, et l'app pouvait éteindre Premium | Règles « Premium » : l'achat suit chez RevenueCat, seul le serveur éteint Premium, la trace protège l'achat |
| Un compte attaché dépouillé par une restauration sans compte était envoyé vers « Restaurer », qui ne marche pas sur l'autre plateforme | Cas 44 : « Reprendre mon Premium », depuis n'importe quel téléphone du compte ; cas 35 reformulé |
| Rien n'était prévu quand un achat prend fin sur un compte invisible | Cas 47 |
| Une session « fermée » lisait et écrivait encore un quart d'heure, et un compte supprimé montrait une liste vide | Règles « Session » : vérifiée à chaque requête, avec sa raison |
| Un acheteur sans compte sur l'autre plateforme était envoyé vers un compte qui n'existe pas | Cas 35 et 60 |
| Le message des deux achats supposait le store et le téléphone | Cas 26 |
| Une suppression réussie dont la réponse s'était perdue se lisait comme une perte de données | Cas 66 |
| Les autres téléphones d'un compte ne disaient rien quand des trackers y arrivaient | Cas 18 et 38 |
| Relier une identité : rien pour un compte de même adresse sans mot de passe, ni pour une adresse non vérifiée | Cas 24, règles « Identité » |
| Les événements d'achat partaient avec le compte absorbé | Règles « Premium » |
| Non dit : le point de départ des 30 jours après un achat, le thème et la langue après avoir rejoint un compte | Cas 62 ; écran « Ce compte existe déjà », règle « Rejoindre » |
| Deux téléphones, manqué : un tracker supprimé ailleurs renvoyait à la liste sans un mot | Cas 53 |
| Deux téléphones, manqué : thème, langue et curseur suivent le compte et s'appliquent à l'autre téléphone à son prochain lancement | Laissé tel quel et dit (cas 54, non-objectifs) : à trancher par Charles s'il le souhaite |
| Ce que le document disait à tort de l'app d'aujourd'hui (liste vide et non trackers affichés, Premium suivi par le SDK entre deux lancements, année affichée seulement) | Cas 48 à 50 corrigés |

**Vérification de la quatrième version**

Le même agent a vérifié que ses trous étaient fermés (ils le sont) et
cherché ceux que la copie ouvrait.

| Trouvé | Réglé par |
|---|---|
| **Grave.** Le compte d'origine, une fois sa copie prise ailleurs, pouvait être effacé au bout de 12 mois alors que son achat était toujours payé | Cas 61 : le délai ne court pas tant qu'un achat que le compte a porté est en cours, où qu'il soit |
| **Grave.** Une copie déjà prise empêchait de reprendre ce qui avait été colorié depuis sur le téléphone d'origine, et dans l'autre sens | Règle des doubles : on compare les contenus ; l'offre revient dès qu'ils diffèrent (cas 32 et 37) |
| « Reprendre mon Premium » donnait à tout compte ayant restauré l'achat une fois le moyen de le reprendre à vie, sans preuve | Cas 44 : le bouton n'existe que pour le compte qui a fait l'achat, et n'ouvre pas d'offre de reprise |
| L'acheteur créait son compte, mais une offre déjà en attente ailleurs donnait encore une copie de ses trackers | Cas 39, règles « Premium » : recevoir une identité met fin à la mémoire et aux offres |
| En rejoignant un compte, une copie inchangée n'était pas ajoutée même si son original avait été supprimé du compte | Règle des doubles : comparée à ce qui est dans le compte à ce moment-là, et comptée à part sur l'écran |
| La ligne des réglages ne disait pas quand les trackers à reprendre seraient effacés | Cas 39 et 47 : la date |
| Un téléphone sans compte était invité à « créer un compte » alors que l'achat était parti sur un compte attaché | Cas 43 |
| Raison de refus manquante pour un compte rejoint | Règles « Session » |
| « Seul un achat en cours ouvre une reprise » contredisait une offre acceptée après la fin de l'achat | Cas 47 reformulé |

**Relecture de la cinquième version**

Un nouvel agent a relu ce que la cinquième version ajoute, avec le
document du hors-ligne, en croisant les deux et en comparant avec la
recherche.

| Trouvé | Réglé par |
|---|---|
| **Grave.** Un compte ouvert par code pouvait déjà être celui de quelqu'un d'autre : une personne inscrit l'adresse d'un autre avec un mot de passe, le vrai propriétaire s'y connecte ensuite par code, et le premier garde l'accès | L'inscription sans code est fermée à la mise à jour, pour toutes les versions. Pour les comptes d'avant, Charles a écarté le retrait du mot de passe (le code ne remplace rien) : cas 70, un avis la première fois, avec de quoi retirer un mot de passe qu'on n'a pas créé |
| **Grave.** Sur un compte invisible ouvert par la clé sur deux appareils, celui qui créait un compte laissait l'autre à la porte (compte Apple partagé, téléphone cédé) | Cas 55 : l'autre appareil peut continuer sans compte avec ses trackers |
| **Grave.** Rejoindre un compte était jugé sur le serveur alors que le téléphone avait encore des modifications en attente : un tracker rempli hors ligne passait pour vide et n'était pas gardé | L'écran « Ce compte existe déjà » et la règle « Rejoindre » : la file part d'abord ; un compte absorbé garde sa trace |
| Une copie restaurée devenait un compte invisible même quand elle venait d'un compte attaché, ou d'une session fermée exprès | Cas 85 et règles « Session » : le serveur dit ce qu'est devenu le compte de la copie |
| Une copie renvoyée au serveur pouvait être refusée pour la limite gratuite, et rien ne disait ce qu'il advenait de ses identifiants ni de deux appareils qui la tiennent | Cas 85, règle « Limite gratuite » |
| La clé arrivée après coup doublait tous les trackers | Cas 85 : le compte provisoire se replie dans le compte d'origine |
| Vider son ancien téléphone par « Supprimer mes données » effaçait ce que le nouveau allait retrouver | Cas 65 : la confirmation dit que la suppression vaut partout |
| Un téléphone resté connecté suffisait à changer l'adresse du compte et à en chasser son propriétaire | Cas 77 : preuve de l'adresse actuelle, e-mail d'annulation à l'ancienne |
| Messages qui affirmaient ce que l'app ne sait pas (« liés à votre compte iCloud », « Vérifié… ») | Cas 79, 80, 82, 90 reformulés |
| La clé synchronisée ne suit pas forcément un transfert direct | Deux entrées dans le trousseau (règles « Session ») ; à essayer |
| La clé de restauration Android annoncée pour un compte invisible, ce que Google ne prévoit pas | Cas 89 |
| Le transfert direct entre deux Android copie les fichiers même sans sauvegarde Google | Ligne 58, cas 79 |
| Le renvoi d'une demande devait resservir un code déjà utilisé | Cas 22 |
| Un compte Apple à adresse masquée n'a pas de porte sur Android | Cas 77 et 79 : ajouter une adresse |
| Durée du souvenir des comptes supprimés non dite | Règles « Session » : 24 mois |
| Thème et langue dits inchangés ici, poussés en direct dans le document du hors-ligne | Cas 54 |

**Vérification de la cinquième version**

Le même agent a vérifié les corrections et ce que Charles a changé ensuite
(inscription sans code fermée, code et mot de passe qui coexistent,
changement d'adresse, clé de restauration Android dans la release).

| Trouvé | Réglé par |
|---|---|
| **Grave.** Le lien d'annulation d'un changement d'adresse partait vers l'adresse mal tapée, donc peut-être vers un inconnu, qui pouvait reprendre le compte | Cas 77 : pas d'e-mail à une adresse jamais vérifiée ; la preuve est alors le mot de passe |
| **Grave.** La clé de restauration Android survivait à une déconnexion forcée : un téléphone prêté ou volé rouvrait le compte sur un autre | Cas 89 : toute fermeture de session la fait oublier au serveur |
| Le compte provisoire du cas 85 : un achat restauré dessus se perdait au repli, la file portée par la sauvegarde n'était pas rejouée, ses identifiants étaient ceux d'un compte encore vivant, un second appareil pouvait le réunir de travers | Cas 85 |
| L'avis du cas 70 ne se montrait qu'à la connexion par e-mail, pas quand l'adresse était prouvée par un autre chemin ; une réunion pouvait reprendre le mot de passe du compte absorbé | Cas 70 et 77 |
| Le cas 55 (continuer avec ses trackers) contredit par le document du hors-ligne et par le cas 85 | Cas 85 ; document du hors-ligne, cas H25 |
| Anciennes routes : le rattachement d'office par l'adresse et l'adresse non vérifiée d'un fournisseur restaient ouverts | « Ce que cela touche », anciennes versions |
| Deux entrées de trousseau sous un même nom s'effaceraient ; une clé morte restée sur l'appareil n'avait pas de réponse | Règles « Session », cas 80 |
| « Reprendre mon Premium » restait à celui qui pose une identité sur un compte trouvé par sa clé | Cas 44 |
| Un tracker pas gardé parce qu'il paraissait vide, alors qu'un autre appareil y avait des points en attente | Règle « Rejoindre » |
| « Créer mon compte » avant que le compte invisible existe sur le serveur | Règles |
| Raisons de refus de session incomplètes ; phrase contradictoire sur la demande rejouée ; repli qui supprimait le cas 80 | Règles « Session », « Rejoindre » ; « À vérifier » |

Mes choix, à corriger si l'un ne convient pas : la copie plutôt que le
compte commun pour reprendre ses trackers ; l'avertissement au téléphone
d'origine (cas 40) ; « Reprendre mon Premium » pour le compte attaché qui
a fait l'achat ; la règle d'ajout des trackers sans point et la règle des
doubles ; l'ordre des écrans
proposés au lancement ; la preuve demandée avant de relier une identité à
un compte de même adresse ; la clé d'appareil et la durée longue des
sessions pour tous ; la ligne du payeur sans compte plutôt qu'un écran
répété ; « Restaurer les achats » dans les réglages ; « Déconnecter mes
autres appareils » ; pas d'autre méthode de connexion.
