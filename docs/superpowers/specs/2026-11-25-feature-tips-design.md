# Astuces : montrer les fonctions cachées — design (2026-11-25)

## Sources

- Demande de Charles le 2026-11-25 : une fois l'accueil fini (premier
  tracker créé, premier point posé), un **chemin complet** qui fait
  découvrir les fonctions qui ne se devinent pas. D'abord les trois façons
  de colorier :
  - le bouton Aujourd'hui de la barre ;
  - toucher un point puis choisir une couleur ;
  - choisir une couleur dans la légende, puis toucher les points.

  Puis le glissement qui plie la barre et le pincement des mois et des
  semaines. Ses mots :
  - « un petit carré qui clignote avec un petit message » ;
  - « une fois qu'il a cliqué comme ça pour découvrir la feature, ou s'il
    l'a déjà cliqué, et bien là on va pas lui proposer » ;
  - « il ne faut pas tous les proposer d'un coup sinon la personne va être
    submergée ».
- Maquettes animées : https://claude.ai/artifact/3HsujtgXLrre5FbtaViGmE.
  Charles les a validées le 2026-11-25 : « ça me paraît pas mal tout ça ».
  Elles font foi pour l'aspect.
- Recherches, toutes trois de Nielsen Norman Group :
  - [les tutoriels au démarrage](https://www.nngroup.com/articles/mobile-tutorials/) :
    la réussite ne s'améliore pas, 91 % de tâches réussies avec le tutoriel
    contre 94 % sans ;
  - [les exemples de tutoriels dans les apps](https://www.nngroup.com/articles/onboarding-tutorials/) :
    l'aide qui arrive pendant l'activité concernée (« pull revelations »)
    vaut mieux que celle qui arrive hors contexte ;
  - [les bulles d'aide superposées sur mobile](https://www.nngroup.com/articles/mobile-instructional-overlay/) :
    plusieurs bulles à la fois chargent la mémoire et font paraître l'app
    compliquée.
- Spec du zoom (`2026-11-25-tracker-zoom-design.md`) : les gestes du zoom et
  le relevé des usages, que cette spec étend.

## Pourquoi

L'ancien accueil en trois cartes expliquait sans rien faire faire ; la spec
d'activation (2026-10-15) l'a remplacé par deux écrans qui font poser le
premier point. Après, plus rien n'apprend.

Or plusieurs fonctions ne se voient pas :
- le pinceau (toucher une couleur de la légende) n'a ni libellé ni repère ;
- le bouton Aujourd'hui ouvre la case du jour depuis n'importe quelle
  année ;
- le commentaire ;
- et bientôt le pincement, le glissement des pages et celui de la barre.

Il n'existe dans l'app aucun mécanisme de bulle ou de repère : seuls le
bouton Éditer qui pulse quand la légende est vide et quelques textes d'aide
fixes.

## Objectifs

- Montrer chaque fonction cachée **une fois**, au moment où elle sert.
- Apprendre en faisant : l'astuce se termine quand la personne fait le
  geste.
- Ne jamais montrer ce que la personne sait déjà faire.
- Rendre le chemin complet visible pour qui le veut (le carnet).

## Non-objectifs

- Un tutoriel au démarrage, une vidéo, un écran d'aide à lire.
- Des astuces sur les écrans d'accueil (le parcours du premier tracker
  reste tel quel).
- Un ciblage décidé par le serveur.

## Anti-objectifs

- Plusieurs astuces à la fois, ou plusieurs dans la même ouverture de
  l'app.
- Une astuce pour une fonction déjà utilisée.
- Une bulle qui cache ce qu'elle montre, ou qui bloque l'écran.
- Une astuce qui revient après « Compris ».
- Une astuce qui vend Premium.

## Approches

| Question | Retenu | Écarté, et pourquoi |
|---|---|---|
| Quand apprendre | **Des astuces dans le contexte, une à la fois**, chacune déclenchée par la situation à l'écran et par ce que la personne a déjà fait | Un tutoriel au démarrage : les études ne lui trouvent pas d'effet, et l'ancien accueil en cartes a été retiré pour ça. Une page d'aide seule : personne ne l'ouvre ; elle reste en complément (le carnet) |
| La forme | **Un cadre qui clignote sur la chose à toucher, une bulle d'une phrase, des doigts fantômes pour les gestes** (les maquettes) | Un bandeau en bas de l'écran : il ne montre pas où toucher. Un projecteur qui assombrit tout l'écran : il bloque et ressemble au tutoriel qu'on évite |
| Ce qui termine une astuce | **Le geste lui-même**, sinon « Compris » | Un bouton « Suivant » : on lit, on ne fait pas |

## La forme d'une astuce

D'après les maquettes ; les tailles sont pour un téléphone de 390 points de
large.

- **Le cadre** :
  - un trait pointillé de 2 points, à la couleur d'accent du thème, à
    3 points autour de la cible, avec des coins de la cible arrondis de
    3 points de plus ;
  - un halo de 3 points : l'accent mêlé vers le fond du thème, jamais vers
    le blanc ou le noir ;
  - il clignote en deux temps, sans fondu (0,66 s visible, 0,44 s à 22 %),
    tant que l'astuce est là ;
  - une cible faite de plusieurs cases (le pinceau) a un cadre par case,
    trois au plus.
- **La bulle** :
  - fond `shell`, bord d'accent de 1,5 point, coins de 11 points, 230 points
    de large au plus ;
  - en haut, « ASTUCE » en police pixel, et l'étape (« 1/2 ») s'il y en a
    deux ;
  - une phrase en police dot, 14 points ;
  - en bas à droite, « COMPRIS » ;
  - une flèche, carré de 9 points tourné, vers le cadre ;
  - elle se place du côté indiqué par l'astuce, change de côté si la place
    manque, ne couvre jamais la cible et reste à 8 points des bords.
- **Les doigts fantômes**, pour les gestes :
  - des disques de 32 points, l'accent à 38 % avec un liseré du fond ;
  - le pincement : deux doigts qui s'écartent en diagonale, de 12 à
    46 points ;
  - le glissement : un doigt et sa traînée ;
  - le geste se rejoue trois fois (2,2 s par fois), puis les doigts
    disparaissent ; le cadre et la bulle restent.
- **L'arrivée** : le cadre et la bulle apparaissent en fondu, la bulle avec
  un léger grossissement (0,9 → 1) en `AppMotion.quick` (200 ms). Pas de
  son.
- **La réussite** :
  - le cadre devient plein, couleur `okText` (à créer : elle n'existe pas
    dans le thème, voir « Passe de confirmation ») ;
  - la bulle dit « ✓ C'EST ÇA ! », avec la phrase de réussite s'il y en a
    une (le pinceau) ;
  - elle reste 1,2 s, ou 2,5 s quand elle a une phrase, puis tout
    s'efface en 200 ms ;
  - son et vibration de `SoundCue.select`, si les sons et les vibrations
    sont activés.
- **Réduire les animations** (réglage du système) : le cadre ne clignote
  pas, les doigts restent figés au milieu du geste, pas de grossissement.

## Les neuf astuces du chemin

Dans cet ordre. Un « usage » est un nom du relevé (section « Le relevé »).

| # | Identifiant | Où | Quand (en plus des règles du rythme) | Terminée par | Phrase (français) |
|---|---|---|---|---|---|
| 1 | `other_day` | La case d'hier dans la vue affichée ; si elle n'est pas vide ou pas visible, le jour vide le plus récent des sept derniers | Tracker ouvert ; aucun usage `fill.grid` ni `fill.brush` ; un jour vide parmi les sept derniers | `fill.grid` ou `fill.brush` | « Hier compte aussi : touchez un jour pour le colorier. » Pour un autre jour que hier : « Les jours passés comptent aussi : touchez un jour pour le colorier. » |
| 2 | `today_button` | Le bouton Aujourd'hui | À partir du 2ᵉ jour d'usage (`usage_days`) ; la case du jour de ce tracker est vide ; aucun usage `fill.today` | `fill.today` | « Chaque jour, touchez ici : la case du jour s'ouvre, même depuis une autre année. » |
| 3 | `brush` | Étape 1 : la couleur de la légende du dernier jour colorié de ce tracker. Étape 2 : les jours vides visés, trois cadres au plus | Aucun usage `fill.brush` ; et soit deux jours vides ou plus parmi les sept derniers (hier compris) après le premier point du tracker, soit trois usages `fill.grid` ou plus | `fill.brush` | 1/2 : « Plusieurs jours à colorier ? Touchez une couleur… » 2/2 : « … puis touchez les cases : elles se colorient d'un toucher. » Réussite : « Touchez {couleur} de nouveau pour ranger le pinceau. » |
| 4 | `comment` | Le champ commentaire de la fenêtre d'un jour (ou « + commentaire » pour un jour déjà colorié) ; la bulle sous les boutons de la fenêtre | À l'ouverture de cette fenêtre ; au moins cinq cases coloriées dans le compte ; aucun commentaire dans le compte ; aucun usage `comment.add` | `comment.add` | « Ajoutez un mot : vous le relirez d'un coup d'œil dans la vue Mois. » Avant le zoom : « Ajoutez un mot : vous le relirez en touchant le jour. » |
| 5 | `open_month` | La colonne du mois en cours, éclairée comme une cible de pincement, et deux doigts fantômes qui s'écartent | Vue Année sur l'année en cours ; sept jours coloriés ou plus ce mois-ci dans ce tracker, ou un commentaire ; aucun usage `zoom.pinch` | `zoom.pinch` | « Écartez deux doigts sur un mois pour l'ouvrir. Ou touchez sa lettre. » Si `zoom.selector` ou `zoom.letter` a déjà servi : « Plus rapide : écartez deux doigts sur un mois. » |
| 6 | `page_swipe` | La vue Mois ou Semaine, un doigt fantôme qui glisse vers la gauche | Deux usages `page.arrows` ou plus ; aucun `page.swipe` | `page.swipe` | « Glissez vers la gauche ou la droite pour changer de mois. » (« … de semaine » en vue Semaine) |
| 7 | `sidebar_swipe` | La barre de gauche dépliée, un doigt fantôme qui la pousse vers la gauche | Vue Mois ou Semaine ; au moins un aperçu de commentaire coupé à l'écran ; trois usages `view.zoomed` ou plus ; aucun `sidebar.swipe` | `sidebar.swipe` | « Poussez la barre vers la gauche : les commentaires prennent la place. Vers la droite, elle revient. » Si `sidebar.chevron` a servi : « Aussi d'un geste : poussez la barre vers la gauche, puis vers la droite pour la retrouver. » |
| 8 | `tracker_settings` | Le bouton Éditer ; une fois le lot 1 des stats construit, la roue des réglages du tracker | Dix jours coloriés ou plus dans ce tracker ; quatre jours d'usage ou plus ; aucun usage `legend.editor` (avant les stats) ou `tracker.settings` (après) | `legend.editor`, puis `tracker.settings` | Avant les stats : « Renommez, recoloriez, ajoutez des couleurs : tout se change ici. » Après : « Le nom, la légende, l'habitude, le rappel : tout se change ici. » |
| 9 | `second_tracker` | Le bouton + de la liste des trackers | Sur la liste ; trois jours d'usage ou plus ; cinq cases coloriées ou plus dans le compte ; un seul tracker | `tracker.create`, ou un 2ᵉ tracker présent | « Suivez autre chose à côté : sommeil, sport, lecture… » |

Précisions :

- **Le pinceau, en deux temps.**
  - Toucher la couleur encadrée (ou une autre) passe à l'étape 2, avec
    cette couleur.
  - Toucher autre chose à l'étape 1 compte comme une astuce ignorée.
  - À l'étape 2, ranger le pinceau sans colorier compte aussi comme
    ignorée.
  - S'il n'y a plus de jour vide visé, l'étape 2 encadre le premier jour
    vide d'avant aujourd'hui dans la vue.
- **Les astuces 5, 6 et 7** n'existent qu'une fois le zoom construit.
- **Trackers « seulement quand ça arrive »** (spec des stats, `pages.cadence`) :
  un jour vide y veut dire qu'il ne s'est rien passé. Les astuces 1, 2 et 3
  ne visent que les trackers « tous les jours » (une habitude jamais
  demandée compte comme « tous les jours »), pour ne jamais inviter à
  colorier un jour qui doit rester vide. Si le compte n'a que des trackers
  occasionnels, ces astuces attendent ; elles restent dans le carnet.
  (*Mon choix*, après la relecture.)
- **Le premier jour** : l'astuce 1 sort dès l'arrivée sur le tracker après
  l'accueil, une fois l'écran calme 1,5 s ; c'est le début du chemin que
  Charles a validé. L'écran de demande des rappels, s'il suit le premier
  point, fait partie de l'accueil : il ne bloque pas l'astuce 1 ce jour-là
  (exception à la règle « En dernier ») ; l'astuce attend qu'il soit fermé.
  La case posée par l'accueil (`setCell` direct) n'ajoute aucun usage.
- **L'astuce 9** ne mène jamais au paywall : à un seul tracker, la version
  gratuite en permet encore deux.
- **Les doigts fantômes** se placent ainsi :
  - astuce 5 : au milieu de la colonne, à hauteur du jour d'aujourd'hui ;
  - astuce 6 : au milieu de la grille ;
  - astuce 7 : au milieu de la barre, sur une course de 46 points.

## Les quatre gestes hors du chemin

Ces gestes ne sont jamais proposés d'eux-mêmes ; on les montre seulement
depuis le carnet. Ils servent peu ou se voient déjà.

| Identifiant | Où | Phrase |
|---|---|---|
| `date_swipe` | La date de la fenêtre d'un jour, un doigt fantôme | « Glissez sur la date pour passer au jour d'avant ou d'après. » |
| `reorder` | La poignée ≡ d'une carte de la liste | « Maintenez ≡ et glissez pour ranger vos trackers. » |
| `rename` | Le titre du tracker | « Touchez le titre pour renommer le tracker. » |
| `back_edge` | Le bord gauche de l'écran du tracker, un doigt fantôme vers la droite | « Glissez depuis le bord gauche pour revenir à la liste. » |

## Le rythme

- **Une à la fois, une par ouverture.**
  - Au plus une astuce par ouverture de l'app. Une ouverture, c'est un
    lancement, ou un retour au premier plan après 30 minutes ou plus en
    arrière-plan.
  - Le pinceau, en deux temps, compte pour une.
  - Les astuces se tentent dans l'ordre du chemin : la première dont les
    conditions sont réunies sort.
- **Jamais ce qu'on sait déjà.**
  - Une astuce dont l'usage final est déjà dans le relevé ne sort jamais,
    qu'il vienne d'une astuce ou non.
  - Les comptes anciens sont traités plus bas.
- **Au bon moment.** Sur l'écran concerné, une fois les animations
  d'arrivée finies :
  - après 1,5 s sans toucher ;
  - ou tout de suite pour une astuce liée à une action : l'ouverture de la
    fenêtre d'un jour (4), l'arrivée sur la liste (9), l'entrée dans une vue
    Mois ou Semaine (6, 7).

  Jamais pendant un geste, jamais par-dessus une autre fenêtre (sauf la 4,
  qui est dans la fenêtre du jour), jamais sur le paywall.
- **En dernier.**
  - Pas d'astuce le jour civil où s'est montrée une autre fenêtre : les
    nouveautés (`WhatsNewDialog`), la pop-up Premium, la demande de rappels,
    « stats prêtes ».
  - Si une astuce est sortie plus tôt dans la journée, ces fenêtres gardent
    leurs propres règles.
- **Elle s'efface.**
  - Un toucher ailleurs que sur la cible ou la bulle la fait partir, et ce
    toucher agit normalement : rien n'est bloqué.
  - Quitter l'écran ou passer l'app en arrière-plan la fait partir aussi.
  - Une astuce partie ainsi est « ignorée ». Elle peut ressortir une seule
    fois, au plus tôt deux jours civils plus tard. Après deux sorties, plus
    jamais.
- **« Compris »** range l'astuce pour toujours.
- **Elle ne vend rien.** Aucune astuce ne montre une fonction Premium :
  stats détaillées, export, thèmes, curseurs.

### Les comptes anciens

Au premier lancement d'une version qui contient les astuces, et sur un
nouvel appareil, le relevé ne sait rien. Les données du compte disent
pourtant déjà beaucoup :

- un commentaire existe : `comment` est tenue pour connue ;
- deux trackers ou plus : `second_tracker` est connue ;
- plus de 30 cases coloriées dans le compte (`cells_total`) : `other_day`, `today_button`,
  `brush` et `tracker_settings` sont connues.

**D'où vient « le compte »** : l'app ne charge qu'une année à la fois
(`GET /api/bootstrap?year=`, l'instantané ne garde que l'année active), et
les cases ne portent pas de date de saisie. *Mon choix*, après la relecture :
le bootstrap ajoute deux champs calculés sur tout le compte, toutes années
et tous trackers confondus :
- `cells_total`, le nombre de cases ;
- `has_comment`, vrai si une case porte un commentaire.

C'est une petite sortie du backend, avant l'app, comme `activated` pour
l'accueil. Ces deux champs servent à la règle des comptes anciens, à la
condition « aucun commentaire dans le compte » de l'astuce 4 et aux « cinq
cases coloriées dans le compte » des astuces 4 et 9. Les conditions « dans ce
tracker » restent calculées sur l'année chargée.

Les astuces du zoom (5, 6, 7) restent proposées à tous : c'est nouveau pour
tout le monde. Les nouveautés de la version annoncent le zoom ; l'astuce 5
montre le geste plus tard, quand il sert, et jamais le même jour (règle
« En dernier »).

## Le relevé

Tout est sur l'appareil, par compte, dans les préférences, sous la même
forme que `first_tracker_done_<userId>` (*mon choix* : pas de synchro
serveur).

**`features_used_<userId>`** : une table du nom vers le nombre d'usages,
bornée à 99. La spec du zoom l'appelait « ensemble de noms » ; c'est cette
table, et un nom présent vaut au moins 1. Les noms :

| Nom | S'ajoute quand |
|---|---|
| `fill.grid` | un jour est colorié par la fenêtre ouverte en touchant ce jour (grille, vue Mois ou Semaine) |
| `fill.brush` | une case est coloriée au pinceau |
| `fill.today` | le bouton Aujourd'hui est touché |
| `comment.add` | un commentaire est enregistré |
| `legend.editor` | l'éditeur de légende s'ouvre parce que la personne l'a demandé (Éditer, ou « Modifier la légende › » des réglages du tracker) ; pas quand l'app l'ouvre seule, à la création d'un tracker personnalisé |
| `tracker.settings` | les réglages du tracker (la roue, spec des stats) s'ouvrent |
| `tracker.create` | un tracker est créé depuis la liste |
| `zoom.pinch`, `zoom.selector`, `zoom.letter` | un changement de niveau acquis par ce moyen (spec du zoom) |
| `page.swipe`, `page.arrows` | une page tournée par ce moyen (année, mois ou semaine) |
| `sidebar.swipe`, `sidebar.chevron` | la barre pliée ou dépliée par ce moyen |
| `view.zoomed` | une entrée dans la vue Mois ou Semaine |
| `editor.date_swipe` | un jour changé en glissant sur la date de la fenêtre |
| `tracker.reorder` | un tracker déplacé dans la liste |
| `tracker.rename` | un tracker renommé |
| `nav.back_edge` | un retour à la liste par le bord |

**`tips_<userId>`** : pour chaque astuce, le nombre de sorties, la date de
la dernière et son état (`done`, `dismissed` ou rien).

**`usage_days_<userId>`** : le nombre de jours civils où l'app a été
ouverte, et la date du dernier, pour compter un jour une seule fois.

La date de la dernière astuce et celle de la dernière autre fenêtre servent
aux règles du rythme. Un usage qui arrive pendant qu'une astuce est
affichée la termine en réussite ; avant ou sans elle, il la rend inutile.

Sur un nouvel appareil d'un compte encore jeune, quelques astuces peuvent
ressortir. C'est accepté ; la règle des comptes anciens couvre les
utilisateurs installés.

## Le carnet d'astuces

Dans les réglages, une ligne « Astuces » avec « 6 sur 9 » ouvre une page
(maquette « Réglages › Astuces ») :

- **le chemin**, les neuf astuces dans l'ordre : ✓ pour celles dont l'usage
  est dans le relevé (ou tenues pour connues), sinon « MONTRER » ;
- **les autres gestes**, les quatre hors du chemin, avec « MONTRER » ;
- **une barre de progression** sur les neuf.

« Montrer » ferme les réglages et joue l'astuce tout de suite, sans règle
de rythme ni condition, à l'endroit qu'il faut :
- le dernier tracker ouvert, sur l'année en cours (l'app oublie
  `last_tracker_id` au retour à la liste : une clé à part garde le dernier
  tracker ouvert pour le carnet) ;
- la liste pour `second_tracker` et `reorder` ;
- la fenêtre du jour d'aujourd'hui pour `comment` et `date_swipe` ;
- la vue Mois du mois en cours pour `page_swipe` et `sidebar_swipe`.

Une astuce montrée ainsi ne compte pas dans le rythme. Sa réussite coche la
ligne.

## Mesurer

Trois événements par astuce, par la route des événements qui existe
(`events_service.dart`, `POST /api/events`, noms en minuscules séparés par
des points) :

- `tip.shown.<id>` : l'astuce sort ;
- `tip.done.<id>` : elle se termine en réussite ;
- `tip.dismissed.<id>` : « Compris ».

Une astuce montrée depuis le carnet envoie les mêmes noms, suivis de
`.notebook`. Rien d'autre n'est envoyé : ni le relevé, ni les comptes
d'usage.

**Base légale** : intérêt légitime, comme les événements du parcours
d'achat. Il faut une ligne dans le registre et dans la politique de
confidentialité (chantier « Registre RGPD » de `docs/FABLE.md`).

## Textes

Le français est ci-dessus. Le constructeur écrit l'anglais et les deux
chinois dans les clés de langue de l'app (`language_provider.dart`,
préfixe `tip.`), en vouvoyant comme le reste de l'app. Charles relit le
français et l'anglais.

## Découpage

- **Lot 1, sans le zoom** :
  - côté serveur d'abord : `cells_total` et `has_comment` dans le
    bootstrap ;
  - le moteur (relevé, règles du rythme, comptes anciens) ;
  - le cadre, la bulle et la réussite ;
  - les astuces 1, 2, 3, 4, 8 et 9 (l'astuce 8 sous sa forme Éditer ou
    roue, selon que le lot 1 des stats est déjà là) ;
  - le carnet, avec les quatre gestes hors du chemin ;
  - les événements.
- **Lot 2, avec le zoom ou après** : les doigts fantômes du pincement, les
  astuces 5, 6 et 7, et la phrase « vue Mois » de l'astuce 4.

## Décidé le 2026-11-25

Charles, sur les maquettes et la proposition (« ça me paraît pas mal tout
ça ») :
- la forme ;
- les neuf astuces et leur ordre ;
- une astuce par ouverture de l'app au plus ;
- jamais pour ce qu'on sait déjà ;
- jamais le jour d'une autre fenêtre ;
- aucune astuce qui vend ;
- la règle des comptes anciens ;
- le carnet d'astuces ;
- les trois événements par astuce.

## Relecture du 2026-11-25

Relecture façon constructeur, faite sur le code et sur les specs des stats,
des rappels et de la pop-up. Ce qu'elle a changé, en *mes choix* :
- deux champs du bootstrap pour connaître le compte entier ;
- l'astuce 2 compte en jours d'usage ;
- les astuces 1 à 3 seulement sur les trackers « tous les jours » ;
- l'astuce 1 dès le premier jour, l'écran des rappels de l'accueil ne la
  bloquant pas ;
- l'astuce 8 devient « les réglages du tracker » et vise la roue quand
  elle existe ;
- l'éditeur de légende ouvert par l'app à la création ne compte pas ;
- une clé à part pour le dernier tracker ouvert, pour le carnet.

## Laissé au constructeur

- L'architecture : un hôte d'astuces par écran au-dessus du contenu
  (`Overlay`), des cibles repérées par des clés ; à lui de voir.
- Le placement fin de la bulle sur tablette et en paysage.
- Les traductions (section « Textes »).

## Passe de confirmation du 2026-11-25

Comparée à `master` (app 1.4.0, backend 1.2.1). Détail :
`docs/CONFIRMATION.md`, points 30 à 32.

1. **`okText` n'existe pas** dans le thème (`AppThemeColors`), pas plus
   que `accentSoft` et `weekend` du zoom. À tirer de chaque thème, en
   mêlant vers le fond du thème, et à vérifier sur les sept thèmes.
2. **Des cases, pas des jours.** `cells_total` compte les cases du compte,
   tous trackers confondus : trois trackers remplis deux jours font six.
   Les seuils « cinq » et « plus de 30 » se lisent en cases (texte
   corrigé) ; ils restent des ordres de grandeur.
3. **`date_swipe`** montre le geste de l'éditeur de jour, qui passe
   aujourd'hui par des jours qui n'existent pas (spec du zoom, « Passe de
   confirmation », point 6) : ce correctif se construit avant l'astuce.
4. **Le glissement des années** (spec du zoom, décidé le 2026-11-25) note
   aussi `page.swipe`. L'astuce 6 ne change pas : elle se montre en vue
   Mois ou Semaine, et quelqu'un qui a déjà glissé d'une année à l'autre
   connaît le geste.
5. **Place dans l'ordre** (*mon choix*, `docs/FABLE.md`) : le lot 1 juste
   après les rappels, avant les lots 2 et 3 des stats ; le lot 2 avec le
   zoom. Le lot 1 arrive donc après le lot 1 des stats : l'astuce 8 vise
   directement la roue.
6. **Confirmé dans le code** : aucun mécanisme de bulle n'existe ; le
   bouton Éditer pulse quand la légende est vide ; `first_tracker_done_`,
   l'oubli de `last_tracker_id` au retour à la liste, la poignée ≡, le
   titre qui se renomme au toucher, le retour par le bord ; les noms
   `tip.shown.<id>.notebook` passent la règle de la route des événements.
7. **Une seule release** (Charles, 2026-11-25) : les deux lots sortent
   ensemble, avec les stats et le zoom. Les formes d'attente ne se
   construisent pas : l'astuce 8 vise la roue (pas Éditer) et l'astuce 4
   dit « dans la vue Mois ». Les lots restent l'ordre de construction.
