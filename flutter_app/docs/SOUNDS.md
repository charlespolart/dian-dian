# Sons de l'app : source et licence

Dix-huit moments (`SoundCue` dans `lib/services/audio_service.dart`), un
fichier par moment dans `assets/sounds/`, wav PCM 16 bits mono 44,1 kHz,
silence de tête rogné, crête à −3 dBFS (−10 pour `press` et `drag_hover`,
−6 pour `select`, `step_next` et `step_prev`, le tout −2 dB), ≤ 400 ms sauf
`tracker_open` et `tracker_close` ≤ 520 ms, `tracker_create` ≤ 650 ms. Tout est
produit par `python3 tools/sounds/build.py` (palette `bubble_palette` par
défaut, numpy seulement).

## Synthèse, propre à l'app

`tools/sounds/bubble_palette.py` (retenu le 2026-10-29), une seule famille :
la bulle d'eau, un sinus qui monte en quelques millisecondes avec une attaque
douce et une octave ronde dessous. Elle descend en « blub » (effacement,
dépôt, fermeture, suppression plus grave et plus lourde), résonne en
« goutte » (création, légende), devient grave et ronde pour le volet. Trois
bulles qui montent ouvrent un tracker, trois qui descendent le ferment. Un
seul son par moment, jamais deux superposés. Aucune licence tierce. Le
générateur de bruit est ressemé par moment : modifier un son ne change pas
les fichiers des autres.

L'ensemble précédent (`cute_palette.py` : clics en bois, marimba, cloche,
souffle, puis bulles) est gardé dans `tools/sounds/aside/cute/` ;
`python3 tools/sounds/build.py cute_palette` le reconstruit.

## Écartées (essais sur l'appareil, 2026-10-23)

Six palettes ont été comparées avant celle-ci, par un sélecteur qui
n'existait qu'en debug et a été retiré : `paper` et `pop` (Mixkit),
`interface` (Kenney, CC0), `pixel` (ondes carrées), `soft` et ses variantes
`softer`, `lighter`, `gentle` (bulles sinusoïdales), et une première `cute`
à plings d'onde triangulaire. Toutes sont dans l'historique git, tables
d'identifiants Mixkit comprises.
