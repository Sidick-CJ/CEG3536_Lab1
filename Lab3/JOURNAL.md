# JOURNAL.md — Journal d'équipe, CEG 3536, laboratoire 3 (automne 2026)

Équipe : Groupe 15 — Sidick Diomande, Amr Ben Reguiga, Chandish Reebye — Section : A01 — Dépôt Git : https://github.com/Sidick-CJ/CEG3536_Lab1

## Jalon J2 — module d'événements testé sur hôte

| Plateforme | Compilateur et version | Commande | Résultat (cas réussis / échecs) | Date et validation Git |
|---|---|---|---|---|
| Windows | | `make` dans `hote/` | | |
| Linux | gcc 13.3.0 (Ubuntu 24.04) | `make` dans `hote/` | 13 / 0 échec (voir `hote/sortie_linux.txt`) | 13 nov. 2026 |
| STM32 (cible) | arm-none-eabi-gcc | commande série `q` | | |

Cas ajoutés par l'équipe (au-delà des 9 fournis) :

| Cas | Description | Résultat |
|---|---|---|
| 10 | Saturation de la commande `t` : 40 push d'un coup → 32 acceptés, 8 débordements, ordre FIFO intact | réussi (Linux) |
| 11 | Trois tours complets de l'index, file à moitié pleine : aucun élément perdu ni réordonné | réussi (Linux) |
| 12 | Un push refusé ne modifie ni `evq_total` ni `evq_count` | réussi (Linux) |
| 13 | `evq_init` remet tous les compteurs à zéro (commande `z`) | réussi (Linux) |

Différences observées entre hôtes (tailles des types, options, avertissements) :
- Linux x86-64 : `sizeof(evq_event_t)` = 12, `int` = 32 bits, `long` = 64 bits ; aucun avertissement avec `-Wall -Wextra`.
- Cible (arm-none-eabi) : `long` = 32 bits ; même source, aucun avertissement. Windows : à compléter.

## Rôles et rotation

| Séance | Réalise | Valide | Module C écrit par chacun | Routine assembleur écrite ou modifiée par chacun |
|---|---|---|---|---|
| Séance 1 | | | | |
| Période d'étude | | | | |
| Séance 2 | | | | |

## Calculs préalables

| Grandeur | Formule | Valeur | Vérifiée par |
|---|---|---|---|
| `RPM_Q16_K` | round(240 × 65 536 / 748) | 21 028 (exact : 21 027,85) | T3 |
| Erreur relative de la constante | (k − 240 × 65 536 / 748) / (240 × 65 536 / 748) | +0,002 % | T3 |
| fronts maximal sans débordement | 2³² / k | 204 249 | T3 |
| `LPUART1_BRR` | 256 × 4 000 000 / 115 200 | 8 889 (0x22B9) | T9 |
| Débit ADC par voie | 4 MHz / (2 × (640,5 + 12,5)) | ≈ 3 063 éch./s | T4 |
| Durée d'un tour du tampon DMA | 64 / débit par voie (v2 : 64 éch. par voie) | ≈ 20,9 ms (≈ 48 tours/s) | T4 |
| Résolution de la température | 3 300 mV / 4 095 / 10,9 mV/°C | ≈ 0,074 °C par pas | T6 |

## Étalonnage de la température (E6)

| Mesure | Température de référence (°C) | `temp_mv` lu | `TEMP_MV_REF` / `TEMP_C10_REF` retenus | Position de S2 |
|---|---|---|---|---|
| Ambiante | | | | |
| Capteur tenu entre deux doigts (30 s) | | | | |
| Conditionnement externe (pont OUT–IN ou circuit) | | | | |

Analyse interne / externe (plage, résolution, bruit) :

## Journal des séances

### Séance 1 — `<date>` — réalise : `<nom>` / valide : `<nom>`
- Objectifs :
- Fait :
- Décisions (découpage des modules, format des trames, routine L3-A choisie) :
- Difficultés et solutions :
- Mesures :
- Validations Git :

### Période d'étude — travail sur hôte
- Fait (evq, test_evq, cas ajoutés, L3-B / L3-C rédigés) :
- Validations Git :

### Séance 2 — `<date>` — réalise : `<nom>` / valide : `<nom>`
- Objectifs :
- Fait :
- Décisions :
- Difficultés et solutions :
- Mesures (température, cycles DWT, désassemblage) :
- Validations Git :

## Composante L3-A : comparaison assembleur / C

Routine comparée : `motor_set_pwm` (motor.s) ↔ `motor_set_pwm_c` (l3a_c.c)

| Cas | Entrée | Résultat assembleur | Résultat C | Effet de bord (registre / variable) | Écart |
|---|---|---|---|---|---|
| 1 | | | | | |

| Version | Cycles DWT (moyenne) | Taille (octets) | Registres utilisés | Observations (prologue, volatile) |
|---|---|---|---|---|
| Assembleur | | | | |
| C, -O0 | | | | |
| C, -O2 | | | | |

## Composante L3-C : objet d'acquisition

- Version 1 (validation Git) :
- Version 2 (validation Git) et ce qui a changé :
- Essai d'indépendance des deux instances :
- Comparaison avec la version impérative (annexe) :
- Limites :

## Composante L3-D : traces

| Élément | Preuve (fichier) |
|---|---|
| Désassemblage -O0 annoté | |
| Désassemblage -O2 annoté | |
| Trois instructions et leur encodage Thumb | |
| Captures du débogueur (R0–R3, SP, variable volatile) | |
| Cycles DWT -O0 / -O2 et transformation analysée | |

## Tableau des essais (T1 à T10)

| Essai | Date | Résultat observé | Verdict | Preuve (fichier) |
|---|---|---|---|---|
| T1 Initialisation en C | | | | |
| T2 Appel C → assembleur | | | | |
| T3 Virgule fixe | | | | |
| T4 ADC et DMA | | | | |
| T5 Consigne | | | | |
| T6 Température | | | | |
| T7 File d'événements | | | | |
| T8 E-Stop | | | | |
| T9 Télémétrie | | | | |
| T10 Comparaison et traces | | | | |

## Déclaration des sources et de l'usage d'outils d'IA générative
- Sources (complément, corrigé du laboratoire 2 le cas échéant, CMSIS, manuel) :
