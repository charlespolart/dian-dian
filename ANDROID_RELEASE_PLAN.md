# Android / Google Play — Plan de publication

Plan de A à Z pour publier Dian Dian sur Google Play. Basé sur un audit du code
au 22/07/2026 (version `1.2.0+2`).

---

## 0. État des lieux (audit du code)

### 🔴 Bloquants — l'app serait rejetée ou cassée

| # | Problème | Fichier |
|---|---|---|
| 1 | **Release signé avec les clés de debug** — Google Play refuse l'upload | `android/app/build.gradle.kts:35-37` |
| 2 | **Clé RevenueCat Android = clé de test** → achats intégrés non fonctionnels | `lib/services/revenue_cat_config.dart:9-10` |
| 3 | **AdMob App ID Android = ID de test Google** (`ca-app-pub-3940256099942544~…`) | `android/app/src/main/AndroidManifest.xml:32` |
| 4 | **AdMob banner Android = unité de test** | `lib/services/ad_service.dart:28` |
| 5 | **Google Sign-In Android non configuré** : pas de client OAuth Android, pas d'empreinte SHA-1 enregistrée | — |

### 🟠 Important

| # | Problème | Fichier |
|---|---|---|
| 6 | Permission `INTERNET` absente du manifest principal (présente seulement en debug). Ça ne marche aujourd'hui que parce que `google_mobile_ads` la fusionne — fragile | `android/app/src/main/AndroidManifest.xml` |
| 7 | **Icône adaptative défectueuse** : le foreground contient son propre fond crème (`#FDF3E7`) inséré à 16 % sur un fond `#F5F0D0` → liseré visible « carré dans le carré » + pastilles rognées par le masque | `pubspec.yaml:129-130`, `res/mipmap-anydpi-v26/ic_launcher.xml` |
| 8 | `sign_in_with_apple` sur Android nécessite un flux web (Service ID + redirect). Décider : masquer le bouton sur Android (simple) ou configurer le flux | `lib/screens/login_screen.dart` |
| 9 | Pas de cible Android dans le `Makefile` (seulement `ipa`) | `Makefile` |
| 10 | `targetSdk` hérité de Flutter — Play exige 35+ pour les nouvelles apps. À figer explicitement | `android/app/build.gradle.kts:28` |

### 🟢 Déjà bon

- `applicationId` = `app.mydiandian.dian_dian` (valide, définitif — **ne jamais le changer**)
- Icônes legacy présentes à toutes les densités, avec la vraie illustration
- AGP 8.11.1 / Kotlin 2.2.20 / Java 17 — à jour
- `version: 1.2.0+2` → `versionCode = 2`
- Politique de confidentialité en ligne : `https://diandian.overridedev.com/privacy`
- `app-ads.txt` déjà servi par le backend (`pub-7932342939488027`)

### ℹ️ Notifications

**L'app n'a aucune notification, sur aucune plateforme.** Aucune dépendance
`firebase_messaging` ni `flutter_local_notifications`. Il n'y a donc **rien à
corriger** côté Android — mais rien ne fonctionne non plus. Si un rappel
quotidien est souhaité un jour, c'est une fonctionnalité à construire
(FCM + `google-services.json` côté Android).

---

## 1. Compte Google Play — choisir le bon type

**Décision : compte ORGANISATION** (au nom d'OVERRIDE).

| | Personnel | Organisation ✅ |
|---|---|---|
| Frais | 25 $ une fois | 25 $ une fois |
| D-U-N-S requis | Non | **Oui** (gratuit, jusqu'à 30 j) |
| **Test fermé obligatoire** | **12 testeurs × 14 jours consécutifs** | **Exempté** |
| Éditeur affiché | Nom perso | OVERRIDE |

Le parcours « 12 testeurs pendant 14 jours » ne s'applique **qu'aux comptes
personnels créés après le 13/11/2023**. Un compte organisation permet d'aller
directement en production.

### Étapes

1. ✅ **D-U-N-S obtenu : `280715872`** (attribué à OVERRIDE, confirmé par Apple
   le 10/03/2026 — il était requis pour l'inscription organisation à l'Apple
   Developer Program). Aucun délai d'attente.
2. Créer le compte sur `play.google.com/console` → type **Organisation**.
3. Payer les 25 $ (une seule fois, à vie, tous produits confondus).
4. Vérification d'identité + du compte de paiement (documents société).

**⚠️ La raison sociale et l'adresse doivent correspondre au caractère près
à la fiche D&B** (`OVERRIDE`, 12 Rue de Porspol, 29660 Carantec). Un écart =
compte bloqué en vérification.

**Compte Google à utiliser :** un compte au nom de la société, conservé sur le
long terme (pas un compte perso). Contrairement à Pinterest, **un seul compte
Play suffit pour toutes les apps d'OVERRIDE**.

---

## 2. Signature de l'app (keystore)

Sans ça, aucun upload possible.

```bash
keytool -genkey -v -keystore ~/dian-dian-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Créer `android/key.properties` (**à ne jamais committer**) :

```properties
storePassword=…
keyPassword=…
keyAlias=upload
storeFile=/Users/charlespolart/dian-dian-upload.jks
```

Puis dans `android/app/build.gradle.kts` : charger `key.properties`, déclarer
un `signingConfigs.create("release")` et remplacer
`signingConfig = signingConfigs.getByName("debug")`.

⚠️ **Sauvegarder le `.jks` et les mots de passe hors du Mac.** Perdre la clé
d'upload est récupérable via Play App Signing, mais c'est pénible.

✅ Activer **Play App Signing** (Google gère la clé de distribution).

---

## 3. Services externes à configurer

### AdMob (Android)
1. Créer une **app Android** dans AdMob (compte `pub-7932342939488027`).
2. Créer une **unité banner** Android.
3. Reporter l'App ID dans le manifest + l'unité dans `ad_service.dart`.
4. Lier l'app AdMob à la fiche Play une fois publiée.

### RevenueCat (Android)
1. Ajouter l'app **Google Play** dans le projet RevenueCat.
2. Créer un **compte de service Google Cloud** avec accès à la Play Developer
   API, l'inviter dans Play Console, et le fournir à RevenueCat (c'est ce qui
   permet de valider les achats).
3. Créer les produits dans Play Console (mensuel / annuel / à vie) avec les
   **mêmes identifiants** que sur iOS si possible.
4. Les rattacher aux offerings et à l'entitlement `premium`.
5. Récupérer la clé `goog_…` → `revenue_cat_config.dart`.
6. Vérifier que le webhook RC (déjà en place côté backend) reçoit bien les
   événements Play.

### Google Sign-In (Android)
1. Google Cloud Console → créer un **client OAuth Android** avec :
   - package `app.mydiandian.dian_dian`
   - **SHA-1 de la clé d'upload** *et* **SHA-1 de la clé Play App Signing**
     (récupérable dans Play Console après le 1ᵉʳ upload)
2. Ajouter ce client ID à `GOOGLE_CLIENT_IDS` dans le `.env` du backend, puis
   redéployer.
3. Tester la connexion Google sur un vrai appareil Android.

---

## 4. Corrections code

### ✅ Faites (22/07/2026)

- [x] `build.gradle.kts` : `signingConfigs.create("release")` lisant
      `android/key.properties`, avec repli sur les clés debug si le fichier est
      absent (le build local continue de marcher). Validé : `./gradlew
      :app:signingReport` → exit 0.
- [x] `AndroidManifest.xml` : `<uses-permission android:name="android.permission.INTERNET"/>`
      déclaré explicitement.
- [x] `pubspec.yaml` : `adaptive_icon_background` `#F5F0D0` → **`#FEF3E5`**
      (couleur réelle du fond de l'illustration) → plus de liseré « carré dans
      le carré ». Icônes régénérées.
- [x] `Makefile` : cible `aab`.
- [x] Nettoyage des `// TODO` du template Flutter.

### ⏸️ Bloquées — nécessitent les comptes externes

- [ ] `AndroidManifest.xml` : vrai AdMob App ID (attend AdMob)
- [ ] `ad_service.dart` : vraie unité banner Android (attend AdMob)
- [ ] `revenue_cat_config.dart` : clé `goog_…` (attend RevenueCat + Play)

### ✔️ Vérifiés — rien à faire (faux positifs de l'audit initial)

- `android/.gitignore` protège déjà `key.properties`, `**/*.jks`, `**/*.keystore`
- Le bouton « Sign in with Apple » est déjà conditionné à `Platform.isIOS`
  (`lib/widgets/oauth_buttons.dart:40`) → invisible sur Android
- `targetSdk` laissé sur `flutter.targetSdkVersion` : le SDK Flutter 3.44.6
  cible déjà une version conforme aux exigences Play. Le figer n'apporterait
  qu'un risque de régression.
- Toolchain machine OK : `flutter doctor` → Android SDK 36.1.0 ✓, Android
  Studio installé (JDK 21 embarqué). Pour lancer Gradle à la main :
  `export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"`

---

## 5. Build

```bash
flutter build appbundle --release
# → build/app/outputs/bundle/release/app-release.aab
```

Play exige un **.aab** (pas un .apk). Tester avant upload sur un vrai appareil :

```bash
flutter build apk --release   # pour test local uniquement
```

---

## 6. Fiche Google Play

| Élément | Contrainte | État |
|---|---|---|
| Nom de l'app | 30 car. | à écrire |
| Description courte | 80 car. | à écrire |
| Description complète | 4000 car. | réutiliser l'App Store |
| Icône | **512×512** PNG 32 bits | à exporter |
| Feature graphic | **1024×500** | **à créer** (nouveau, n'existe pas sur iOS) |
| Captures téléphone | min. 2, 16:9 ou 9:16 | à générer sur émulateur Android |
| Captures tablette | optionnel | possible depuis les captures iPad |
| Politique de confidentialité | URL | ✅ `…/privacy` |

### Déclarations obligatoires
- **Content rating** : questionnaire (l'app est tout public)
- **Data safety** : déclarer email, données de suivi, logs IP, et
  **l'identifiant publicitaire AdMob** (sinon rejet)
- **Contient des annonces** : **Oui**
- **Public cible** : préciser les tranches d'âge

---

## 7. Ordre d'exécution recommandé

1. **D-U-N-S** (jusqu'à 30 j — à lancer maintenant, en parallèle de tout le reste)
2. Keystore + signingConfig
3. Corrections code non bloquées par les comptes externes (INTERNET, icône, Apple button, Makefile, targetSdk)
4. Compte Play créé → AdMob + RevenueCat + client OAuth Android
5. Reporter les vraies clés dans le code
6. Build `.aab` + test sur appareil réel
7. Fiche Play + assets + déclarations
8. Upload en **test interne** (immédiat, pas de délai) pour valider achats + Google Sign-In
9. Passage en production

---

## Annexe — commandes utiles

```bash
# Empreinte SHA-1 de la clé d'upload
keytool -list -v -keystore ~/dian-dian-upload.jks -alias upload

# Bundle de release
flutter build appbundle --release

# Vérifier ce que Flutter résout comme SDK versions
cd flutter_app/android && ./gradlew :app:properties | grep -i sdk
```
