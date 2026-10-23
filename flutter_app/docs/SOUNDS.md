# Sons de l'app : sources et licences

Dix moments (`SoundCue` dans `lib/services/audio_service.dart`), un fichier
par moment et par palette dans `assets/sounds/<palette>/`, wav PCM 16 bits
mono 44,1 kHz, silence de tête rogné, crête à −3 dBFS (−10 pour `press`),
≤ 400 ms sauf `tracker_open`, `tracker_close`, `tracker_create` ≤ 700 ms.
Tout est produit par `python3 tools/sounds/build.py all` (ffmpeg + numpy),
qui télécharge les sources dans `tools/sounds/cache/` (ignoré par git).
Trois palettes sont construites pour être comparées sur l'appareil ; une
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

## interface — Kenney, CC0 1.0

Packs *Interface Sounds* et *UI Audio* (https://kenney.nl/assets/interface-sounds,
https://kenney.nl/assets/ui-audio), domaine public, aucune attribution requise.

| Moment | Fichier | Traitement |
|---|---|---|
| dot_fill | Interface Sounds `pluck_001.ogg` | 200 ms max |
| dot_erase | Interface Sounds `drop_001.ogg` | 220 ms max |
| tracker_open | Interface Sounds `open_001.ogg` | 600 ms max |
| tracker_close | Interface Sounds `close_001.ogg` | 600 ms max |
| dialog_open | Interface Sounds `open_002.ogg` | 350 ms max |
| dialog_close | Interface Sounds `close_002.ogg` | 350 ms max |
| tracker_create | Interface Sounds `confirmation_001.ogg` | 600 ms max |
| legend_add | Interface Sounds `glass_001.ogg` | 300 ms max |
| year_change | Interface Sounds `scroll_001.ogg` | 300 ms max |
| press | UI Audio `click1.ogg` | 70 ms, −10 dBFS |

## pixel — synthèse, propre à l'app

Généré par `tools/sounds/pixel_palette.py` (ondes carrées et triangulaires
adoucies, enveloppes courtes) : une note pour poser, un glissé descendant
pour effacer, un arpège montant pour ouvrir et descendant pour fermer, deux
notes pour les pop-ups et la légende, quatre pour la création, un balayage
pour l'année, un tic bref pour le bouton. Aucune licence tierce.
