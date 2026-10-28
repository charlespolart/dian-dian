# Sons de l'app : source et licence

Dix-huit moments (`SoundCue` dans `lib/services/audio_service.dart`), un
fichier par moment dans `assets/sounds/`, wav PCM 16 bits mono 44,1 kHz,
silence de tête rogné, crête à −3 dBFS (−10 pour `press` et `drag_hover`,
−6 pour `select`, `step_next` et `step_prev`, le tout −2 dB), ≤ 400 ms sauf
`tracker_open` et `tracker_close` ≤ 520 ms, `tracker_create` ≤ 650 ms. Tout est
produit par `python3 tools/sounds/build.py` (numpy seulement).

## Synthèse, propre à l'app

`tools/sounds/cute_palette.py`, dans l'esprit de Minecraft, Tiny Wings et
Stardew Valley : organique, chaud, un peu boisé. Des bulles (un sinus qui
glisse en quelques millisecondes, un grain de bruit) pour le bouton, la
sélection, les pas (qui montent vers l'avant, descendent vers l'arrière) et
le survol d'un glisser ; le « pop » de ramassage, la
même voix en plus grand, pour le point posé et, plus grave, la prise d'un
glisser ; un « plop » sourd (sinus qui descend dans un
coup grave, une bouffée de bruit) pour l'effacement et le dépôt ; des notes
de marimba (fondamentale, anche au quadruple, coup de maillet), seules,
pour l'ouverture, la fermeture et les pop-ups ; un « ding » de cloche à
partiels inharmoniques, façon orbe d'expérience, pour la création et la
légende ; un souffle, plus clair à l'ouverture et plus sombre à la fermeture,
pour le panneau ; le même plop, plus grave et plus lourd, pour la suppression
d'un tracker. Un seul son par moment, jamais deux superposés. Aucune
licence tierce.

## Écartées (essais sur l'appareil, 2026-10-23)

Six palettes ont été comparées avant celle-ci, par un sélecteur qui
n'existait qu'en debug et a été retiré : `paper` et `pop` (Mixkit),
`interface` (Kenney, CC0), `pixel` (ondes carrées), `soft` et ses variantes
`softer`, `lighter`, `gentle` (bulles sinusoïdales), et une première `cute`
à plings d'onde triangulaire. Toutes sont dans l'historique git, tables
d'identifiants Mixkit comprises.
