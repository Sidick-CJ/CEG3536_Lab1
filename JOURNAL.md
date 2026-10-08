# JOURNAL.md — Journal d'équipe, CEG 3536, laboratoire 1 (automne 2026)

Équipe : `Sidick` et `Amr Ben Reguiga` — Section : `A01 (vendredi)` — Dépôt Git : `https://github.com/Sidick-CJ/CEG3536_Lab1`

## Jalon J1 (au plus tard le vendredi 25 septembre 2026, validé dans Git)

### Exigences de l'équipe
| Id | Exigence (reformulée par l'équipe) | Critère d'acceptation | Hypothèses |
|---|---|---|---|
| E1 | Après réinitialisation (uC Reset ou mise sous tension), le système démarre dans l'état ARRÊT : DEL rouge seule allumée. | La DEL rouge s'allume seule dans les 100 ms suivant NRST ; verte et bleue éteintes. | Horloge MSI 4 MHz au démarrage (SystemInit vide, non reconfigurée). |
| E2 | Un appui validé sur User fait défiler le véhicule : ARRÊT → MARCHE_AVANT → ARRÊT → MARCHE_ARRIÈRE → ARRÊT. | 4 appuis successifs reproduisent exactement rouge → verte → rouge → bleue → rouge ; une seule DEL allumée à la fois ; le changement de sens passe toujours par ARRÊT. | Bouton User (PC13), niveau actif haut (confirmé par lecture de IDR, essai T4). |
| E3 | Chaque appui sur un bouton est filtré par anti-rebond logiciel et ne produit qu'un seul événement par appui. | Fenêtre d'anti-rebond de 20 à 50 ms (30 ms retenue au code de départ) ; 20 appuis consécutifs produisent exactement 20 transitions ; un appui maintenu 2 s n'en produit qu'une seule. | button_pressed est appelée toutes les PERIODE_SCRUTATION_MS = 1 ms (cadence de fsm_step). |
| E4 | Un appui sur E-Stop déclenche une interruption externe (EXTI2) de priorité maximale qui met immédiatement les sorties en état sûr. | EXTI2 configurée, priorité 0 (la plus élevée) ; DEL verte et bleue éteintes, rouge allumée, immédiatement après l'appui — y compris si la boucle principale est occupée dans delay_ms. | Bouton E-Stop (PB2), niveau actif haut (confirmé, T4) ; l'arrêt est entièrement logiciel, aucune coupure matérielle du moteur. |
| E5 | En ARRÊT_URGENCE, la DEL rouge clignote à 2 Hz et les appuis sur User sont ignorés. | Clignotement 250 ms allumée / 250 ms éteinte (± 10 %) ; DEL verte et bleue éteintes ; les appuis sur User n'ont aucun effet sur l'état. | Clignotement compté en pas de scrutation (via clignote_compteur), jamais par un delay_ms bloquant. |
| E6 | Le retour à ARRÊT depuis ARRÊT_URGENCE ne se fait que par un appui validé sur Touch En, et seulement si E-Stop est relâché. | Touch En avec E-Stop relâché → retour à ARRÊT ; Touch En avec E-Stop maintenu → aucun effet ; aucune reprise automatique. | Bouton Touch En (PB5), niveau actif haut (confirmé, T4). |
| E7 | Hors urgence, chaque appui validé sur Touch En inverse la variable d'autorisation touch_enabled et le signale brièvement. | touch_enabled bascule 0/1 à chaque appui valide ; extinction brève (100 ms) de la DEL active, visible mais non bloquante. | Cette variable autorisera le TouchPad au laboratoire 4. |
| E8 | Toutes les temporisations proviennent d'une routine delay_ms documentée et calibrée. | Boucle calibrée acceptée au laboratoire 1, fréquence d'horloge indiquée ; période de clignotement mesurée conforme à ± 10 %. | Horloge MSI 4 MHz ; DELAY_BOUCLES_PAR_MS (1000) calculé sous-calibré d'environ 25 % (essai T6) — correction prévue (voir Analyse et limites). |
| E9 | Le système reste cohérent lors d'appuis simultanés ou d'un E-Stop pendant une transition/un clignotement. | Jamais deux DEL allumées simultanément ; jamais de sortie d'ARRÊT_URGENCE sans acquittement valide. | Un seul point d'appel de led_set dans tout le programme (fsm_maj_del), garanti par construction (critère B3). |

### Rôles et rotation
| Séance | Réalise | Valide (essais, mesures, relecture) |
|---|---|---|
| Séance 0 | Sidick et Amr (travail conjoint — DEL rouge allumée ; rôles non formalisés) | — |
| Séance 1 | Amr | Sidick |
| Séance 2 | Sidick | Amr |

*Note : rotation suivie à partir de la séance 1 (Amr réalise / Sidick valide), inversée à la séance 2 (Sidick réalise / Amr valide).*

### Échéancier des laboratoires 1 à 5
| Laboratoire | Séances | Démonstration | Remise | Responsable du suivi |
|---|---|---|---|---|
| 1 | Séance 0 : ven. 18 sept. · Séance 1 : ven. 25 sept. · Séance 2 : ven. 2 oct. (section A01, STE 2061) | Vendredi 2 octobre 2026, devant l'assistant | Vendredi 9 octobre 2026, 23 h 59 | `<à répartir>` |
| 2 | `<dates à confirmer — plan de cours Brightspace>` | | | |
| 3 | `<dates à confirmer>` | | | |
| 4 | `<dates à confirmer>` | | | |
| 5 | `<dates à confirmer>` | | | |

## Journal des séances

### Séance 0 — 18 septembre 2026 — réalise : Sidick et Amr (conjoint) / valide : —
- Objectifs : prise en main du kit Leafy + Nucleo, premier projet STM32CubeIDE en assembleur.
- Fait : projet créé, DEL rouge (LD3, PA9) allumée après réinitialisation ; vérifiée au débogueur.
- Décisions :
- Difficultés et solutions :
- Essais et mesures :
- Validations Git (auteur, message) : `<dépôt créé — voir ci-dessous>`

### Séance 1 — 25 septembre 2026 — réalise : Amr / valide : Sidick
- Objectifs : compléter le code de laboratoire 1 (button_pressed/E3, fsm_step/E2, fsm_maj_del/E5-E7, estop_init et EXTI2_IRQHandler/E4), importer le projet dans STM32CubeIDE.
- Fait : anti-rebond (button_pressed, E3) écrit et vérifié ; fsm_step (E2), fsm_maj_del (E5/E7) et estop_init/EXTI2_IRQHandler (E4) complétés et vérifiés par compilation ; projet importé et compilé dans STM32CubeIDE.
- Décisions : fenêtre d'anti-rebond retenue à 30 ms (ANTIREBOND_MS).
- Difficultés et solutions : erreur de connexion du débogueur ST-Link (« error 138 ») sur un poste ; contournée en travaillant sur un autre poste. Problème d'encodage de texte (caractères accentués) réglé en forçant UTF-8 dans les propriétés du projet.
- Essais et mesures : essais T1 à T10 amorcés en fin de séance.
- Validations Git :

### Séance 2 — 2 octobre 2026 — réalise : Sidick / valide : Amr
- Objectifs : finaliser les essais (T1 à T10) et démonstration devant l'assistant.
- Fait : tous les essais T1 à T10 démontrés avec succès devant l'assistant. Lecture des registres IDR (T4) et vérification du comportement complet (E1-E9) confirmées au débogueur (Live Expressions / Debugger Console).
- Décisions : niveaux actifs des trois boutons (User, E-Stop, Touch En) confirmés hauts par lecture directe de IDR (PC13) et par le comportement correct de l'acquittement/Touch En (PB2, PB5) — aucune modification de registres.inc nécessaire.
- Difficultés et solutions : variables définies en assembleur sans type connu du débogueur (symboles .bss sans .type %object) — contourné par cast explicite (*(unsigned int*)&variable) dans GDB.
- Essais et mesures : voir tableau des essais ci-dessous.
- Validations Git :

### Hors séance — 8-9 octobre 2026 — finalisation
- Objectifs : compléter le rapport et le journal pour la remise du 9 octobre, 23 h 59.
- Fait : calcul théorique de la calibration de delay_ms (T6, voir ci-dessous) en l'absence d'accès au matériel ; rédaction du rapport.
- Décisions : calibration de DELAY_BOUCLES_PAR_MS non modifiée dans le code avant remise (pas de matériel disponible pour retester) ; correction documentée comme limite connue, à appliquer au prochain accès au matériel.
- Difficultés et solutions :
- Essais et mesures : T6 calculé théoriquement (voir tableau).
- Validations Git :

## Tableau des essais (T1 à T10)
| Essai | Date | Résultat observé | Verdict | Preuve (fichier) |
|---|---|---|---|---|
| T1 Réinitialisation | 2 oct. 2026 | DEL rouge seule allumée après réinitialisation (uC Reset), aucune autre DEL. | Conforme (E1) | Démontré à la démonstration du 2 octobre. |
| T2 Cycle User | 2 oct. 2026 | 4 appuis successifs sur User → rouge → verte → rouge → bleue → rouge, une seule DEL allumée à la fois. | Conforme (E2) | Démontré à la démonstration du 2 octobre. |
| T3 Anti-rebond | 2 oct. 2026 | 20 appuis sur User → 20 transitions exactement (compteur_transitions : 0→20, lu au débogueur) ; 1 appui maintenu 2 s → 1 seule transition (20→21). | Conforme (E3) | Capture Live Expressions / Debugger Console (GDB print). |
| T4 Niveaux logiques | 2 oct. 2026 | Lecture directe de GPIOC_IDR bit 13 (User) : relâché = 0, appuyé = 1. Comportement correct de E-Stop (acquittement, E6) et Touch En (E7) à la démonstration confirme le même sens (actif haut) pour PB2 et PB5. | Conforme (E2, E4) — les trois boutons sont actifs hauts, hypothèse initiale validée. | Capture Live Expressions (PC13, PB2, PB5) / Debugger Console. |
| T5 E-Stop | 2 oct. 2026 | Appui sur E-Stop en MARCHE_AVANT et en MARCHE_ARRIÈRE → passage immédiat en ARRÊT_URGENCE, DEL verte/bleue éteintes immédiatement. | Conforme (E4, E5) | Démontré à la démonstration du 2 octobre. |
| T6 Clignotement | 8 oct. 2026 (calcul) | Calcul théorique (cycles ARM Cortex-M33, instructions de traitement = 1 cycle, branchement pris ≈ 2 cycles) : delay_ms(1) ≈ 3005 cycles ≈ 0,75 ms à 4 MHz (au lieu de 1 ms visé). Période de clignotement calculée ≈ 416 ms (250 × ~0,83 ms/itération, fsm_step inclus). | Hors tolérance par le calcul (416 ms < 450-550 ms visés) — DELAY_BOUCLES_PAR_MS (1000) sous-calibré d'environ 25 % ; correction à ~1330-1340 recommandée, non appliquée faute d'accès au matériel pour retester avant la remise. Visuellement conforme à la démonstration (clignotement perçu à l'œil comme correct). | Calcul détaillé en section Analyse et limites du rapport. |
| T7 Acquittement | 2 oct. 2026 | Touch En avec E-Stop relâché → retour en ARRÊT. Touch En avec E-Stop maintenu → aucun effet, clignotement continue. | Conforme (E6) | Démontré à la démonstration du 2 octobre. |
| T8 User ignoré en urgence | 2 oct. 2026 | Appuis sur User pendant ARRÊT_URGENCE → aucun changement d'état. | Conforme (E5) | Démontré à la démonstration du 2 octobre. |
| T9 Touch En hors urgence | 2 oct. 2026 | Deux appuis sur Touch En en ARRÊT → touch_enabled passe à 1 puis à 0 ; extinction brève de la DEL active à chaque appui. | Conforme (E7) | Démontré à la démonstration du 2 octobre. |
| T10 Robustesse | 2 oct. 2026 | Appuis simultanés User/Touch En et E-Stop pendant une transition → jamais deux DEL allumées, jamais de sortie d'urgence sans acquittement. | Conforme (E9) | Démontré à la démonstration du 2 octobre. |

## Routine conservée pour L3-A
- Routine : `button_pressed` ou `led_set`
- Interface :
- Cas d'essai :

## Déclaration des sources et de l'usage d'outils d'IA générative
- Sources : manuel de référence RM0438 (STM32L552), guide de plateforme Leafy, tutoriels TUT01/TUT02 du cours, code de départ fourni (CEG3536_Lab1_Demarrage).
- Outils d'IA (outil, version, usage) : Claude (Anthropic, assistant Claude Code/Cowork) — utilisé en appui tout au long du laboratoire, sous la supervision de l'équipe : (1) reformulation des exigences E1 à E9 et structuration du jalon J1 ; (2) rédaction d'une partie du code assembleur à compléter dans `fsm.s` (fsm_step, fsm_maj_del) et `estop.s` (estop_init, EXTI2_IRQHandler), à partir des exercices des tutoriels et de l'énoncé, relue et comprise par l'équipe ; (3) aide au dépannage (configuration du projet STM32CubeIDE, erreurs de compilation et de connexion du débogueur ST-Link, expressions GDB pour lire les registres et variables en mémoire) ; (4) calcul théorique de la calibration de delay_ms (T6) en l'absence d'accès au matériel ; (5) aide à la rédaction de ce journal et du rapport. Chaque membre de l'équipe reste en mesure d'expliquer et de justifier tout le contenu remis.
