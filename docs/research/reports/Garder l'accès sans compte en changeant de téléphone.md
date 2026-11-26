# La clé peut suivre la personne vers un nouveau téléphone, mais l'app ne peut pas savoir si elle suivra

Les deux plateformes ont de quoi faire suivre une clé d'appareil, mais aucune ne dit à l'app si ce chemin est ouvert ni s'il a servi. Sur iOS, aucune API documentée n'indique si la synchronisation du trousseau iCloud est activée, si un élément est parti vers iCloud ou s'il vient d'un autre appareil. Ce constat repose sur une absence et sur le support technique d'Apple (DTS) : « once you do the system is in charge of that process » en 2026, « No. » en 2017 sur la double authentification ([forum 854637](https://developer.apple.com/forums/thread/854637), [forum 70549](https://developer.apple.com/forums/thread/70549)) [PRIMARY]. Sur Android, l'app ne peut pas lire si la sauvegarde est activée, et aucun rappel ne confirme un envoi. Elle peut en revanche savoir si une sauvegarde serait chiffrée de bout en bout, donc illisible par Google, et détecter une restauration ([BlockstoreClient](https://developers.google.com/android/reference/com/google/android/gms/auth/blockstore/BlockstoreClient), [BackupAgent](https://developer.android.com/reference/android/app/backup/BackupAgent)) [PRIMARY].

Le second constat est le secret qui arrive en retard. Sur un nouvel iPhone, la clé synchronisée peut manquer au premier lancement. L'appareil doit d'abord être approuvé dans le cercle du trousseau ([Support 109016](https://support.apple.com/en-us/109016)) [PRIMARY] ; la seule mesure trouvée donne ensuite environ 30 secondes d'iOS à iOS et 30 minutes d'iOS vers macOS ([forum 854637](https://developer.apple.com/forums/thread/854637)) [ISSUE]. Pour le magasin clé-valeur iCloud, une valeur restait vide environ une minute après la connexion à iCloud, délai qu'un ingénieur d'Apple a reconnu ([forum 726593](https://developer.apple.com/forums/thread/726593)) [PRIMARY]. Une app qui crée une clé quand elle ne lit rien dédouble l'identité. Si deux appareils ont chacun écrit une clé avant de se synchroniser, « one or the other is chosen » ([guide de sécurité d'Apple](https://help.apple.com/pdf/security/en_US/apple-platform-security-guide.pdf), p. 149) [PRIMARY] : l'un perd la sienne sans avertissement.

Le paquet flutter_secure_storage, que l'app utilise en 11.2.0 (darwin 0.4.3) avec `const FlutterSecureStorage()` aux options par défaut [CODE], aggrave ces pièges. Sur iOS, un `read()` aux options par défaut ne voit pas un élément synchronisé, alors que `containsKey()` le voit. Une écriture de la même clé avec `synchronizable: false`, ou un `deleteAll()`, efface la copie synchronisée ([source du plugin](https://github.com/juliansteenbakker/flutter_secure_storage/blob/flutter_secure_storage_darwin-v0.4.3/flutter_secure_storage_darwin/darwin/flutter_secure_storage_darwin/Sources/flutter_secure_storage_darwin/FlutterSecureStorage.swift)) [DOCS], et Apple précise que cette suppression « affects all copies of the item » ([kSecAttrSynchronizable](https://developer.apple.com/documentation/security/ksecattrsynchronizable)) [PRIMARY]. Sur Android, le manifeste ne règle pas la sauvegarde [CODE] : elle copie le fichier chiffré du plugin, jamais la clé du Keystore qui le déchiffre. Sur le nouveau téléphone, le plugin échoue à le lire, efface tout (`resetOnError` vaut true par défaut) et `read` rend `null` : l'app crée une nouvelle identité sans rien dire ([#1240](https://github.com/juliansteenbakker/flutter_secure_storage/issues/1240)) [ISSUE] [INFERENCE].

Ce rapport décrit ; il ne décide pas. Il complète « Utiliser l'app sans compte » et « Compte exigé avant l'achat et revue Apple ».

## Sur iOS, seul le trousseau synchronisé suit partout, et seulement s'il est activé

Un élément du trousseau rejoint les autres appareils Apple de la personne à quatre conditions ([kSecAttrSynchronizable](https://developer.apple.com/documentation/security/ksecattrsynchronizable), [Support 109016](https://support.apple.com/en-us/109016)) [PRIMARY]. L'app l'écrit avec `kSecAttrSynchronizable = true`, sans quoi il reste local (guide de sécurité, p. 148). Sa classe d'accès ne finit pas par `ThisDeviceOnly`. Chaque appareil utilise le même compte Apple, avec double authentification, et a activé « Sync this iPhone » (Réglages > [nom] > iCloud > Mots de passe). Aucun entitlement n'est requis : sans groupe d'accès, seule l'app voit l'élément ([kSecAttrAccessGroup](https://developer.apple.com/documentation/security/ksecattraccessgroup)) [PRIMARY]. L'app, avec son seul entitlement Sign in with Apple et iOS 15.0 au minimum [CODE], n'a rien à changer pour cela [INFERENCE]. L'élément atteint iPad, Mac et visionOS, pas l'Apple TV.

Aucune page d'Apple lue ne dit la synchronisation activée par défaut ([guide de l'iPhone](https://support.apple.com/guide/iphone/passwords-devices-iph82d6721b2/ios)) [PRIMARY]. La double authentification couvrait « more than 95 percent of active iCloud accounts » en 2022 ([Apple Newsroom](https://www.apple.com/newsroom/2022/12/apple-advances-user-security-with-powerful-new-data-protections/)) [PRIMARY], mais aucun chiffre ne mesure l'usage du trousseau iCloud.

Une clé rangée comme aujourd'hui, non synchronisée et en `WhenUnlocked` ([défaut du plugin](https://github.com/juliansteenbakker/flutter_secure_storage/blob/flutter_secure_storage-v11.2.0/flutter_secure_storage/lib/options/apple_options.dart)) [DOCS], suit déjà par Quick Start en transfert direct et par une sauvegarde chiffrée sur ordinateur ([forum 788360](https://developer.apple.com/forums/thread/788360)) [PRIMARY]. Elle se perd lors d'une restauration iCloud Backup sur un autre iPhone : le trousseau n'y est restaurable « only to the same device from which it originated » (guide de sécurité, p. 138), et le test du DTS donne « gone » ([forum 93373](https://developer.apple.com/forums/thread/93373)) [PRIMARY]. Une pull request de Zeus soutient le contraire ([Zeus #5533](https://github.com/ZeusLN/zeus/pull/5533)) [ISSUE], ce qu'Apple contredit sauf pour le même appareil. Après une désinstallation, le trousseau survit en pratique ([forum 36442](https://developer.apple.com/forums/thread/36442)) [PRIMARY], mais le DTS prévient : « Yeah, don't rely on that » ([forum 730924](https://developer.apple.com/forums/thread/730924)) [PRIMARY].

Le magasin clé-valeur iCloud (`NSUbiquitousKeyValueStore`, dit KVS) est simple, mais Apple écrit « Don't store personal or sensitive information in the key-value store » : il est stocké « in an unencrypted format » ([NSUbiquitousKeyValueStore](https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore)) [PRIMARY]. La base privée CloudKit rend l'état du compte iCloud lisible, mais demande un container, un schéma, et peut perdre les données après certaines erreurs (« permanently lost ») ([Encrypting User Data](https://developer.apple.com/documentation/cloudkit/encrypting-user-data)) [PRIMARY]. Son chiffrement de bout en bout est contradictoire : la page développeur le rattache au trousseau, la page `encryptedValues` et le support ne le promettent qu'avec la Protection avancée des données (ADP) ([encryptedValues](https://developer.apple.com/documentation/cloudkit/ckrecord/encryptedvalues), [Support 102651](https://support.apple.com/en-us/102651)) [PRIMARY]. Le trousseau est chiffré de bout en bout dans les deux modes.

## Sur Android, rien ne synchronise la clé ; trois mécanismes la portent une fois, à l'installation

Auto Backup, Block Store et la clé de restauration agissent une fois, à l'installation de l'app ou du téléphone ([Auto Backup](https://developer.android.com/identity/data/autobackup), [Block Store](https://developer.android.com/identity/block-store), [Restore Credentials](https://developer.android.com/identity/sign-in/restore-credentials)) [PRIMARY]. Seul le gestionnaire de mots de passe de Google synchronise entre appareils en usage, via une fenêtre système refusable ([Passwords](https://developer.android.com/identity/passwords)) ; sinon, Google renvoie au serveur de l'app ([Backup overview](https://developer.android.com/guide/topics/data/backup)) [PRIMARY].

Le stockage actuel ne peut pas suivre. Les clés du Keystore, coffre matériel d'Android, sont « non-exportable » ([Keystore](https://developer.android.com/privacy-and-security/keystore)) [PRIMARY] : une sauvegarde copie le fichier chiffré, jamais la clé. Google demande d'exclure des sauvegardes « raw authentication tokens, hardware-bound Android Keystore ciphertext » ([Restore Credentials](https://developer.android.com/identity/sign-in/restore-credentials)) [PRIMARY], et le mainteneur du plugin confirme : « That's intentional » ([#1240](https://github.com/juliansteenbakker/flutter_secure_storage/issues/1240)) [ISSUE]. Sans règles [CODE], Auto Backup copie tout le stockage privé, sauf le cache et `no_backup`, vers le nuage comme lors d'un transfert d'appareil à appareil (D2D, par câble ou Wi-Fi) ([Auto Backup](https://developer.android.com/identity/data/autobackup)) [PRIMARY].

Auto Backup réserve 25 Mo par app ; une page de test dit « 2 MB for cloud backup », sans doute une coquille ([Testing backup](https://developer.android.com/identity/data/testingbackup)) [PRIMARY]. Il tourne, sauvegarde activée, au plus une fois par 24 heures, appareil inactif et sur Wi-Fi, et « a device might never back up ». Il restaure avant le premier lancement et chiffre de bout en bout dès Android 9 avec un verrouillage d'écran ([Auto Backup](https://developer.android.com/identity/data/autobackup)) [PRIMARY].

Block Store garde jusqu'à 16 petites valeurs dans Google Play services : 4 Ko par entrée selon sa page, 1 024 octets selon sa référence, assez pour 32 octets dans les deux cas ([Block Store](https://developer.android.com/identity/block-store), [BlockstoreClient](https://developers.google.com/android/reference/com/google/android/gms/auth/blockstore/BlockstoreClient)) [PRIMARY]. Les valeurs ne vont au nuage que si l'app le demande (`setShouldBackupToCloud(true)`), chiffrées de bout en bout seulement dès Android 9 avec verrouillage. Elles passent sur un nouveau téléphone seulement avec le compte Google ([Testing restore flows](https://developer.android.com/identity/block-store/testing-restore-flows)) [PRIMARY], et survivent à une désinstallation si la sauvegarde Google est activée. Mais la page s'ouvre sur « consider using Passkeys with Credential Manager instead », et la bibliothèque n'a pas bougé depuis juillet 2024 ([Google Maven](https://dl.google.com/android/maven2/com/google/android/gms/play-services-auth-blockstore/maven-metadata.xml)) [PRIMARY].

La clé de restauration (Restore Credentials) est une paire de clés WebAuthn que Google Play services crée en silence et porte au nouveau téléphone, par sauvegarde chiffrée de bout en bout ou par D2D, quel que soit `allowBackup`. Elle exige un serveur WebAuthn et Android 9. Sans compte Google, sauvegarde ou verrouillage, l'app reçoit `E2eeUnavailableException` et peut la créer pour le seul D2D. La désinstallation la supprime ([mise en œuvre](https://developer.android.com/identity/sign-in/restore-credentials-implementation)) [PRIMARY]. Elle ne contient pas la clé de 32 octets ; elle la représente côté serveur [INFERENCE].

Dès avril 2027, Google Play exigera de toute app qui propose une connexion, facultative ou obligatoire, qu'elle rétablisse la session sur un nouvel appareil ; la réussite se mesure à la récupération d'une clé de restauration ([blog Android, 26 août 2026](https://android-developers.googleblog.com/2026/08/app-quality-memory-optimization-secure-onboarding.html), [Play Console Help](https://support.google.com/googleplay/android-developer/answer/17492799)) [PRIMARY]. Mais « Apps that do not offer user accounts or login functionality are not affected », et un invité doit retrouver « that same unauthenticated state ». Block Store ne compte que s'il était en production le 30 septembre 2026 au plus tard [PRIMARY]. Un compte facultatif ajouté plus tard ferait entrer l'app dans le champ [INFERENCE].

D'un iPhone vers Android, les données d'app ne passent que dans le nouveau parcours d'Android 17, « at app developer's discretion » ([Google Support 13626960](https://support.google.com/android/answer/13626960)) [PRIMARY].

## Ce que l'app peut savoir : une restauration sur Android, jamais une sauvegarde

L'app sait ce qu'elle a demandé, jamais ce qui est parti.

| Ce que l'app voudrait savoir | iOS | Android |
|---|---|---|
| La synchro du trousseau, ou la sauvegarde, est-elle activée ? | **Impossible.** Aucune API documentée. L'état n'apparaît que dans l'app Trousseaux d'accès du Mac (« iCloud Keychain » ou « Local Items ») ([TN3137](https://developer.apple.com/documentation/technotes/tn3137-on-mac-keychains)) [PRIMARY] | **Impossible.** `BackupManager` public n'a pas `isBackupEnabled` ([BackupManager](https://developer.android.com/reference/android/app/backup/BackupManager)) [PRIMARY], réservé à la permission système BACKUP [SEARCH]. Indice indirect : `E2eeUnavailableException` (pas de compte Google, sauvegarde coupée ou pas de verrouillage, sans dire lequel) |
| La personne est-elle connectée au compte de la plateforme ? | Pour iCloud en général, oui, avec un entitlement : `CKContainer.accountStatus()` et `CKAccountChanged` (capacité CloudKit et un container), ou `ubiquityIdentityToken` (iCloud Documents ; nil si iCloud Drive est coupé pour l'app). Ne dit rien de l'interrupteur du trousseau ([guide de sécurité](https://help.apple.com/pdf/security/en_US/apple-platform-security-guide.pdf), p. 132) [PRIMARY] | Aucun moyen direct dans les sources ; seulement l'exception ci-dessus |
| La double authentification est-elle active ? | **Impossible** (« No. », [forum 70549](https://developer.apple.com/forums/thread/70549)) | Sans objet |
| Une sauvegarde serait-elle chiffrée de bout en bout ? | Le trousseau l'est toujours. Pour iCloud Backup (de bout en bout seulement avec ADP), aucune API dans les sources | **Oui** : Block Store `isEndToEndEncryptionAvailable()` à tout moment ; `getTransportFlags()` (`FLAG_CLIENT_SIDE_ENCRYPTION_ENABLED`) seulement dans un `BackupAgent`, pendant une sauvegarde |
| La clé est-elle partie dans le nuage, et quand ? | **Impossible.** Un `SecItemAdd` réussi ne prouve rien [INFERENCE] | **Impossible.** Aucun rappel de succès ; `onFullBackup` dit qu'une passe commence, `onQuotaExceeded` que la limite est dépassée |
| Comment la clé a-t-elle été rangée ? | L'app sait seulement qu'elle a écrit avec `kSecAttrSynchronizable = true` | L'app sait si elle a demandé `setShouldBackupToCloud(true)` (le plugin existant ne le renvoie pas à Dart) et si sa clé de restauration a été créée pour le nuage ou pour le seul D2D |
| La première synchro est-elle arrivée sur un nouvel appareil ? | Trousseau : **impossible**, aucune notification de changement. KVS : **oui**, `didChangeExternallyNotification` avec la raison `InitialSyncChange` (entitlement KVS) | Sans objet : Auto Backup restaure avant le premier lancement ; Block Store et la clé de restauration arrivent pendant la configuration du téléphone |
| Cette installation vient-elle d'une restauration ou d'un autre appareil ? | Pas d'API. Heuristique : un repère non synchronisé (élément `ThisDeviceOnly` ou fichier) écrit quand cette installation crée la clé [INFERENCE] | **Oui** : `BackupAgent.onRestoreFinished()` (exige un `backupAgent`), octets Block Store présents sur une installation neuve, clé de restauration présente, ou repère dans `getNoBackupFilesDir()` comparé à une copie sauvegardée |

## Ce qui suit vers un nouveau téléphone dépend du chemin, et les données peuvent arriver sans la clé

| Chemin | Fichiers de l'app | Clé non synchronisée (trousseau iOS aux options actuelles ; stockage chiffré par le Keystore sur Android) | Clé synchronisée (iOS) ; Block Store ou clé de restauration (Android) |
|---|---|---|---|
| iOS · désinstaller puis réinstaller | Perdus [INFERENCE] | Le plus souvent encore là, non documenté : « don't rely on that » ([forum 730924](https://developer.apple.com/forums/thread/730924)) | Encore là, et dans iCloud si la synchro est activée [INFERENCE] |
| iOS · Quick Start, transfert direct | Transférés ([Support 102659](https://support.apple.com/en-us/102659)) | Transférée ([forum 788360](https://developer.apple.com/forums/thread/788360)) | Arrive par la synchro, si activée [INFERENCE] |
| iOS · Quick Start, téléchargement depuis iCloud | Restaurés en arrière-plan ([Support 102659](https://support.apple.com/en-us/102659)) | Inconnu | Par la synchro, si activée |
| iOS · restauration iCloud Backup sur un nouvel iPhone | Restaurés ([Support 108770](https://support.apple.com/en-us/108770)) | **Perdue** ([guide de sécurité](https://help.apple.com/pdf/security/en_US/apple-platform-security-guide.pdf), p. 138 ; [forum 93373](https://developer.apple.com/forums/thread/93373)) | Par la synchro seulement : « iCloud Keychain items aren't part of iCloud backup » ([Support 102441](https://support.apple.com/en-us/102441)) |
| iOS · sauvegarde chiffrée sur ordinateur | Restaurés | Restaurée (guide de sécurité, p. 95 ; forum 93373) | Par la synchro ; traitement par la sauvegarde inconnu |
| iOS · sauvegarde non chiffrée sur ordinateur | Restaurés [INFERENCE] | **Perdue** (guide de sécurité, p. 95) | Par la synchro |
| iOS · Effacer contenu et réglages, puis configurer comme neuf | Effacés (guide de sécurité, p. 92) | Effacée | Revient quand l'appareil rejoint le cercle avec la synchro activée ([Support 109016](https://support.apple.com/en-us/109016)) ; non écrit pour les apps tierces |
| iOS · déconnexion d'iCloud | Restent, sauf si la personne choisit d'effacer ([Support 104958](https://support.apple.com/en-us/104958), [Support 122682](https://support.apple.com/en-us/122682)) | Reste [INFERENCE] | « Garder » : copie locale qui ne se met plus à jour ; « supprimer » : retirée de l'appareil, gardée sur iCloud ([Support 109016](https://support.apple.com/en-us/109016)). Écrit pour « passwords and passkeys » ; inconnu pour une app tierce |
| Android · désinstaller puis réinstaller | Restaurés à l'installation si la sauvegarde est activée et qu'une sauvegarde existe ([Auto Backup](https://developer.android.com/identity/data/autobackup)) ; un témoignage de 2020 cité dans « Utiliser l'app sans compte » le conteste | **Perdue** : restaurée mais indéchiffrable, puis effacée ([#887](https://github.com/juliansteenbakker/flutter_secure_storage/issues/887), [#1240](https://github.com/juliansteenbakker/flutter_secure_storage/issues/1240)) | Block Store : gardé si la sauvegarde Google est activée. Clé de restauration : supprimée ([Play Console Help](https://support.google.com/googleplay/android-developer/answer/17492799)) |
| Android · transfert D2D | Copiés, sauf cache et `no_backup` | **Perdue** : copiée, indéchiffrable, effacée | Block Store : seulement si le compte Google est transféré. Clé de restauration : « always transfers » |
| Android · restauration depuis le nuage | Restaurés si une sauvegarde a eu lieu, 25 Mo au plus | **Perdue**, comme ci-dessus | Block Store : seulement si écrit avec `setShouldBackupToCloud(true)` ; Android 12 (Android 9 sur Pixel). Clé de restauration : seulement si créée pour le nuage |
| Android · sauvegarde coupée | Rien dans le nuage ; D2D inconnu | Rien à récupérer | Block Store : pas de nuage ; D2D et réinstallation inconnus. Clé de restauration : passe encore en D2D ([mise en œuvre](https://developer.android.com/identity/sign-in/restore-credentials-implementation)) |

Les fichiers et la clé peuvent se séparer. Une restauration iCloud Backup sans trousseau synchronisé rend les données locales sans la clé de l'espace serveur ; le trousseau synchronisé sans sauvegarde rend la clé sans les données [INFERENCE].

## Les pannes rapportées sont banales : retard, remplacement, suppression propagée, mise à jour du plugin

**Retard et dédoublement.** Le trousseau n'envoie aucune notification quand un élément arrive : l'app doit relire [INFERENCE]. Pour KVS, une synchronisation a lieu « typically … shortly after » le lancement, selon le DTS ([forum 796134](https://developer.apple.com/forums/thread/796134)) [PRIMARY]. Le paquet flutter_cloud_preferences applique « What the app writes first wins », ce qui garderait une clé neuve contre la restaurée, et a dû corriger la perte de valeurs écrites avant la première descente d'iCloud ([flutter_cloud_preferences](https://github.com/nvanderwaal/flutter_cloud_preferences)) [DOCS].

**Suppression propagée.** Le contournement répandu contre la survie du trousseau à la désinstallation, un drapeau qui repère la réinstallation puis efface le trousseau ([#897](https://github.com/juliansteenbakker/flutter_secure_storage/issues/897)) [ISSUE], effacerait par `deleteAll()` la clé synchronisée sur tous les appareils [INFERENCE]. Passer une clé existante à `synchronizable: true` la cache à `read()` mais pas à `containsKey()` : une app qui prend `null` pour « pas de clé » en crée une autre [INFERENCE].

**Mises à jour du plugin.** `synchronizable` a été ignoré sans erreur de la 10.0.0 à la 10.0.x, jusqu'en mai 2026 ([pub.dev](https://pub.dev/api/packages/flutter_secure_storage_darwin)) [DOCS]. La ligne 0.3.x a ensuite rendu des éléments illisibles : « all our iOS users are logged out » ([#1158](https://github.com/juliansteenbakker/flutter_secure_storage/issues/1158)), une « device-identity key » introuvable après un changement d'accessibilité ([#1164](https://github.com/juliansteenbakker/flutter_secure_storage/issues/1164)), une valeur disparue ([#1229](https://github.com/juliansteenbakker/flutter_secure_storage/issues/1229)) [ISSUE] ; les correctifs vont de la 0.4.1 à la 0.4.3, en septembre 2026. Le plugin ignore encore `synchronizable`, sans erreur, avec `accessControlFlags` ou `useSecureEnclave`, et ne refuse pas une accessibilité `_this_device` [DOCS]. Un développeur rapporte que `WhenUnlocked`, le défaut, échouait souvent au démarrage ([#1164](https://github.com/juliansteenbakker/flutter_secure_storage/issues/1164)) [ISSUE]. Chez react-native-keychain, `cloudSync: false` envoyait `kSecAttrSynchronizable = true` ([#800](https://github.com/oblador/react-native-keychain/issues/800)) [ISSUE].

**Android.** Une restauration D2D a provoqué des plantages au démarrage, parfois même avec `allowBackup="false"` ([tink-java #23](https://github.com/tink-crypto/tink-java/issues/23)) [ISSUE]. Le plugin a renvoyé à `read()` la chaîne « Data has been reset » au lieu de `null` chez plus de 150 utilisateurs, chemin encore présent en 11.2.0 ([#941](https://github.com/juliansteenbakker/flutter_secure_storage/issues/941)) [ISSUE]. Le ticket ouvert [#1298](https://github.com/juliansteenbakker/flutter_secure_storage/issues/1298) décrit la perte de toutes les valeurs après une erreur passagère du Keystore, « even with `resetOnError: false` » [ISSUE].

**Familles, téléphones cédés, vieilles sauvegardes.** Ces risques sont déduits, sans retour d'expérience trouvé. Une clé synchronisée suit le compte Apple : une famille sur un même compte partagerait un espace, et un téléphone cédé encore connecté, ou restauré depuis une vieille sauvegarde, le rouvrirait [INFERENCE]. Le cas observé le plus proche est FlutterFire : une réinstallation reconnectait au même compte, sans régler un plantage dû à des données corrompues ([FlutterFire #3660](https://github.com/firebase/flutterfire/issues/3660)) [ISSUE].

## Les options comparées : aucune ne réunit synchronisation, chiffrement de bout en bout et état lisible

| Option | Nouveau téléphone | Réinstallation, même téléphone | Deux appareils en usage | Chiffré de bout en bout | État détectable | Travail pour une app Flutter |
|---|---|---|---|---|---|---|
| Trousseau iCloud, élément synchronisable | Oui, si synchro du trousseau activée et appareil approuvé | Oui (local, non documenté ; et iCloud) | Oui, entre appareils Apple ; 30 s à 30 min mesurés ; en conflit, une version gagne | Oui, par défaut | Non | Déjà dans flutter_secure_storage 11.2.0 (`synchronizable: true`) ; 60 à 100 lignes Swift seulement pour lire avec `kSecAttrSynchronizableAny` ou éviter les suppressions croisées |
| Magasin clé-valeur iCloud (KVS) | Oui si connecté à iCloud ; vide environ 1 min | Inconnu | Oui ; la valeur la plus récente gagne | **Non** ; stocké en clair sur le disque | Partiel : notifications `InitialSyncChange`, `AccountChange` ; entitlement KVS | flutter_cloud_preferences 0.3.0 (nov. 2026, un auteur, valeurs en clair, « first write wins ») ou environ 120 lignes Swift |
| CloudKit, base privée | Oui si compte iCloud | Inconnu | Oui | Contradictoire ; sûr seulement avec ADP | Compte iCloud oui (`accountStatus`) ; interrupteur du trousseau non | cloud_kit 1.3.0 (sept. 2024, inactif, 344 lignes Swift) ; container, schéma, erreurs de réinitialisation |
| iCloud Backup ou Quick Start, fichiers seuls | Oui | Non | Non | Seulement avec ADP | Non ; la date n'apparaît que dans Réglages | Aucun |
| Auto Backup, fichier ordinaire (hors Keystore) | Oui, par nuage ou D2D, si une sauvegarde a eu lieu | Oui si la sauvegarde est activée | Non | Android 9+ avec verrouillage | Restauration oui ; envoi et interrupteur non | Aucun code ; Google déconseille d'y mettre un jeton |
| Block Store avec sauvegarde cloud | Oui si le compte Google est transféré, ou restauration cloud (Android 12, Android 9 sur Pixel) | Oui si la sauvegarde Google est activée | Non | Oui si Android 9+ avec verrouillage ; l'app peut n'envoyer qu'à cette condition | E2EE oui ; présence locale oui ; envoi non | play_services_block_store 0.8.0 (juin 2025, un auteur, masque l'indicateur E2EE) ou 80 à 150 lignes Kotlin ; API sans nouvelle version depuis juillet 2024 |
| Restore Credentials | Oui : D2D toujours ; nuage si compte, sauvegarde et verrouillage | Non | Non | Oui pour le nuage | Restauration oui ; mode de création oui | Serveur WebAuthn et `BackupAgent` Kotlin sans moteur Flutter ; android_restore_credentials 0.1.0 (sept. 2026, 428 lignes Kotlin) |
| Gestionnaire de mots de passe Google via Credential Manager | Oui si même compte Google | Oui [INFERENCE] | Oui | Inconnu (non étudié) | Non ; enregistrement par une fenêtre refusable | credential_manager 5.1.0 (sept. 2026) ; entrée visible dans la liste des mots de passe [INFERENCE] |

Aucun plugin officiel n'existe pour ces mécanismes ; chaque candidat est un petit paquet d'un seul auteur ([play_services_block_store](https://github.com/chris-wolf/play_services_block_store), [android_restore_credentials](https://github.com/wunderbytes/android_restore_credentials), [cloud_kit](https://github.com/Tutorialwork/cloud_kit)) [DOCS]. Aucun n'expose `ubiquityIdentityToken` ni l'indicateur E2EE de Block Store.

## Les apps comparables annoncent une destination, une date et la condition du retour

Apple affiche « Back Up This [Device] » et « the date and time of your last backup » ([Support 108366](https://support.apple.com/en-us/108366)) [PRIMARY] ; Google, « Backup by Google One » et « On » sous chaque type de données ([Google Support 2819582](https://support.google.com/android/answer/2819582?hl=en)) [PRIMARY]. Bear montre la date de dernière synchronisation et un nuage barré pour « not connected to the internet, or that you have disabled sync » ([Bear](https://bear.app/faq/sync-troubleshooting/)) [VENDOR]. Les apps sans nuage disent la perte : « if your data isn't saved to the cloud, it will be lost » ([HabitKeep](https://www.habitskeep.com/faq)) [SEARCH]. Signal dit la condition du retour : « Losing it means losing access to your backup permanently » ([Signal](https://signal.org/blog/introducing-secure-backups/)) [VENDOR]. Aucune app nommée ne garde une identité anonyme dans Block Store ou un trousseau synchronisé ; un petit projet prévoit « A restore without its key shows Try again / Delete them, never failing silently » ([look-together #111](https://github.com/shrujancheruku/look-together/issues/111)) [ISSUE].

## RevenueCat ne dit rien du trousseau, et un identifiant fourni par l'app change la connexion

La documentation de RevenueCat ne mentionne ni le trousseau ni KVS ([Identifying Customers](https://www.revenuecat.com/docs/customers/identifying-customers.md)) [VENDOR]. En 2022, l'équipe écrivait : « There are some tricks you can do for storing it in the keychain, but … not without it's complications. We don't do this internally in the SDK » ([communauté, 2022](https://community.revenuecat.com/general-questions-7/can-the-anonymous-revenuecat-id-be-used-to-identify-users-across-multiple-app-versions-and-devices-1871)) [VENDOR]. En juin 2026, un employé confirme qu'un identifiant fourni par l'app « will survive reinstalls », mais compte comme un utilisateur identifié : une connexion ultérieure transfère alors les achats au lieu de relier les identifiants ([communauté, 2026](https://community.revenuecat.com/sdks-51/suggestion-allow-custom-anonymous-appuserids-7699)) [VENDOR]. La documentation veut des App User IDs « not guessable » ; prendre la clé d'appareil comme App User ID ferait sortir le secret de l'app [INFERENCE]. L'app utilise purchases_flutter 10.15.2 [CODE].

## Apple n'a pas de règle propre à ce cas ; le droit européen couvre la clé sur l'appareil

Aucune règle d'App Review ne vise ce cas ([App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)) [PRIMARY]. La règle 5.1.1(v) pousse vers l'usage sans connexion ; 5.1.1(i) veut une politique de confidentialité qui explique conservation et suppression. Le DTS cite lui-même trousseau iCloud, KVS et CloudKit pour persister sans compte ([forum 730924](https://developer.apple.com/forums/thread/730924)) [PRIMARY]. L'interdiction du fingerprinting vise ce qu'on « derive … from a device » pour l'identifier ([User Privacy and Data Use](https://developer.apple.com/app-store/user-privacy-and-data-use/)) [PRIMARY] ; une clé aléatoire créée par l'app n'en est pas [INFERENCE]. Le trousseau et KVS ne sont pas des API à justifier dans le manifeste de confidentialité ([Required reason API](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)) [PRIMARY]. Dans l'étiquette de confidentialité, un identifiant serveur relié aux données correspond à « User ID », lié à la personne [INFERENCE] ; il ne devient « tracking » que croisé avec des données tierces publicitaires ou cédé à un courtier ([App privacy details](https://developer.apple.com/app-store/app-privacy-details/)) [PRIMARY].

Le RGPD compte « an online identifier » parmi les moyens d'identifier une personne ([art. 4(1)](https://gdpr-info.eu/art-4-gdpr/), [considérant 30](https://gdpr-info.eu/recitals/no-30/)) [PRIMARY]. Pour l'EDPB, l'article 5(3) de la directive ePrivacy couvre toute information stockée sur l'appareil, « regardless of whether or not it is personal data », sans imposer « systematically » un consentement ([lignes directrices 2/2023](https://www.edpb.europa.eu/system/files/2024-10/edpb_guidelines_202302_technical_scope_art_53_eprivacydirective_v2_en.pdf), § 10 et § 56) [PRIMARY]. Le développeur ne peut pas effacer la copie rangée dans l'iCloud ou le compte Google de la personne ; supprimer l'espace serveur rend la clé inutile [INFERENCE].

## Ce que les preuves n'établissent pas

- **L'absence d'API sur iOS** n'est écrite nulle part par Apple ; elle se déduit.
- **Le trousseau d'une app tierce** n'est pas documenté pour : écriture synchronisée interrupteur coupé, déconnexion d'iCloud, Quick Start via iCloud, sauvegarde chiffrée d'un élément synchronisé, effet d'ADP sur iCloud Backup (le DTS l'ignorait en 2023).
- **Les délais** reposent sur une mesure (2026, trousseau) et un témoignage (2023, KVS).
- **Aucun chiffre** sur l'usage du trousseau iCloud, d'iCloud Backup ou de la sauvegarde Android, ni sur l'état par défaut du trousseau dans iOS 27.
- **La survie du trousseau à la désinstallation** sur iOS 26 ou 27 : aucun témoignage.
- **Le plugin** a été lu dans son code, pas essayé sur un appareil.
- **Android, sauvegarde coupée** : D2D des données et de Block Store, survie de Block Store à une désinstallation, et « certain user actions » qui l'effacent ne sont pas documentés.
- **Restore Credentials** : le besoin d'`assetlinks.json` est flou, et rien ne couvre une clé de restauration sans compte visible.
- **Contradictions non résolues** : 25 Mo ou 2 Mo (Auto Backup), 4 Ko ou 1 024 octets (Block Store), champs CloudKit sans ADP, catégories chiffrées de bout en bout chez Apple (15 et 25 au support, 14 et 23 au guide de sécurité), Zeus contre Apple.
- **Familles, téléphones cédés, clés créées en même temps** : aucun retour d'expérience.
- **La conservation des données KVS et CloudKit** après suppression de l'app, et l'exemption ePrivacy « strictement nécessaire », n'ont pas été examinées.

## Sources

Toutes les pages ont été lues le 26 novembre 2026 par les trois notes de recherche de ce rapport (ios_trousseau_et_alternatives.md, android_mecanismes.md, flutter_apps_et_retours.md), sauf celles marquées [SEARCH], vues seulement en extrait de moteur de recherche. Étiquettes : [PRIMARY] documentation ou réponse du propriétaire de la plateforme, ou texte de loi et de régulateur ; [DOCS] documentation ou code d'un paquet ; [ISSUE] ticket ou témoignage de développeur ; [VENDOR] entreprise parlant de son produit ; [COMMENTARY] article tiers ; [SEARCH] extrait seulement ; [INFERENCE] raisonnement des notes ou du rapport ; [CODE] lu dans le code de l'app.

### Apple, documentation

- [Apple Platform Security guide, août 2026 (PDF)](https://help.apple.com/pdf/security/en_US/apple-platform-security-guide.pdf) — [PRIMARY]
- [kSecAttrSynchronizable](https://developer.apple.com/documentation/security/ksecattrsynchronizable) — [PRIMARY]
- [kSecAttrSynchronizableAny](https://developer.apple.com/documentation/security/ksecattrsynchronizableany) — [PRIMARY]
- [kSecAttrAccessible](https://developer.apple.com/documentation/security/ksecattraccessible) — [PRIMARY]
- [Restricting keychain item accessibility](https://developer.apple.com/documentation/security/restricting-keychain-item-accessibility) — [PRIMARY]
- [kSecAttrAccessibleAfterFirstUnlock](https://developer.apple.com/documentation/security/ksecattraccessibleafterfirstunlock) — [PRIMARY]
- [kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly](https://developer.apple.com/documentation/security/ksecattraccessibleafterfirstunlockthisdeviceonly) — [PRIMARY]
- [Sharing access to keychain items among a collection of apps](https://developer.apple.com/documentation/security/sharing-access-to-keychain-items-among-a-collection-of-apps) — [PRIMARY]
- [kSecAttrAccessGroup](https://developer.apple.com/documentation/security/ksecattraccessgroup) — [PRIMARY]
- [kSecUseDataProtectionKeychain](https://developer.apple.com/documentation/security/ksecusedataprotectionkeychain) — [PRIMARY]
- [TN3137, On Mac keychains](https://developer.apple.com/documentation/technotes/tn3137-on-mac-keychains) — [PRIMARY]
- [FileManager.ubiquityIdentityToken](https://developer.apple.com/documentation/foundation/filemanager/ubiquityidentitytoken) — [PRIMARY]
- [Technical Q&A QA1935 (archive)](https://developer.apple.com/library/archive/qa/qa1935/_index.html) — [PRIMARY]
- [iCloud Design Guide (archive, 2015)](https://developer.apple.com/library/archive/documentation/General/Conceptual/iCloudDesignGuide/Chapters/iCloudFundametals.html) — [PRIMARY]
- [CKContainer.accountStatus](https://developer.apple.com/documentation/cloudkit/ckcontainer/accountstatus(completionhandler:)) — [PRIMARY]
- [CKAccountStatus](https://developer.apple.com/documentation/cloudkit/ckaccountstatus) — [PRIMARY]
- [Entitlement iCloud Services](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.icloud-services) — [PRIMARY]
- [Entitlement ubiquity-kvstore-identifier](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.ubiquity-kvstore-identifier) — [PRIMARY]
- [NSUbiquitousKeyValueStore](https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore) — [PRIMARY]
- [didChangeExternallyNotification](https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore/didchangeexternallynotification) — [PRIMARY]
- [CKRecord.encryptedValues](https://developer.apple.com/documentation/cloudkit/ckrecord/encryptedvalues) — [PRIMARY]
- [Encrypting User Data (CloudKit)](https://developer.apple.com/documentation/cloudkit/encrypting-user-data) — [PRIMARY]
- [App Review Guidelines, « Last Updated: October 16, 2026 »](https://developer.apple.com/app-store/review/guidelines/) — [PRIMARY]
- [App privacy details](https://developer.apple.com/app-store/app-privacy-details/) — [PRIMARY]
- [User Privacy and Data Use](https://developer.apple.com/app-store/user-privacy-and-data-use/) — [PRIMARY]
- [Describing use of required reason API](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api) — [PRIMARY]
- [Apple Support 109016, Set up iCloud Keychain (1er octobre 2026)](https://support.apple.com/en-us/109016) — [PRIMARY]
- [Apple Support 102441, If iCloud Keychain won't turn on or sync (15 septembre 2026)](https://support.apple.com/en-us/102441) — [PRIMARY]
- [Apple Support 104958, Sign out of your Apple Account and iCloud (12 novembre 2026)](https://support.apple.com/en-us/104958) — [PRIMARY]
- [Apple Support 122682, Sign Out But Don't Erase](https://support.apple.com/en-us/122682) — [PRIMARY]
- [Apple Support 102651, iCloud data security overview (5 janvier 2026)](https://support.apple.com/en-us/102651) — [PRIMARY]
- [Apple Support 108770, iCloud Backup](https://support.apple.com/en-us/108770) — [PRIMARY]
- [Apple Support 102659, Use Quick Start (17 novembre 2026)](https://support.apple.com/en-us/102659) — [PRIMARY]
- [Apple Support 108366, Back up iPhone with iCloud (24 septembre 2026)](https://support.apple.com/en-us/108366) — [PRIMARY]
- [iPhone User Guide, Passwords on devices](https://support.apple.com/guide/iphone/passwords-devices-iph82d6721b2/ios) — [PRIMARY]
- [Apple Newsroom, 7 décembre 2022](https://www.apple.com/newsroom/2022/12/apple-advances-user-security-with-powerful-new-data-protections/) — [PRIMARY]

### Apple, forums développeurs (réponses du DTS ou d'ingénieurs, hors documentation)

- [Forum 854637, délais de synchro du trousseau (novembre 2026)](https://developer.apple.com/forums/thread/854637) — [PRIMARY] ; mesure du développeur [ISSUE]
- [Forum 70549, double authentification (2017)](https://developer.apple.com/forums/thread/70549) — [PRIMARY]
- [Forum 36442, trousseau et désinstallation](https://developer.apple.com/forums/thread/36442) — [PRIMARY]
- [Forum 730924, persister sans compte (2023)](https://developer.apple.com/forums/thread/730924) — [PRIMARY]
- [Forum 93373, trousseau et sauvegardes (tableau de test)](https://developer.apple.com/forums/thread/93373) — [PRIMARY]
- [Forum 788360, Quick Start et sauvegarde chiffrée (2025)](https://developer.apple.com/forums/thread/788360) — [PRIMARY]
- [Forum 726593, KVS vide après connexion (2023)](https://developer.apple.com/forums/thread/726593) — [PRIMARY]
- [Forum 796134, synchro KVS au lancement (2025)](https://developer.apple.com/forums/thread/796134) — [PRIMARY]

### Google et Android

- [Block Store](https://developer.android.com/identity/block-store) — [PRIMARY]
- [BlockstoreClient (référence)](https://developers.google.com/android/reference/com/google/android/gms/auth/blockstore/BlockstoreClient) — [PRIMARY]
- [Testing restore flows (Block Store)](https://developer.android.com/identity/block-store/testing-restore-flows) — [PRIMARY]
- [Google Maven, play-services-auth-blockstore](https://dl.google.com/android/maven2/com/google/android/gms/play-services-auth-blockstore/maven-metadata.xml) — [PRIMARY]
- [Restore Credentials, présentation](https://developer.android.com/identity/sign-in/restore-credentials) — [PRIMARY]
- [Restore Credentials, mise en œuvre](https://developer.android.com/identity/sign-in/restore-credentials-implementation) — [PRIMARY]
- [Android Developers Blog, 26 août 2026, Zero Tap Sign-In](https://android-developers.googleblog.com/2026/08/app-quality-memory-optimization-secure-onboarding.html) — [PRIMARY]
- [Play Console Help 17492799, exigences de qualité technique](https://support.google.com/googleplay/android-developer/answer/17492799) — [PRIMARY]
- [Auto Backup for Apps](https://developer.android.com/identity/data/autobackup) — [PRIMARY]
- [Backup overview](https://developer.android.com/guide/topics/data/backup) — [PRIMARY]
- [Testing backup and restore](https://developer.android.com/identity/data/testingbackup) — [PRIMARY]
- [Backup best practices](https://developer.android.com/privacy-and-security/risks/backup-best-practices) — [PRIMARY]
- [Android Keystore](https://developer.android.com/privacy-and-security/keystore) — [PRIMARY]
- [BackupManager](https://developer.android.com/reference/android/app/backup/BackupManager) — [PRIMARY]
- [FullBackupDataOutput](https://developer.android.com/reference/android/app/backup/FullBackupDataOutput) — [PRIMARY]
- [BackupAgent](https://developer.android.com/reference/android/app/backup/BackupAgent) — [PRIMARY]
- [Passwords (Credential Manager)](https://developer.android.com/identity/passwords) — [PRIMARY]
- [Google Support 6197437, gestionnaire de mots de passe](https://support.google.com/accounts/answer/6197437) — [PRIMARY]
- [Google Support 2819582, sauvegarder ou restaurer](https://support.google.com/android/answer/2819582?hl=en) — [PRIMARY]
- [Google Support 13626960, passer d'un iPhone à Android](https://support.google.com/android/answer/13626960) — [PRIMARY]

### Paquets et suivis de tickets

- [flutter_secure_storage, dépôt et README](https://github.com/juliansteenbakker/flutter_secure_storage) — [DOCS]
- [flutter_secure_storage_darwin 0.4.3, FlutterSecureStorage.swift](https://github.com/juliansteenbakker/flutter_secure_storage/blob/flutter_secure_storage_darwin-v0.4.3/flutter_secure_storage_darwin/darwin/flutter_secure_storage_darwin/Sources/flutter_secure_storage_darwin/FlutterSecureStorage.swift) — [DOCS]
- [flutter_secure_storage 11.2.0, apple_options.dart](https://github.com/juliansteenbakker/flutter_secure_storage/blob/flutter_secure_storage-v11.2.0/flutter_secure_storage/lib/options/apple_options.dart) — [DOCS]
- [pub.dev, flutter_secure_storage_darwin (versions)](https://pub.dev/api/packages/flutter_secure_storage_darwin) — [DOCS]
- [pub.dev, flutter_secure_storage (versions)](https://pub.dev/api/packages/flutter_secure_storage) — [DOCS]
- [flutter_secure_storage #1158, utilisateurs iOS déconnectés](https://github.com/juliansteenbakker/flutter_secure_storage/issues/1158) — [ISSUE]
- [flutter_secure_storage #1164, filtre d'accessibilité](https://github.com/juliansteenbakker/flutter_secure_storage/issues/1164) — [ISSUE]
- [flutter_secure_storage #1229, valeur disparue](https://github.com/juliansteenbakker/flutter_secure_storage/issues/1229) — [ISSUE]
- [flutter_secure_storage #897, effacement au premier lancement](https://github.com/juliansteenbakker/flutter_secure_storage/issues/897) — [ISSUE]
- [flutter_secure_storage #1240, Keystore et transfert (mainteneur)](https://github.com/juliansteenbakker/flutter_secure_storage/issues/1240) — [ISSUE]
- [flutter_secure_storage #887, données perdues à la réinstallation](https://github.com/juliansteenbakker/flutter_secure_storage/issues/887) — [ISSUE]
- [flutter_secure_storage #941, « Data has been reset »](https://github.com/juliansteenbakker/flutter_secure_storage/issues/941) — [ISSUE]
- [flutter_secure_storage #1298, perte après erreur du Keystore (ouvert)](https://github.com/juliansteenbakker/flutter_secure_storage/issues/1298) — [ISSUE]
- [tink-java #23, AEADBadTagException au démarrage](https://github.com/tink-crypto/tink-java/issues/23) — [ISSUE]
- [react-native-keychain #800, cloudSync inversé](https://github.com/oblador/react-native-keychain/issues/800) — [ISSUE]
- [FlutterFire #3660, session après réinstallation](https://github.com/firebase/flutterfire/issues/3660) — [ISSUE]
- [Zeus, pull request #5533](https://github.com/ZeusLN/zeus/pull/5533) — [ISSUE]
- [play_services_block_store](https://github.com/chris-wolf/play_services_block_store) — [DOCS]
- [android_restore_credentials](https://github.com/wunderbytes/android_restore_credentials) — [DOCS]
- [flutter_cloud_preferences](https://github.com/nvanderwaal/flutter_cloud_preferences) — [DOCS]
- [icloud_kv_storage_spm](https://github.com/devaryakjha/icloud_kv_storage_spm) — [DOCS]
- [cloud_kit](https://github.com/Tutorialwork/cloud_kit) — [DOCS]
- [pub.dev, credential_manager](https://pub.dev/api/packages/credential_manager) — [DOCS]
- [look-together #111, plan trousseau et Block Store](https://github.com/shrujancheruku/look-together/issues/111) — [ISSUE]

### Apps et vendeurs

- [Bear, sync troubleshooting](https://bear.app/faq/sync-troubleshooting/) — [VENDOR]
- [Signal, Secure Backups (8 septembre 2025)](https://signal.org/blog/introducing-secure-backups/) — [VENDOR]
- [HabitKeep, FAQ](https://www.habitskeep.com/faq) — [SEARCH]
- [RevenueCat, Identifying Customers](https://www.revenuecat.com/docs/customers/identifying-customers.md) — [VENDOR]
- [Communauté RevenueCat, identifiant anonyme entre installations (2022)](https://community.revenuecat.com/general-questions-7/can-the-anonymous-revenuecat-id-be-used-to-identify-users-across-multiple-app-versions-and-devices-1871) — [VENDOR]
- [Communauté RevenueCat, App User IDs anonymes personnalisés (2026)](https://community.revenuecat.com/sdks-51/suggestion-allow-custom-anonymous-appuserids-7699) — [VENDOR]

### Droit

- [RGPD, article 4](https://gdpr-info.eu/art-4-gdpr/) — [PRIMARY]
- [RGPD, considérant 30](https://gdpr-info.eu/recitals/no-30/) — [PRIMARY]
- [EDPB, lignes directrices 2/2023 sur l'article 5(3) ePrivacy, v2.0 (7 octobre 2024)](https://www.edpb.europa.eu/system/files/2024-10/edpb_guidelines_202302_technical_scope_art_53_eprivacydirective_v2_en.pdf) — [PRIMARY]
