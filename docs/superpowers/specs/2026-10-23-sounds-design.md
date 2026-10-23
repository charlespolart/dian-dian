# Sons — design

Date : 2026-10-23. Lot 2 du point 7 de `docs/ROADMAP.md`, à la suite des
animations (`docs/superpowers/specs/2026-10-22-animations-design.md`, branche
`feat/animations`, livraison en app 1.5.0). Brainstormé le 2026-10-23.

## Objectif

Que l'app sonne à ses moments clés, dans le même ton que les animations :
léger, jamais un spectacle. Trois palettes complètes sont montées pour être
comparées à l'oreille sur l'appareil ; une seule est livrée, avec un réglage
« Sons » qui coupe tout.

## Décisions prises en brainstorming

- Trois palettes à l'essai : **Papeterie** (Mixkit), **Interface douce**
  (Kenney, CC0), **Pixel** (synthétisée). Le choix se fait sur l'appareil.
- Dix moments, les mêmes pour chaque palette. Les deux mp3 actuels
  (`dot-tap.mp3`, `dot-erase.mp3`) ne comptent pas : chaque palette apporte
  ses propres « point posé » et « point effacé ».
- Le sélecteur de palette n'existe que sur les builds de debug. Une fois la
  palette choisie, les deux autres dossiers sont supprimés et la tuile se
  cache d'elle-même.
- Hors périmètre : son à la suppression d'un tracker, à la sélection d'une
  légende comme pinceau, réglage de volume, vibration.

## 1. Les moments : `SoundCue`

`lib/services/audio_service.dart` :

```dart
enum SoundCue {
  dotFill,       // un point posé
  dotErase,      // un point effacé
  trackerOpen,   // départ du morphing carte → tracker
  trackerClose,  // départ du morphing tracker → carte
  dialogOpen,    // un pop-up s'ouvre (showAppDialog)
  dialogClose,   // un pop-up se ferme, quelle que soit la façon
  trackerCreate, // une carte de tracker vient d'apparaître
  legendAdd,     // une légende vient d'être ajoutée
  yearChange,    // la grille glisse vers une autre année
  press,         // un bouton ou un lien sous le doigt (PressScale)
}
```

Intention par moment, valable pour les trois palettes : poser est net et
court, effacer est plus doux et plus bas ; ouvrir monte, fermer descend, le
pop-up est une version plus légère du tracker ; créer fait un petit
« voilà » ; l'année glisse ; le bouton fait un tic, plus discret que tout le
reste.

| Moment | Point d'appel | Quand |
|---|---|---|
| `dotFill` / `dotErase` | `CellsProvider`, là où `playTap` / `playErase` sont appelés aujourd'hui | à la mise à jour locale, avant le réseau |
| `trackerOpen` / `trackerClose` | `AppShell._navigate`, quand `transitionFor` rend `morphOpen` / `morphClose` | au départ de la scène (le repli en fondu sonne pareil : même geste) |
| `dialogOpen` | `showAppDialog`, juste avant `navigator.push` | au départ de l'entrée |
| `dialogClose` | `AppDialogRoute.didPop` | au départ de la sortie, barrière, croix, bouton ou retour système confondus |
| `trackerCreate` | `PagesProvider.createPage`, quand la page est ajoutée localement | |
| `legendAdd` | `LegendsProvider.createLegend`, quand la légende est ajoutée localement | |
| `yearChange` | `TrackerScreen._changeYear` et `PageListScreen._changeYear` | avec le glissement |
| `press` | `PressScale`, au tap, avant d'appeler `onTap` / `onTapAt` | voir la règle « un son par geste » |
| `panelOpen` / `panelClose` | la flèche de la barre latérale du tracker (`_showLegendLabels`) | au tap, selon le nouvel état |
| `dragPick` | `Draggable.onDragStarted` d'une carte (liste) ou d'une légende (éditeur) | à la prise |
| `dragHover` | `DragTarget.onWillAcceptWithDetails` quand la cible accepte (elle se surligne) | à chaque entrée sur une cible valable |
| `dragDrop` | `DragTarget.onAcceptWithDetails` | au dépôt, avant le réordonnancement |
| `select` | légende prise comme pinceau (barre latérale), légende choisie dans l'éditeur de case, pastille ou couleur choisie dans l'éditeur de légendes | au tap |
| `dayNext` / `dayPrev` | les flèches de l'éditeur de case (`_navigateDay`) | au pas, selon le sens |

Les points de la grille ne passent pas par `PressScale` : un tap sur une
case ne fait sonner que `dotFill` ou `dotErase`.

## 2. Palettes et fichiers

### Disposition

```
assets/sounds/
  paper/      dot_fill.wav dot_erase.wav tracker_open.wav tracker_close.wav
              dialog_open.wav dialog_close.wav tracker_create.wav
              legend_add.wav year_change.wav press.wav
  interface/  (les dix mêmes noms)
  pixel/      (les dix mêmes noms)
```

`pubspec.yaml` liste les trois dossiers (`assets/sounds/paper/`, …) : une
entrée de dossier n'inclut pas ses sous-dossiers. L'entrée `assets/sounds/`
et les deux mp3 disparaissent. Le nom de fichier d'un moment est son nom en
`snake_case` ; l'identifiant de palette est le nom du dossier
(`SoundPalette.paper` / `.interface` / `.pixel`).

### Format

wav PCM 16 bits, mono, 44,1 kHz (lu nativement sur iOS et Android, sans
latence de décodage ni silence d'amorce). Pas de silence de tête au-delà de
5 ms : le son part avec l'animation. Crête normalisée à −3 dBFS pour tous,
−10 dBFS pour `press`. Durée ≤ 400 ms, sauf `trackerOpen`, `trackerClose` et
`trackerCreate` ≤ 700 ms. Dix fichiers par palette, moins de 100 Ko chacun.

Les conversions (ogg et mp3 → wav, rognage, normalisation) se font avec
`ffmpeg`, par un script commité dans `tools/sounds/` pour que l'import se
rejoue.

### Sources

- **Papeterie** — Mixkit, catégories papier et crayon (page qui tourne,
  papier glissé, crayon qui écrit, tampon, trombone, carton). Licence
  « Sound Effects Free License » : usage personnel et commercial, pas
  d'attribution, interdiction de redistribuer les fichiers tels quels ; les
  embarquer dans une app est l'usage prévu. Les fichiers se téléchargent
  sans compte (`assets.mixkit.co/active_storage/sfx/<id>/<id>-preview.mp3`).
  À confirmer sur la page licence au moment de l'import et noter dans les
  crédits.
- **Interface douce** — Kenney, packs *Interface Sounds* (100 sons : open,
  close, drop, pluck, confirmation, select, tick, toggle, click, switch,
  scroll, back, minimize, maximize…) et *UI Audio* (click, switch,
  rollover). CC0, aucune attribution requise. Déjà téléchargés.
- **Pixel** — synthétisée par `tools/sounds/pixel_palette.py` (numpy) :
  ondes carrées et triangulaires adoucies par un passe-bas, enveloppes
  courtes, une note pour poser et effacer, un arpège de trois notes qui
  monte pour ouvrir et qui descend pour fermer, deux notes pour les pop-ups
  et la légende, quatre pour la création, un balayage pour l'année, un tic
  grave et bref pour le bouton. Le script est la source : on règle les notes
  dedans et on régénère.

`flutter_app/docs/SOUNDS.md` liste, par palette et par fichier, la source,
l'identifiant d'origine et la licence, même quand elle n'exige rien.

### Choix

La comparaison se fait sur iPhone et Android avec la tuile de debug (§4),
chaque palette sur les dix moments, en usage réel pendant quelques minutes.
Une palette gagne ; les deux autres dossiers sont supprimés, l'enum garde
une valeur, `pubspec.yaml` et `SOUNDS.md` suivent. Si Pixel ne gagne pas,
le script de synthèse est supprimé avec elle.

**Essai 1 (2026-10-23, simulateur).** Aucune des trois ne convient : Pixel
est écartée (« horrible »), Interface aussi ; Papeterie est la meilleure
parce que la plus douce et légère, mais « trop papier ». Nouvelle
direction : des sons simples, légers, satisfaisants, comme dans un jeu
chill. Deux palettes la remplacent à l'essai, Papeterie restant la
référence : **Pop** (Mixkit : bulles, pops, petites tonalités de jeu) et
**Soft** (synthèse `tools/sounds/soft_palette.py` : notes de kalimba
pentatoniques, bulles, un souffle, rien de carré). `SoundPalette { paper,
soft, pop }`.

**Ajout (2026-10-23, essai 2).** Six moments de plus demandés à l'essai :
`panelOpen`, `panelClose`, `dragPick`, `dragHover`, `dragDrop`, `select`
(table du §1). `dragHover` et `select` sont plus discrets (−10 et −6 dBFS).
Dix-huit fichiers par palette (`dayNext` / `dayPrev` ajoutés à l'essai 3).

**Essai 2 (2026-10-23).** Dans Soft, le style des bulles des pop-ups plaît ;
le reste doit être aussi simple, « comme des clics satisfaisants ». Soft
devient tout bulles : une par moment, deux ou trois pour le tracker et la
création, le tap sourd pour le bouton ; les notes de kalimba partent.

**Essai 3 (2026-10-23).** Soft tout bulles plaît (« pas mal ! »). Gardée
telle quelle, et deux variantes du même script la rejoignent à l'essai,
« plus soft, plus léger » : **softer** (plus grave, glissés plus étroits,
attaque plus lente, moins d'écho, −4 dB) et **lighter** (plus aigu, plus
court, sans écho, −6 dB). Papier et pop sortent. `SoundPalette { soft,
softer, lighter }` ; `tools/sounds/build.py` ne fait plus que de la
synthèse (numpy seul), plus aucune source tierce.

## 3. Le service : `AudioService`

```dart
enum SoundPalette { paper, interface, pixel }

/// Un son préchargé, rejouable. L'implémentation réelle enveloppe
/// `AudioPlayer` ; les tests en injectent une fausse qui enregistre.
abstract class SoundPlayer {
  Future<void> load(String assetPath);   // 'sounds/paper/dot_fill.wav'
  Future<void> play();                   // depuis le début, même en cours
  Future<void> dispose();
}

class AudioService extends ChangeNotifier {
  factory AudioService();                              // singleton de l'app
  AudioService.custom({required SoundPlayer Function() players});  // tests
  AudioService.silent();                               // rien ne joue, rien ne charge

  bool get enabled;
  Future<void> setEnabled(bool value);                 // persiste
  SoundPalette get palette;
  Future<void> setPalette(SoundPalette value);         // persiste, recharge (debug)
  void play(SoundCue cue);                             // ne lève jamais

  static const prefEnabled = 'sounds_enabled';         // défaut : true
  static const prefPalette = 'sounds_palette';         // défaut : paper
}
```

**Chargement.** Au démarrage (`_init`, comme `PremiumProvider`) : lecture
des deux préférences, puis un `SoundPlayer` par moment, chargé avec le
fichier de la palette active. `setPalette` jette les dix lecteurs et en
recharge dix. Un `play` avant la fin du chargement ne fait rien.

**Lecture.** `play(cue)` : si `enabled` est faux, rien. Sinon le lecteur du
moment rejoue depuis le début (un son en cours est coupé : deux points posés
vite font deux sons). Toute erreur est avalée avec un `debugPrint`, comme
aujourd'hui : un son qui échoue ne remonte jamais d'un tap.

**Lecteur réel** (`lib/services/audioplayers_sound_player.dart`) :
`AudioPlayer` avec `ReleaseMode.stop` (la source reste chargée après un
stop) et `PlayerMode.lowLatency` (SoundPool sur Android ; sans effet sur
iOS). `load` = `setSourceAsset` ; `play` = `stop` puis `resume`. À la
première construction, le contexte audio global est posé une fois :
iOS `AVAudioSessionCategory.ambient` (l'interrupteur silence est respecté,
la musique en cours continue), Android `contentType: sonification`,
`usageType: assistanceSonification`, `audioFocus: none`.

**Un son par geste.** `play(SoundCue.press)` ne joue pas tout de suite : le
tic est mis en attente et joué dans une microtâche. Si un autre moment est
joué d'ici là, dans le même tour d'événement, le tic est abandonné : un
bouton qui ouvre un pop-up, change l'année ou ouvre un tracker ne fait
sonner que ça. Un moment qui arrive plus tard (une création après la réponse
du serveur) sonne en plus du tic : ce sont deux instants.

**Mode « réduire les animations ».** Sans effet sur les sons : ce n'est pas
du mouvement. Seul le réglage « Sons » les coupe.

**Fourniture.** `main.dart` ajoute `ChangeNotifierProvider.value(value:
AudioService())` au `MultiProvider` ; `CellsProvider`, `PagesProvider` et
`LegendsProvider` prennent `AudioService? audio` en construction (défaut :
le singleton), comme `CellsProvider` aujourd'hui. Les widgets (`PressScale`,
les écrans pour l'année, `showAppDialog`) lisent
`context.read<AudioService?>()` : absent dans un test qui ne le fournit pas,
le widget ne sonne pas et ne casse pas.

## 4. Réglages

Section « Sons » dans `SettingsScreen`, entre « Curseur » et les liens, sur
le modèle des sections existantes (`_buildSectionTitle` + `_buildLinkTile`) :

- une tuile dont le libellé est `settings.soundsOn` ou `settings.soundsOff`
  selon l'état ; un tap bascule `setEnabled`, et joue `press` quand on
  réactive, comme aperçu ;
- en debug seulement (`kDebugMode`) et tant que l'enum a plus d'une valeur,
  une tuile « Palette : paper / interface / pixel » qui passe à la suivante
  au tap et joue `trackerOpen` en aperçu. Libellé en dur, pas de
  traduction.

Clés de traduction, dans les quatre locales de `LanguageProvider` (fr, en,
zh simplifié, zh traditionnel) : `settings.sounds` (« Sons » / « Sounds » /
« 音效 » / « 音效 »), `settings.soundsOn` (« Activés » / « On » / « 开启 » /
« 開啟 »), `settings.soundsOff` (« Coupés » / « Off » / « 关闭 » / « 關閉 »).

## 5. Tests

- `audio_service_test.dart`, avec une fausse fabrique de lecteurs et
  `SharedPreferences.setMockInitialValues` : dix lecteurs chargés avec
  `sounds/<palette>/<fichier>.wav` ; `play` rejoue le bon lecteur ; coupé →
  rien ; `press` abandonné quand un autre moment joue dans le même tour,
  joué sinon ; `setEnabled` et `setPalette` persistent, `setPalette`
  recharge ; un lecteur qui lève ne fait pas lever `play`.
- `sound_assets_test.dart` : pour chaque palette et chaque moment, le wav
  existe sous `assets/sounds/`, commence par `RIFF`, pèse moins de 100 Ko ;
  `pubspec.yaml` liste le dossier de chaque palette.
- `app_dialog_test.dart` : `dialogOpen` à l'ouverture, `dialogClose` à la
  fermeture par la barrière et par `pop`.
- `press_scale_test.dart` : `press` enregistré au tap ; rien sans service.
- `cells_provider_test.dart`, `pages_provider_test.dart`,
  `legends_provider_test.dart` : le bon moment enregistré à la pose, à
  l'effacement, à la création.
- Les harnais existants (`ListHarness`, `TrackerHarness`) fournissent
  `AudioService.silent()`.

Sur l'appareil : iPhone avec l'interrupteur silence, puis avec une musique
en cours ; Android ; latence ressentie sur un point posé ; les trois
palettes sur les dix moments.

## 6. Livraison

Avec les animations, en app 1.5.0 : `CHANGELOG.md` (Unreleased, « Added » :
sons, réglage « Sons »), `docs/changelogs/1.5.0.md` en quatre langues,
entrée `whats_new.dart`. Pas de changement backend. Avant de taguer : une
seule palette dans `assets/sounds`, `SOUNDS.md` à jour, tuile de debug sans
objet.
