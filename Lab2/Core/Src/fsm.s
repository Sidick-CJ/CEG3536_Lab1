/* ---------------------------------------------------------------------------
 * fsm.s — machine à états du véhicule (CEG 3536, laboratoires 1 et 2)
 *
 * Routines exportées : fsm_init, fsm_step
 * Variables (.bss)   : etat, touch_enabled, compteur_transitions,
 *                      consigne_pct, pwm_pct (globales) ; clignote_compteur,
 *                      clignote_phase, prochain_sens, etat_sorties,
 *                      bip_demande, rampe_compteur, fenetre_compteur (locales)
 *
 * États : ETAT_ARRET (rouge fixe, moteur en veille), ETAT_MARCHE_AVANT
 * (verte, AI1 = 1), ETAT_MARCHE_ARRIERE (bleue, AI2 = 1), ETAT_ARRET_URGENCE
 * (rouge 2 Hz, buzzer continu, STB = 0).
 *
 * fsm_step est appelée une fois par tick SysTick (1 ms) par main :
 *   A. estop_flag consommé -> ARRÊT_URGENCE (E7, E8) ;
 *   B. boutons : User (E3), Touch En = consigne (E4) ou acquittement (E8) ;
 *   C. fenêtre de vitesse de FENETRE_VITESSE_MS -> encoder_read (E6) ;
 *   D. fsm_maj_sorties : SEUL point d'appel de led_set, motor_set_pwm,
 *      motor_set_dir et buzzer_bip (critère B4).
 * Les transitions n'écrivent que des variables (etat, consigne_pct,
 * bip_demande) ; fsm_maj_sorties détecte l'entrée dans un nouvel état
 * (etat != etat_sorties) et applique la direction et le bip correspondants.
 * ------------------------------------------------------------------------- */
#include "registres.inc"
#include "registres_lab2.inc"

    .syntax unified
    .cpu    cortex-m33
    .thumb

    .bss
    .align  2
    .global etat
    .type   etat, %object
etat:                   .space  4   /* état courant (ETAT_x)                     */
    .global touch_enabled
    .type   touch_enabled, %object
touch_enabled:          .space  4   /* lab. 1, conservée à 0 pour lab1.h         */
    .global compteur_transitions
    .type   compteur_transitions, %object
compteur_transitions:   .space  4   /* transitions par User (watch)              */
    .global consigne_pct
    .type   consigne_pct, %object
consigne_pct:           .space  4   /* 25, 50, 75 ou 100 % (E4)                  */
    .global pwm_pct
    .type   pwm_pct, %object
pwm_pct:                .space  4   /* rapport cyclique appliqué, rampe (E4)     */
clignote_compteur:      .space  4   /* ms écoulées dans la demi-période (E8)     */
clignote_phase:         .space  4   /* 0 rouge éteinte, 1 rouge allumée          */
prochain_sens:          .space  4   /* 0 = prochain départ en avant, 1 = arrière */
etat_sorties:           .space  4   /* état pour lequel les sorties sont appliquées */
bip_demande:            .space  4   /* bips à lancer par fsm_maj_sorties (0, 1, 2) */
rampe_compteur:         .space  4   /* ms depuis le dernier pas de rampe         */
fenetre_compteur:       .space  4   /* ms depuis la dernière mesure de vitesse   */

/* ---- Tables indexées par l'état (un octet par état) --------------------- */
    .section .rodata
etat_vers_del:
    .byte   LED_ROUGE       /* ETAT_ARRET          */
    .byte   LED_VERTE       /* ETAT_MARCHE_AVANT   */
    .byte   LED_BLEUE       /* ETAT_MARCHE_ARRIERE */
    .byte   LED_ROUGE       /* ETAT_ARRET_URGENCE (clignotante)            */
etat_vers_dir:
    .byte   MOTOR_ARRET     /* ETAT_ARRET          */
    .byte   MOTOR_AVANT     /* ETAT_MARCHE_AVANT   */
    .byte   MOTOR_ARRIERE   /* ETAT_MARCHE_ARRIERE */
    .byte   MOTOR_ARRET     /* ETAT_ARRET_URGENCE (non utilisé : ISR + partie A) */
etat_vers_bips:
    .byte   1               /* ARRÊT : bip court                           */
    .byte   1               /* MARCHE_AVANT : bip court                    */
    .byte   2               /* MARCHE_ARRIÈRE : double bip                 */
    .byte   0               /* ARRÊT_URGENCE : son continu (buzzer_continu) */

    .text
    .align  2

/* void fsm_init(void)
 * État initial ARRÊT, consigne 50 %, PWM nulle, DEL rouge seule, buzzer
 * silencieux (E1) : etat_sorties = ARRÊT, donc aucun bip à la mise sous tension.
 * Appelle fsm_maj_sorties : push {r4, lr} (alignement 8).                   */
    .global fsm_init
    .type   fsm_init, %function
fsm_init:
    push    {r4, lr}
    movs    r1, #0
    ldr     r0, =etat
    str     r1, [r0]                    /* ETAT_ARRET = 0                    */
    ldr     r0, =etat_sorties
    str     r1, [r0]
    ldr     r0, =touch_enabled
    str     r1, [r0]
    ldr     r0, =compteur_transitions
    str     r1, [r0]
    ldr     r0, =pwm_pct
    str     r1, [r0]
    ldr     r0, =clignote_compteur
    str     r1, [r0]
    ldr     r0, =clignote_phase
    str     r1, [r0]
    ldr     r0, =prochain_sens
    str     r1, [r0]
    ldr     r0, =bip_demande
    str     r1, [r0]
    ldr     r0, =rampe_compteur
    str     r1, [r0]
    ldr     r0, =fenetre_compteur
    str     r1, [r0]
    ldr     r0, =consigne_pct
    movs    r1, #CONSIGNE_INITIALE
    str     r1, [r0]
    bl      fsm_maj_sorties
    pop     {r4, pc}
    .size   fsm_init, .-fsm_init

/* void fsm_step(void)
 * Un pas de la machine à états, une fois par tick de 1 ms (main attend
 * tick_1ms). Ne bloque jamais.
 * AAPCS : appelle d'autres routines ; r4-r6 préservés, push de 16 octets.  */
    .global fsm_step
    .type   fsm_step, %function
fsm_step:
    push    {r4, r5, r6, lr}

    /* A. E-Stop reçu par l'ISR : mise en sécurité redondante, puis urgence */
    ldr     r6, =estop_flag
    ldr     r0, [r6]
    cmp     r0, #0
    beq     fsm_step_lire
    movs    r0, #0
    str     r0, [r6]                    @ estop_flag consommé
    bl      motor_stop_now              @ CCR1 = 0, STB = 0, AI1 = AI2 = 0 (déjà fait par l'ISR)
    movs    r0, #0
    ldr     r1, =pwm_pct
    str     r0, [r1]                    @ la rampe repartira de 0
    ldr     r1, =clignote_compteur
    str     r0, [r1]
    ldr     r1, =bip_demande
    str     r0, [r1]                    @ un bip en attente n'a plus de sens
    movs    r0, #1
    ldr     r1, =buzzer_continu
    str     r0, [r1]                    @ son continu (déjà mis par l'ISR)
    ldr     r1, =clignote_phase
    str     r0, [r1]                    @ le clignotement commence rouge allumée
    ldr     r1, =etat
    movs    r0, #ETAT_ARRET_URGENCE
    str     r0, [r1]

fsm_step_lire:
    /* B. lire les deux boutons à chaque pas (anti-rebond entretenu même
     *    quand l'appui est ignoré) */
    movs    r0, #BTN_USER
    bl      button_pressed
    mov     r4, r0                      @ r4 = appui User validé
    movs    r0, #BTN_TOUCH
    bl      button_pressed
    mov     r5, r0                      @ r5 = appui Touch En validé

    ldr     r6, =etat
    ldr     r0, [r6]
    cmp     r0, #ETAT_ARRET_URGENCE
    beq     fsm_step_urgence

    /* --- hors urgence, E3 : rouge -> verte -> rouge -> bleue -> rouge --- */
    cmp     r4, #0
    beq     fsm_step_touch
    cmp     r0, #ETAT_ARRET
    bne     fsm_step_vers_arret
    ldr     r2, =prochain_sens
    ldr     r3, [r2]
    cmp     r3, #0
    bne     fsm_step_arriere
    movs    r0, #ETAT_MARCHE_AVANT
    movs    r3, #1                      @ le prochain départ ira en arrière
    b       fsm_step_depart
fsm_step_arriere:
    movs    r0, #ETAT_MARCHE_ARRIERE
    movs    r3, #0                      @ le prochain départ ira en avant
fsm_step_depart:
    str     r3, [r2]
    b       fsm_step_applique
fsm_step_vers_arret:
    movs    r0, #ETAT_ARRET             @ toujours par ARRÊT entre deux sens
fsm_step_applique:
    str     r0, [r6]
    ldr     r2, =compteur_transitions
    ldr     r3, [r2]
    adds    r3, r3, #1
    str     r3, [r2]

fsm_step_touch:
    /* E4 : Touch En hors urgence = palier de consigne suivant + bip court */
    cmp     r5, #0
    beq     fsm_step_fenetre
    ldr     r1, =consigne_pct
    ldr     r0, [r1]
    adds    r0, r0, #CONSIGNE_PAS
    cmp     r0, #CONSIGNE_MAX
    it      hi
    movhi   r0, #CONSIGNE_MIN           @ 100 -> 25
    str     r0, [r1]
    ldr     r1, =bip_demande
    movs    r0, #1
    str     r0, [r1]
    b       fsm_step_fenetre

fsm_step_urgence:
    /* E8 : User et consigne ignorés ; Touch En = acquittement si E-Stop relâché */
    cmp     r5, #0
    beq     fsm_step_fenetre
    movs    r0, #BTN_ESTOP
    bl      button_raw
    cmp     r0, #0
    bne     fsm_step_fenetre            @ E-Stop maintenu : acquittement refusé
    ldr     r1, =buzzer_continu
    movs    r0, #0
    str     r0, [r1]                    @ buzzer coupé
    movs    r0, #ETAT_ARRET
    str     r0, [r6]                    @ retour en ARRÊT, consigne conservée

fsm_step_fenetre:
    /* C. E6 : mesure de vitesse toutes les FENETRE_VITESSE_MS */
    ldr     r1, =fenetre_compteur
    ldr     r0, [r1]
    adds    r0, r0, #1
    cmp     r0, #FENETRE_VITESSE_MS
    blo     fsm_step_fenetre_garde
    movs    r0, #0
    str     r0, [r1]
    ldr     r0, =sens_mesure
    bl      encoder_read                @ met à jour vitesse_fronts et sens_mesure
    b       fsm_step_sorties
fsm_step_fenetre_garde:
    str     r0, [r1]

fsm_step_sorties:
    /* D. sorties */
    bl      fsm_maj_sorties
    pop     {r4, r5, r6, pc}
    .size   fsm_step, .-fsm_step

/* static void fsm_maj_sorties(void) — seul point d'appel de led_set,
 * motor_set_pwm, motor_set_dir et buzzer_bip (critère B4).
 *   1. entrée dans un nouvel état (etat != etat_sorties) : pwm_pct = 0,
 *      motor_set_dir(direction de l'état), bip(s) de l'état ;
 *   2. bip demandé (entrée d'état ou changement de consigne) -> buzzer_bip ;
 *   3. rampe : en marche, pwm_pct +/- 1 vers consigne_pct toutes les
 *      RAMPE_PAS_MS, puis motor_set_pwm ;
 *   4. DEL (clignotement 2 Hz en urgence) ;
 *   5. buzzer_step.
 * r4 = état courant.                                                        */
    .type   fsm_maj_sorties, %function
fsm_maj_sorties:
    push    {r4, lr}
    ldr     r0, =etat
    ldr     r4, [r0]
    cmp     r4, #ETAT_ARRET_URGENCE
    bhi     fsm_maj_fin                 /* état invalide : ne rien changer   */

    /* 1. entrée dans un état */
    ldr     r1, =etat_sorties
    ldr     r2, [r1]
    cmp     r2, r4
    beq     fsm_maj_bip
    str     r4, [r1]                    /* etat_sorties = etat               */
    movs    r0, #0
    ldr     r1, =pwm_pct
    str     r0, [r1]                    /* la rampe repart de 0              */
    ldr     r1, =rampe_compteur
    str     r0, [r1]
    ldr     r1, =etat_vers_bips
    ldrb    r0, [r1, r4]
    ldr     r1, =bip_demande
    str     r0, [r1]                    /* 1, 1, 2 ou 0 (urgence)            */
    cmp     r4, #ETAT_ARRET_URGENCE
    beq     fsm_maj_bip                 /* urgence : sécurité déjà faite (ISR, partie A) */
    ldr     r1, =etat_vers_dir
    ldrb    r0, [r1, r4]
    bl      motor_set_dir               /* ARRÊT : CCR1 = 0 immédiatement ;
                                           marche : CCR1 déjà nul, accepté   */

fsm_maj_bip:
    /* 2. bip demandé */
    ldr     r1, =bip_demande
    ldr     r0, [r1]
    cbz     r0, fsm_maj_rampe
    movs    r2, #0
    str     r2, [r1]
    bl      buzzer_bip

fsm_maj_rampe:
    /* 3. rampe de 1 point par RAMPE_PAS_MS, seulement en marche */
    cmp     r4, #ETAT_MARCHE_AVANT
    beq     fsm_maj_rampe_marche
    cmp     r4, #ETAT_MARCHE_ARRIERE
    bne     fsm_maj_del
fsm_maj_rampe_marche:
    ldr     r1, =rampe_compteur
    ldr     r0, [r1]
    adds    r0, r0, #1
    cmp     r0, #RAMPE_PAS_MS
    blo     fsm_maj_rampe_garde
    movs    r0, #0
    str     r0, [r1]
    ldr     r1, =pwm_pct
    ldr     r0, [r1]
    ldr     r2, =consigne_pct
    ldr     r2, [r2]
    cmp     r0, r2
    beq     fsm_maj_del                 /* consigne atteinte                 */
    ite     lo
    addlo   r0, r0, #1                  /* montée                            */
    subhs   r0, r0, #1                  /* descente                          */
    str     r0, [r1]
    ldr     r1, =estop_flag             /* E-Stop arrivé depuis le début du pas : */
    ldr     r1, [r1]                    /* ne pas réécrire CCR1 (partie A au prochain tick) */
    cbnz    r1, fsm_maj_del
    bl      motor_set_pwm               /* CCR1 = pwm_pct * 200 / 100        */
    b       fsm_maj_del
fsm_maj_rampe_garde:
    str     r0, [r1]

fsm_maj_del:
    /* 4. DEL */
    cmp     r4, #ETAT_ARRET_URGENCE
    beq     fsm_maj_del_urgence
    ldr     r1, =etat_vers_del
    ldrb    r0, [r1, r4]                /* DEL fixe de l'état                */
    b       fsm_maj_del_appel
fsm_maj_del_urgence:
    /* clignotement 2 Hz : bascule toutes les CLIGNOTEMENT_DEMI_MS ticks */
    ldr     r1, =clignote_compteur
    ldr     r2, [r1]
    adds    r2, r2, #1
    cmp     r2, #CLIGNOTEMENT_DEMI_MS
    blo     fsm_maj_del_pasbascule
    movs    r2, #0
    ldr     r3, =clignote_phase
    ldr     r0, [r3]
    eor     r0, r0, #1
    str     r0, [r3]
fsm_maj_del_pasbascule:
    str     r2, [r1]
    ldr     r3, =clignote_phase
    ldr     r0, [r3]
    cmp     r0, #0
    ite     ne
    movne   r0, #LED_ROUGE
    moveq   r0, #LED_AUCUNE
fsm_maj_del_appel:
    bl      led_set

    /* 5. buzzer (bips non bloquants ou son continu) */
    bl      buzzer_step
fsm_maj_fin:
    pop     {r4, pc}
    .size   fsm_maj_sorties, .-fsm_maj_sorties
