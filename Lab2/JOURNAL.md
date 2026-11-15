# JOURNAL.md — Journal d'équipe, CEG 3536, laboratoire 2 (automne 2026)

Équipe (groupe 15) : `Sidick Diomande (300360538)`, `Amr Ben Reguiga (300339764)` et `Chandish Reebye (300329078)` — Section : `A01 (vendredi)` — Dépôt Git : `https://github.com/Sidick-CJ/CEG3536_Lab1` (dossier `lab2`)

## Suivi du jalon J1

| Laboratoire | Échéancier prévu (J1) | Déroulement réel | Écart et cause | Ajustement pour les laboratoires 3 à 5 |
|---|---|---|---|---|
| 1 | Séances 18 sept., 25 sept., 2 oct. ; démo 2 oct. ; remise 9 oct. | Démo réussie le 2 oct. ; rapport remis le 9 oct. | Calibration de `delay_ms` non corrigée faute d'accès au matériel (remplacée par SysTick au lab 2) | Garder une capture de chaque mesure au moment où elle est faite |
| 2 | Séances 16 et 23 oct. ; démo 23 oct. ; remise 2 nov. | Code compilé et moteur commandé dès la séance 1 ; démo du 23 oct. réussie (T1 à T10 validés) | Remise reportée au 8 nov. (report annoncé) ; certains relevés de `ticks_ms` (rampe, bips, SysTick) non conservés | Suspendre le processeur avant chaque capture SFR ; noter les relevés directement dans ce journal |

## Rôles et rotation

| Séance | Réalise | Valide (essais, mesures, relecture) | Périphérique configuré ou mesuré par chacun |
|---|---|---|---|
| Séance 1 (16 oct.) | Sidick (écriture et intégration du code) | Amr (essais sur la carte) | Sidick : TIM1, SysTick, EXTI0 (code) · Amr : PWM et rampe sur la carte · Chandish : relevés au débogueur |
| Séance 2 (23 oct.) | Amr (essais T5 à T10, démonstration) | Sidick (relecture, explications du code) | Amr : encodeur et E-Stop sur la carte · Chandish : relevés de vitesse (T6) |

*Note : le partage est resté proche aux deux séances (Sidick au code, Amr aux essais). Au laboratoire 3, les rôles seront réellement inversés.*

## Calculs préalables (avant la séance 1)

| Grandeur | Formule | Valeur | Vérifiée par (essai) |
|---|---|---|---|
| `PWM_PSC`, `PWM_ARR` | f = 4 MHz / ((PSC + 1)(ARR + 1)) = 20 kHz | PSC = 0, ARR = 199 (0xC7) → 4 MHz / 200 = 20 kHz | T3 (SFR : PSC = 0, ARR = 0xC7) |
| `CCR1` pour 25 / 50 / 75 / 100 % | pct × (ARR + 1) / 100 | 50 / 100 / 150 / 200 | T3 |
| `SYSTICK_LOAD_1MS` | 4 MHz × 1 ms − 1 | 3999 (0xF9F) | T10 |
| Fronts par tour (arbre de sortie) | 2 × 11 × 34 | 748 | T5 |
| tr/min à partir de `vitesse_fronts` | fronts × 120 / 748 (fenêtre 500 ms) | ex. 2 182 fronts → 350 tr/min | T6 |
| Fronts attendus par fenêtre de 500 ms à 100 % | 350 tr/min (arbre de sortie) × 748 / 120 | ≈ 2 182 (2 167 mesurés par le prof. à 348 tr/min) | T6 |

## Journal des séances

### Séance 1 — 16 octobre 2026 — réalise : Sidick / valide : Amr
- Objectifs : intégrer le complément au projet du lab 1 ; écrire motor, systick, buzzer, encoder ; raccorder la propulsion à la machine à états (E1 à E4, E9, E10).
- Fait : projet `CEG3536_Lab2_Diomande_BenReguiga_Reebye` compilé sans avertissement ; moteur commandé dans les deux sens ; rampe et consigne fonctionnelles ; SysTick en service ; bips corrects ; encodeur testé en fin de séance.
- Décisions :
  - Sens réel de rotation pour AI1 = 1, AI2 = 0 : **antihoraire** (vu face à l'arbre de sortie).
  - `ENC_SENS_INVERSE = 0` : enc_count croît en marche avant (sens_mesure = 1), décroît en arrière.
  - `ENC_PUPDR = 0` (sorties de l'encodeur actives, aucun tirage nécessaire).
  - Buzzer : variante GPIO sur PA0 (pas de TIM2).
  - Les variables définies en assembleur sont lues dans Live Expressions avec un transtypage, ex. `*(unsigned int*)&pwm_pct`, `*(int*)&enc_count` (signé).
- Difficultés et solutions :
  - Première mesure de rampe faite avec la consigne restée à 50 % : la condition « pwm_pct == 100 » ne pouvait pas se déclencher. Refaite après avoir mis la consigne à 100 % par Touch En.
  - La vue SFR affiche CCR1 = 0 pendant la marche : elle n'est pas rafraîchie tant que le processeur n'est pas suspendu. CCR1 établi par le calcul à partir de pwm_pct.
- Mesures (PWM, SysTick, bips) : SFR TIM1 : PSC = 0, ARR = 0xC7, CCER = 0x1, BDTR = 0x8000 ; pwm_pct = consigne aux paliers 50, 75, 100 et 25 % ; enc_count = +18 583 après une marche avant, −1 379 après une marche arrière ; marche arrière à 100 % : vitesse_fronts = 2 316, sens_mesure = 2.
- Validations Git (auteur, message) :

### Séance 2 — 23 octobre 2026 — réalise : Amr / valide : Sidick / présent : Chandish
- Objectifs : vitesse et sens aux quatre paliers (T5, T6) ; E-Stop (T7) ; urgence et acquittement (T8) ; robustesse (T10) ; démonstration.
- Fait : tous les essais T1 à T10 démontrés et validés par l'assistant, en présence des trois membres.
- Décisions : aucune modification de code depuis la séance 1.
- Difficultés et solutions : —
- Mesures (encodeurs, vitesse, délai E-Stop) : marche avant 75 % : vitesse_fronts = 1 620 (259,9 tr/min), sens_mesure = 1 ; marche arrière 100 % : vitesse_fronts = 2 322 (372,5 tr/min), sens_mesure = 2. Délai E-Stop → PWM nulle estimé à ≈ 6 µs (écriture de CCR1), ≤ 56 µs pour la sortie PE9. Paliers relevés par Chandish (3 fenêtres chacun) — avant : 402/400/404, 1037/1040/1035, 1620/1619/1622, 2313/2320/2320 ; arrière : 422/415/423, 1045/1050/1055, 1632/1631/1643, 2316/2322/2320.
- Validations Git :

### Hors séance — 6 au 8 novembre 2026 — rédaction
- Rédaction du rapport (`Rapport_de_Lab_2_CEG3536`) et mise à jour de ce journal à partir des captures des deux séances.
- Valeurs de vitesse T6 ajoutées par Chandish ; tr/min recalculés (tr/min = fronts × 120 / 748).

## Tableau des mesures (composante L2-A)

| Mesure | Exigence | Valeur mesurée | Incertitude / méthode | Écart | Cause | Preuve (fichier) |
|---|---|---|---|---|---|---|
| Fréquence PWM | 20 kHz ± 5 % | 20,0 kHz | Calcul d'après PSC = 0, ARR = 199 lus en SFR | 0 | — | Fig. A1 du rapport |
| Rapport cyclique à 25 / 50 / 75 / 100 % | ± 2 points | 25 / 50 / 75 / 100 % (CCR1 = 50 / 100 / 150 / 200) | pwm_pct en Live Expressions ; résolution 0,5 % | 0 | — | Fig. A2 |
| Rampe 0 → 100 % | 1 s ± 10 % | 1 000 ms par construction ; validée à la démo | Points d'arrêt conditionnels + ticks_ms | — | Relevé non conservé | Démo |
| Période SysTick | 1 ms ± 1 % | 1,000 ms (LOAD = 3999) | Calcul ; chronomètre non effectué | — | — | — |
| Vitesse à 25 / 50 / 75 / 100 % (avant) | croissante, stable ± 10 % | 402 / 1037 / 1620 / 2318 fronts → 64,5 / 166,4 / 259,9 / 371,8 tr/min (moyenne de 3 fenêtres) | vitesse_fronts, ± 1 front ; variation < 2 % sur 3 fenêtres | Non proportionnelle (17 % de la vitesse max à 25 %) | Frottements du réducteur, tension de seuil du moteur | Fig. A5, tableau 5.2 |
| Vitesse à 25 / 50 / 75 / 100 % (arrière) | idem | 420 / 1050 / 1635 / 2319 fronts → 67,4 / 168,4 / 262,4 / 372,1 tr/min | idem | +6 % vs 350 tr/min à 100 % ; < 5 % d'écart avec l'avant | Mesure à vide, dispersion moteur et alimentation | Fig. A4, A5, tableau 5.2 |
| Sens de comptage (avant, arrière) | inversé selon le sens | enc_count croît en avant, décroît en arrière ; sens_mesure 1 / 2 | Live Expressions | 0 | — | Fig. A4 |
| Délai E-Stop → PWM nulle | < 1 ms | ≈ 6 µs (CCR1), ≈ 8 µs (STB), ≤ 56 µs (PE9) | Comptage de cycles + point d'arrêt dans EXTI2_IRQHandler | — | — | Démo |
| Durée d'un bip | 100 ms ± 10 % | 100 ms par construction ; validée à la démo | Comptage de ticks | — | Relevé non conservé | Démo |

## Tableau des essais (T1 à T10)

| Essai | Date | Résultat observé | Verdict | Preuve (fichier) |
|---|---|---|---|---|
| T1 Réinitialisation | 16 et 23 oct. | DEL rouge seule, moteur immobile ; TIM1 configuré (PSC = 0, ARR = 0xC7, CCER = 0x1, BDTR = 0x8000) | Conforme | Fig. A1, démo |
| T2 Cycle User et sens | 16 et 23 oct. | Rouge → verte → rouge → bleue → rouge ; etat et sens_mesure cohérents | Conforme | Fig. A4, A5, démo |
| T3 PWM | 16 oct. | pwm_pct = consigne aux 4 paliers ; f = 20 kHz | Conforme | Fig. A2 (limite : Fig. A3) |
| T4 Rampe | 16 et 23 oct. | Montée et descente progressives | Conforme | Démo |
| T5 Encodeur | 16 oct. | enc_count + en avant, − en arrière | Conforme | Fig. A4 |
| T6 Vitesse | 16 et 23 oct. | Valeurs stables et croissantes ; ≈ 372 tr/min à 100 % | Conforme | Fig. A5, tableau 5.2 du rapport |
| T7 E-Stop | 23 oct. | Moteur coupé immédiatement en avant à 100 % et en arrière pendant une rampe | Conforme | Démo |
| T8 Urgence et acquittement | 23 oct. | User ignoré ; acquittement refusé puis accepté | Conforme | Démo |
| T9 Buzzer | 16 et 23 oct. | Bip court, double bip, son continu en urgence | Conforme | Démo |
| T10 SysTick et robustesse | 23 oct. | Système cohérent dans tous les cas de E12 | Conforme | Démo |

## Routine conservée pour L3-A
- Routine : `motor_set_pwm` (remplace la routine retenue au lab 1).
- Interface : `uint32_t motor_set_pwm(uint32_t pct)` — R0 = rapport cyclique en %, retour R0 = CCR1 écrit (pct × 200 / 100, saturé à 100 %) ; routine feuille, R0–R2.
- Cas d'essai et résultats : 0 → 0 ; 25 / 50 / 75 / 100 → 50 / 100 / 150 / 200 ; 150 → 200 (saturation) ; 1 → 2. Conformes.

## Déclaration des sources et de l'usage d'outils d'IA générative
