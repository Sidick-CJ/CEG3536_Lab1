# JOURNAL.md — Journal d'équipe, CEG 3536, laboratoire 1 (automne 2026)

Équipe : `Sidick` et `<coéquipier — à compléter>` — Section : `A01 (vendredi)` — Dépôt Git : `<adresse — à compléter>`

## Jalon J1 (au plus tard le vendredi 25 septembre 2026, validé dans Git)

### Exigences de l'équipe
| Id | Exigence (reformulée par l'équipe) | Critère d'acceptation | Hypothèses |
|---|---|---|---|
| E1 | Après réinitialisation (uC Reset ou mise sous tension), le système démarre dans l'état ARRÊT : DEL rouge seule allumée. | La DEL rouge s'allume seule dans les 100 ms suivant NRST ; verte et bleue éteintes. | Horloge MSI 4 MHz au démarrage (SystemInit vide, non reconfigurée). |
| E2 | Un appui validé sur User fait défiler le véhicule : ARRÊT → MARCHE_AVANT → ARRÊT → MARCHE_ARRIÈRE → ARRÊT. | 4 appuis successifs reproduisent exactement rouge → verte → rouge → bleue → rouge ; une seule DEL allumée à la fois ; le changement de sens passe toujours par ARRÊT. | Bouton User (PC13), niveau actif haut (à confirmer par lecture de IDR, essai T4). |
| E3 | Chaque appui sur un bouton est filtré par anti-rebond logiciel et ne produit qu'un seul événement par appui. | Fenêtre d'anti-rebond de 20 à 50 ms (30 ms retenue au code de départ) ; 20 appuis consécutifs produisent exactement 20 transitions ; un appui maintenu 2 s n'en produit qu'une seule. | button_pressed est appelée toutes les PERIODE_SCRUTATION_MS = 1 ms (cadence de fsm_step). |
| E4 | Un appui sur E-Stop déclenche une interruption externe (EXTI2) de priorité maximale qui met immédiatement les sorties en état sûr. | EXTI2 configurée, priorité 0 (la plus élevée) ; DEL verte et bleue éteintes, rouge allumée, immédiatement après l'appui — y compris si la boucle principale est occupée dans delay_ms. | Bouton E-Stop (PB2), niveau actif haut (à confirmer, T4) ; l'arrêt est entièrement logiciel, aucune coupure matérielle du moteur. |
| E5 | En ARRÊT_URGENCE, la DEL rouge clignote à 2 Hz et les appuis sur User sont ignorés. | Clignotement 250 ms allumée / 250 ms éteinte (± 10 %) ; DEL verte et bleue éteintes ; les appuis sur User n'ont aucun effet sur l'état. | Clignotement compté en pas de scrutation (via clignote_compteur), jamais par un delay_ms bloquant. |
| E6 | Le retour à ARRÊT depuis ARRÊT_URGENCE ne se fait que par un appui validé sur Touch En, et seulement si E-Stop est relâché. | Touch En avec E-Stop relâché → retour à ARRÊT ; Touch En avec E-Stop maintenu → aucun effet ; aucune reprise automatique. | Bouton Touch En (PB5), niveau actif haut (à confirmer, T4). |
| E7 | Hors urgence, chaque appui validé sur Touch En inverse la variable d'autorisation touch_enabled et le signale brièvement. | touch_enabled bascule 0/1 à chaque appui valide ; extinction brève (100 ms) de la DEL active, visible mais non bloquante. | Cette variable autorisera le TouchPad au laboratoire 4. |
| E8 | Toutes les temporisations proviennent d'une routine delay_ms documentée et calibrée. | Boucle calibrée acceptée au laboratoire 1, fréquence d'horloge indiquée ; période de clignotement mesurée conforme à ± 10 %. | Horloge MSI 4 MHz ; DELAY_BOUCLES_PAR_MS (valeur de départ 1000) à calibrer via le compteur de cycles DWT_CYCCNT (essai T6, énoncé v1.2). |
| E9 | Le système reste cohérent lors d'appuis simultanés ou d'un E-Stop pendant une transition/un clignotement. | Jamais deux DEL allumées simultanément ; jamais de sortie d'ARRÊT_URGENCE sans acquittement valide. | Un seul point d'appel de led_set dans tout le programme (fsm_maj_del), garanti par construction (critère B3). |

### Rôles et rotation
| Séance | Réalise | Valide (essais, mesures, relecture) |
|---|---|---|
| Séance 0 | Sidick et coéquipier (travail conjoint — DEL rouge allumée ; rôles non formalisés) | — |
| Séance 1 | `<à décider avec le coéquipier>` | `<à décider>` |
| Séance 2 | (inversé par rapport à la séance 1) | (inversé) |

*Note : la rotation formelle (un membre réalise, l'autre valide, inversée à chaque séance) commence à être suivie à partir de la séance 1. À confirmer avec le coéquipier dès que possible et à corriger dans ce fichier avant la séance 1 sur place.*

### Échéancier des laboratoires 1 à 5
| Laboratoire | Séances | Démonstration | Remise | Responsable du suivi |
|---|---|---|---|---|
| 1 | Séance 0 : ven. 18 sept. · Séance 1 : ven. 25 sept. · Séance 2 : ven. 2 oct. (section A01, STE 2061) | Vendredi 2 octobre 2026, devant l'assistant | Vendredi 9 octobre 2026, 23 h 59 | `<à répartir>` |
| 2 | `<dates à confirmer — plan de cours Brightspace>` | | | |
| 3 | `<dates à confirmer>` | | | |
| 4 | `<dates à confirmer>` | | | |
| 5 | `<dates à confirmer>` | | | |

## Journal des séances

### Séance 0 — 18 septembre 2026 — réalise : `<à préciser>` / valide : `<à préciser>`
- Objectifs : prise en main du kit Leafy + Nucleo, premier projet STM32CubeIDE en assembleur.
- Fait : projet créé, DEL rouge (LD3, PA9) allumée après réinitialisation ; vérifiée au débogueur.
- Décisions :
- Difficultés et solutions :
- Essais et mesures :
- Validations Git (auteur, message) : `<dépôt à créer — voir ci-dessous>`

### Séance 1 — `<date>` — réalise : `<nom>` / valide : `<nom>`
- Objectifs :
- Fait :
- Décisions :
- Difficultés et solutions :
- Essais et mesures :
- Validations Git :

### Séance 2 — `<date>` — réalise : `<nom>` / valide : `<nom>`
- Objectifs :
- Fait :
- Décisions :
- Difficultés et solutions :
- Essais et mesures :
- Validations Git :

## Tableau des essais (T1 à T10)
| Essai | Date | Résultat observé | Verdict | Preuve (fichier) |
|---|---|---|---|---|
| T1 Réinitialisation | | | | |
| T2 Cycle User | | | | |
| T3 Anti-rebond | | | | |
| T4 Niveaux logiques | | | | |
| T5 E-Stop | | | | |
| T6 Clignotement | | | | |
| T7 Acquittement | | | | |
| T8 User ignoré en urgence | | | | |
| T9 Touch En hors urgence | | | | |
| T10 Robustesse | | | | |

## Routine conservée pour L3-A
- Routine : `button_pressed` ou `led_set`
- Interface :
- Cas d'essai :

## Déclaration des sources et de l'usage d'outils d'IA générative
- Sources :
- Outils d'IA (outil, version, usage) : Claude (Anthropic) — utilisé en appui pour reformuler les exigences E1 à E9 du jalon J1 et structurer ce journal, sous la supervision de l'équipe ; chaque membre reste en mesure d'expliquer et de justifier le contenu.
