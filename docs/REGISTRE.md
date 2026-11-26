# Registre des activités de traitement — Dian Dian

Registre tenu au titre de l'article 30 du RGPD, sur le modèle simplifié de
la CNIL. Il décrit ce que fait la branche `master` du dépôt : chaque
chantier qui ajoute ou change un traitement met sa fiche à jour dans le même
lot. Un test (`backend/src/lib/registre.test.ts`) échoue quand une table de
la base n'est nommée dans aucune fiche.

**Responsable du traitement** : OVERRIDE, SASU, SIREN 953 122 868.
Contact : contact@diandian.overridedev.com. Pas de délégué à la protection
des données désigné.

À ne jamais écrire, ici ni ailleurs : que ces traitements sont « validés par
la CNIL » ou « conformes au RGPD ». La CNIL ne valide rien ; ce registre dit
ce que nous faisons, pourquoi nous pensons être dans le cadre, et là où nous
n'y sommes pas (« Écarts connus », à la fin).

**D'où viennent les faits.** Chaque fiche cite le code. Les durées mesurées
sur le serveur l'ont été le 2026-11-26 (« Relevés du serveur », plus bas).
Les faits des fournisseurs ont été lus sur leurs pages le 2026-11-26 ; leurs
adresses sont dans le tableau des sous-traitants. « À relever par Charles »
marque ce que ni le code ni ces lectures ne disent : rien n'y est deviné.

## Vue d'ensemble

| Fiche | Traitement | Finalité | Base légale | Durée |
|---|---|---|---|---|
| 1 | Mesure d'audience du site | connaître la fréquentation du site | intérêt légitime, sans cookie ni traceur | 25 mois par jour, puis des totaux par mois |
| 2 | Comptes et connexion | ouvrir un compte, s'y connecter, garder ses réglages | contrat | vie du compte |
| 3 | Contenu des trackers | garder et synchroniser ce que la personne note | contrat | vie du compte |
| 4 | Achats et abonnements | donner Premium à qui l'a acheté ; mesurer les ventes | contrat ; intérêt légitime | vie du compte ; 13 mois pour un événement sans compte |
| 5 | E-mails de service | envoyer le code de réinitialisation et la confirmation de suppression | contrat | aucune copie chez nous ; 30 jours chez Resend |
| 6 | Contact et assistance | répondre à qui nous écrit | intérêt légitime | 3 ans après le dernier échange |
| 7 | Événements produit | savoir où l'app bloque ses utilisateurs | intérêt légitime | 13 mois |
| 8 | Statistiques d'usage internes | décider du produit | intérêt légitime | rien de nouveau n'est gardé |
| 9 | Publicité de la version gratuite | financer la version gratuite | consentement, **non recueilli aujourd'hui** | chez Google |
| 10 | Sécurité et journaux | limiter les abus, voir une attaque | intérêt légitime | 15 minutes en mémoire ; journaux 6 mois au plus |
| 11 | Sauvegardes | restaurer la base après une panne | intérêt légitime (sécurité des données) | 30 jours |

## Sous-traitants et destinataires

Personne d'autre que l'éditeur ne lit les données. Les sociétés ci-dessous
les hébergent ou les transportent pour lui (sous-traitants), ou traitent pour
leur propre compte ce que la personne leur confie (responsables de leurs
propres traitements).

| Qui | Rôle | Ce qu'il reçoit | Où | Contrat et transfert hors d'Europe | Source, lue le 2026-11-26 |
|---|---|---|---|---|---|
| Vultr (Vultr Holdings LLC, États-Unis) | sous-traitant : le serveur | tout ce que le serveur traite, base comprise | centre de Paris, France | avenant de traitement (DPA) à demander par ticket, **pas encore demandé** ; clauses contractuelles types d'après sa documentation ; inscription au Data Privacy Framework non confirmée | `docs.vultr.com/support/platform/compliance/does-vultr-offer-a-data-processing-addendum`, `…/are-vultr-services-gdpr-compliant` |
| Cloudflare (Cloudflare, Inc., États-Unis) | sous-traitant : stockage R2 des sauvegardes ; acheminement des e-mails reçus à l'adresse de contact | les sauvegardes, chiffrées avant de quitter le serveur et illisibles sans une clé que Cloudflare n'a pas ; les messages écrits à l'adresse de contact, le temps de les faire suivre (sa documentation décrit un journal d'activité de l'acheminement ; elle ne dit pas si le contenu est gardé, ni combien de temps) | R2 : juridiction Union européenne (le point d'accès du dépôt est en `.eu.r2.cloudflarestorage.com`) | DPA inclus dans ses conditions ; inscrit au Data Privacy Framework, clauses contractuelles types en second | `cloudflare.com/dpa`, `cloudflare.com/trust-hub/gdpr` |
| Resend (Resend, Inc., États-Unis) | sous-traitant : envoi des e-mails | l'adresse du destinataire, l'objet et le corps de chaque e-mail (fiches 5 et 6), gardés 30 jours | États-Unis | DPA en vigueur pour tout compte ; clauses contractuelles types, et inscription au Data Privacy Framework | `resend.com/legal/dpa`, `resend.com/security/gdpr` |
| RevenueCat (RevenueCat, Inc., États-Unis) | sous-traitant : état des achats | l'identifiant du compte (un UUID), les reçus d'achat des stores, des informations techniques sur l'appareil ; jamais l'adresse e-mail (fiche 4) | États-Unis | DPA inclus dans ses conditions (version en vigueur depuis août 2026) ; clauses contractuelles types ; le Data Privacy Framework n'y est pas mentionné. Une demande d'effacement est à notre charge : le DPA ne décrit aucun moyen | `revenuecat.com/dpa`, `revenuecat.com/gdpr` |
| Apple | responsable de ses propres traitements : « Se connecter avec Apple », App Store (vente et encaissement) | de nous : rien. Apple sait que la personne se connecte à Dian Dian ou y achète | — | ses propres conditions | `apple.com/legal/privacy` |
| Google | responsable de ses propres traitements : connexion Google, Google Play (vente et encaissement), AdMob (publicité, fiche 9) | de notre serveur : rien. Par son SDK publicitaire dans l'app : des identifiants de l'appareil et des données d'usage, selon ses règles | — | pour AdMob, « Google Ads Controller-Controller Data Protection Terms » | `support.google.com/admob/answer/9035987`, `business.safety.google/adscontrollerterms` |
| Microsoft (boîte Outlook de l'éditeur) | fournisseur de la boîte où arrivent les messages de contact | les messages de contact et leurs réponses | à relever par Charles | à relever par Charles | aucune : su par l'éditeur, pas par le code |

DB-IP et les opérateurs de robots (fiche 1) ne reçoivent rien : le serveur
télécharge leurs fichiers publics.

## Hébergement, transferts et sauvegardes

Le serveur est une machine virtuelle louée à Vultr dans son centre de Paris.
La base PostgreSQL, le backend et le serveur web (Caddy) y tournent ; seuls
les ports du web et de SSH sont ouverts. Vultr est une société américaine :
son avenant de traitement est **à demander par Charles** et à citer ici avec
sa date.

Toute la base est sauvegardée, chiffrée, vers Cloudflare R2 dans la
juridiction Union européenne (fiche 11). Les e-mails partent par Resend et
les achats passent par RevenueCat, tous deux aux États-Unis : ce sont les
deux transferts hors d'Europe de données rattachées à un compte.

Depuis le 2026-11-26 le site sert lui-même ses polices
(`backend/public/fonts/`) : une visite du site n'envoie plus aucune requête à
un tiers. Avant, chaque page les chargeait chez Google Fonts, qui recevait
l'adresse IP de chaque visiteur.

## Demandes des personnes

Une demande arrive à l'adresse de contact ; elle reçoit une réponse sous un
mois.

- **Effacement** : dans l'app (Réglages, « Supprimer le compte »), immédiat
  et en cascade sur toutes les tables (`backend/src/routes/auth.ts:272`) ; à
  la main pour qui n'a plus accès à l'app. Ce qui reste ensuite est dit dans
  les fiches 4 (RevenueCat) et 11 (sauvegardes, 30 jours).
- **Accès et copie** : à la main. Les lignes du compte sont lues dans la base
  par `psql` et envoyées à la personne. Aucun script n'existe : il n'y a
  encore eu aucune demande.
- **Rectification** : l'app permet de tout modifier, sauf l'adresse e-mail,
  changée à la main sur demande.
- **Opposition aux événements produit** : fiche 7.
- **Opposition à la mesure d'audience du site** : fiche 1.
- **Réclamation** : auprès de la CNIL (`cnil.fr/fr/plaintes`), ce que la
  politique de confidentialité indique.

---

## Fiche 1 — Mesure d'audience du site

| | |
|---|---|
| Créée le | 2026-11-25 |
| Mise à jour | 2026-11-26 |
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
| Ce qui est écrit en base | Des compteurs par jour (`audience_counts`, `audience_totals`), puis par mois (`audience_months`) : type (visite ou clic store), store, site d'origine, lien marqué ou non, classe d'appareil, famille de navigateur, app à navigateur intégré, langue de la page, pays, et pour les robots leur famille, leur nom et le résultat de la vérification. Aucune ligne ne décrit une personne. |

Aucune donnée sensible. Aucun identifiant de visiteur ne dure plus d'un jour.

### Destinataires

Le responsable du traitement, seul. Pas d'outil d'analyse tiers, pas de
script tiers sur la page, et depuis le 2026-11-26 plus aucune ressource
chargée chez un tiers : le site sert lui-même ses polices. Sous-traitant :
l'hébergeur du serveur (voir « Hébergement, transferts et sauvegardes »).

### Durées de conservation

- Compteurs par jour : 25 mois au plus (le mois en cours et les 24
  précédents), puis remplacés par un total par mois (visites, clics par
  store, passages de robots).
- Sauvegardes chiffrées de la base, où ces compteurs figurent : 30 jours
  (fiche 11).
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
base, ils figurent dans ses sauvegardes chiffrées, envoyées vers Cloudflare
R2 dans la juridiction Union européenne (fiche 11). L'avenant de traitement
de Vultr reste à demander : voir « Hébergement, transferts et sauvegardes ».

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

---

## Fiche 2 — Comptes et connexion

| | |
|---|---|
| Créée le | 2026-11-26 |
| Code | `backend/src/routes/auth.ts`, `backend/src/lib/oauth.ts`, `backend/src/lib/jwt.ts`, `backend/src/db/schema.ts` |

**Finalité.** Ouvrir un compte, s'y connecter (adresse e-mail et mot de
passe, Apple ou Google), retrouver l'accès à son compte, et garder ses
réglages d'un appareil à l'autre.

**Base légale.** Exécution du contrat (article 6.1.b) : sans compte, l'app
d'aujourd'hui ne fonctionne pas.

**Personnes concernées.** Les utilisateurs de l'app.

| Donnée | Ce qui en est fait |
|---|---|
| `users` | L'adresse e-mail ; l'empreinte Argon2id du mot de passe, jamais le mot de passe (vide pour un compte ouvert par Apple ou Google) ; `email_verified`, vrai seulement quand Apple ou Google l'affirme (une adresse saisie n'est pas vérifiée aujourd'hui) ; le thème, la langue et le curseur choisis ; la date de création ; `vip`, posé à la main par l'éditeur pour ses comptes de test et ses invités ; `events_opt_out` (fiche 7). |
| `oauth_accounts` | Le fournisseur (Apple ou Google) et l'identifiant stable qu'il donne pour la personne. Du jeton qu'il envoie, le serveur ne lit que l'identifiant et l'adresse e-mail (pour Apple, ce peut être une adresse relais) ; un jeton Google peut porter un nom et une photo, qui ne sont ni lus ni gardés. L'app demande à Apple le nom de la personne (`flutter_app/lib/widgets/oauth_buttons.dart`) mais ne l'envoie jamais au serveur. |
| `refresh_tokens` | L'empreinte SHA-256 du jeton de session, valable 7 jours ; les jetons expirés sont effacés toutes les heures. Le jeton d'accès (15 minutes) n'est écrit nulle part. |
| `password_reset_tokens` | L'empreinte d'un code à 6 chiffres envoyé par e-mail, valable 10 minutes et 5 essais ; effacée toutes les heures une fois expirée. |
| `email_verification_tokens` | Table vide : aucun code ne l'écrit. Elle date d'une vérification d'adresse qui n'a jamais été mise en service ; le chantier 9 la reprend ou la supprime. |
| Sur le téléphone | Le jeton de session, l'adresse e-mail et l'identifiant du compte, dans le stockage sécurisé du système (`flutter_app/lib/services/storage_service.dart`) ; le jeton d'accès en mémoire seulement ; les réglages dans les préférences de l'app. |

**Destinataires.** L'éditeur ; Vultr (hébergement). Apple ou Google quand la
personne choisit de se connecter par eux.

**Durées.** La vie du compte. Aucun compte inactif n'est effacé d'office
aujourd'hui. La suppression, dans l'app, est immédiate et emporte toutes les
tables par cascade (`auth.ts:272`) ; un e-mail de confirmation part ensuite
(fiche 5) ; le compte reste 30 jours dans les sauvegardes (fiche 11).

**Mesures de sécurité.** Argon2id ; jetons gardés sous forme d'empreinte ;
30 tentatives par quart d'heure et par adresse IP sur l'inscription, la
connexion et la connexion par Apple ou Google, 5 sur la demande de code ;
une connexion refusée et une demande de code répondent de la même façon que
le compte existe ou non ; HTTPS partout.

**Limite connue.** L'inscription répond « un compte existe déjà » pour une
adresse déjà prise : quelqu'un peut ainsi savoir si une adresse a un compte.
Le chantier 9 remplace cette inscription par un code envoyé à l'adresse.

## Fiche 3 — Contenu des trackers

| | |
|---|---|
| Créée le | 2026-11-26 |
| Code | `backend/src/routes/pages.ts`, `cells.ts`, `legends.ts`, `bootstrap.ts`, `stats.ts`, `backend/src/lib/ws.ts` |

**Finalité.** Garder ce que la personne note dans ses trackers et le lui
rendre sur tous ses appareils.

**Base légale.** Exécution du contrat (article 6.1.b).

**Personnes concernées.** Les utilisateurs de l'app.

| Donnée | Ce qui en est fait |
|---|---|
| `pages` | Un tracker : son titre, son année, sa position, sa palette, et deux marques techniques (`keep_free`, `client_id`). |
| `cells` | Un jour colorié : la date, la couleur, un commentaire libre, les dates de création et de modification. |
| `legends` | Une entrée de légende : une couleur et son libellé. |
| Synchronisation en direct | Par WebSocket, entre les appareils d'un même compte. Rien n'y est gardé. |
| Sur le téléphone | Depuis l'app 1.3.0, une copie de l'année affichée (trackers, légendes, jours et commentaires) dans le fichier `snapshot_v1.json` du dossier de l'app (`flutter_app/lib/services/snapshot_store.dart`), pour afficher l'app avant la réponse du serveur ; effacée à la déconnexion. Comme le reste des données de l'app, elle peut être emportée par la sauvegarde du téléphone (iCloud ; sur Android, la sauvegarde automatique de Google, que l'app ne désactive pas). Le chantier 10 étend cette copie à tout le compte et complète cette ligne. |

**Destinataires.** L'éditeur, qui ne lit le contenu de personne en
particulier (voir la fiche 8 pour les totaux) ; Vultr (hébergement).

**Durées.** La vie du compte. Un tracker, un jour ou une légende supprimés
dans l'app le sont aussitôt dans la base, et 30 jours plus tard dans les
sauvegardes.

**Risque résiduel : un contenu libre.** L'app ne demande aucune donnée
sensible, mais un titre, un libellé ou un commentaire est un texte libre :
rien n'empêche d'y suivre son humeur, des symptômes ou un traitement, qui
sont des données de santé au sens de l'article 9 du RGPD. La personne les
note alors de sa propre initiative, pour elle seule ; nous ne les cherchons
pas, ne les classons pas et n'en tirons rien. Ce point n'a pas été tranché :
ni analyse d'impact, ni recueil d'un consentement explicite. **À décider par
Charles**, au besoin avec un juriste, d'autant que le site présente
l'humeur et le sommeil comme des usages de l'app.

## Fiche 4 — Achats et abonnements

| | |
|---|---|
| Créée le | 2026-11-26 |
| Code | `backend/src/routes/purchase.ts`, `backend/src/lib/rcEvent.ts`, `backend/src/lib/premium.ts`, `backend/src/lib/retention.ts`, `flutter_app/lib/services/purchase_service.dart` |

**Finalités.** Donner Premium au compte qui l'a acheté ; mesurer les ventes
(essais commencés et convertis, résiliations et leurs raisons, revenu par
mois : `backend/scripts/prod-purchases.sql`).

**Bases légales.** Exécution du contrat pour la première ; intérêt légitime
(article 6.1.f) pour la mesure.

**Personnes concernées.** Les acheteurs.

| Donnée | Ce qui en est fait |
|---|---|
| `subscriptions` | L'état présent : store, produit, identifiant de la transaction d'origine, date de fin, actif ou non. |
| `subscription_events` | Chaque événement que RevenueCat nous envoie, tel qu'il arrive : type, environnement (réel ou bac à sable), store, produit, période d'essai ou non, prix en dollars et dans la devise de l'achat, pays du store, raisons d'annulation et d'expiration, identifiant de transaction, dates. Du reste de l'événement, les champs qui disent de qui il s'agit sont retirés avant l'écriture (`app_user_id`, `original_app_user_id`, `aliases`, `transferred_from`, `transferred_to`, `subscriber_attributes` : `rcEvent.ts`). |
| Ce que nous n'avons jamais | Un moyen de paiement, un nom, une adresse de facturation : Apple et Google vendent et encaissent. |
| Ce que RevenueCat reçoit de l'app | L'identifiant du compte (`Purchases.logIn`, `purchase_service.dart:60`) et les reçus des stores. L'app ne lui donne ni adresse e-mail ni aucun autre attribut. |

**Destinataires.** L'éditeur ; RevenueCat (sous-traitant) ; Apple et Google,
qui sont à l'origine de ces données.

**Durées.** Les lignes d'un compte vivent autant que lui et partent avec lui.
Un événement qui ne nomme aucun de nos comptes (compte supprimé depuis,
achat fait sous un identifiant anonyme, événement de test) est effacé
13 mois au plus après sa réception (la politique et la page de suppression le
disent, avec le fait qu'un abonnement continue de se renouveler après la
suppression du compte) : le mois en cours et les 12 précédents
(`retention.ts`, purge au démarrage puis toutes les heures).

**Écart.** Supprimer un compte n'efface pas le client correspondant chez
RevenueCat, qui garde l'identifiant du compte et l'historique d'achat. À
construire dans le chantier 9, qui donne au serveur la clé d'API de
RevenueCat.

## Fiche 5 — E-mails de service

| | |
|---|---|
| Créée le | 2026-11-26 |
| Code | `backend/src/lib/email.ts` |

**Finalité.** Envoyer deux e-mails : le code de réinitialisation du mot de
passe, et la confirmation qu'un compte a été supprimé. (Un troisième, la
vérification d'adresse, est écrit mais rien ne l'envoie.) Aucun e-mail
publicitaire.

**Base légale.** Exécution du contrat (article 6.1.b).

**Données.** L'adresse du destinataire, l'objet et le corps du message.
L'objet de l'e-mail de réinitialisation contient le code, valable 10 minutes.

**Destinataires.** Resend, sous-traitant, aux États-Unis.

**Durées.** Nous ne gardons aucune copie. Resend garde le contenu et le
journal des e-mails envoyés 30 jours (ses offres Free, Pro et Scale, d'après
`resend.com/security/gdpr`) ; il n'offre pas d'effacer un e-mail avant.

## Fiche 6 — Contact et assistance

| | |
|---|---|
| Créée le | 2026-11-26 |
| Code | `backend/src/index.ts` (`POST /api/contact`), `backend/src/routes/legal.ts` (page `/contact`) |

**Finalité.** Répondre à qui nous écrit, par le formulaire du site ou
directement à l'adresse de contact.

**Base légale.** Intérêt légitime (article 6.1.f) à répondre aux messages
reçus.

**Données.** Le nom, l'adresse et le message que la personne saisit. Rien
n'est écrit dans la base : le formulaire envoie un e-mail par Resend à
l'adresse de contact, que Cloudflare fait suivre vers la boîte Outlook de
l'éditeur (ce dernier point est su par l'éditeur, il n'est pas dans le
code).

**Durées.** 3 ans au plus après le dernier message de l'échange (proposé
par Fable, accepté avec le plan le 2026-11-26). La boîte est un compte
Outlook personnel, qui n'offre aucune suppression automatique à 3 ans (son
« Balayage » ne sait que « plus de 10 jours ») et que le serveur n'atteint
pas : Charles s'en charge dans Outlook (2026-11-26 : « je vais me
débrouiller pour Outlook »).

**Mesures de sécurité.** 5 messages par quart d'heure et par adresse IP ; le
contenu saisi est neutralisé avant d'entrer dans l'e-mail.

## Fiche 7 — Événements produit

| | |
|---|---|
| Créée le | 2026-11-26 |
| Code | `backend/src/routes/events.ts`, `backend/src/lib/retention.ts`, `backend/scripts/prod-events.sql`, `flutter_app/lib/services/events_service.dart` |

**Finalité.** Savoir combien de comptes butent sur chaque limite de la
version gratuite, et sur quelle plateforme, pour régler ces limites et le
paywall.

**Base légale.** Intérêt légitime (article 6.1.f), décidé le 2026-11-23
(`docs/PRICING.md`). Rien n'est lu sur l'appareil : l'événement part de la
session du compte, comme n'importe quelle action de l'app.

**Personnes concernées.** Les utilisateurs de l'app.

| Donnée | Ce qui en est fait |
|---|---|
| `events` | Un nom, le compte, la plateforme (`ios`, `android`, `web`), la version de l'app, la date. Un nom est une suite de mots en minuscules, 64 caractères au plus : aucun contenu, aucune valeur libre. |
| Noms d'aujourd'hui | `paywall.tracker_limit`, `paywall.locked_tracker`, `paywall.themes`, `paywall.cursor`, `paywall.export`, `paywall.stats`, `paywall.global_stats`, `paywall.no_ads`, `paywall.list_upgrade`, `paywall.settings_upgrade` : un mur Premium s'est affiché. Les chantiers suivants (paywall, astuces, compte) en ajoutent et complètent cette fiche. |

**Destinataires.** L'éditeur, seul. Jamais partagés.

**Durées.** 13 mois au plus : le mois en cours et les 12 précédents
(`retention.ts`, purge au démarrage puis toutes les heures). Les événements d'un
compte partent avec lui.

**Droit d'opposition.** La politique de confidentialité dit de nous écrire.
À la demande, Charles lance sur la base, avec l'adresse du compte :

```sql
UPDATE users SET events_opt_out = true WHERE lower(email) = lower('<adresse>');
DELETE FROM events WHERE user_id IN (SELECT id FROM users WHERE lower(email) = lower('<adresse>'));
```

Le serveur n'écrit alors plus aucun événement pour ce compte, et répond à
l'app comme d'habitude.

**Mesures de sécurité.** 120 événements par quart d'heure et par adresse IP.

## Fiche 8 — Statistiques d'usage internes

| | |
|---|---|
| Créée le | 2026-11-26 |
| Code | `backend/scripts/prod-stats.sql`, `prod-activation.sql`, `prod-trackers.sql`, `prod-events.sql`, `prod-purchases.sql`, `backend/src/lib/prodScripts.test.ts` |

**Finalité.** Décider du produit : combien de comptes, combien s'en servent
encore, combien de trackers ils créent, où ils s'arrêtent.

**Base légale.** Intérêt légitime (article 6.1.f).

**Ce qui est fait.** L'éditeur lance ces scripts à la main, par SSH, sur la
base de production. Ils ne font que lire : chacun se déclare en lecture
seule à la base, et un test refuse un script qui écrirait. Les résultats
s'affichent dans son terminal ; des chiffres en sont recopiés dans les
documents du projet, jamais une ligne qui décrit une personne.

**Données lues.** Des totaux et des répartitions sur l'ensemble des comptes
(`users`, `pages`, `cells`, `subscriptions`, `events`,
`subscription_events`). Deux exceptions à connaître :

- `prod-trackers.sql` affiche les titres portés par au moins deux trackers.
  Un titre est un texte libre : un titre rare donné deux fois par la même
  personne s'afficherait.
- `prod-stats.sql` affiche les adresses des comptes écartés des chiffres :
  les comptes de test et les comptes `vip`.

**Destinataires.** L'éditeur, seul.

## Fiche 9 — Publicité de la version gratuite

| | |
|---|---|
| Créée le | 2026-11-26 |
| Code | `flutter_app/lib/services/ad_service.dart`, `flutter_app/lib/widgets/ad_banner.dart`, `flutter_app/ios/Runner/Info.plist`, `backend/src/index.ts` (`/app-ads.txt`) |

**Finalité.** Financer la version gratuite : une bannière Google AdMob pour
les comptes qui ne sont pas Premium, sur iPhone, iPad et Android.

**Ce qui est fait.** L'app démarre le SDK de Google et demande une bannière
sans aucun réglage (`AdRequest()`). Google décide seul de ce qu'il collecte
(identifiants de l'appareil, données d'usage) et en est responsable. Sur
iOS, l'app n'affiche pas l'écran de suivi d'Apple (ATT) : l'identifiant
publicitaire n'y est donc pas accessible. Sur Android, rien ne retient le
SDK de le lire.

**Base légale requise.** Le consentement : la lecture d'un identifiant sur
l'appareil le demande (article 82 de la loi Informatique et Libertés,
recommandation de la CNIL sur les applications mobiles), et Google exige
depuis 2024 un formulaire de consentement certifié pour servir autre chose
que des annonces limitées dans l'Espace économique européen, au Royaume-Uni
et en Suisse.

**Écart.** L'app ne demande aucun consentement. Le « message de
remplacement » que Google propose aux apps sans SDK UMP (réglage
« Autoriser Google à maximiser la couverture des messages », coché, et
interrupteur « Solution de remplacement (consentement) » par app, laissé
désactivé) ne peut rien y changer : Google l'affiche dans une annonce
interstitielle ou d'ouverture d'app, et l'app n'a que des bannières
(`support.google.com/admob/answer/14237900`, lu le 2026-11-26). Décidé par Charles le 2026-11-26 : un chantier « consentement
publicitaire » (chantier 11) entre dans la release unique (le formulaire
de Google, déjà dans le paquet `google_mobile_ads`, affiché avant la
première bannière là où il est requis). Ce chantier complétera cette fiche
et la politique de confidentialité.

**Réglages AdMob** (« Confidentialité et messagerie » → « Réglementations
européennes », 2026-11-26) : les 199 partenaires publicitaires courants
inclus d'office, Google compris ; la couverture des messages maximisée
(message de remplacement) ; les options d'intérêt légitime du TCF
affichées, actives par défaut, que la personne peut refuser une à une ;
ni mode Consentement, ni fonctionnalité spéciale 2 (analyse des
caractéristiques de l'appareil pour l'identifier), ni synchronisation du
consentement entre applications, ni finalité propre à l'éditeur. Deux
cases recommandées par Fable le même jour, cochées ou non par Charles (à
confirmer) : « Ajouter automatiquement des sources d'annonces en tant que
partenaires publicitaires » et « Vérifier le consentement des créations de
partenaires publicitaires pour les partenaires d'enchères en temps réel ».

**Message de consentement**, publié par Charles le 2026-11-26 :
« Dian Dian – GDPR consent », pour les deux apps (Android `app.mydiandian`,
iOS 6761432329), en anglais (langue par défaut), français et chinois
simplifié, pour les pays soumis au RGPD (EEE, Royaume-Uni, Suisse), avec
trois boutons dès le premier écran (refuser, accepter, gérer les options),
le texte de Google sans retouche, et l'adresse de la politique de
confidentialité. Il ne s'affiche qu'à travers le SDK UMP, que l'app
intégrera avec le chantier 11.

## Fiche 10 — Sécurité et journaux

| | |
|---|---|
| Créée le | 2026-11-26 |
| Code | `backend/src/index.ts`, `backend/src/routes/auth.ts:97`, `backend/src/middleware/auth.ts:27`, `ops/Caddyfile` |

**Finalité.** Limiter les abus (essais de mots de passe, envois en masse) et
pouvoir constater une attaque.

**Base légale.** Intérêt légitime (article 6.1.f) à protéger le service et
les comptes.

| Donnée | Ce qui en est fait |
|---|---|
| Adresse IP, limitation des abus | Comptée en mémoire pendant 15 minutes, par route sensible. Jamais écrite. |
| Adresse IP, connexions refusées | Une connexion refusée ou un jeton de session refusé écrit une ligne avec l'adresse IP, sans adresse e-mail, dans la sortie du backend, qui va au journal du système (voir « Durées »). |
| Erreurs du serveur | Une ligne par erreur. Aucune ne nomme un compte volontairement ; l'erreur brute d'une base qui refuse une valeur peut citer cette valeur. |
| Serveur web (Caddy) | Pas de journal d'accès. Son journal de fonctionnement (certificats, erreurs) ne suit pas les requêtes. |
| Base PostgreSQL | Ni les requêtes ni les connexions ne sont journalisées (`log_statement = none`). |
| Système du serveur | Le journal du système garde les tentatives de connexion SSH et les bannissements, avec leurs adresses IP. |
| Journal de requêtes du backend | En développement seulement, jamais en production. |

**Durées.** 6 mois au plus, comme la CNIL le recommande pour des journaux
(entre 6 mois et 1 an). Les trois conteneurs écrivent dans le journal du
système (`logging: driver: journald`, `ops/docker-compose.prod.yml`), qui
efface une entrée au plus tard 179 jours après (`ops/journald/dian-dian.conf` :
`MaxRetentionSec=178d`, un fichier par jour), réglage que `deploy-prod.sh`
installe sur le serveur. Un test (`backend/src/lib/retentionConfig.test.ts`)
tient ces réglages et la durée annoncée ensemble. En service avec le
déploiement de la release unique ; jusque-là, les journaux n'ont pas de
durée maximale (relevés ci-dessous).

## Fiche 11 — Sauvegardes

| | |
|---|---|
| Créée le | 2026-11-26 |
| Code | `ops/pgbackrest/`, `ops/scripts/backup.sh`, `ops/docker-compose.prod-backup.yml` |

**Finalité.** Pouvoir restaurer la base, à la minute près, après une panne
ou une erreur.

**Base légale.** Intérêt légitime (article 6.1.f) ; c'est aussi l'obligation
de sécurité de l'article 32.

**Données.** Toute la base, donc toutes les tables des autres fiches.

**Ce qui est fait.** pgBackRest envoie vers Cloudflare R2 (juridiction Union
européenne) une sauvegarde complète chaque nuit, une différentielle chaque
heure et les journaux de transactions en continu. Tout est chiffré en
AES-256 avant de quitter le serveur ; la clé est sur le serveur et dans le
gestionnaire de mots de passe de l'éditeur, Cloudflare ne l'a pas. Une
restauration a été essayée avec succès le 2026-08-03.

**Durées.** 30 sauvegardes complètes sont gardées, soit **30 jours**
(`repo1-retention-full=30`, `ops/pgbackrest/pgbackrest.conf`) : une donnée
supprimée de la base n'est plus dans aucune sauvegarde 30 jours plus tard,
et un problème découvert tard (un bug qui abîme des trackers, signalé deux
semaines après) peut encore être réparé. C'est la réponse à « et vos
sauvegardes ? » après une suppression de compte. Décidé par Charles le
2026-11-26 (7 jours avant) ; en service avec le déploiement de la release
unique, qui reconstruit le conteneur de la base.

**Anciennes sauvegardes, supprimées le 2026-11-26.** Dix fichiers de
l'ancien système (une copie de la base chiffrée chaque nuit et laissée sur
le serveur, `pg-2026-07-25.sql.age` à `pg-2026-08-03.sql.age`) étaient
restés dans `/srv/dian-dian/backups/` après le passage à pgBackRest le
2026-08-03. Ils contenaient la base de cette époque, comptes supprimés
depuis compris. Supprimés avec leur dossier, et la clé qui les ouvrait
effacée du poste de l'éditeur, avec l'accord de Charles.

**À relever par Charles.** Les sauvegardes automatiques et les instantanés
de Vultr sont-ils activés pour ce serveur ? Si oui, c'est une copie de plus,
avec sa propre durée.

---

## Relevés du serveur (2026-11-26, 16:42 UTC)

Lus sur le serveur de production, sans rien y changer.

| Commande | Résultat |
|---|---|
| `docker inspect -f '{{.HostConfig.LogConfig}}'` sur les trois conteneurs ; `/etc/docker/daemon.json` | pilote `json-file` sans option, pas de `daemon.json` : aucune rotation. Journal du backend : 4 Ko, première ligne du 2026-11-23, jour du dernier déploiement |
| `journalctl --disk-usage` ; `/etc/systemd/journald.conf` | 2,2 Go, première entrée du 2026-05-14 ; réglages par défaut, aucune durée maximale |
| `pgbackrest --stanza=dian-dian info` | état `ok` ; 7 sauvegardes complètes, du 20 au 26 novembre ; 29 différentielles |
| `ls /srv/dian-dian/backups/` | 10 fichiers `pg-2026-07-25.sql.age` à `pg-2026-08-03.sql.age` ; supprimés le même jour (fiche 11) |
| `pg_settings` | `log_statement = none`, `log_min_duration_statement = -1`, `log_connections = off` |
| `ops/Caddyfile` sur le serveur | aucune directive `log` |

## Écarts connus et décisions attendues

| Écart | Fiche | Ce qui le règle | Qui |
|---|---|---|---|
| L'app affiche de la publicité sans demander de consentement | 9 | le chantier « consentement publicitaire », dans la release unique | Fable, puis Charles pour les essais sur appareil |
| Supprimer un compte n'efface pas le client chez RevenueCat | 4 | une demande d'effacement à RevenueCat à chaque suppression, dans le chantier 9 | Fable |
| Les journaux n'ont pas de durée maximale tant que la release n'est pas déployée | 10 | le déploiement de la release unique (6 mois au plus ensuite) | Charles, en déployant |
| L'avenant de traitement de Vultr n'est pas demandé | « Sous-traitants » | un ticket chez Vultr | Charles |
| Ce que Cloudflare garde d'un e-mail qu'il achemine n'est pas établi | « Sous-traitants » | lire son avenant de traitement, ou lui poser la question | Fable, au prochain passage sur ce registre |
| Sauvegardes automatiques de Vultr, boîte de contact chez Microsoft | 11, « Sous-traitants » | les relever dans les tableaux de bord | Charles |
| Les messages de contact ne s'effacent pas tout seuls au bout de 3 ans (Outlook personnel ne le permet pas) | 6 | Charles s'en charge dans Outlook | Charles |
| Des données de santé peuvent être notées dans un contenu libre | 3 | une décision, au besoin avec un juriste | Charles |
| L'inscription dit si une adresse a déjà un compte | 2 | l'inscription par code du chantier 9 | Fable |

## Violations de données

Aucune violation connue au 2026-11-26.

Si une fuite ou une perte de données est découverte : noter l'heure de la
découverte (les 72 heures partent de là), changer les secrets exposés,
établir ce qui a fui et pour qui, puis notifier la CNIL sous 72 heures s'il y
a un risque pour les personnes
(`cnil.fr/fr/notifier-une-violation-de-donnees-personnelles`), et les
personnes elles-mêmes si le risque est élevé. Chaque incident est inscrit
ici avec sa date, son périmètre et ce qui a été décidé, même quand il n'est
pas notifié, avec la raison.

| Date | Ce qui s'est passé | Données et personnes touchées | Notifié ? | Suites |
|---|---|---|---|---|
| — | — | — | — | — |
