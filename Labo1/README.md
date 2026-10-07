# Hordle : un Wordle personnalisable pour le terminal

**Équipe :** Calvin Graf, Esteban Lopez

**Cours :** PLP, HEIG-VD, Projet 1

## Description

Hordle est un jeu de Wordle en ligne de commande, écrit en Haskell. Dans le Wordle original, tout le monde joue le même mot de 5 lettres, une fois par jour, sans aucun contrôle sur la difficulté. Hordle laisse le joueur choisir la **longueur du mot** et la **difficulté**, puis tire un mot dans une **liste de mots au format CSV** qui correspond à ces choix.

Un enseignant qui veut un jeu de vocabulaire avec des mots de 7 lettres, un parent qui veut des mots faciles de 4 lettres pour son enfant, ou un groupe d'amis qui veut un vrai défi ne peuvent pas facilement configurer le jeu original. De plus, « difficile » est subjectif. Mot calcule donc un score de difficulté pour chaque mot à partir de plusieurs règles.

**Ce qui rend le projet original.**
- La difficulté est mesurée : elle dépend du nombre de mots proches (par exemple `LIGHT`, `FIGHT`, `MIGHT`, `SIGHT`...), des lettres répétées et de la rareté des lettres.
- Chaque puzzle a un **code** partageable. Un ami peut rejouer exactement le même puzzle avec ce code, et la **grille de partage** de fin de partie montre le résultat sans révéler le mot. 
 Exemple : 
<br>⬛🟨⬛⬛🟩
<br>🟨🟩⬛⬛🟩
<br>🟩🟩⬛🟩🟩
<br>🟩🟩🟩🟩🟩

## Fonctionnalités

### Noyau

1. **Liste de mots CSV.** L'application lit un fichier CSV, le valide, normalise les mots (minuscules, lettres `a-z` uniquement, sans doublons) et les filtre par longueur.
2. **Réglages du joueur.** Le joueur choisit la longueur du mot (`--length`), la difficulté (`--difficulty easy|medium|hard`) et, au besoin, le nombre d'essais (`--tries`, 6 par défaut).
3. **Score de difficulté.** Une fonction pure attribue à chaque mot un score de 0 à 100, calculé à partir de :
   - le nombre de *voisins* dans la liste (mots qui diffèrent d'exactement une lettre)
   - la présence de lettres répétées
   - la rareté de ses lettres (calculée avec les fréquences des lettres dans la liste)

   Le score est ensuite classé en `Easy`, `Medium` ou `Hard`. Le joueur peut avoir les détails de difficulté d'un mot avec `rate`
4. **Partie dans le terminal.** Le joueur a un nombre d'essais limité. Chaque essai est validé (bonne longueur, uniquement des lettres, présent dans la liste) et le résultat est affiché : 🟩 bien placée, 🟨 présente ailleurs dans le mot, ⬛ absente. Les lettres répétées sont gérées correctement.
5. **Tirage reproductible.** `--seed N` rend le choix du mot déterministe. Nous écrivons notre propre petit générateur pseudo-aléatoire (une fonction pure), car le paquet `random` n'est pas distribué avec GHC.
6. **Codes de puzzle.** Chaque puzzle a un code comme `WS1-5-6-KQVNB` (version, longueur du mot, nombre d'essais, et la réponse légèrement brouillée pour qu'elle ne soit pas lisible au premier coup d'œil). `play --code CODE` rejoue un puzzle.
7. **Grille de partage.** À la fin de la partie, l'application affiche une grille de carrés de couleur sans lettres, avec le code du puzzle et le nombre d'essais utilisés.

### Bonus

- **Clavier des lettres.** Après chaque essai, l'application affiche le meilleur statut connu de chaque lettre de l'alphabet (vertes, jaunes, absentes, restantes). Une lettre garde son meilleur statut : une lettre trouvée à la bonne place reste verte.
- **Fichiers CSV de l'utilisateur.** Le joueur peut utiliser sa propre liste de mots avec `--words FILE`. Les erreurs sont signalées avec le numéro de ligne (mot vide, caractères interdits, ...).

## Commandes et options

| Commande | Description |
|---|---|
| `hordle play [options]` | Jouer un puzzle |

| Option | Description | Valeur par défaut |
|---|---|---|
| `--length N` | Longueur du mot | `5` |
| `--difficulty D` | `easy`, `medium` ou `hard` | `medium` |
| `--tries N` | Nombre maximal d'essais | `6` |
| `--seed N` | Graine du tirage aléatoire | aucune |
| `--code CODE` | Rejouer le puzzle correspondant à un code | aucun |
| `--words FILE` | Utiliser une autre liste CSV (bonus) | `data/words.csv` |

**Format du CSV :** une ligne d'en-tête `word`, puis un mot par ligne. Les mots ne contiennent que les lettres `a-z` (la liste fournie est sans accents).

```csv
word
grave
pause
terre
```

## Exemples

### Jouer une partie

```
$ hordle play --length 5 --difficulty medium --seed 42
Puzzle WS1-5-6-KQVNB (5 lettres, 6 essais)

Essai 1/6 > pause
P  A  U  S  E
⬛ 🟨 ⬛ ⬛ 🟩

Essai 2/6 > xyzzy
Essai invalide : "xyzzy" n'est pas dans la liste de mots.

Essai 2/6 > aride
A  R  I  D  E
🟨 🟩 ⬛ ⬛ 🟩

Essai 3/6 > grive
G  R  I  V  E
🟩 🟩 ⬛ 🟩 🟩

Essai 4/6 > grave
G  R  A  V  E
🟩 🟩 🟩 🟩 🟩

Gagné en 4/6 !

Partagez votre résultat :
hordle HL1-5-6-KQVNB 4/6
⬛🟨⬛⬛🟩
🟨🟩⬛⬛🟩
🟩🟩⬛🟩🟩
🟩🟩🟩🟩🟩
```

Un essai invalide ne consomme pas d'essai. Le code et les valeurs de ces exemples sont donnés à titre d'illustration.

### Rejouer un puzzle partagé

```
$ hordle play --code WS1-5-6-KQVNB
```

### Évaluer un mot

```
$ hordle rate terre
Mot               : TERRE
Voisins           : 6
Lettres répétées  : oui
Lettres rares     : 0
Difficulté        : 61/100 (Moyen)
```

### Clavier des lettres (bonus)

Affiché après chaque essai :

```
Essai 1/6 > pause
P  A  U  S  E
⬛ 🟨 ⬛ ⬛ 🟩

Vertes    : E
Jaunes    : A
Absentes  : P S U
Restantes : B C D F G H I J K L M N O Q R T V W X Y Z
```

### Erreurs

```
$ hordle play --length 12 --difficulty hard
Erreur : aucun mot de 12 lettres avec la difficulté Difficile dans data/words.csv.

$ hordle play --words mes_mots.csv        # bonus
Erreur : mes_mots.csv, ligne 12 : "b0njour" ne doit contenir que des lettres.
```