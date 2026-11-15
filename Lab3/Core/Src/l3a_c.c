/* ---------------------------------------------------------------------------
 * l3a_c.c — version C de la routine assembleur conservée pour L3-A
 *           (CEG 3536, laboratoire 3) — complété par l'équipe (Groupe 15)
 *
 * Composante L3-A (section 4.5 de l'énoncé) : réécrire en C, avec exactement
 * le même prototype et le même comportement, la routine assembleur conservée
 * du laboratoire 1 ou 2 (button_pressed, led_set, motor_set_pwm ou
 * encoder_read, au choix de l'équipe), sans modifier la version assembleur.
 * Le squelette ci-dessous vise motor_set_pwm (motor.s, laboratoire 2) ;
 * adapter le prototype, bench_l3a.h et les cas du banc si une autre routine
 * est choisie. Comparer valeur de retour, effets de bord et cycles DWT avec
 * bench_l3a.c (commande série b), puis le désassemblage à -O0 et -O2.
 * Tant que la routine n'est pas écrite, le banc signale des écarts.
 * ------------------------------------------------------------------------- */
#include "stm32l552xx.h"
#include "bench_l3a.h"

#define PWM_PLEINE_C 200u          /* ARR + 1 (registres_lab2.inc : PWM_PLEINE) */

/* uint32_t motor_set_pwm_c(uint32_t pct) — même contrat que motor_set_pwm :
 * pct > 100 saturé à 100 ; CCR1 = pct x 200 / 100 ; retour = valeur écrite.
 * Accès au registre par TIM1->CCR1 (volatile via CMSIS) : l'écriture est
 * conservée par le compilateur à tous les niveaux d'optimisation.          */
uint32_t motor_set_pwm_c(uint32_t pct)
{
    if (pct > 100u) {
        pct = 100u;
    }
    uint32_t ccr = (pct * PWM_PLEINE_C) / 100u;
    TIM1->CCR1 = ccr;
    return ccr;
}
