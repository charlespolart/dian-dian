# Vérification des faits cités dans les docs — 2026-11-23

Vérification sur le web (docs officielles Apple / Google / Flutter, pub.dev, code
source des paquets, rapports RevenueCat) des affirmations reprises dans
`docs/PRICING.md`, `docs/ROADMAP.md`, `ANDROID_RELEASE_PLAN.md`,
`docs/superpowers/specs/2026-11-23-reminders-design.md` et les rapports de
`docs/research/`. Aucun fichier existant n'a été modifié.

Verdicts : **CONFIRMÉ**, **PARTIEL** (vrai en partie ou à préciser),
**FAUX**, **INVÉRIFIABLE**.

| N° | Verdict | Fait correct | Source (date) |
|---|---|---|---|
| 1 | **PARTIEL** | La dernière version est **23.0.4** (2026-11-23), pas 23.0.3 (2026-11-18). L'exigence AGP 9.1.1 est exacte (depuis 23.0.0 du 2026-11-06). Elle va avec compileSdk ≥ 37, le desugaring (`desugar_jdk_libs` 2.1.4), Java 17, minSdk 24 et Flutter ≥ 3.44 / Dart ≥ 3.12. Le plugin ne fixe pas de version de Gradle, mais AGP 9.1.x impose **Gradle ≥ 9.3.1**. | [pub.dev changelog](https://pub.dev/packages/flutter_local_notifications/changelog) (23.0.4, 2026-11-23) ; [README](https://pub.dev/packages/flutter_local_notifications) ; [AGP 9.1](https://developer.android.com/build/releases/agp-9-1-0-release-notes) |
| 2 | **CONFIRMÉ** (corrections pour Gradle et compileSdk) | Flutter accepte AGP 9 depuis **3.44** (stable du 2026-05-18), en mode compatible (`android.builtInKotlin=false`, `android.newDsl=false`). Le Kotlin intégré marche depuis **3.47** (2026-08-12). La stable actuelle est 3.50.1 (2026-11-20). En revanche, « Gradle 9.1 » (ANDROID_RELEASE_PLAN §8, ROADMAP) ne suffit pas pour AGP 9.1.1, qui demande Gradle ≥ 9.3.1. Flutter fixe encore `flutter.compileSdkVersion` à 36 : il faut écrire `compileSdk = 37` à la main. | [Flutter, built-in Kotlin](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin) (2026-08-20) ; [guide app](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers) (2026-11-20) ; `gradle_utils.dart` aux tags 3.44.0 / 3.47.0 / 3.50.1 |
| 3 | **PARTIEL** (l'essentiel est faux) | Android : le plugin gère `visibility: NotificationVisibility.private`, mais **pas de version publique** (aucun paramètre, seul `setVisibility` est appelé). iOS : **pas de `hiddenPreviewsBodyPlaceholder`** (`DarwinNotificationCategory` = identifier, actions, options). Les API natives existent (`setPublicVersion` API 21, placeholder iOS 11+). `timezone` **0.11.2** (2026-10-12) ; `flutter_timezone` **5.1.1** (2026-10-03). | [AndroidNotificationDetails](https://pub.dev/documentation/flutter_local_notifications/latest/flutter_local_notifications/AndroidNotificationDetails/AndroidNotificationDetails.html) ; [DarwinNotificationCategory](https://pub.dev/documentation/flutter_local_notifications/latest/flutter_local_notifications/DarwinNotificationCategory/DarwinNotificationCategory.html) ; sources du plugin (master, 2026-11-23) ; [pub.dev timezone](https://pub.dev/packages/timezone), [flutter_timezone](https://pub.dev/packages/flutter_timezone) |
| 4 | **CONFIRMÉ** | Notifications « coupées par défaut » pour une nouvelle installation sur Android 13+. Deux refus = refus définitif ; fermer le dialogue d'un geste ne compte pas comme un refus. Une alarme inexacte ne part jamais avant l'heure demandée, et part dans l'heure qui suit sur Android 12+, **sauf économiseur de batterie ou Doze** (alors plus tard). | [Notification permission](https://developer.android.com/develop/ui/views/notifications/notification-permission) ; [Requesting permissions](https://developer.android.com/training/permissions/requesting) ; [Schedule alarms](https://developer.android.com/develop/background-work/services/alarms/schedule) (consultés 2026-11-23) |
| 5 | **CONFIRMÉ** | Le dialogue n'apparaît qu'à la première demande. L'autorisation provisoire existe depuis iOS 12 (livraison silencieuse, Centre de notifications seulement). Limite de **64** notifications en attente par app (ingénieur Apple, janvier 2026). | [Apple, Asking permission](https://developer.apple.com/documentation/usernotifications/asking-permission-to-use-notifications) ; [Forum Apple 811171](https://developer.apple.com/forums/thread/811171) (réponse de janvier 2026) ; [UILocalNotification](https://developer.apple.com/documentation/uikit/uilocalnotification) |
| 6 | **CONFIRMÉ** | 2,99 €, 14,99 € et 29,99 € existent sur la vitrine France, y compris pour des abonnements. On peut fixer un prix à la main par pays (un par un, pas de groupe « zone euro »). Les changements se programment à l'avance. L'option « Keep the current price for existing subscribers » existe. Précision : **Apple ne réajuste jamais les prix des abonnements auto-renouvelables** ; ses réajustements ne touchent que le lifetime. | [Subscriptions pricing](https://developer.apple.com/help/app-store-connect/manage-subscriptions/manage-pricing-for-auto-renewable-subscriptions) ; [IAP price](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/set-a-price-for-an-in-app-purchase) ; [Schedule IAP price changes](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/schedule-price-changes-for-in-app-purchases) ; fiches App Store FR (Bear, Caiyun), 2026-11-23 |
| 7 | **PARTIEL** | Les modèles de prix ont bien été retirés le **27 octobre 2025**. Mais ils n'ont jamais ajusté les prix au taux de change : ils partageaient un même prix entre produits. Google génère les prix locaux une fois (taux du jour) ; on peut les « rafraîchir » à la main, mais aucun réajustement périodique n'est documenté. Par défaut, les abonnés existants gardent bien leur prix (cohorte de prix antérieur). Une hausse appliquée à ces abonnés demande par défaut leur accord. | [Play Console, Set up prices](https://support.google.com/googleplay/android-developer/answer/6334373) ; [Change subscription prices](https://developer.android.com/google/play/billing/price-changes) |
| 8 | **CONFIRMÉ** (précisions) | Frais de service de 10 % sur le premier million de dollars de gains annuels et sur tous les abonnements, plus des frais de facturation de 5 % pour Play Billing. En vigueur aux États-Unis, au Royaume-Uni et dans l'EEE depuis le **30 juin 2026**. Puis : Australie et Japon le 30 septembre 2026, Corée, Turquie et Afrique du Sud le 31 décembre 2026, reste du monde le 30 septembre 2027. Total : 15 %, comme avant. | [Blog Android, 2026-06-24](https://android-developers.googleblog.com/2026/06/play-expanded-billing.html) ; [Play Console Help 16954621](https://support.google.com/googleplay/android-developer/answer/16954621) |
| 9 | **CONFIRMÉ** (source non officielle) | Le texte des Guidelines n'a pas changé (mise à jour du 16 octobre 2026, aucun « toggle »). App Review rejette ces paywalls au titre de la **3.1.2** depuis **mi-janvier 2026**. Plusieurs sources le rapportent : rejets cités par RevenueCat et Adapty, et propos d'un contact senior chez Apple rapportés par Superwall, hors micro. | [RevenueCat, 2026-02-09](https://www.revenuecat.com/blog/growth/r-i-p-toggle-paywall-we-hardly-knew-ye/) ; [Adapty](https://adapty.io/blog/your-toggle-paywall-is-about-to-get-rejected/) ; [Superwall, 2026-06-03](https://superwall.com/blog/external-checkout-a-b-testing-and-trial-toggles-confirmed-apples-rules-for-ios) ; [Guidelines](https://developer.apple.com/app-store/review/guidelines/) |
| 10 | **CONFIRMÉ** (une précision) | Nom : **Retention messages** (section « Retention Messaging », Monetization › Subscriptions), disponibles depuis le **4 novembre 2026**. En-tête ≤ 66 caractères, corps ≤ 144. Interdit dans l'en-tête **comme** dans le corps : offre, remise ou prix. Images de 3840×2160 ou 5244×2950. | [ASC Help, Configure retention messages](https://developer.apple.com/help/app-store-connect/manage-subscriptions/configure-retention-messages) ; [Apple news, 2026-11-04](https://developer.apple.com/news?id=fk9ps3gv) ; [Retention Messaging API, header](https://developer.apple.com/documentation/retentionmessaging/header) / [body](https://developer.apple.com/documentation/retentionmessaging/body) |
| 11 | **FAUX** | C'est presque l'inverse. **Google Play envoie un e-mail** quand l'essai va finir : « If you accept a trial offer, you'll get an email when your trial is about to end. » **Apple ne documente aucun rappel**. Sa page d'aide dit seulement d'annuler au moins 24 h avant la fin de l'essai. RevenueCat affirme qu'iOS envoie une notification push, sans source Apple. | [Google Play Help 2476088](https://support.google.com/googleplay/answer/2476088?hl=en&co=GENIE.Platform%3DAndroid) ; [Blog Android, 2020-04-16](https://android-developers.googleblog.com/2020/04/building-user-trust-through-more.html) ; [Apple support 118428](https://support.apple.com/en-us/118428) (2026-09-29) ; [RevenueCat, 2026-03-25](https://www.revenuecat.com/blog/engineering/android-paywall-gap) |
| 12 | **CONFIRMÉ** (le 82 % vient d'une autre édition) | SOSA 2026 : ≤ 4 jours 25,5 %, 5–9 jours 37,4 %, 17–32 jours 42,5 % ; santé-forme 37,7 %. Le « 82 % des essais le jour de l'installation » vient de **SOSA 2025** (toutes apps). SOSA 2026 ne donne pas de chiffre global (« nearly all ») ; pour la santé-forme, il donne **82,1 %** le jour 0. | [SOSA 2026](https://www.revenuecat.com/state-of-subscription-apps-2026/) (mars 2026) ; [SOSA 2025](https://www.revenuecat.com/state-of-subscription-apps-2025/) |
| 13 | **CONFIRMÉ** | Freemium, téléchargement → payant à J35 : médiane 2,1 %, quartile supérieur > 4,5 %. Pour comparaison : paywall dur 10,7 %, toutes apps 2,0 %. | [SOSA 2026](https://www.revenuecat.com/state-of-subscription-apps-2026/) (mars 2026) |
| 14 | **CONFIRMÉ** (préciser la mesure) | Avec une promotion détectée au Nouvel An, les apps gagnent **+14 % de nouveaux clients payants par jour** ; sans promotion, −4 %. Mesure : app médiane, contre la base de chaque app du 15 septembre au 12 octobre, période du 26 décembre au 1er février. 236 apps sur 4 964 avaient une promotion. C'est une corrélation, pas un effet mesuré. | [RevenueCat, M. Loktionova, 2026-10-27](https://www.revenuecat.com/blog/growth/holiday-offers-subscription-apps) |

---

## Notes par affirmation

### 1. flutter_local_notifications : version et exigences Android

- Versions (API pub.dev) : 23.0.0 du 2026-11-06, 23.0.1 du 11-11, 23.0.2 du 11-13,
  23.0.3 du 11-18, **23.0.4 du 2026-11-23 à 09:47 UTC**. La 23.0.4 corrige une
  régression de la 23.0.3 sur iOS et macOS avec les calendriers non grégoriens.
  La 23.0.3 est donc à éviter.
- Changements cassants de la 23.0.0, d'après le changelog :
  - « Breaking change bumped to AGP 9.1.1 » ;
  - « bumped `compileSdk` to 37 » ;
  - Flutter ≥ 3.44.0 et Dart ≥ 3.12.0 ;
  - passage au Kotlin DSL ;
  - l'app d'exemple quitte le plugin Kotlin (KGP) pour le Kotlin intégré.
- Le `android/build.gradle.kts` du plugin contient :
  - AGP 9.1.1, `compileSdk = 37`, `minSdk = 24`, Java 17 ;
  - `isCoreLibraryDesugaringEnabled = true` et `desugar_jdk_libs:2.1.4`.

  Le code du plugin est en Java : il n'impose pas de version de Kotlin.
- Le README demande à l'app :
  - AGP 9.1.1 au minimum ;
  - `compileSdk = 37` ;
  - le desugaring avec `desugar_jdk_libs` 2.1.4 ;
  - Java 17 ;
  - un bloc `kotlin { compilerOptions { jvmTarget = JVM_17 } }`, « seulement si
    l'app a des sources Kotlin ». C'est le cas de Dian Dian, à cause de
    `MainActivity.kt`.
- AGP 9.1 exige Gradle 9.3.1 au minimum, JDK 17 et KGP 2.2.10 au moins
  (dépendance d'exécution). AGP 9.0 plafonne à l'API 36.1 : compileSdk 37
  demande donc AGP 9.1.1 ou plus. Dernier AGP : 9.5.1, qui exige Gradle 9.6.0.
- **Piège pour la release R8** : avec `isShrinkResources = true`, le README
  demande de garder l'icône de notification dans un `keep.xml`. Sans cela, les
  notifications peuvent échouer en silence. Les règles ProGuard de Gson sont
  fournies automatiquement depuis la v19.
- Docs concernées :
  - spec rappels l. 77 ;
  - rapport « Notifications de rappel et fidélisation » l. 120 ;
  - ROADMAP l. 170 ;
  - `autorisation_optin.md` l. 209, 287 et 293.

  Mettre « 23.0.4 ou plus récent » à la place de « 23.0.3 ».

### 2. Flutter et AGP 9

- Depuis Flutter 3.44.0 (stable du 2026-05-18), une app peut passer en AGP 9.
  L'outil de migration de Flutter ajoute alors `android.newDsl=false` et
  `android.builtInKotlin=false` dans `gradle.properties`, au prochain
  `flutter run` ou `flutter build`.
- `android.builtInKotlin=true` demande Flutter 3.47 ou plus. Le projet tourne
  en local sous Flutter 3.47.5 : c'est suffisant.
- Étapes de migration pour l'app :
  1. Retirer `id("kotlin-android")` de `app/build.gradle.kts`.
  2. Remplacer `kotlinOptions` par
     `kotlin { compilerOptions { jvmTarget = JvmTarget.JVM_17 } }`.
  3. Passer `android.builtInKotlin=true`.
  4. Vérifier que chaque plugin utilisé est migré. Un plugin qui applique encore
     KGP fera échouer le build. Flutter retirera le support de KGP « dans une
     version future », sans date annoncée.
- L'ancienne page Flutter « migrate-to-agp-9 » renvoie une 404. Elle est
  remplacée par les guides « built-in Kotlin ».
- Versions connues de `gradle_utils.dart` :

  | Flutter | AGP max géré | Gradle max | KGP max | Gabarit (AGP / Gradle / KGP) |
  |---|---|---|---|---|
  | 3.44.0 | 9.1 | 9.3.1 | 2.3.20 | 9.0.1 / 9.1.0 / 2.3.20 |
  | 3.47.0 | 9.2 | 9.3.1 | 2.4.0 | 9.1.0 / 9.3.1 / 2.4.0 |
  | 3.50.1 | 9.4 | 9.5.0 | 2.4.20 | 9.3.1 / 9.5.0 / 2.4.20 |

  Dans les trois versions, `compileSdkVersionInt = 36` : il faut écrire
  `compileSdk = 37` en dur pour le plugin.
- **À corriger** : ANDROID_RELEASE_PLAN.md l. 245 et ROADMAP l. 165 disent
  « AGP 9.x + Gradle 9.1 + Kotlin 2.3 ». Pour AGP 9.1.1, il faut
  **Gradle ≥ 9.3.1**. Kotlin 2.3 suffit (minimum 2.2.10), mais les gabarits
  récents de Flutter sont en 2.4.x.
- Point R8 lié : AGP 9.1 active par défaut le reconditionnement R8 vers le
  package par défaut (`-repackageclasses`). Pour l'annuler : `-dontrepackage`.

### 3. Écran verrouillé, timezone et flutter_timezone

- Android, côté plugin :
  - `NotificationVisibility.private`, `.public` et `.secret` sont gérés ;
  - pas de version publique : le Java appelle seulement `setVisibility`, et le
    constructeur d'`AndroidNotificationDetails` (51 paramètres) n'a pas de
    `publicVersion` ;
  - aucune issue ni PR trouvée sur le sujet.
- Android, côté système : la documentation dit que `VISIBILITY_PRIVATE` cache les
  infos sensibles « sur les écrans verrouillés sécurisés ». L'icône et le titre
  peuvent rester visibles : ne pas mettre de nom de tracker dans le titre. La
  page d'aide Android décrit le réglage utilisateur « Sensitive notifications »
  (écran de verrouillage), qui permet de masquer le contenu sensible. Le
  masquage dépend donc aussi de ce réglage (déduction, pas affirmé tel quel par
  Google).
- iOS, côté plugin : les catégories sont créées avec
  `categoryWithIdentifier:actions:intentIdentifiers:options:`, sans placeholder.
  Seules les options `hiddenPreviewShowTitle` et `hiddenPreviewShowSubtitle`
  existent.
- iOS, côté système : quand les aperçus sont masqués, le système affiche un
  texte générique. `hiddenPreviewsBodyPlaceholder` sert seulement à le
  personnaliser. Les noms de trackers restent donc cachés même sans placeholder.
- Conséquence pour la spec (l. 272–275, déjà marquée « à vérifier ») : avec le
  plugin seul, on n'obtient que la visibilité privée sur Android et le masquage
  par défaut d'iOS. Pour un texte générique maison, il faut du code natif (canal
  de plateforme ou fork). L'autre solution est d'accepter le texte générique du
  système.
- Paquets de fuseau horaire :
  - `timezone` 0.11.2 du 2026-10-12. Le plugin dépend de `timezone: ^0.11.0`.
  - `flutter_timezone` 5.1.1 du 2026-10-03. AGP 9 est géré depuis la 5.1.0
    (2026-05-28). Depuis la 5.0.0, l'API renvoie un objet `TimezoneInfo`, plus
    une `String`.

### 4. Android 13+ : autorisation et alarmes inexactes

- « If a user installs your app on a device that runs Android 13 or higher, your
  app's notifications are off by default. »
- Exceptions et cas particuliers :
  - les apps mises à jour lors d'un passage à Android 13 reçoivent
    l'autorisation d'office ;
  - une app qui vise 12L ou moins perd la demande dès le premier refus.
- « if the user taps Deny for a specific permission more than once […] the user
  will no longer see the system permissions dialog » (règle générale depuis
  Android 11). Un geste qui ferme le dialogue sans choisir ne change pas l'état.
- Alarmes : « the alarm never goes off before the supplied trigger time. On
  Android 12 (API level 31) and higher, the system invokes the alarm within one
  hour of the supplied trigger time, unless any battery-saving restrictions are
  in effect such as battery saver or Doze. » « Environ une heure » est donc la
  borne normale ; elle peut être dépassée sous économiseur ou Doze.
- Le mode `inexactAllowWhileIdle` du plugin appelle bien
  `AlarmManagerCompat.setAndAllowWhileIdle` (vérifié dans le code source).

### 5. iOS : autorisation et limite de 64

- Apple : « The first time your app makes this authorization request, the system
  prompts the person […] Subsequent authorization requests don't prompt the
  person. »
- Autorisation provisoire : « send notifications on a trial basis », livrées sans
  son ni bannière, dans l'historique du Centre de notifications. La 23.0.2 du
  plugin corrige d'ailleurs la demande provisoire envoyée seule.
- Limite de 64 :
  - réponse acceptée d'un « Apple Engineer » (janvier 2026) : « there is a limit
    of 64 for how many simultaneous notification requests can be active/pending
    at one time per app » ;
  - l'ancienne doc `UILocalNotification` disait déjà : « the system keeps the
    soonest-firing 64 notifications (with automatically rescheduled
    notifications counting as a single notification) » ;
  - la doc UserNotifications actuelle ne cite pas le chiffre.
- À noter (README du plugin) : iOS 27 renvoie des erreurs quand l'autorisation
  manque. Le plugin ignore les erreurs `UNErrorDomain`, mais il recommande de
  vérifier l'autorisation avant de programmer.

### 6. App Store Connect : prix en euros, prix manuels, programmation

- Les prix existent, relevés sur les fiches App Store France le 2026-11-23 :
  - Bear : abonnement mensuel à 2,99 € ;
  - Caiyun : abonnement annuel à 14,99 € et achats à 29,99 €.

  Apple propose jusqu'à 800 paliers par devise, avec « the most common pricing
  convention for each country or region ».
- Prix manuels, pour les achats intégrés (dont le lifetime) : « If you select
  your own prices, Apple won't adjust your pricing on those storefronts in the
  future. »
- Prix manuels, pour les abonnements : « App Store Connect provides comparable
  prices […] If you want to set different prices for specific storefronts, make
  the changes ». La FAQ ajoute : « Apple will not make price adjustments on your
  auto-renewable subscription products. »
- Programmation, abonnements :
  - une seule modification future à la fois, par pays et par type de formule ;
  - au plus tôt « generally 1 to 2 days in advance ».

  Pour un changement au 1er décembre, programmer **au plus tard le 28 ou le
  29 novembre**.
- Programmation, achats intégrés : date d'effet possible jusqu'à la fin de
  l'année civile suivante.
- Hausse d'un abonnement : l'option A dit « Keep the current price for existing
  subscribers ». Un abonné expiré peut se réabonner à l'ancien prix dans les
  60 jours. L'option B applique la hausse, avec un simple avis ou une demande
  d'accord selon les pays.
- Il n'y a pas de groupe « zone euro » : chaque pays en euros se règle à part.
  La TVA diffère d'un pays à l'autre, donc le même prix TTC ne rapporte pas la
  même somme partout.

### 7. Google Play : prix locaux et abonnés existants

- Retrait des modèles : « Starting October 27th, 2025, you'll no longer be able
  to manage prices across your products using pricing templates. » Les prix des
  modèles ont été recopiés produit par produit.
- Ce que la doc dit des prix locaux : « Local prices use today's exchange rate
  and country-specific pricing patterns » et « You can manually refresh the
  price ». Rien ne décrit de réajustement automatique, ni avant ni après le
  retrait des modèles. Le lien de cause à effet de PRICING.md l. 127–129 est
  donc faux, même si la conclusion pratique (régler les prix à la main) reste
  juste.
- Correction associée : « recommencer à chaque réajustement annoncé par Apple »
  ne vaut que pour le lifetime. Apple ne touche jamais aux prix des abonnements
  (voir n° 6).
- Abonnés existants : « existing subscribers are unaffected by default; they are
  placed into a legacy price cohort ».
- Si l'on met fin à la cohorte avec une hausse : accord de l'utilisateur
  obligatoire par défaut, faute de quoi l'abonnement est annulé. Préavis de
  37 jours. La hausse sans accord (« opt-out ») n'existe que dans certains pays,
  avec des limites de montant et de fréquence.

### 8. Frais Google Play en 2026

- Le tableau de la Play Console Help indique pour le palier « premier million de
  gains annuels » : 10 % + frais de facturation, pour les nouvelles comme pour
  les anciennes installations. Les abonnements sont aussi à 10 % + frais de
  facturation, quel que soit le palier.
- Frais de facturation : 5 % pour Play Billing dans les pays déjà ouverts. Ils
  ne s'appliquent pas à la facturation alternative ni aux liens web externes.
- Calendrier de déploiement :

  | Date | Pays |
  |---|---|
  | 2026-06-30 | EEE, Royaume-Uni, États-Unis |
  | 2026-09-30 | Australie, Japon |
  | 2026-12-31 | Corée, Turquie, Afrique du Sud |
  | 2027-09-30 | Reste du monde |

  Pour la France (EEE) : 10 % + 5 %.
- Non trouvé dans la doc : faut-il encore s'inscrire au palier ? L'ancien palier
  à 15 % demandait une inscription (groupe de comptes). À vérifier dans la Play
  Console.

### 9. Interrupteur d'essai sur iOS

- Texte du refus cité par RevenueCat : « Guideline 3.1.2 – Business – Payments –
  Subscriptions […] The purchase screen includes a toggle to add or remove a
  free trial from the subscription purchase. » RevenueCat écrit : « Apple
  hasn't published an explicit policy update or blog post about it. »
- Superwall (3 juin 2026) rapporte, hors micro, les mots d'un contact senior chez
  Apple : « Free trial toggles on paywalls are not allowed. Full stop. »
- La mention « depuis janvier 2026 » est juste. Il faut seulement la sourcer
  comme une pratique d'App Review et non comme une règle écrite.

### 10. Messages de résiliation (« Retention messages »)

- Annonce Apple du 2026-11-04 : « Retention messages appear in the cancellation
  flow and can include text, images, or a special offer. »
- Règle : « Header and body text can't reference promotional offers, discounts,
  or specific prices […] App Review rejects retention messages that contain
  pricing or offer mentions. » Elle vaut **aussi pour l'en-tête** :
  PRICING.md l. 190 ne parle que du corps.
- Autres règles :
  - 10 messages au plus par app ;
  - un seul message actif par abonnement ;
  - validation par App Review ;
  - « Ensure your message includes localizations for all storefronts where your
    subscription is offered ».

  À vérifier : ce que voient les pays dont la langue n'est pas traduite.
- Limites des API Apple : en-tête « maximum length of 66 characters », corps
  « 144 characters ».
- Les quatre messages rédigés dans PRICING.md tiennent dans les limites :

  | Langue | En-tête | Corps |
  |---|---|---|
  | en-US | 34 | 134 |
  | fr-FR | 41 | 141 |
  | zh-Hans | 13 | 55 |
  | zh-Hant | 13 | 55 |

- Le libellé français de l'interface (« Messages de fidélisation ») n'a pas pu
  être vérifié : la page d'aide en français renvoie une 404.

### 11. Avis de fin d'essai : Google contre Apple

- Google Play Help (abonnements) : « If you accept a trial offer, you'll get an
  email when your trial is about to end. »
- Blog Android du 2020-04-16 : « We now email users a reminder before their free
  trial or intro price ends. »
- Apple, page « Cancel a subscription from Apple » (2026-09-29) : seulement
  « cancel it at least 24 hours before the trial ends ». Aucune mention de
  rappel. Aucune doc Apple trouvée sur un rappel de fin d'essai.
- RevenueCat (2026-03-25, « android-paywall-gap ») écrit le contraire :
  « Apple sends a system-level push notification before a trial ends » et
  « Google Play does not send an equivalent system notification ». C'est la
  source de l'erreur, et elle contredit la page d'aide de Google.
- Sans effet sur la décision : aucun rappel de fin d'essai, l'argument est même
  renforcé. Mais ces phrases sont à corriger :
  - PRICING.md « même si Google ne prévient pas » ;
  - spec rappels l. 283–284 « que Google Play ne signale pas » ;
  - rapport « Prix abonnement et achat à vie » l. 94 et l. 142 ;
  - `stores_mecanique_prix.md` l. 158.

### 12. Conversion essai → payant (SOSA 2026)

- Médianes par durée d'essai :

  | Durée d'essai | Médiane | Quartile supérieur |
  |---|---|---|
  | ≤ 4 jours | 25,5 % | > 38,5 % |
  | 5–9 jours | 37,4 % | > 52,8 % |
  | 10–16 jours | 35,4 % | — |
  | 17–32 jours | 42,5 % | > 59,4 % |

- Santé-forme : 37,7 % (quartile supérieur > 51,4 %).
- Le 82 % de PRICING.md l. 95 est attribué à SOSA 2026, mais il vient de
  SOSA 2025 : « 82% of trial starts occur the same day a user installs an app »
  (Phil Carter). SOSA 2026 donne 82,1 % pour la santé-forme. Il suffit de
  corriger la source.
- SOSA 2026 est paru en mars 2026 : partie 1 début mars, partie 2 ensuite.

### 13. Freemium : téléchargement → payant

- SOSA 2026, à J35 : freemium médiane 2,1 %, quartile supérieur « above 4.5% ».
- Pour comparaison : paywall dur médiane 10,7 % (quartile supérieur > 20 %),
  toutes apps 2,0 %.

### 14. Promotions du Nouvel An (étude RevenueCat sur les fêtes)

- « Apps with detected New Year promotions get 14% more new paying customers per
  day than in September–October ». Sans promotion : −4 %. Du 26 décembre au
  4 janvier : +24 % avec offre.
- Fenêtre : « December 26–February 1 for New Year and January ». Échantillon :
  4 964 apps, dont 236 avec une promotion détectée au Nouvel An.
- La santé-forme fait +11 % au Nouvel An et en janvier, mais ce chiffre mélange
  les apps avec et sans promotion.
- La formulation de PRICING.md (« +14 % de nouveaux payants par jour au Nouvel
  An avec promotion ») est exacte. Il faut garder à l'esprit qu'il s'agit d'une
  corrélation.
