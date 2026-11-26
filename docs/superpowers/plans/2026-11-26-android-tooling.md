# Outillage Android (chantier 3) — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** L'app Android se construit avec l'outillage que Flutter 3.47.5 génère aujourd'hui (AGP 9.1, Gradle 9.3.1, Kotlin 2.4) et `compileSdk = 37`, pour que les rappels (chantier 4) puissent prendre le plugin de notifications le plus récent. La bannière publicitaire ne passe plus sous la barre de navigation du système.

**Architecture:** Trois fichiers Gradle alignés sur le modèle d'app de Flutter 3.47.5, plus `compileSdk = 37` écrit à la main. Puis la bannière décalée de la hauteur de la barre système, mesurée par `MediaQuery.viewPaddingOf`, dans le widget de la bannière lui-même : les deux écrans qui l'affichent en profitent. Rien ne change côté serveur.

**Tech Stack:** Flutter 3.47.5 / Dart 3.13.4 (inchangés), Android Gradle Plugin 9.1.1, Gradle 9.3.1, Kotlin Gradle Plugin 2.4.0, R8 9.1, SDK Android 37 (plateforme déjà installée sur la machine de Charles le 2026-11-26).

**Spec:** pas de spec propre. Sources : `docs/FABLE.md` (ligne du chantier 3), `ANDROID_RELEASE_PLAN.md` §8, `docs/CONFIRMATION.md` point 12, `docs/superpowers/specs/2026-11-23-reminders-design.md` (« Plugin » : `flutter_local_notifications` 23 exige AGP ≥ 9.1.1 et `compileSdk` 37).

**Estimation :** ½ à 1 jour de code, plus les essais de Charles sur un téléphone Android.

## Ce qu'un essai a montré (2026-11-26)

Avant d'écrire ce plan, j'ai essayé la montée dans une copie à part du dépôt, supprimée depuis :

- **Le build de debug et le bundle release passent** avec AGP 9.1.1, Gradle 9.3.1, Kotlin 2.4.0 et `compileSdk = 37`, sans erreur (3 min 25 s puis 2 min 37 s ; la plateforme 37 et les build-tools 36.0.0 se sont installés d'eux-mêmes).
- **R8 est déjà actif, et depuis toujours.** Le plugin Gradle de Flutter active la minification, la réduction des ressources et les règles de Flutter sur tout build release (`FlutterPlugin.kt`, sauf `--no-shrink`). Le bundle 1.4.0 du 29 octobre a été passé à R8 8.11 et porte son fichier de correspondance (`BUNDLE-METADATA/com.android.tools.build.obfuscation/proguard.map`), que la Play Console reçoit avec lui. `ANDROID_RELEASE_PLAN.md` §8 partait du principe contraire : il n'y a **rien à activer**, seulement à vérifier que R8 9.1 ne casse aucun plugin (essai sur appareil).
- Un seul avertissement nouveau : `purchases_ui_flutter` (l'écran d'abonnement de RevenueCat, ouvert depuis les réglages) applique lui-même le plugin Kotlin. Il empêche le « Kotlin intégré » d'AGP 9. Flutter le désactive de toute façon dans son propre modèle (`android.builtInKotlin=false`, `android.newDsl=false`, déjà dans notre `gradle.properties`) : on garde ces deux réglages.

## Global Constraints

- Branche `feat/android-tooling`, partie de `master`. Pas de release : tout sort dans la release unique.
- **Flutter reste en 3.47.5**, Dart en 3.13.4 : ce chantier ne met pas Flutter à jour.
- Versions exactes : AGP `9.1.1`, Gradle `9.3.1`, Kotlin Gradle Plugin `2.4.0`, `compileSdk = 37`. `minSdk` et `targetSdk` restent ceux de Flutter (24 et 36).
- `android.newDsl=false` et `android.builtInKotlin=false` restent dans `flutter_app/android/gradle.properties`, avec un commentaire qui dit pourquoi.
- L'identité de l'app ne change pas : `applicationId` et `namespace` `app.mydiandian`, signature par `key.properties`.
- **Jamais `dart format`** dans `flutter_app`. Garde-fous : `flutter analyze`, `flutter test`, `git diff --stat`.
- Le décalage de la bannière ne s'applique qu'aux comptes gratuits (la bannière n'existe pas pour les autres) et suit la barre système réelle de l'appareil, quelle qu'elle soit.
- Changelog : entrées sous « Unreleased » dans `flutter_app/CHANGELOG.md`, en anglais.

## Choix de Fable (à valider par Charles)

1. **Suivre exactement le modèle de Flutter 3.47.5** (le plugin `kotlin-android` retiré du `build.gradle.kts` de l'app, que Flutter applique lui-même ; `kotlin { compilerOptions { jvmTarget = JVM_17 } }` au lieu de `kotlinOptions`) plutôt que garder nos écarts : la prochaine montée de Flutter se fera sans surprise.
2. **Kotlin 2.4.0**, la version du modèle de Flutter, plutôt que 2.3.x : 2.3.20 est déjà le seuil sous lequel Flutter avertit.
3. **Pas de `proguard-rules.pro` d'avance.** R8 tourne déjà avec les règles livrées par les plugins (RevenueCat, AdMob, Google Sign-In) ; un fichier n'est ajouté que si l'essai sur appareil montre une fonction cassée, avec la règle exacte qui la répare.
4. **La bannière monte au-dessus de la barre système, sur Android et sur iPhone.** Sur iPhone, elle passe aujourd'hui sous la barre d'accueil (34 points sur la bannière de 50) : même défaut, même correction. *Si tu préfères Android seulement*, une condition sur la plateforme suffit, et l'iPhone garde la bannière d'aujourd'hui.
5. **Pas d'émulateur installé** (il resterait 17 Go libres sur le disque) : les vérifications à l'écran se font sur ton téléphone Android et ton iPhone.

## Review Focus

1. **Navigation à trois boutons sur Android 15 ou plus** : la bannière, sa croix et le bouton + de la liste sont entièrement au-dessus de la barre ; rien ne passe dessous.
2. **Navigation par gestes et iPhone avec barre d'accueil** : la bannière est juste au-dessus de la petite barre, sans trou anormal ; sur un iPhone à bouton d'accueil (pas de barre), elle reste collée au bas de l'écran.
3. **Paysage sur tablette** (`tracker_screen`, bannière large à gauche) : même règle, et la bannière garde sa largeur.
4. **Compte Premium** : aucun espace réservé en bas, ni sur la liste ni sur un tracker.
5. **R8 9.1 sur les plugins** : achat, restauration, écran d'abonnement RevenueCat, connexion Google, bannière, partage, pages légales en WebView, sons. Tout marche dans le build release installé.

---

### Task 1: AGP 9.1.1, Gradle 9.3.1, Kotlin 2.4.0, `compileSdk = 37`

**Files:**
- Modify: `flutter_app/android/settings.gradle.kts` (versions des plugins), `flutter_app/android/gradle/wrapper/gradle-wrapper.properties` (`gradle-9.3.1-all.zip`), `flutter_app/android/app/build.gradle.kts`, `flutter_app/android/gradle.properties` (commentaires seulement)

- [ ] **Step 1: Mesurer l'état d'avant.** Sur `master` : `cd flutter_app && flutter build appbundle --release` ; noter la taille du `.aab`, `# compiler_version` en tête de `build/app/outputs/mapping/release/mapping.txt` (attendu : 8.11.x) et la présence de `BUNDLE-METADATA/com.android.tools.build.obfuscation/proguard.map` (`unzip -l`).
- [ ] **Step 2: Monter les versions.** `settings.gradle.kts` : `com.android.application` `9.1.1`, `org.jetbrains.kotlin.android` `2.4.0`. Wrapper : `gradle-9.3.1-all.zip`.
- [ ] **Step 3: Aligner `app/build.gradle.kts` sur le modèle de Flutter.** Retirer `id("kotlin-android")` et le bloc `kotlinOptions` ; ajouter après `android { }` :

```kotlin
kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}
```

et `compileSdk = 37`, avec un commentaire : Flutter 3.47.5 fixe encore 36, `flutter_local_notifications` 23 (chantier 4) demande 37 ; revenir à `flutter.compileSdkVersion` quand Flutter passera à 37. Le reste du fichier (signature, `applicationId`) ne bouge pas.

- [ ] **Step 4: Commenter `gradle.properties`.** Au-dessus des deux réglages : ils restent à `false` comme dans le modèle de Flutter 3.47.5, les plugins sont sur l'ancien DSL, et `purchases_ui_flutter` applique lui-même le plugin Kotlin ; à revoir à chaque montée de Flutter.
- [ ] **Step 5: Construire.** `flutter build apk --debug` puis `flutter build appbundle --release`.
  Attendu : deux `✓ Built`, aucune erreur ; un seul avertissement de plugin (`purchases_ui_flutter`). `mapping.txt` commence par `# compiler: R8` / `# compiler_version: 9.1.` ; le `.aab` porte `obfuscation/proguard.map` ; sa taille est à ±5 % de celle de l'étape 1.
- [ ] **Step 6: Vérifier ce que l'app déclare.** `cd flutter_app/android && ./gradlew :app:processReleaseMainManifest -q` puis lire `build/app/intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml`. Attendu : `minSdkVersion="24"`, `targetSdkVersion="36"`, `package` / `applicationId` `app.mydiandian`, mêmes permissions qu'avant (`INTERNET`, plus celles des plugins : comparer avec le manifeste fusionné de `master`). Si le chemin du manifeste fusionné a changé avec AGP 9, le retrouver par `find build/app/intermediates -name AndroidManifest.xml -path "*release*"`.
- [ ] **Step 7: Garde-fous Dart.** `flutter analyze` (aucun problème) et `flutter test` (tout vert).
- [ ] **Step 8: Commit.**

### Task 2: La bannière au-dessus de la barre système

**Files:**
- Modify: `flutter_app/lib/widgets/ad_banner.dart`, `flutter_app/lib/screens/page_list_screen.dart` (position du bouton +), `flutter_app/lib/screens/tracker_screen.dart` (si sa marge du bas suppose la bannière collée au bord)
- Test: `flutter_app/test/ad_banner_frame_test.dart`

**Interfaces:**
- Produces:
  ```dart
  /// La bannière chargée, sa croix, et sous elles la hauteur de la barre système
  /// (`MediaQuery.viewPaddingOf(context).bottom`) : rien ne passe dessous.
  class AdBannerFrame extends StatelessWidget {
    const AdBannerFrame({super.key, required this.adSize, required this.ad, required this.onClose});
    final Size adSize;
    final Widget ad;
    final VoidCallback onClose;
  }
  ```
  `AdBannerWidget` garde son interface (`width`) et construit `AdBannerFrame` une fois la bannière chargée ; tant qu'elle ne l'est pas, ou pour un compte Premium, il rend toujours `SizedBox.shrink()` (aucun espace réservé).

- [ ] **Step 1: Écrire les tests de `AdBannerFrame`** (`ad` = un `SizedBox` de la taille de la bannière, `MediaQuery` posé par le test) :
  - `viewPadding.bottom = 48` (Android, trois boutons) : la hauteur du cadre vaut `50 + 4 + 48` ; le bas de la bannière est à 48 du bas de l'écran ;
  - `viewPadding.bottom = 34` (iPhone, barre d'accueil) : `50 + 4 + 34` ;
  - `viewPadding.bottom = 0` (bouton d'accueil, ancien Android) : `50 + 4`, comme aujourd'hui ;
  - un clavier ouvert (`viewInsets.bottom = 300`) ne change rien : seul `viewPadding` compte ;
  - toucher la croix appelle `onClose`.
- [ ] **Step 2: Voir échouer** — `flutter test test/ad_banner_frame_test.dart` → « AdBannerFrame isn't defined ».
- [ ] **Step 3: Écrire `AdBannerFrame`** (dans `ad_banner.dart`), en reprenant la mise en page d'aujourd'hui (marges de 2, bannière centrée, croix en haut à droite) et en ajoutant la marge du bas ; `AdBannerWidget` l'utilise.
- [ ] **Step 4: Tests verts**, puis `flutter test` en entier.
- [ ] **Step 5: Le bouton + de la liste** (`page_list_screen.dart:633`) : sa distance au bas ajoute `MediaQuery.viewPaddingOf(context).bottom` quand la bannière est là, pour rester au-dessus d'elle. Un test de `page_list_screen_test.dart` : avec `viewPadding.bottom = 48` et la bannière annoncée, le bouton est au-dessus de 48 + 54. Si l'écran ne sait pas aujourd'hui que la bannière est chargée (il réserve 66 pour tout compte gratuit), garder cette règle et ajouter seulement la barre système.
- [ ] **Step 6: Le tracker** : vérifier dans `tracker_screen.dart` (marge `_bottomSafe`, `:617`) que la grille ne passe pas sous la bannière remontée. Si elle passe dessous, la marge du bas de la grille devient `_bottomSafe + hauteur de la bannière` pour un compte gratuit, et un test le tient.
- [ ] **Step 7: `flutter analyze`, `flutter test`, `git diff --stat` (aucun fichier reformaté), commit.**

### Task 3: Essais sur appareil (Charles) et documents

**Files:**
- Modify: `flutter_app/CHANGELOG.md`, `ANDROID_RELEASE_PLAN.md` §8, `docs/FABLE.md` (ligne du chantier 3 ; la règle « Ne pas mettre Flutter à jour avant le chantier 3 »), `docs/ROADMAP.md` §6

- [ ] **Step 1: Changelog** (Unreleased) : la montée d'outillage avec ses versions, `compileSdk` 37, R8 déjà actif (rien à activer), la bannière au-dessus de la barre système.
- [ ] **Step 2: Documents.** `ANDROID_RELEASE_PLAN.md` §8 : fait le 2026-11-26, avec le constat sur R8 ; FABLE : la règle sur Flutter devient « Flutter peut être mis à jour, comme un chantier testé sur appareil ; vérifier `compileSdk`, `android.newDsl` et `android.builtInKotlin` à chaque montée » ; ROADMAP §6 marqué fait.
- [ ] **Step 3: Essais de Charles**, sur le build release installé depuis la branche (`flutter run --release` avec le téléphone branché, ou `flutter install --release`) :
  - Android, navigation à trois boutons (Réglages → Système → Navigation) : bannière, croix et bouton + au-dessus de la barre, sur la liste et sur un tracker ; puis navigation par gestes ;
  - iPhone : la bannière au-dessus de la barre d'accueil ;
  - Android release : connexion Google et par e-mail, achat en bac à sable (compte testeur de licence), restauration, écran d'abonnement RevenueCat (Réglages), partage d'un export, pages légales, sons ;
  - Play Console : la remarque « R8 » du 15 octobre apparaît-elle encore sur la 1.4.0 ? (Le bundle de la 1.4.0 était déjà passé par R8.)
- [ ] **Step 4: Ce que les essais trouvent** est corrigé dans la branche (test d'abord quand c'est du Dart ; une règle R8 précise dans `proguard-rules.pro` quand c'est un plugin), puis relecture neuve de toute la branche, tout corrigé, mineurs compris, fusion et push.

## Hors périmètre

- Mettre Flutter à jour (possible après ce chantier, comme un chantier à part).
- Le « Kotlin intégré » et le nouveau DSL d'AGP 9 : ils attendent que Flutter et les plugins les adoptent.
- `targetSdk` 37 : il suit Flutter.
- Le plugin de notifications et tout ce qui touche aux rappels : chantier 4.
