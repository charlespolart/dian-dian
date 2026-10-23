# Sons de l'app : sources et licences

Dix-sept moments (`SoundCue` dans `lib/services/audio_service.dart`), un fichier
par moment et par palette dans `assets/sounds/<palette>/`, wav PCM 16 bits
mono 44,1 kHz, silence de tête rogné, crête à −3 dBFS (−10 pour `press` et
`drag_hover`, −6 pour `select`, `step_next` et `step_prev`, plus un décalage par palette), ≤ 400 ms sauf
`tracker_open`, `tracker_close`, `tracker_create` ≤ 700 ms. Tout est produit
par `python3 tools/sounds/build.py` (numpy seulement). Les palettes sont
construites pour être comparées sur l'appareil ; une seule est livrée (spec
`docs/superpowers/specs/2026-10-23-sounds-design.md`).

## soft, gentle, cute — synthèse, propre à l'app

**soft** et **gentle** sortent de `tools/sounds/soft_palette.py` : chaque
moment est une bulle, un sinus dont la hauteur glisse vers le haut ou vers
le bas en quelques millisecondes et s'éteint en quelques dizaines, court et
net comme un clic ; les grands moments en enchaînent deux ou trois ; un tap
sourd pour le bouton ; deux courts échos pour le corps. Un `Style`
infléchit tout le jeu :

| Palette | Hauteur | Décroissance | Glissé | Attaque | Écho | Passe-bas | Niveau |
|---|---|---|---|---|---|---|---|
| soft | ×1 | ×1 | ×1 | 1,5 ms | ×1 | aucun | 0 dB |
| gentle | ×0,95 | ×0,9 | ×0,6 | 6 ms | ×0,8 | 2 600 Hz | −3 dB |

**cute** sort de `tools/sounds/cute_palette.py` : des « plings », une onde
triangulaire creuse et moelleuse avec un petit coup de hauteur à l'attaque,
décroissance courte, passe-bas à 3,5 kHz, sur une pentatonique majeure ;
les grands moments sont des motifs de deux à quatre plings, la prise d'un
glisser fait « boing » (coup de hauteur long, un peu de vibrato), le dépôt
fait « plop » ; niveau −2 dB. Aucune licence tierce.

## Écartées

- `softer` (plus grave, glissés étroits) et `lighter` (plus aigu, court,
  sec) : essai 3, 2026-10-23, variantes de soft non retenues.
- `paper` (Mixkit, papier et crayon) et `pop` (Mixkit, bulles et pops) :
  essais 1 et 2. Les tables d'identifiants sont dans l'historique git
  (`tools/sounds/build.py` avant le passage tout synthèse).
- `interface` (Kenney, CC0) et `pixel` (ondes carrées) : essai 1.
- Première version de `soft` à notes de kalimba : jugée trop musicale.
