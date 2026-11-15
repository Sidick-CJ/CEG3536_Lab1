/* ---------------------------------------------------------------------------
 * main.s — point d'entrée et boucle principale (CEG 3536, laboratoire 2)
 *
 * Structure : toutes les sorties mises en état sûr (DEL, buzzer, moteur)
 * avant d'activer les interruptions (EXTI0, EXTI2, SysTick), puis boucle
 * infinie cadencée par tick_1ms : fsm_step une fois par milliseconde.
 * delay_ms n'est plus appelée dans la boucle (E10).
 * Le fichier de démarrage (Core/Startup, généré par STM32CubeIDE) initialise
 * la pile, copie .data, efface .bss, appelle SystemInit puis main.
 * ------------------------------------------------------------------------- */
#include "registres.inc"
#include "registres_lab2.inc"

    .syntax unified
    .cpu    cortex-m33
    .thumb

    .text
    .align  2

/* void SystemInit(void)
 * Appelé par le démarrage avant main. Au laboratoire 1, l'horloge reste
 * celle de la réinitialisation (MSI, 4 MHz) : rien à configurer.
 * Registres modifiés : aucun.                                               */
    .global SystemInit
    .type   SystemInit, %function
SystemInit:
    bx      lr
    .size   SystemInit, .-SystemInit

/* int main(void)
 * Ne retourne jamais.                                                       */
    .global main
    .type   main, %function
main:
    bl      gpio_init               /* DEL en sortie, boutons en entrée      */
    bl      buzzer_init             /* PA0 en sortie, silence                */
    bl      motor_init              /* TIM1 PWM 20 kHz à 0 %, STB = 0        */
    bl      encoder_init            /* EXTI0 sur PB0, priorité 1             */
    bl      estop_init              /* EXTI2 sur PB2, priorité 0             */
    ldr     r0, =SYSTICK_PERIODE_US
    bl      systick_init            /* 1 ms, priorité 2                      */
    bl      fsm_init                /* ARRÊT, DEL rouge seule (E1)           */

boucle_principale:
    ldr     r0, =tick_1ms
    ldr     r1, [r0]
    cmp     r1, #0
    beq     boucle_principale       /* attente du prochain tick              */
    movs    r1, #0
    str     r1, [r0]                /* tick consommé                         */
    bl      fsm_step                /* un pas toutes les 1 ms exactement     */
    b       boucle_principale
    .size   main, .-main
