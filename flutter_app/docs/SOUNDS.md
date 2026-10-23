# Sons de l'app : sources et licences

Dix-sept moments (`SoundCue` dans `lib/services/audio_service.dart`), un fichier
par moment et par palette dans `assets/sounds/<palette>/`, wav PCM 16 bits
mono 44,1 kHz, silence de tête rogné, crête à −3 dBFS (−10 pour `press` et
`drag_hover`, −6 pour `select`, `step_next` et `step_prev`, plus un décalage par palette), ≤ 400 ms sauf
`tracker_open`, `tracker_close`, `tracker_create` ≤ 700 ms. Tout est produit
par `python3 tools/sounds/build.py` (numpy seulement). Les palettes sont
construites pour être comparées sur l'appareil ; une seule est livrée (spec
`docs/superpowers/specs/2026-10-23-sounds-design.md`).

## gentle, cute — synthèse, propre à l'app

**gentle** sort de `tools/sounds/soft_palette.py` : chaque moment est une
bulle, un sinus dont la hauteur glisse vers le haut ou vers le bas en
quelques millisecondes et s'éteint en quelques dizaines, court et net comme
un clic ; les grands moments en enchaînent deux ou trois ; un tap sourd pour
le bouton ; deux courts échos pour le corps. Son `Style` : hauteur ×0,95,
décroissance ×0,9, glissé ×0,6, attaque 6 ms, écho ×0,8, passe-bas à
2 600 Hz, niveau −3 dB.

**cute** sort de `tools/sounds/cute_palette.py`, dans l'esprit de
Minecraft, Tiny Wings et Stardew Valley : organique, chaud, un peu boisé.
Des clics en bois (une bande de bruit qui meurt en quelques millisecondes
sur un corps grave) pour le bouton, les pas, le survol et la sélection ; le
« pop » de ramassage (un sinus qui monte très vite, un grain de bruit) pour
le point posé ; un « plop » sourd (sinus qui descend dans un coup grave, une
bouffée de bruit) pour l'effacement et le dépôt ; des notes de marimba
(fondamentale, anche au quadruple, coup de maillet) pour l'ouverture, la
fermeture et les pop-ups ; un « ding » de cloche à partiels inharmoniques,
façon orbe d'expérience, pour la création et la légende ; un souffle pour
le panneau. Niveau −2 dB. Aucune licence tierce.

## Écartées

- `soft` (les bulles sans adoucissement) : essai 4, gentle la remplace.
- Première `cute` à plings d'onde triangulaire : essai 4, « à retravailler ».
- `softer` (plus grave, glissés étroits) et `lighter` (plus aigu, court,
  sec) : essai 3, variantes de soft non retenues.
- `paper` (Mixkit, papier et crayon) et `pop` (Mixkit, bulles et pops) :
  essais 1 et 2. Les tables d'identifiants sont dans l'historique git
  (`tools/sounds/build.py` avant le passage tout synthèse).
- `interface` (Kenney, CC0) et `pixel` (ondes carrées) : essai 1.
- Première version de `soft` à notes de kalimba : jugée trop musicale.
