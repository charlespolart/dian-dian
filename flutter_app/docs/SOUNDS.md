# Sons de l'app : sources et licences

Dix moments (`SoundCue` dans `lib/services/audio_service.dart`), un fichier
par moment et par palette dans `assets/sounds/<palette>/`, wav PCM 16 bits
mono 44,1 kHz, silence de tête rogné, crête à −3 dBFS (−10 pour `press`),
≤ 400 ms sauf `tracker_open`, `tracker_close`, `tracker_create` ≤ 700 ms.
Tout est produit par `python3 tools/sounds/build.py all` (ffmpeg + numpy),
qui télécharge les sources dans `tools/sounds/cache/` (ignoré par git).
Les palettes sont construites pour être comparées sur l'appareil ; une
seule est livrée (spec `docs/superpowers/specs/2026-10-23-sounds-design.md`).

Titres Mixkit relevés le 2026-10-23 sur `mixkit.co/free-sound-effects/`.

## paper — Mixkit, Sound Effects Free License

Usage personnel et commercial, sans attribution ; les fichiers ne doivent
pas être redistribués tels quels (ils sont embarqués dans l'app, pas
proposés au téléchargement). https://mixkit.co/license/

| Moment | Source Mixkit | Traitement |
|---|---|---|
| dot_fill | 2376 « Short pencil writing » | 160 ms |
| dot_erase | 2380 « Paper quick movement » | 220 ms |
| tracker_open | 1104 « Page turn single » | 600 ms max |
| tracker_close | 1104 « Page turn single » | inversé, 600 ms max |
| dialog_open | 1530 « Paper slide » | 260 ms |
| dialog_close | 1530 « Paper slide » | inversé, 260 ms |
| tracker_create | 2995 « Stapling paper » | 400 ms |
| legend_add | 3102 « Duct tape bandage » | 300 ms |
| year_change | 1097 « Turning the newspaper big page » | 380 ms |
| press | 1125 « Typewriter soft click » | 70 ms, −10 dBFS |

## pop — Mixkit, Sound Effects Free License

Bulles, pops et petites tonalités de jeu (même licence que `paper`).

| Moment | Source Mixkit | Traitement |
|---|---|---|
| dot_fill | 731 « Cartoon bubble pop » | 160 ms |
| dot_erase | 2925 « Soap bubble sound » | 220 ms |
| tracker_open | 2820 « Magic marimba » | 600 ms max |
| tracker_close | 2575 « Software interface back » | 500 ms max |
| dialog_open | 2357 « Bubble pop up alert notification » | 260 ms |
| dialog_close | 2356 « Dry pop up notification alert » | 260 ms |
| tracker_create | 3193 « Bubbly achievement tone » | 700 ms max |
| legend_add | 960 « Tile game reveal » | 350 ms |
| year_change | 3005 « Explainer video pops whoosh light pop » | 300 ms max |
| press | 1124 « Plastic bubble click » | 60 ms, −10 dBFS |

## soft — synthèse, propre à l'app

Généré par `tools/sounds/soft_palette.py` : notes de kalimba (quelques
partiels sinusoïdaux à décroissance douce, attaque de 2 ms, un tic de
maillet) sur une gamme pentatonique, bulles (sinus dont la hauteur glisse
en quelques millisecondes), un souffle filtré pour l'année, un tap sourd
pour le bouton, deux courts échos pour le corps. Aucune licence tierce.

Palettes écartées après le premier essai sur l'appareil (2026-10-23) :
`interface` (Kenney Interface Sounds + UI Audio, CC0) et `pixel` (ondes
carrées synthétisées), jugées respectivement quelconque et désagréable.
