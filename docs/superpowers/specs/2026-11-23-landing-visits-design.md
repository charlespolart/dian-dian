# Compteur de visites du site — design

2026-11-23. Phase de préparation : rien n'est codé avant la passe de
confirmation avec Fable (`docs/ROADMAP.md`). Petit chantier : design court.

## Pourquoi

Le site (`backend/src/routes/landing.ts`, servi sur
`diandian.overridedev.com`) ne garde aucune trace de ses visites : le
journal de requêtes du backend n'existe qu'en dev, et Caddy n'a pas de
journal d'accès. On a découvert par hasard que ChatGPT y envoie des gens
(campagne `chatgptcom` dans App Store Connect, 10 téléchargements entre
mi-octobre et le 22 novembre) et on ne sait pas combien Pinterest en envoie
(ses campagnes restent sous le seuil d'Apple, voir le point 3 de la feuille
de route).

Les mots de Charles : suivre « le nombre d'utilisateurs et la source d'où ils
viennent, différencier les robots ; s'il y a différents robots
identifiables, on peut les suivre aussi ».

## Objectifs, non-objectifs

**Objectifs**
- Compter les visites du site par jour, par source et par épingle.
- Compter les visiteurs uniques par jour, sans cookie.
- Compter les clics vers chaque store, pour avoir le parcours
  visites → clics store → téléchargements (Apple, Google).
- Séparer les robots des personnes, et nommer chaque robot reconnaissable,
  les robots des IA surtout.

**Non-objectifs**
- Savoir qui est le visiteur : il est anonyme, rien ne le relie à un compte
  (sauf le bonus Android plus bas, côté app).
- Un tableau de bord : un script SQL suffit, comme `backend/scripts/prod-*.sql`.
- Suivre le visiteur d'une page à l'autre ou d'un jour à l'autre.

**Anti-objectifs**
- Un bandeau de cookies : aucun cookie, aucun script tiers, aucune adresse
  IP gardée.
- Ralentir la page : le comptage ne doit jamais retarder la réponse.

## Approches

1. **Compteur maison dans le backend — retenu (Charles, 2026-11-23).** Le
   serveur compte à chaque affichage de la page et à chaque clic sur un
   bouton store. Il voit les robots, qui n'exécutent pas de JavaScript, et
   suit le modèle des événements de l'app (`events`, `POST /api/events`).
2. Outil tout fait respectueux de la vie privée (Plausible payant, Umami
   auto-hébergé). Écarté : script sur la page, abonnement ou service de
   plus, il ne voit pas les robots des IA et compte mal les clics vers les
   stores.
3. Journaux d'accès de Caddy. Écarté : ils gardent les adresses IP (donnée
   personnelle), mélangent robots et visiteurs et se lisent mal.

## Ce qu'on enregistre

Pour chaque affichage de la page (`GET /`) et chaque clic sur un bouton
store :

| Donnée | D'où | Exemple |
|---|---|---|
| jour (UTC) | horloge | 2026-11-23 |
| type | route | `visit`, `store_tap` |
| store | route du clic | `apple`, `play` |
| source, campagne | `utm_source`, `utm_campaign`, nettoyés comme aujourd'hui (`campaignParam`) | `pinterest`, `mood-en` ; `chatgptcom` |
| site d'origine | en-tête `Referer`, nom de domaine seul | `pinterest.com`, `chatgpt.com`, `google.com` |
| appareil | `User-Agent` | `iphone`, `ipad`, `android`, `desktop`, `other` |
| navigateur intégré | `User-Agent` | `pinterest`, `instagram`, `facebook`, `tiktok`, rien |
| langue | celle choisie par `detectLang` | `fr` |
| pays | adresse IP → base de géolocalisation, IP jetée aussitôt ; pas plus fin que le pays (voir plus bas) | `FR` |
| robot | `User-Agent` (liste plus bas) | `ChatGPT-User`, rien pour une personne |

*Mon choix* : des compteurs agrégés par jour (une ligne par combinaison,
incrémentée), pas une ligne par visite. Rien de ce qui est stocké ne permet
de retrouver une personne.

**Localisation sans consentement (vérifié le 2026-11-23).** L'adresse IP est
une donnée personnelle, mais la CNIL dispense de consentement la mesure
d'audience qui respecte ses conditions : finalité limitée à la mesure
d'audience pour notre seul compte, statistiques anonymes, aucun croisement
avec d'autres traitements (donc jamais relié à un compte), adresse IP non
conservée (tronquée ou jetée), localisation **pas plus précise que la
ville**. *Mon choix* : le pays seulement (assez pour nos questions ; une
ville croisée avec l'appareil et le jour pourrait désigner quelqu'un, vu nos
petits volumes). La dispense ne supprime pas l'information : une ligne dans
la politique de confidentialité et en pied de page du site (« mesure
d'audience anonyme, sans cookie »). Les lignes directrices européennes
(EDPB 2/2023) rangent aussi le suivi par IP dans le champ de l'ePrivacy :
suivre les conditions de la CNIL couvre ce point pour un éditeur français.

**Visiteurs uniques par jour.** Sans cookie ni IP gardée, on ne reconnaît
pas un visiteur. *Mon choix*, la méthode de Plausible : une empreinte du
jour = hachage(IP + User-Agent + sel du jour), le sel changeant chaque jour
et n'étant jamais stocké ; on ne garde que le nombre d'empreintes
distinctes par jour et par source, et les empreintes sont effacées le jour
suivant. À confirmer au constructeur : si c'est trop lourd, compter des
visites seulement.

**Clics vers les stores.** Les boutons du site pointent vers une adresse du
serveur (`/go/apple`, `/go/play`, avec les mêmes paramètres `utm_*`), qui
compte le clic puis redirige (302) vers le lien store construit comme
aujourd'hui (`storeLinks()` : `pt`/`ct` pour Apple, `referrer` pour Play).
Un clic de robot n'est pas compté comme clic.

## Les robots

Reconnus par leur `User-Agent`, rangés par famille (liste de départ, à
tenir à jour) :

| Famille | Robots | Ce que ça veut dire |
|---|---|---|
| IA, à la demande d'une personne | `ChatGPT-User`, `Claude-User`, `Perplexity-User` | quelqu'un a demandé à une IA de lire la page, à l'instant |
| IA, recherche | `OAI-SearchBot`, `Claude-SearchBot`, `PerplexityBot` | l'IA indexe la page pour ses réponses |
| IA, entraînement | `GPTBot`, `ClaudeBot`, `CCBot`, `Bytespider`, `meta-externalagent`, `Amazonbot` | collecte pour entraîner des modèles |
| Moteurs | `Googlebot`, `bingbot`, `Applebot`, `DuckDuckBot`, `YandexBot` | moteurs de recherche |
| Aperçus de lien | `Pinterestbot`, `facebookexternalhit`, `Twitterbot`, `Slackbot`, `Discordbot`, `WhatsApp`, `TelegramBot` | un lien vers le site a été partagé ou épinglé |
| Autres | tout `User-Agent` qui contient `bot`, `crawler`, `spider` | robot non identifié |

Un `User-Agent` peut être imité : les chiffres des robots sont « déclarés ».
OpenAI publie les adresses de ses robots ; vérifier par adresse est laissé
au constructeur, en option.

## Lecture

Un script `backend/scripts/prod-landing.sql`, lancé comme les autres
(lecture seule) :
- visites et visiteurs uniques par jour et par source, robots à part ;
- parcours par source : visites → clics App Store / Play, à rapprocher des
  téléchargements vus dans App Store Connect et la Play Console ;
- appareils, navigateurs intégrés, pays, langues ;
- robots par famille et par nom, par jour.

## Bonus Android : la source enregistrée avec le compte

Google Play transmet à l'app, au premier lancement, l'étiquette du lien
d'installation (API Install Referrer : `utm_source`, `utm_campaign` venus
du `referrer` que la landing ajoute déjà). L'app l'envoie à la création du
compte, et le serveur la garde avec l'utilisateur. On saurait alors combien
d'utilisateurs Android viennent de Pinterest ou de ChatGPT, et combien
restent. Impossible sur iPhone : Apple ne transmet rien à l'app et interdit
de rapprocher une visite du site d'une installation. Une question
« Comment avez-vous connu Dian Dian ? » a été évoquée pour iPhone,
laissée de côté pour l'instant (elle ajouterait une étape au démarrage, là
où la plupart des gens partent). La politique de confidentialité doit
mentionner la source enregistrée avec le compte.

## Liés

- Regrouper le `ct` Apple par source (`pinterest`, ou `pinterest-en`) pour
  que Pinterest passe le seuil des campagnes d'Apple : point 3 de la
  feuille de route, même fichier (`landing.ts`), à faire dans le même lot.

## Laissé au constructeur

- Le schéma exact de la table de compteurs et sa migration.
- La base de géolocalisation (DB-IP Lite ou MaxMind GeoLite2, gratuites
  sous licence).
- La reconnaissance des navigateurs intégrés et des robots (une fonction
  pure testée unitairement avec des `User-Agent` réels).
- Le comptage hors du chemin de la réponse (pas d'attente de la base avant
  d'envoyer la page).
- Les tests de `/go/apple` et `/go/play` dans `backend/scripts/smoke.ts`.
