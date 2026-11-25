# Registre des activités de traitement — Dian Dian

Registre tenu au titre de l'article 30 du RGPD, sur le modèle simplifié de
la CNIL. Il commence avec la fiche du compteur de visites (chantier 1) ; les
autres traitements du projet (comptes, données de suivi, achats, e-mails,
événements produit, publicité, sauvegardes, journaux de sécurité) y entrent
avec le lot « registre et politique de confidentialité » qui suit.

**Responsable du traitement** : OVERRIDE, SASU, SIREN 953 122 868.
Contact : contact@diandian.overridedev.com. Pas de délégué à la protection
des données désigné.

À ne jamais écrire, ici ni ailleurs : que ce traitement est « validé par la
CNIL ». La CNIL ne valide rien ; ce registre dit ce que nous faisons et
pourquoi nous pensons être dans le cadre.

---

## Fiche 1 — Mesure d'audience du site

| | |
|---|---|
| Créée le | 2026-11-25 |
| Mise à jour | 2026-11-25 |
| Mise en service | avec la release unique (date à porter ici par Charles) |
| Code | `backend/src/audience/`, branché dans `backend/src/routes/landing.ts` |

### Finalité

Mesurer la fréquentation du site `diandian.overridedev.com` pour le seul
compte de Dian Dian : nombre de visites et de visiteurs du jour, clics vers
l'App Store et Google Play, site d'où viennent les visiteurs, type
d'appareil, pays, et passages des robots. Les chiffres ne sont jamais reliés
à un compte de l'app, à une installation, ni transmis à un tiers.

### Base légale et cadre

- RGPD : intérêt légitime (article 6.1.f) à connaître la fréquentation de
  son propre site.
- Article 82 de la loi Informatique et Libertés : aucun cookie ni traceur
  de mesure n'est déposé ni lu sur l'appareil du visiteur. Le seul cookie
  lié à ce traitement est celui de l'opposition, déposé à la demande du
  visiteur.
- Référence suivie : les lignes directrices de la CNIL sur les cookies et
  autres traceurs (délibération 2020-091) et sa grille d'auto-évaluation de
  la mesure d'audience (juillet 2025).

### Personnes concernées

Les visiteurs du site. Pas les utilisateurs de l'app en tant que tels :
l'app n'appelle pas les pages du site que le compteur regarde.

### Données

| Donnée | Ce qui en est fait |
|---|---|
| Adresse IP | Lue en mémoire le temps de la requête : pour trouver le pays (base DB-IP chargée en mémoire), pour l'empreinte du jour, et pour vérifier qu'un robot vient bien des plages d'adresses de son opérateur. Jamais écrite : ni en base, ni dans un journal. |
| `User-Agent` | Lu en mémoire : réduit à une classe d'appareil, une famille de navigateur, le nom d'une app à navigateur intégré, ou le nom d'un robot. Le `User-Agent` complet n'est jamais écrit. |
| En-tête `Referer` | Réduit au nom de domaine du site d'origine. L'adresse de la page d'origine n'est jamais écrite. |
| Paramètre `utm_source` | Sa valeur n'est jamais écrite. Seul reste le fait qu'un lien était marqué, et, quand il n'y a pas de `Referer`, le nom de domaine que désigne une valeur d'une liste fermée (voir « Risque résiduel »). `utm_campaign` n'est jamais lu par le compteur. |
| Empreinte du jour | `SHA-256(sel du jour ‖ domaine ‖ IP ‖ User-Agent)`, gardée en mémoire jusqu'à minuit UTC pour compter les visiteurs distincts. Le sel est tiré au hasard chaque jour, vit en mémoire seulement, n'est dérivé d'aucun secret et n'est jamais écrit. Le sel et les empreintes d'un jour sont effacés de la mémoire dans les secondes qui suivent minuit UTC (un contrôle toutes les 5 secondes) : passé ce moment, elles ne peuvent plus être recalculées. Un redémarrage du serveur efface le tout. |
| Ce qui est écrit en base | Des compteurs par jour : type (visite ou clic store), store, site d'origine, lien marqué ou non, classe d'appareil, famille de navigateur, app à navigateur intégré, langue de la page, pays, et pour les robots leur famille, leur nom et le résultat de la vérification. Aucune ligne ne décrit une personne. |

Aucune donnée sensible. Aucun identifiant de visiteur ne dure plus d'un jour.

### Destinataires

Le responsable du traitement, seul. Pas d'outil d'analyse tiers, pas de
script tiers sur la page. Sous-traitant : l'hébergeur du serveur (voir
« Hébergement »).

### Durées de conservation

- Compteurs par jour : 25 mois au plus (le mois en cours et les 24
  précédents), puis remplacés par un total par mois (visites, clics par
  store, passages de robots).
- Sauvegardes chiffrées de la base, où ces compteurs figurent : durée à
  porter dans la fiche des sauvegardes (lot « registre »).
- Empreintes et sel : la journée en cours, en mémoire.
- Cookie d'opposition (`dd_noaudience`) : 13 mois sur l'appareil du visiteur.

### Information et droit d'opposition

- Section « Mesure d'audience du site » de la politique de confidentialité
  (`/privacy`), en quatre langues, et ligne en pied de page du site.
- Opposition : page `/privacy/audience`, qui dépose le cookie
  `dd_noaudience` ; le visiteur n'est alors plus compté du tout. Les
  navigateurs qui envoient « Global Privacy Control » ou « Do Not Track » ne
  sont pas comptés non plus, sans rien avoir à faire. L'opposition est
  vérifiée avant que l'adresse IP ou le `User-Agent` ne soient lus par le
  compteur (la page elle-même lit le `User-Agent` de chaque visiteur, sans
  le garder, pour choisir le bouton du store à afficher).
- Les droits d'accès, de rectification et d'effacement n'ont pas d'objet :
  aucune ligne ne peut être rattachée à une personne.

### Hébergement et transferts

Serveur privé virtuel loué à Vultr, dans son centre de Paris : les compteurs
sont dans la base PostgreSQL de ce serveur, en France. Comme le reste de la
base, ils figurent dans ses sauvegardes chiffrées, envoyées vers un stockage
objet (Cloudflare R2) : son emplacement et ses garanties sont à préciser
dans la fiche des sauvegardes, avec le lot « registre ». Vultr est une
société américaine : son
avenant de traitement des données (DPA) est **à demander par Charles** (par
ticket, signature électronique d'après sa documentation) et à citer ici avec
sa date.

Deux services sont interrogés par le serveur, sans qu'aucune donnée de
visiteur ne leur soit envoyée : DB-IP (téléchargement mensuel de la base
des pays, licence CC BY 4.0, lien « IP Geolocation by DB-IP » sur le site)
et les opérateurs de robots qui publient leurs plages d'adresses
(téléchargement quotidien de listes publiques).

### Mesures de sécurité

- Rien d'identifiant n'est écrit ; le compteur ne peut donc rien divulguer
  sur une personne, même en cas de fuite de la base.
- Les valeurs écrites par celui qui envoie la requête (site d'origine, nom
  de robot) sont nettoyées et plafonnées par jour. Le nom d'un robot n'est
  gardé que s'il a la forme d'un nom de produit : un morceau d'adresse
  e-mail ou d'URL trouvé dans un `User-Agent` est compté sous « other ».
- La page d'opposition n'accepte un choix que de son propre formulaire : un
  autre site ne peut ni opposer un visiteur ni lever son opposition.
- Pas de journal d'accès du serveur web (Caddy) ; le journal de requêtes du
  backend n'existe qu'en développement.
- Lecture des chiffres par un script SQL en lecture seule
  (`backend/scripts/prod-landing.sql`), qui affiche « <10 » pour toute
  cellule sous dix dans les croisements par mois.

### Risque résiduel : le repli sur `utm_source`

La grille d'auto-évaluation de la CNIL (juillet 2025) exclut de l'exemption
de consentement « toute mesure à visée marketing », dont la « mesure des
canaux d'acquisition », et recommande de désactiver « toute collecte …
d'UTM ou d'identifiant de campagne dans les URLs ».

Ce que fait le compteur : quand le navigateur n'envoie pas de `Referer`, un
`utm_source` qui figure dans une liste fermée de sites (`pinterest.com`,
`chatgpt.com`, `instagram.com`…) est traduit en ce nom de domaine ; toute
autre valeur est jetée, et `utm_campaign` n'est jamais lu. La colonne
`origin_from` dit, pour chaque compteur, si l'origine vient du `Referer` ou
de ce repli, ce qui permet de mesurer sa part.

Pourquoi : les apps ChatGPT n'envoient presque jamais de `Referer` ; sans
ce repli, ces visites n'auraient pas d'origine du tout. Notre lecture : la
valeur gardée n'en dit pas plus qu'un nom de domaine d'origine, que
l'exemption admet. C'est une lecture, pas une certitude : le risque est
qu'elle soit jugée trop large.

Ce qui permet de revenir en arrière : le réglage `AUDIENCE_TAG_FALLBACK=off`
éteint le repli sans changer le code ; il ne reste alors que le drapeau
« lien marqué ». Décidé par Charles le 2026-11-23, à revoir si la CNIL
précise sa position.

Le détail par épingle ou par campagne ne se lit pas sur le site : il reste
dans Pinterest Analytics, App Store Connect et la Play Console.
