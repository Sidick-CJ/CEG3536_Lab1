/* ---------------------------------------------------------------------------
 * estop.s — arrêt d'urgence par interruption externe (CEG 3536, laboratoires 1 et 2)
 *
 * Routines exportées : estop_init, EXTI2_IRQHandler
 * Variable (.bss)     : estop_flag
 *
 * Règle des interruptions (section 4.1) : l'ISR est courte. Exception exigée
 * pour E-Stop : l'ISR met d'abord les sorties en état sûr (verte et bleue
 * éteintes, rouge allumée), positionne estop_flag, efface la requête EXTI et
 * se termine. Le changement complet d'état vers ARRÊT_URGENCE est fait par
 * fsm_step dans la boucle principale.
 *
 * Particularité STM32L5 (RM0438, section 16) : les registres de sélection de
 * port EXTICR sont dans EXTI (EXTI_EXTICR1, offset 0x60), et non dans SYSCFG
 * comme sur les STM32F4/L4. La requête se lit et s'efface dans EXTI_RPR1
 * (front montant) et EXTI_FPR1 (front descendant), par écriture de 1.
 * ------------------------------------------------------------------------- */
#include "registres.inc"
#include "registres_lab2.inc"

    .syntax unified
    .cpu    cortex-m33
    .thumb

    .bss
    .align  2
    .global estop_flag
estop_flag:     .space  4           /* 1 = E-Stop reçu, à consommer par fsm_step */

    .text
    .align  2

/* void estop_init(void)
 * Configure PB2 comme source de l'interruption EXTI2, priorité la plus élevée.
 *
 * À FAIRE (E4) :
 *   1. EXTI_EXTICR1 : champ EXTI2 (bits 18:16) = EXTICR_PORT_B (0x01).
 *      (lire, effacer le champ avec bic, insérer avec orr, écrire)
 *   2. Choisir le front qui correspond à l'APPUI selon BTN_ESTOP_ACTIF_HAUT :
 *      actif haut -> EXTI_RTSR1 |= EXTI_LIGNE2 ; actif bas -> EXTI_FTSR1 |= EXTI_LIGNE2.
 *      Effacer l'autre front. Effacer toute requête en attente (RPR1 / FPR1).
 *   3. EXTI_IMR1 |= EXTI_LIGNE2 (démasquer la ligne 2).
 *   4. NVIC : octet de priorité NVIC_IPR_BASE + EXTI2_IRQn = NVIC_PRIO_MAX (strb),
 *      puis NVIC_ISER0 = (1 << EXTI2_IRQn) pour activer l'interruption.
 *   (RCC_APB2ENR.SYSCFGEN n'est pas nécessaire pour EXTICR sur la L5.)
 * Registres modifiés : r0-r3 (routine feuille).                             */
    .global estop_init
    .type   estop_init, %function
estop_init:
    ldr     r0, =EXTI_BASE
    ldr     r1, [r0, #EXTI_EXTICR1]
    bic     r1, r1, #(0xFF << EXTICR1_EXTI2_POS)
    orr     r1, r1, #(EXTICR_PORT_B << EXTICR1_EXTI2_POS)
    str     r1, [r0, #EXTI_EXTICR1]     @ 1. ligne 2 -> port B

    movs    r2, #EXTI_LIGNE2
    ldr     r1, [r0, #EXTI_RTSR1]
.if BTN_ESTOP_ACTIF_HAUT
    orr     r1, r1, r2                  @ front montant = appui (actif haut)
.else
    bic     r1, r1, r2
.endif
    str     r1, [r0, #EXTI_RTSR1]

    ldr     r1, [r0, #EXTI_FTSR1]
.if BTN_ESTOP_ACTIF_HAUT
    bic     r1, r1, r2
.else
    orr     r1, r1, r2                  @ front descendant = appui (actif bas)
.endif
    str     r1, [r0, #EXTI_FTSR1]       @ 2. le bon front

    str     r2, [r0, #EXTI_RPR1]        @ nettoyer toute requête déjà en attente
    str     r2, [r0, #EXTI_FPR1]

    ldr     r1, [r0, #EXTI_IMR1]
    orr     r1, r1, r2
    str     r1, [r0, #EXTI_IMR1]        @ 3. démasquer

    ldr     r0, =NVIC_IPR_BASE
    movs    r1, #(PRIO_ESTOP << PRIO_POS)
    strb    r1, [r0, #EXTI2_IRQn]       @ 4. priorité maximale
    ldr     r0, =NVIC_ISER0
    movs    r1, #(1 << EXTI2_IRQn)
    str     r1, [r0]                    @ 4. activer l'IRQ
    bx      lr
    .size   estop_init, .-estop_init

/* void EXTI2_IRQHandler(void)   — vecteur d'interruption EXTI ligne 2
 * Remplace le gestionnaire faible (.weak) du fichier de démarrage.
 * Priorité 0 : préempte EXTI0 (encodeur, 1) et SysTick (2).
 * Exception à la règle « ISR courte » exigée par E7 : l'ISR met elle-même
 * la propulsion en sécurité, puis le buzzer et les DEL :
 *   0. motor_stop_now (CCR1 = 0 en 4e instruction utile, STB = 0, AI1 = AI2 = 0) ;
 *   1. buzzer_set(1), buzzer_continu = 1 ;
 *   2. verte et bleue éteintes, rouge allumée (BSRR) ;
 *   3. estop_flag = 1 ; requête effacée (RPR1/FPR1), dsb.
 * Le changement d'état vers ARRÊT_URGENCE reste dans fsm_step.
 * motor_stop_now et buzzer_set n'utilisent que r0-r1 ; le bl impose de
 * sauvegarder LR (EXC_RETURN) : push {r4, lr} / pop {r4, pc}.              */
    .global EXTI2_IRQHandler
    .type   EXTI2_IRQHandler, %function
EXTI2_IRQHandler:
    push    {r4, lr}                    @ bl dans l'ISR : LR (EXC_RETURN) sauvegardé, 8 octets
    /* 0. propulsion en sécurité EN PREMIER (E7) : CCR1 = 0, STB = 0, AI1 = AI2 = 0 */
    bl      motor_stop_now
    /* buzzer : son continu jusqu'à l'acquittement */
    movs    r0, #1
    bl      buzzer_set
    ldr     r0, =buzzer_continu
    movs    r1, #1
    str     r1, [r0]

    /* 1. DEL : état sûr immédiat, par BSRR */
    ldr     r0, =GPIOC_BASE
    mov     r1, #(1 << (LED_VERTE_PIN + 16))
    str     r1, [r0, #GPIO_BSRR]        @ verte éteinte

    ldr     r0, =GPIOB_BASE
    mov     r1, #(1 << (LED_BLEUE_PIN + 16))
    str     r1, [r0, #GPIO_BSRR]        @ bleue éteinte

    ldr     r0, =GPIOA_BASE
    mov     r1, #(1 << LED_ROUGE_PIN)
    str     r1, [r0, #GPIO_BSRR]        @ rouge allumée

    /* 2. drapeau pour fsm_step */
    ldr     r0, =estop_flag
    movs    r1, #1
    str     r1, [r0]

    /* 3. effacement de la requête (écriture de 1 : w1c) */
    ldr     r0, =EXTI_BASE
    mov     r1, #EXTI_LIGNE2
    str     r1, [r0, #EXTI_RPR1]
    str     r1, [r0, #EXTI_FPR1]
    dsb                                 @ effacement effectif avant le retour
    pop     {r4, pc}                    @ pc <- EXC_RETURN : retour d'exception
    .size   EXTI2_IRQHandler, .-EXTI2_IRQHandler
