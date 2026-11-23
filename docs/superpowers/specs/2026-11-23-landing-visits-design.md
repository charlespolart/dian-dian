# Compteur de visites du site — design

2026-11-23, révisé le même jour après la recherche
`docs/research/reports/Mesure de trafic auto hébergée.md` (notes dans
`docs/research/notes/Mesure de trafic auto hébergée/`). Phase de
préparation : rien n'est codé avant la passe de confirmation avec Fable
(`docs/ROADMAP.md`).

## Pourquoi

Le site (`backend/src/routes/landing.ts`, servi sur
`diandian.overridedev.com`) ne garde aucune trace de ses visites : le
journal de requêtes du backend n'existe qu'en dev, et Caddy n'a pas de
journal d'accès. On a découvert par hasard que ChatGPT y envoie des gens
(campagne `chatgptcom` dans App Store Connect, 10 téléchargements entre
mi-octobre et le 22 novembre) et on ne sait pas ce que donne Pinterest (ses
campagnes restent sous le seuil d'Apple, point 3 de la feuille de route).

Les mots de Charles : suivre « le nombre d'utilisateurs et la source d'où ils
viennent, différencier les robots ; s'il y a différents robots
identifiables, on peut les suivre aussi ». Le pays suffit, pas la ville.

## Décisions du 2026-11-23

Charles : « pour les 4 points, fais comme tu recommandes ».

1. **Compteur maison** dans le backend, pas d'outil open source. Les outils
   complets (Plausible CE, Rybbit, Swetrix, OpenPanel, PostHog sur
   ClickHouse ; Matomo) demandent 2 Go de RAM ou plus, le VPS a 1 vCPU et
   ≈ 950 Mo dont ≈ 490 libres ; Umami v3 y tiendrait de justesse
   (270–360 Mo, fuites signalées) ; et aucun outil qui tient ne nomme les
   robots (Umami, Plausible, GoatCounter, Liwan les jettent), donc la table
   des robots serait à écrire de toute façon.
2. **Sources : lecture stricte de la CNIL**, détail par source et par épingle
   lu côté stores et Pinterest ; une option de repli écrite mais éteinte
   (voir « Sources et CNIL »).
3. **Pas d'interface.** Les chiffres sont lus par Claude Code ou par des
   scripts automatiques, jamais par Charles sur le serveur : un script SQL en
   lecture seule suffit, pas de page d'admin ni de tableau de bord.
4. **Réutilisation : un module autonome et un playbook** ; un paquet partagé
   seulement quand un deuxième projet l'adopte (voir « Réutilisation »).

## Objectifs, non-objectifs

**Objectifs**
- Compter les visites et les visiteurs uniques du jour.
- Savoir d'où viennent les visiteurs dans les limites de l'exemption CNIL :
  site d'origine, navigateur intégré, « arrivé par un lien marqué ».
- Compter les clics vers chaque store (parcours visites → clics store ;
  les téléchargements se lisent chez Apple et Google).
- Séparer les robots des personnes, les nommer et les vérifier, les robots
  des IA surtout (ChatGPT-User = une personne a demandé à ChatGPT de lire la
  page).

**Non-objectifs**
- Savoir qui est le visiteur, ou relier une visite à un compte.
- Compter par épingle ou par campagne sur le site (fait par Pinterest
  Analytics, App Store Connect et la Play Console).
- Un écran.

**Anti-objectifs**
- Un bandeau de consentement : aucun cookie de mesure, aucun script tiers.
- Garder une adresse IP, un `User-Agent` complet ou une valeur `utm_*`.
- Ralentir la page : le comptage se fait hors du chemin de la réponse.

## Approches

1. **Compteur maison dans Express — retenu.** Middleware sur `GET /`,
   redirections `/go/apple` et `/go/play`, compteurs agrégés dans le
   PostgreSQL existant (sauvegardé par pgBackRest avec le reste). Seule
   option qui voit et nomme les robots sur ce serveur.
2. Un outil open source auto-hébergé. Écarté pour la mémoire et parce qu'il
   jette les robots (pas pour les clics : ces outils acceptent des
   événements envoyés par le serveur).
3. Journaux d'accès de Caddy (+ GoAccess). Écarté : ils gardent les IP et
   GoAccess mêle les robots des IA dans un seul panier.

## Ce qu'on enregistre

Deux types d'événements seulement : `visit` (affichage de la page) et
`store_tap` (passage par `/go/apple` ou `/go/play`).

| Donnée | D'où | Exemple |
|---|---|---|
| jour (UTC) | horloge | 2026-11-23 |
| type, store | route | `visit` ; `store_tap` + `apple` / `play` |
| site d'origine | en-tête `Referer`, nom de domaine seul | `pinterest.com`, `chatgpt.com` |
| lien marqué | présence d'un `utm_source` dans l'URL, **sans sa valeur** | oui / non |
| appareil | `User-Agent`, classe seulement | `iphone`, `ipad`, `android`, `desktop`, `other` |
| navigateur | famille seulement, jamais de version fine | `safari`, `chrome`… |
| navigateur intégré | `User-Agent` | `pinterest`, `instagram`, `facebook`, `tiktok` |
| langue | `detectLang` | `fr` |
| pays | IP → DB-IP Lite, IP jetée | `FR` |
| robot | famille, nom, vérifié / non vérifié / invérifiable | `ai_user` `ChatGPT-User` vérifié |

Compteurs agrégés par jour (une ligne par combinaison, incrémentée), plus
une ligne « total du jour » pour les visiteurs uniques. Reconnaissance du
`User-Agent` par expressions maison ou `bowser` (MIT) ; **pas** `ua-parser-js`
v2 (AGPL).

## Sources et CNIL

La grille d'auto-évaluation de la CNIL (juillet 2025), référence de
l'exemption de consentement, exclut « toute mesure à visée marketing », dont
la « mesure des canaux d'acquisition », et recommande de désactiver « toute
collecte … d'UTM ou d'identifiant de campagne dans les URLs ». Compter par
`utm_source` ou par épingle sur le site en sortirait.

- **Retenu (options 1 et 5 du rapport)** : le site garde le site d'origine,
  le navigateur intégré, les clics par store et un drapeau « lien marqué »
  (comme le mode CNIL de Matomo). Le détail par source et par épingle se lit
  dans Pinterest Analytics, App Store Connect (avec le `ct` regroupé par
  source, point 3 de la feuille de route) et la Play Console (dimensions UTM
  source / campaign). Le site continue de relayer `utm_*` vers les liens
  stores sans rien stocker.
- **Option de repli, écrite mais éteinte** (réglage, désactivé par défaut) :
  quand le `Referer` manque, traduire `utm_source` en un nom de site d'une
  liste fermée (`pinterest.com`, `chatgpt.com`, `instagram.com`…), jamais
  `utm_campaign`. À décider après 4 à 6 semaines : si une grosse part des
  visites « lien marqué » arrive sans site d'origine ni navigateur intégré,
  l'activer en écrivant le risque résiduel au registre ; sinon la laisser
  éteinte.

## Visiteurs uniques

`SHA-256(sel du jour ‖ domaine ‖ IP ‖ User-Agent)`. Le sel est tiré au hasard
à minuit UTC et vit **en mémoire seulement**, jamais dérivé d'un secret ni de
la date, jamais écrit en base (sinon il partirait dans les WAL et les
sauvegardes pgBackRest). Les empreintes du jour vivent aussi en mémoire ; la
base ne reçoit que des comptes. Un redémarrage du backend recommence le
compte du jour : accepté. Indicateur seulement : une même IP mobile fusionne
des gens, un passage du navigateur de Pinterest à Safari compte double.

## Clics vers les stores

Les boutons du site pointent vers `/go/apple` et `/go/play` (mêmes
paramètres `utm_*`), qui comptent puis redirigent en 302 vers le lien store
construit comme aujourd'hui (`storeLinks()` : `pt`/`ct` regroupé pour Apple,
`referrer` pour Play). La redirection reste sur le domaine de la landing
(Apple retient la dernière URL de la chaîne comme « Web referrer »).
Préchargements et robots ne comptent pas comme clics.

## Robots

Jetons cherchés dans le `User-Agent` (liste de départ, relue chaque
trimestre) :

| Famille | Jetons | Vérifiable par IP |
|---|---|---|
| IA à la demande d'une personne | ChatGPT-User, Claude-User, Perplexity-User, MistralAI-User, DuckAssistBot, Amzn-User, meta-externalfetcher, Google-Agent, Google-GeminiNotebook ; agent ChatGPT par l'en-tête `Signature-Agent: "https://chatgpt.com"` | oui, sauf Meta ; Amazon en page HTML |
| IA, recherche | OAI-SearchBot, Claude-SearchBot, PerplexityBot, MistralAI-Index, Amzn-SearchBot, meta-webindexer | OpenAI, Anthropic, Perplexity |
| IA, entraînement | GPTBot, ClaudeBot, anthropic-ai, CCBot, Bytespider, meta-externalagent, Amazonbot, MistralAI-Training | OpenAI, Anthropic, Common Crawl |
| Moteurs | Googlebot, bingbot, Applebot, DuckDuckBot, YandexBot | Google, Apple (aussi DNS inverse) |
| Aperçus de lien | Pinterestbot, Pinterest/0.2, facebookexternalhit, WhatsApp, Discordbot, Twitterbot, Slackbot, TelegramBot, GoogleMessages | Pinterest par DNS inverse |
| Autres | OAI-AdsBot, GoogleOther, Google-CloudVertexBot, puis ce que `isbot` reconnaît, sous le nom trouvé | — |
| Faux à coup sûr | Google-Extended ou Applebot-Extended dans un `User-Agent` (ce sont des jetons robots.txt) | — |

Vérification : les listes JSON d'IP publiées par huit opérateurs (OpenAI ×3,
Perplexity ×2, Anthropic, Google, Apple, DuckDuckGo, Common Crawl, Mistral),
rechargées chaque jour dans `net.BlockList` de Node ; chaque robot est
étiqueté vérifié / non vérifié / invérifiable, puis l'IP est jetée.
ChatGPT-User, le nom le plus imité, n'est compté comme tel que vérifié.
Gemini et les réponses IA de Google ne relisent pas la page : ils ne
laissent aucune trace.

## Pays

DB-IP IP-to-Country Lite (CC BY 4.0, sans compte, fichier MMDB de 8 Mo,
mise à jour mensuelle par une tâche planifiée), lue avec le paquet npm
`maxmind` (MIT ; vérifier qu'il lit bien le fichier de DB-IP). La licence
demande un lien « IP Geolocation by DB-IP » sur la page. Pas de MaxMind
GeoLite (licence restrictive).

## Lecture

Pas d'écran. `backend/scripts/prod-landing.sql`, en lecture seule, lancé
comme les autres scripts `prod-*.sql` (par Claude Code ou un script
automatique) :
- totaux du jour exacts : visites, visiteurs uniques, clics par store ;
- croisements (site d'origine, navigateur intégré, appareil, pays, lien
  marqué) au mois, cellules sous 10 affichées « <10 » ;
- robots par famille et par nom, vérifiés à part.

Conservation : lignes du jour 25 mois au plus, puis totaux mensuels.

## Volet légal

| Point | À faire |
|---|---|
| Finalité | Statistiques du site pour le seul compte de Dian Dian ; jamais reliées à un compte, à l'Install Referrer ou à un tiers |
| Opposition | Lien dans la politique de confidentialité, cookie d'opposition respecté par le compteur ; respecter aussi Global Privacy Control et Do Not Track |
| Information | Section dédiée dans la politique de confidentialité, en quatre langues (`legal.ts`, qui dit aujourd'hui que les cookies ne servent qu'à la connexion) ; mention du cookie d'opposition ; lien DB-IP ; ligne en pied de page du site |
| Registre | Une entrée « Mesure d'audience du site » dans le modèle simplifié de la CNIL |
| IP | Jamais dans les journaux du backend ni de Caddy |
| Hébergement | Vérifier la région du VPS Vultr et son avenant de traitement des données |
| Communication | Ne jamais écrire « validé par la CNIL » |

## Attribution des installations

- **iOS** : App Store Connect seulement, avec le `ct` regroupé par source
  (même lot, même fichier). Aucun rapprochement visite-installation :
  Apple l'interdit (empreinte).
- **Android** : la Play Console d'abord. Lire l'Install Referrer et
  l'enregistrer avec le compte devient un traitement **séparé**, plus tard :
  après la montée à Dart 3.12 (`play_install_referrer` 0.6.0) et une réponse
  sur l'article 82. Pas dans ce lot.

## Réutilisation

- Le compteur s'écrit comme un dossier autonome du backend (par exemple
  `backend/src/audience/`) qui ne dépend de Dian Dian que par la connexion à
  la base, avec une configuration explicite : domaine, fabrique des liens
  stores, liste fermée des sites d'origine, table des familles de robots.
  `isbot` et `crawler-user-agents` restent des dépendances npm.
- **Playbook** : `/Users/charlespolart/Documents/Coding/playbook` (base de
  connaissances partagée entre Charles et Claude Code). **Fable** y ajoute
  la fiche « mesure d'audience d'un site » : liste de contrôle CNIL, texte de
  politique de confidentialité, migration, règles du classifieur de robots,
  rafraîchissement de DB-IP et des listes d'IP, script SQL. Rien n'y est
  écrit pendant la phase de préparation ; selon la règle du playbook, l'ajout
  est proposé à Charles, pas fait en cachette. Emplacement à choisir par
  Fable (probablement `infrastructure/`, avec un renvoi depuis
  `legal/rgpd.md` et l'index du README).
- Un paquet privé seulement quand un deuxième projet l'adopte.

## Effort (estimations)

| Lot | Estimation |
|---|---|
| Compteur (migration, middleware, classifieur, navigateurs intégrés, `/go/`, DB-IP, purge, `prod-landing.sql`, tests smoke) | 1,5 à 2,5 jours |
| Vérification des robots (listes JSON, `BlockList`, `Signature-Agent`) | ½ jour |
| Volet légal | ½ jour |
| Regroupement du `ct` Apple par source | quelques heures |
| Module autonome et playbook | ½ jour |
| **Total** | **3 à 4 jours** |

## Questions ouvertes

- Le navigateur intégré de Pinterest envoie-t-il un `Referer` et un jeton
  reconnaissable ? Ouvre-t-il l'App Store ?
- ChatGPT envoie-t-il un `Referer` aujourd'hui (un bug d'octobre 2026 a
  supprimé UTM et référent quelques jours) ?
- Le relais des `utm_*` vers les liens stores, en production depuis le
  15 octobre, demande-t-il un avis ?
- Région du VPS Vultr et avenant de traitement.

## Laissé au constructeur

- Le schéma exact des tables et la migration.
- La fonction de classification (`User-Agent` → appareil, navigateur,
  navigateur intégré, robot), pure et testée avec de vrais `User-Agent`.
- Le comptage hors du chemin de la réponse.
- Les tâches planifiées (DB-IP mensuel, listes d'IP quotidiennes, purge à
  25 mois).
- Les tests de `/go/apple` et `/go/play` dans `backend/scripts/smoke.ts`.
