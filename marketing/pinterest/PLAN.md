# Pinterest — plan éditorial

Premier canal de communication (décidé le 2026-10-15). Objectif : du trafic
évergreen vers la landing, et donc les stores, à partir des recherches
"year in pixels", "mood tracker", "habit tracker", "bullet journal".
Pinterest est un moteur de recherche visuel : une épingle vit des mois, le
rythme compte plus que le volume.

Langues : anglais (le gros du trafic), français (communauté bullet journal
très active, langue des réponses aux commentaires) et chinois traditionnel
(Taïwan, Hong Kong : audience Pinterest petite, mais les épingles existent
déjà, donc coût nul). Pas de chinois simplifié, Pinterest n'est pas
disponible en Chine continentale.

## Compte et tableaux

Compte Business "Dian Dian" (profil : icône du chat, bio "One dot a day —
year in pixels, mood & habit tracker. Free on iOS & Android.", site
`diandian.overridedev.com`, déjà vérifié).

Tableaux (un par intention de recherche, titres = mots-clés) :

| Tableau | Contenu |
|---|---|
| Year in Pixels | épingles "year", exports d'utilisateurs, idées de palettes |
| Mood Tracker Ideas | épingles "mood", palettes d'humeur, légendes types |
| Habit Tracker | épingles "habits", "exercise", "reading" |
| Sleep Tracker | épingles "sleep" |
| Suivi d'humeur & habitudes (FR) | toutes les épingles françaises |
| 心情與習慣追蹤 (繁體) | toutes les épingles en chinois traditionnel |

Descriptions des tableaux : une phrase avec le mot-clé du tableau, "one dot
a day" et "Dian Dian, free on iOS & Android".

## Les épingles

Générées par `marketing/pinterest/pins.py` dans le style de l'app
(1000 × 1500, le format Pinterest), une par thème et par langue, avec
`pins.csv` à côté : titre, description, texte alternatif, mots-clés et lien
de chaque épingle, à coller tels quels.

```bash
python3 marketing/pinterest/pins.py "/Users/charlespolart/Documents/Store captures/Dian Dian/Pinterest"
```

Règles de copie (celles de Pinterest) : titre ≤ 100 caractères avec le
mot-clé principal au début ; description 200–500 caractères, 2 ou 3
mots-clés placés naturellement, pas de liste de hashtags ; texte alternatif
descriptif ; lien vers la landing avec `utm_source=pinterest` et un
`utm_campaign` par épingle (la landing le reporte sur les boutons stores,
voir "Mesure").

Thèmes v1 : mood, sleep, exercise, reading, habits, year (18 épingles).
Thèmes à ajouter ensuite : water, meditation, study, period, "12 things to
track in 2027" (épingle liste), palettes de couleurs (épingle "5 palettes
pour un mood tracker"), avant/après (grille vide → grille pleine).

## Rythme

- Semaine 1 : créer le compte et les tableaux, publier 6 épingles anglaises
  (une par thème), 3 françaises (mood, year, habits) et 2 en chinois
  traditionnel (mood, year), étalées sur la semaine avec "Publier à une
  date ultérieure".
- Ensuite : 3 à 5 épingles par semaine, programmées d'avance dans Pinterest
  (bouton "Publier à une date"), en alternant thèmes et langues. Une même
  image peut être réépinglée sur un second tableau pertinent deux semaines
  plus tard.
- Tous les mois : régénérer un lot avec de nouvelles palettes (changer les
  `seed`) et de nouveaux thèmes, 10 à 15 épingles.
- Les effets arrivent à 2–3 mois ; ne rien juger avant 8 semaines.

## Contenu d'utilisateurs (le vrai levier)

L'export PNG de l'app est déjà une image de tracker avec titre, légendes,
stats et "点点 Dian Dian". Prochaine évolution de l'app (1.3.x) : le rendre
directement épinglable — format 2:3, le chat, un lien court — et proposer
"Partager sur Pinterest" dans la feuille de partage. Chaque utilisateur qui
partage son année devient une épingle de plus vers la landing.

## Mesure

- Pinterest Analytics : impressions, enregistrements, clics sortants par
  épingle (les enregistrements sont le signal le plus fiable).
- Landing : les liens d'épingles portent `utm_source=pinterest&utm_campaign=…` ;
  la landing reporte la campagne sur les boutons stores (lien campagne App
  Store Connect, `referrer` Play), donc les installations attribuées
  apparaissent dans App Store Connect → Analytics → Sources et dans la Play
  Console → Acquisition.
- À regarder toutes les deux semaines : épingles enregistrées, clics,
  installations attribuées, et quel thème/langue marche le mieux pour
  orienter le lot suivant.

## Après Pinterest

Vidéo courte (TikTok / Reels / Shorts) : le remplissage d'une grille en 10 s
est "satisfying" et se fait en capture d'écran, sans visage ni montage. À
instruire : quels outils IA génèrent ces vidéos à partir de captures
(l'app elle-même peut aussi exporter une animation du remplissage).
