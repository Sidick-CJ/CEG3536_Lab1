/* ---------------------------------------------------------------------------
 * fsm.c — machine à états du véhicule en C (CEG 3536, laboratoire 3, E8)
 *         — complété par l'équipe (Groupe 15) ; remplace fsm.s du laboratoire 2
 *
 * États et transitions du laboratoire 2, à conserver :
 *   EV_USER   : ARRÊT -> AVANT / ARRIÈRE (alternance), AVANT / ARRIÈRE -> ARRÊT ;
 *               ignoré en ARRÊT_URGENCE
 *   EV_ESTOP  : tout état -> ARRÊT_URGENCE (propulsion déjà coupée par l'ISR) [FOURNI]
 *   EV_TOUCH  : en urgence, acquittement si button_raw(BTN_ESTOP) == 0 ;
 *               sinon bascule touch_enabled + bip court
 *   EV_CONSIGNE (valeur = %) : mémorisée dans consigne_pot ; appliquée à
 *               consigne_pct seulement en marche (E5)
 *   EV_VITESSE  (valeur = fronts) : enc_fronts_vers_rpm_q16 (E3), sens_mesure
 * Sorties (fsm_sorties, un seul point) : rampe 1 point / RAMPE_PAS_MS, DEL
 * (rouge clignotante en urgence), buzzer_step.
 * Les variables etat, touch_enabled, compteur_transitions, consigne_pct et
 * pwm_pct déclarées dans lab1.h / lab2.h sont définies ici (fsm.s retiré).
 * ------------------------------------------------------------------------- */
#include "fsm.h"

/* variables déclarées extern volatile dans lab1.h / lab2.h */
volatile uint32_t etat;
volatile uint32_t touch_enabled;
volatile uint32_t compteur_transitions;
volatile uint32_t consigne_pct;
volatile uint32_t pwm_pct;

static uint32_t consigne_pot;       /* dernière position du potentiomètre (%) */
static uint32_t prochain_sens;      /* 0 : prochain départ en avant           */
static uint32_t rampe_compteur, clignote_compteur, clignote_phase;
static etat_vehicule_t expose;

static const uint8_t etat_vers_del[4]  = { LED_ROUGE, LED_VERTE, LED_BLEUE, LED_ROUGE };
static const uint8_t etat_vers_dir[4]  = { MOTOR_ARRET, MOTOR_AVANT, MOTOR_ARRIERE, MOTOR_ARRET };
static const uint8_t etat_vers_bips[4] = { 1u, 1u, 2u, 0u };

/* Entrée dans un état hors urgence [FOURNI] : etat, transitions, rampe à 0,
 * direction (acceptée car CCR1 = 0), consigne prise au départ, bips.       */
static void entree_etat(uint32_t nouvel_etat)
{
    etat = nouvel_etat;
    compteur_transitions++;
    pwm_pct = 0u;
    rampe_compteur = 0u;
    (void)motor_set_dir(etat_vers_dir[nouvel_etat]);
    if (nouvel_etat == ETAT_MARCHE_AVANT || nouvel_etat == ETAT_MARCHE_ARRIERE) {
        consigne_pct = consigne_pot;
    } else {
        consigne_pct = 0u;
    }
    buzzer_bip(etat_vers_bips[nouvel_etat]);
}

void fsm_init(void)
{
    touch_enabled = 0u;
    consigne_pot = 0u;
    prochain_sens = 0u;
    clignote_compteur = clignote_phase = 0u;
    expose.vitesse_rpm_q16 = 0u;
    expose.sens = SENS_IMMOBILE;
    (void)motor_set_dir(MOTOR_ARRET);
    etat = ETAT_ARRET;
    pwm_pct = 0u;
    consigne_pct = 0u;
    compteur_transitions = 0u;
    fsm_sorties();
}

void fsm_traiter(const evq_event_t *e)
{
    switch (e->type) {
    case EV_ESTOP:                              /* [FOURNI] : état sûr          */
        motor_stop_now();
        pwm_pct = 0u;
        consigne_pct = 0u;
        buzzer_continu = 1u;
        clignote_compteur = 0u;
        clignote_phase = 1u;
        if (etat != ETAT_ARRET_URGENCE) {
            etat = ETAT_ARRET_URGENCE;
            compteur_transitions++;
        }
        break;

    case EV_USER:                               /* [FOURNI] : défilement (E8) */
        if (etat == ETAT_ARRET) {
            entree_etat(prochain_sens ? ETAT_MARCHE_ARRIERE : ETAT_MARCHE_AVANT);
            prochain_sens ^= 1u;
        } else if (etat == ETAT_MARCHE_AVANT || etat == ETAT_MARCHE_ARRIERE) {
            entree_etat(ETAT_ARRET);
        }
        /* ARRÊT_URGENCE : User ignoré */
        break;

    case EV_TOUCH:                              /* E9 : acquittement ; E5 : bascule */
        if (etat == ETAT_ARRET_URGENCE) {
            if (button_raw(BTN_ESTOP) == 0u) {  /* E-Stop relâché seulement     */
                buzzer_continu = 0u;
                entree_etat(ETAT_ARRET);        /* ARRÊT, 1 bip                 */
            }                                   /* sinon : ignoré, reste en urgence */
        } else {
            touch_enabled ^= 1u;                /* préparation du laboratoire 4 */
            buzzer_bip(1u);
        }
        break;

    case EV_CONSIGNE:                           /* E5 : potentiomètre (déjà filtré par acq v2) */
        consigne_pot = (e->valeur > 100u) ? 100u : e->valeur;
        if (etat == ETAT_MARCHE_AVANT || etat == ETAT_MARCHE_ARRIERE) {
            consigne_pct = consigne_pot;        /* ARRÊT / urgence : mémorisée seulement */
        }
        break;

    case EV_VITESSE:                            /* E3 : fronts -> tr/min Q16.16 (vitesse.s) */
        expose.vitesse_rpm_q16 = enc_fronts_vers_rpm_q16(e->valeur);
        expose.sens = sens_mesure;
        break;

    default:
        break;
    }
}

/* Rampe du laboratoire 2 (E5) : en marche seulement, toutes les RAMPE_PAS_MS,
 * pwm_pct se rapproche de consigne_pct d'un point, puis motor_set_pwm.
 * En ARRÊT et en urgence, rien n'est écrit : CCR1 reste à 0 (mis par
 * entree_etat / motor_set_dir(MOTOR_ARRET) ou par l'ISR E-Stop).           */
static void rampe(void)
{
    if (etat != ETAT_MARCHE_AVANT && etat != ETAT_MARCHE_ARRIERE) {
        rampe_compteur = 0u;
        return;
    }
    if (++rampe_compteur < RAMPE_PAS_MS) {
        return;
    }
    rampe_compteur = 0u;
    if (pwm_pct < consigne_pct) {
        pwm_pct++;
    } else if (pwm_pct > consigne_pct) {
        pwm_pct--;
    } else {
        return;                                 /* consigne atteinte            */
    }
    (void)motor_set_pwm(pwm_pct);
}

void fsm_sorties(void)
{
    rampe();
    if (etat == ETAT_ARRET_URGENCE) {
        if (++clignote_compteur >= CLIGNOTEMENT_DEMI_MS) {
            clignote_compteur = 0u;
            clignote_phase ^= 1u;
        }
        led_set(clignote_phase ? LED_ROUGE : LED_AUCUNE);
    } else if (etat <= ETAT_MARCHE_ARRIERE) {
        led_set(etat_vers_del[etat]);
    }
    buzzer_step();
}

const etat_vehicule_t *fsm_etat(void)
{
    expose.etat = etat;
    expose.consigne_pct = consigne_pct;
    expose.pwm_pct = pwm_pct;
    expose.transitions = compteur_transitions;
    return &expose;
}
