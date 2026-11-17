# JOURNAL.md — Journal d'équipe, CEG 3536, laboratoire 3 (automne 2026)

Équipe : Groupe 15 — Sidick Diomande, Amr Ben Reguiga, Chandish Reebye — Section : A01 — Dépôt Git : https://github.com/Sidick-CJ/CEG3536_Lab1

## Jalon J2 — module d'événements testé sur hôte

| Plateforme | Compilateur et version | Commande | Résultat (cas réussis / échecs) | Date et validation Git |
|---|---|---|---|---|
| Windows | — | `make` dans `hote/` | Non réalisé (pas de gcc hôte sur le poste de STE 2061) | — |
| Linux | gcc 13.3.0 (Ubuntu 24.04) | `make` dans `hote/` | 13 / 0 échec (voir `hote/sortie_linux.txt`) | Testé le 13 nov. 2026 ; validé dans Git le 14 nov. (commit ae64f1a) |
| STM32 (cible) | arm-none-eabi-gcc (STM32CubeIDE 2.2.0) | commande série `q` | `Q,echecs=0` | 13 nov. 2026 |

Cas ajoutés par l'équipe (au-delà des 9 fournis) :

| Cas | Description | Résultat |
|---|---|---|
| 10 | Saturation de la commande `t` : 40 push d'un coup → 32 acceptés, 8 débordements, ordre FIFO intact | réussi (Linux, cible) |
| 11 | Trois tours complets de l'index, file à moitié pleine : aucun élément perdu ni réordonné | réussi (Linux, cible) |
| 12 | Un push refusé ne modifie ni `evq_total` ni `evq_count` | réussi (Linux, cible) |
| 13 | `evq_init` remet tous les compteurs à zéro (commande `z`) | réussi (Linux, cible) |

Différences observées entre hôtes (tailles des types, options, avertissements) :
- Linux x86-64 : `sizeof(evq_event_t)` = 12, `int` = 32 bits, `long` = 64 bits ; aucun avertissement avec `-Wall -Wextra`.
- Cible (arm-none-eabi) : `long` = 32 bits ; même source, aucun avertissement.
- Windows : non testé.

## Rôles et rotation

La répartition est restée la même pendant tout le laboratoire.

| Séance | Réalise | Valide | Module C écrit par chacun | Routine assembleur écrite ou modifiée par chacun |
|---|---|---|---|---|
| Séance 1 (6 nov.) | Sidick | Amr, Chandish | non consigné | non consigné |
| Période d'étude et 13 nov. | Sidick | Amr, Chandish | Sidick : main.c, fsm.c, evq.c, acq.c, adc_dma.c, telem.c, l3a_c.c | Sidick : vitesse.s |
| Séance 2 (13 nov.) et séance du 17 nov. | Sidick | Amr (essais, captures), Chandish (mesures) | — | — |

## Calculs préalables

| Grandeur | Formule | Valeur | Vérifiée par |
|---|---|---|---|
| `RPM_Q16_K` | round(240 × 65 536 / 748) | 21 028 (exact : 21 027,85) | T3 |
| Erreur relative de la constante | (k − 240 × 65 536 / 748) / (240 × 65 536 / 748) | +0,002 % | T3 |
| fronts maximal sans débordement | 2³² / k | 204 249 | T3 |
| `LPUART1_BRR` | 256 × 4 000 000 / 115 200 | 8 889 (0x22B9) | T1 (SFR), T9 |
| Débit ADC par voie | 4 MHz / (2 × (640,5 + 12,5)) | ≈ 3 063 éch./s | T4 : 3 010 et 3 112 éch./s mesurés |
| Durée d'un tour du tampon DMA | 64 / débit par voie (v2 : 64 éch. par voie) | ≈ 20,9 ms (≈ 48 tours/s) | T4 : 47,0 et 48,6 tours/s mesurés |
| Résolution de la température | 3 300 mV / 4 095 / 10,9 mV/°C | ≈ 0,074 °C par pas | T6 |

## Étalonnage de la température (E6)

| Mesure | Température de référence (°C) | `temp_mv` lu | `TEMP_MV_REF` / `TEMP_C10_REF` retenus | Position de S2 |
|---|---|---|---|---|
| Ambiante | non relevée (pas de thermomètre utilisé) | 1 816 mV → 26,4 °C affichés | 1 831 mV / 250 (point de la fiche LMT86, 25,0 °C) | gauche (Int) |
| Capteur tenu entre deux doigts (30 s) | — | — | — | gauche (Int) : 27,7 °C au maximum observé, puis retour à 26,9 °C |
| Conditionnement externe (pont OUT–IN ou circuit) | non réalisé | — | — | — |

Analyse interne / externe : avec le conditionnement interne, les 270 mV utiles entre 15 et 40 °C donnent environ 340 pas (0,074 °C par pas). Un gain d'environ 10 en externe donnerait environ 3 400 pas (0,007 °C par pas), au prix d'un circuit supplémentaire, d'une plage réduite et d'un bruit amplifié du même facteur. Détails dans le rapport, section 8.

## Journal des séances

### Séance 1 — 6 nov. 2026 — réalise : Sidick / valide : Amr, Chandish
- Contenu de la séance non consigné au moment même.

### Période d'étude et 13 nov. (avant la séance 2)
- Fait : projet CEG3536_Lab3 copié du lab 2, complément intégré, main.s et fsm.s retirés ; main.c, fsm.c, evq.c, acq.c (v2), adc_dma.c, telem.c, vitesse.s et l3a_c.c complétés (avec l'aide de Claude, cf. déclaration) ; 4 cas ajoutés à evq_test.c ; compilation sans avertissement à -O0 et -O2 ; test_evq sur Linux : 13 / 0.
- Décisions : routine L3-A = motor_set_pwm ; tampon DMA de 64 échantillons par voie (température moyennée sur 64, potentiomètre sur 16) ; trame CSV formatée à la main ; E-Stop mis dans la file avant les boutons.

### Séance 2 — 13 nov. 2026 — réalise : Sidick / valide : Amr, Chandish
- Fait : démonstration ; essais T1 à T8 avec captures (dossier captures_lab3).
- Difficultés et solutions : le serveur GDB du ST-LINK refusait la connexion (« Unknown MCU found on target ») sur deux cartes et deux câbles, puis s'est rétabli ; la console série ouvrait COM1 au lieu du port du ST-LINK (corrigé avec le Gestionnaire de périphériques).
- Mesures : voir le tableau des essais.

### 14 nov. 2026 — hors séance
- Validations Git : projet du lab 2 (f0ef64c), jalon J2 (ae64f1a), projet du lab 3 (e6813bb). J2 validé un jour après l'échéance.
- Brouillon du rapport.

### 17 nov. 2026 — séance de reprise
- Fait : T9 (telemetrie.py, port COM7) ; T10 hors carte (désassemblage, tailles, encodages, équivalence sur modèle) ; rapport final (f88ad19).
- Difficultés : pip absent (installé par `ensurepip`) ; journal.csv modifié par Excel (en-tête perdue) ; fin de séance avant la commande `b`, cycles DWT non mesurés.

## Composante L3-A : comparaison assembleur / C

Routine comparée : `motor_set_pwm` (motor.s) ↔ `motor_set_pwm_c` (l3a_c.c)

Résultats obtenus sur un modèle des deux codes machine vérifié sur hôte (0 écart sur 101 004 entrées) ; banc `b` non exécuté sur la carte.

| Cas | Entrée | Résultat assembleur | Résultat C | Effet de bord (registre / variable) | Écart |
|---|---|---|---|---|---|
| 1 | 0 | 0 | 0 | CCR1 = 0 | 0 |
| 2 | 1 | 2 | 2 | CCR1 = 2 | 0 |
| 3 | 25 | 50 | 50 | CCR1 = 50 | 0 |
| 4 | 50 | 100 | 100 | CCR1 = 100 | 0 |
| 5 | 75 | 150 | 150 | CCR1 = 150 | 0 |
| 6 | 99 | 198 | 198 | CCR1 = 198 | 0 |
| 7 | 100 | 200 | 200 | CCR1 = 200 | 0 |
| 8 | 0xFFFFFFFF | 200 | 200 | CCR1 = 200 (saturé) | 0 |

| Version | Cycles DWT (moyenne) | Taille (octets) | Registres utilisés | Observations (prologue, volatile) |
|---|---|---|---|---|
| Assembleur | ≈ 15 à 25 (estimé, non mesuré) | 24 + 4 (pool) | R0–R2 | aucun prologue ; `udiv` (2 à 11 cycles) |
| C, -O0 | ≈ 30 à 38 (estimé, non mesuré) | 64 | R0, R2, R3, R7 | push {r7}, cadre de 20 octets, pct et ccr en pile ; division remplacée par `umull` + `lsrs #5` |
| C, -O2 | ≈ 13 à 17 (estimé, non mesuré) | 36 | R0–R3 | aucun prologue ; écriture TIM1->CCR1 conservée (volatile) |

## Composante L3-C : objet d'acquisition

- Version 1 (validation Git) : pas de commit séparé ; elle correspond au comportement de `acq_valeur` sans appel à `acq_config_filtre` (instance `acq_temp`).
- Version 2 (validation Git) et ce qui a changé : commit e6813bb ; ajout de `acq_config_filtre` (zone morte 3 %, hystérésis 2 points) et lissage de la température sur 64 échantillons ; seule l'initialisation de main.c change.
- Essai d'indépendance des deux instances : T4, potentiomètre de 0 à 4 039 (brut) pendant que temp_mv reste à 1 816 mV ; essai sur hôte avec tampon simulé.
- Comparaison avec la version impérative (annexe) : rapport, section 4.
- Limites : 48 octets par instance, pas de polymorphisme, lecture du tampon DMA pendant l'écriture (rapport, section 4).

## Composante L3-D : traces

| Élément | Preuve (fichier) |
|---|---|
| Désassemblage -O0 annoté | `preuves/desasm_motor_set_pwm_c_O0.txt`, `preuves/desasm_rampe_O0.txt` |
| Désassemblage -O2 annoté | `preuves/desasm_motor_set_pwm_c_O2.txt`, `preuves/desasm_fsm_sorties_O2.txt` ; rapport, section 6 |
| Trois instructions et leur encodage Thumb | rapport, section 6 (cmp 0x2864, str 0x6350, mul.w 0xFB01 F000) |
| Captures du débogueur (R0–R3, SP, variable volatile) | captures t2, t2f_pile_appels, t2g pile, t8-3 (rapport, annexe A) |
| Cycles DWT -O0 / -O2 et transformation analysée | cycles non mesurés (estimés) ; transformations : variables en pile éliminées, division par l'inverse, `rampe` intégrée dans `fsm_sorties`, `ldrd`/`strd` |

## Tableau des essais (T1 à T10)

| Essai | Date | Résultat observé | Verdict | Preuve (fichier) |
|---|---|---|---|---|
| T1 Initialisation en C | 13 nov. | Ligne H, première trame à 201 ms puis toutes les 200 ms ; ARRÊT ; ADC1->CR = 0x10000005, DMA1 CCR1 = 0x5A1, LPUART1 BRR = 0x22B9, CR1 = 0x2000000D | Conforme | t4, adc1, dma1, lpaurt1 brr, lpaurt1 cr1 |
| T2 Appel C → assembleur | 13 nov. | motor_set_pwm depuis rampe() : R0 = 1, SP = 0x2002FF98, LR = 0x08001B3D ; pile relevée | Conforme | t2, t2f_pile_appels, t2g pile |
| T3 Virgule fixe | 13 nov. | 0 ; 0,32 ; 240,00 ; 600,01 ; 21 027,68 tr/min ; erreur +0,002 % | Conforme | rapport, section 5 |
| T4 ADC et DMA | 13 nov. | Brut 0 / 1 893 / 4 039 ; 47,0 et 48,6 tours/s | Conforme | t4-1, t4-2, t4-3 |
| T5 Consigne | 13 nov. | Consigne 0 → 100 % avec rampe, avant et arrière ; 349,7 et 368,4 tr/min à 100 % ; stable à 36 % au repos ; 0 en ARRÊT | Conforme | t5, t5-2, t5-3, t5-4 |
| T6 Température | 13 nov. | 26,4 °C au repos, 27,7 °C après les doigts ; pas de thermomètre de référence | Partiel | t6 |
| T7 File d'événements | 13 nov. | Q,echecs=0 ; débordements 8, 16, 24… à chaque `t`, trames continues | Conforme | t7-1, t7-2 |
| T8 E-Stop | 13 nov. | etat 1 → 3, pwm = 0 immédiatement ; STB = 0 ; buzzer_continu = 1 ; aucune reprise sans acquittement | Conforme | t8-1 à t8-4 |
| T9 Télémétrie | 17 nov. | 151 trames, 200 ms, 5,00 Hz ; puis en-tête présente, RESULTAT : OK | Conforme | captures T9 (rapport, annexe A) |
| T10 Comparaison et traces | 17 nov. | Désassemblage, tailles, encodages ; 0 écart sur modèle ; cycles estimés | Partiel | `preuves/` |

## Déclaration des sources et de l'usage d'outils d'IA générative
- Sources : complément CEG3536_Lab3_Complement.zip, en-têtes CMSIS (ARM, STMicroelectronics), énoncé du laboratoire 3 v1.3, RM0438, guide de la plateforme Leafy, projet du laboratoire 2 de l'équipe.
- Outils d'IA : Claude (Anthropic), modèle Claude Opus 5.5 — aide à l'écriture du code C et de vitesse.s à partir des squelettes, explication des étapes d'essai, désassemblage et tailles hors carte, mise en forme du rapport.
