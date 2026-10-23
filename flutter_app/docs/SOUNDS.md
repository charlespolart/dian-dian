# Sons de l'app : sources et licences

Seize moments (`SoundCue` dans `lib/services/audio_service.dart`), un fichier
par moment et par palette dans `assets/sounds/<palette>/`, wav PCM 16 bits
mono 44,1 kHz, silence de tête rogné, crête à −3 dBFS (−10 pour `press` et
`drag_hover`, −6 pour `select`, plus un décalage par palette), ≤ 400 ms sauf
`tracker_open`, `tracker_close`, `tracker_create` ≤ 700 ms. Tout est produit
par `python3 tools/sounds/build.py` (numpy seulement). Les palettes sont
construites pour être comparées sur l'appareil ; une seule est livrée (spec
`docs/superpowers/specs/2026-10-23-sounds-design.md`).

## soft, softer, lighter — synthèse, propre à l'app

Toutes trois sortent de `tools/sounds/soft_palette.py` : chaque moment est
une bulle, un sinus dont la hauteur glisse vers le haut ou vers le bas en
quelques millisecondes et s'éteint en quelques dizaines, court et net comme
un clic ; les grands moments en enchaînent deux ou trois ; un tap sourd pour
le bouton ; deux courts échos pour le corps. Un `Style` infléchit tout le
jeu :

| Palette | Hauteur | Durée | Décroissance | Glissé | Attaque | Écho | Niveau |
|---|---|---|---|---|---|---|---|
| soft | ×1 | ×1 | ×1 | ×1 | 1,5 ms | ×1 | 0 dB |
| softer | ×0,85 | ×1 | ×0,85 | ×0,65 | 5 ms | ×0,7 | −4 dB |
| lighter | ×1,3 | ×0,6 | ×0,6 | ×0,8 | 1,5 ms | ×0 | −6 dB |

Aucune licence tierce.

## Écartées

- `paper` (Mixkit, papier et crayon) et `pop` (Mixkit, bulles et pops) :
  essais 1 et 2, 2026-10-23. Les tables d'identifiants sont dans l'historique
  git (`tools/sounds/build.py` avant le passage tout synthèse).
- `interface` (Kenney, CC0) et `pixel` (ondes carrées) : essai 1.
- Première version de `soft` à notes de kalimba : jugée trop musicale.
