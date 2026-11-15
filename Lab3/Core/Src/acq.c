/* ---------------------------------------------------------------------------
 * acq.c — objet d'acquisition d'une voie analogique (CEG 3536, lab. 3, L3-C)
 *         — complété par l'équipe (Groupe 15), version 2
 * Aucun registre : les échantillons viennent d'un tampon mémoire rempli par
 * le DMA. Toutes les opérations en entiers 32 bits.
 * Version 1 : acq_init, acq_brut, acq_mv, acq_valeur (relation linéaire).
 * Version 2 (changement d'exigence, énoncé 4.6) : acq_config_filtre et, dans
 * acq_valeur, zone morte puis hystérésis, sans toucher aux appelants.
 * ------------------------------------------------------------------------- */
#include "acq.h"

#define ACQ_PLEINE_ECHELLE 4095
#define ACQ_VREF_MV        3300

void acq_init(acq_t *a, const volatile uint16_t *src, uint32_t pas, uint32_t n_moy,
              int32_t gain_num, int32_t gain_den, int32_t decalage)
{
    a->src = src;
    a->pas = (pas == 0u) ? 1u : pas;
    a->n_moy = (n_moy == 0u) ? 1u : n_moy;
    a->gain_num = gain_num;
    a->gain_den = (gain_den == 0) ? 1 : gain_den;
    a->decalage = decalage;
    a->hysteresis = 0;
    a->zone_morte = 0;
    a->v_min = 0;
    a->v_max = 0;
    a->derniere = 0;
    a->initialisee = 0u;
}

void acq_config_filtre(acq_t *a, int32_t hysteresis, int32_t zone_morte,
                       int32_t v_min, int32_t v_max)
{
    a->hysteresis = hysteresis;
    a->zone_morte = zone_morte;
    a->v_min = v_min;
    a->v_max = v_max;
    a->initialisee = 0u;      /* la prochaine valeur est prise telle quelle   */
}

/* Moyenne arrondie des n_moy échantillons src[i * pas] (E4). Lecture seule
 * du tampon DMA : chaque mot de 16 bits est lu en une instruction, une
 * valeur en cours de remplacement par le DMA est soit l'ancienne soit la
 * nouvelle (jamais un mélange). Somme max 64 x 4095 : tient sur 32 bits.   */
uint32_t acq_brut(const acq_t *a)
{
    uint32_t somme = 0u;
    for (uint32_t i = 0u; i < a->n_moy; i++) {
        somme += a->src[i * a->pas];
    }
    return (somme + a->n_moy / 2u) / a->n_moy;
}

uint32_t acq_mv(const acq_t *a)
{
    return (acq_brut(a) * ACQ_VREF_MV + ACQ_PLEINE_ECHELLE / 2) / ACQ_PLEINE_ECHELLE;
}

/* Division entière arrondie au plus proche (numérateur signé, d > 0 ou < 0). */
static int32_t div_arrondi(int32_t n, int32_t d)
{
    if (d < 0) { n = -n; d = -d; }
    return (n >= 0) ? (n + d / 2) / d : -((-n + d / 2) / d);
}

/* Valeur étalonnée (E5, E6) : v = mv x gain_num / gain_den + decalage.
 * Version 2 (changement d'exigence, 4.6) — sans effet tant que
 * acq_config_filtre n'a pas été appelée :
 *   zone morte : v < v_min + zone_morte -> v_min ; v > v_max - zone_morte -> v_max
 *   hystérésis : la valeur retournée ne change que si |v - derniere| > hysteresis,
 *                sauf pour atteindre exactement une borne (0 % / 100 %).        */
int32_t acq_valeur(acq_t *a)
{
    int32_t v = div_arrondi((int32_t)acq_mv(a) * a->gain_num, a->gain_den) + a->decalage;

    if (a->zone_morte > 0) {
        if (v < a->v_min + a->zone_morte) {
            v = a->v_min;
        } else if (v > a->v_max - a->zone_morte) {
            v = a->v_max;
        }
    }
    if (a->hysteresis > 0 && a->initialisee) {
        int32_t ecart = v - a->derniere;
        if (ecart < 0) ecart = -ecart;
        int borne = (a->zone_morte > 0) && (v == a->v_min || v == a->v_max);
        if (ecart <= a->hysteresis && !borne) {
            return a->derniere;
        }
    }
    a->derniere = v;
    a->initialisee = 1u;
    return v;
}
