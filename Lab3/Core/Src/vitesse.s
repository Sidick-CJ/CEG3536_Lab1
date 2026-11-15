/* ---------------------------------------------------------------------------
 * vitesse.s — conversion des fronts d'encodeur en vitesse, virgule fixe
 *             (CEG 3536, laboratoire 3, E3) — complété par l'équipe (Groupe 15)
 *
 * Routine exportée (AAPCS) : enc_fronts_vers_rpm_q16 (prototype dans lab3.h)
 *
 * Fenêtre de FENETRE_VITESSE_MS = 250 ms ; 748 fronts par tour de l'arbre de
 * sortie (2 fronts x 11 impulsions x 34). tr/min = fronts x 4 x 60 / 748
 * = fronts x 240 / 748.
 * Format Q16.16 : résultat = tr/min x 65536 = fronts x (240 x 65536 / 748).
 * À faire : calculer la constante entière k (arrondie), son erreur relative,
 * la valeur maximale de fronts sans débordement 32 bits, et vérifier sur les
 * cas de l'essai T3 (0, 1, 748, 1870, 65535). Repère : le banc du laboratoire 2
 * donnait ~350 tr/min à pleine vitesse, soit ~1 090 fronts par fenêtre.
 * ------------------------------------------------------------------------- */
#include "registres.inc"
#include "registres_lab2.inc"

    .syntax unified
    .cpu    cortex-m33
    .thumb

/* k = round(240 x 65536 / 748) = round(21 027,85…) = 21028
 * erreur relative = (21028 - 21027,85) / 21027,85 = +0,002 % (< 0,05 %)
 * débordement : fronts x k < 2^32  <=>  fronts <= 204 249 (65 535 x k = 1 378 069 980)
 * Cas T3 : 0 -> 0 ; 1 -> 21 028 (0,32 tr/min) ; 748 -> 15 728 944 (240,00) ;
 *          1 870 -> 39 322 360 (600,01) ; 65 535 -> 1 378 069 980 (21 027,68)   */
    .equ RPM_Q16_K, 21028        /* identique à RPM_Q16_K de lab3.h */

    .text
    .align  2

/* uint32_t enc_fronts_vers_rpm_q16(uint32_t fronts)
 * r0 = fronts comptés dans la fenêtre ; retour r0 = tr/min en Q16.16.
 * Routine feuille : r0-r3 utilisables, rien à préserver, retour par bx lr.
 * Indice : ldr r1, =RPM_Q16_K puis mul (32 bits suffisent si fronts <= 204 249 ;
 * umull si l'on veut 64 bits).                                              */
    .global enc_fronts_vers_rpm_q16
    .type   enc_fronts_vers_rpm_q16, %function
enc_fronts_vers_rpm_q16:
    ldr     r1, =RPM_Q16_K          /* r1 = k (ne tient pas dans un immédiat 8 bits) */
    muls    r0, r1, r0              /* r0 = fronts x k (32 bits bas, exact si fronts <= 204 249) */
    bx      lr                      /* retour r0 = tr/min en Q16.16 */
    .size   enc_fronts_vers_rpm_q16, .-enc_fronts_vers_rpm_q16
