/* ---------------------------------------------------------------------------
 * telem.c — télémétrie LPUART1 au niveau des registres (CMSIS, sans HAL)
 *           (CEG 3536, laboratoire 3, E10) — complété par l'équipe (Groupe 15)
 *
 * LPUART1 : TX = PG7, RX = PG8 (AF8), 115 200 bauds, 8N1, vers le port COM
 * virtuel du ST-LINK (guide, p. 54-55). Le port G (broches 2 à 15) est alimenté
 * par VDDIO2 : PWR_CR2.IOSV doit être mis à 1 (RM0438, section PWR).
 * Horloge noyau = PCLK1 = 4 MHz (RCC_CCIPR1.LPUART1SEL = 00) :
 *   BRR = 256 x fck / bauds (vérifier fck >= 3 x bauds).
 * FIFO activée (CR1.FIFOEN, 8 octets) : telem_step remplit la FIFO tant que
 * ISR.TXFNF est à 1, sans jamais attendre.
 *
 * Fourni : horloges, IOSV, broches, file logicielle (telem_put), formatage
 * entier, en-tête. À écrire : BRR et CR1 (fin de telem_init), telem_step,
 * telem_rx, telem_trame.
 * ------------------------------------------------------------------------- */
#include "stm32l552xx.h"
#include "telem.h"

#define TX_TAILLE 512u
static char     tx_file[TX_TAILLE];
static uint32_t tx_tete, tx_queue, tx_nombre, pertes;

void telem_init(uint32_t bauds)
{
    RCC->APB1ENR1 |= RCC_APB1ENR1_PWREN;
    (void)RCC->APB1ENR1;
    PWR->CR2 |= PWR_CR2_IOSV;                         /* alimentation du port G */
    RCC->AHB2ENR |= RCC_AHB2ENR_GPIOGEN;
    RCC->APB1ENR2 |= RCC_APB1ENR2_LPUART1EN;
    RCC->CCIPR1 &= ~RCC_CCIPR1_LPUART1SEL;            /* 00 = PCLK1             */
    (void)RCC->APB1ENR2;

    /* PG7 (TX) : AFRL champ 7 = 8 ; PG8 (RX) : AFRH champ 0 = 8 ; MODER = 10 */
    GPIOG->AFR[0] = (GPIOG->AFR[0] & ~GPIO_AFRL_AFSEL7) | (8u << GPIO_AFRL_AFSEL7_Pos);
    GPIOG->AFR[1] = (GPIOG->AFR[1] & ~GPIO_AFRH_AFSEL8) | (8u << GPIO_AFRH_AFSEL8_Pos);
    GPIOG->MODER = (GPIOG->MODER & ~(GPIO_MODER_MODE7 | GPIO_MODER_MODE8))
                 | GPIO_MODER_MODE7_1 | GPIO_MODER_MODE8_1;
    GPIOG->OSPEEDR |= GPIO_OSPEEDR_OSPEED7_0;
    GPIOG->PUPDR = (GPIOG->PUPDR & ~GPIO_PUPDR_PUPD8) | GPIO_PUPDR_PUPD8_0; /* RX tiré à 1 */

    /* BRR = 256 x fck / bauds, arrondi : 256 x 4 000 000 / 115 200 = 8 888,9 -> 8 889
     * (0x22B9) ; débit réel 115 199 bauds (écart -0,001 %). fck = 4 MHz >= 3 x 115 200. */
    LPUART1->CR1 = 0u;                                /* UE = 0 pour configurer */
    LPUART1->BRR = (uint32_t)(((uint64_t)HORLOGE_HZ_C * 256u + bauds / 2u) / bauds);
    LPUART1->CR2 = 0u;                                /* 1 bit d'arrêt          */
    LPUART1->CR3 = 0u;                                /* sans contrôle de flux  */
    LPUART1->CR1 = USART_CR1_FIFOEN | USART_CR1_TE | USART_CR1_RE;   /* 8N1   */
    LPUART1->CR1 |= USART_CR1_UE;

    tx_tete = tx_queue = tx_nombre = pertes = 0u;
}

bool telem_put(const char *s)
{
    while (*s) {
        if (tx_nombre >= TX_TAILLE) {
            pertes++;
            return false;
        }
        tx_file[tx_queue] = *s++;
        tx_queue = (tx_queue + 1u) % TX_TAILLE;
        tx_nombre++;
    }
    return true;
}

/* Vide la file logicielle dans la FIFO matérielle tant qu'elle a de la
 * place (TXFNF = 1). Aucune attente : au plus 8 octets par appel (1 ms),
 * soit 8 ko/s > 11,5 ko/s x 2,5 % utilisés par la télémétrie (E10).       */
void telem_step(void)
{
    while (tx_nombre > 0u && (LPUART1->ISR & USART_ISR_TXE_TXFNF)) {
        LPUART1->TDR = (uint8_t)tx_file[tx_tete];
        tx_tete = (tx_tete + 1u) % TX_TAILLE;
        tx_nombre--;
    }
}

/* Caractère reçu (commande d'un caractère), ou -1. Un débordement de
 * réception (ORE) est effacé pour ne pas bloquer les réceptions suivantes. */
int telem_rx(void)
{
    if (LPUART1->ISR & USART_ISR_ORE) {
        LPUART1->ICR = USART_ICR_ORECF;
    }
    if (LPUART1->ISR & USART_ISR_RXNE_RXFNE) {
        return (int)(LPUART1->RDR & 0xFFu);
    }
    return -1;
}

uint32_t telem_pertes(void) { return pertes; }

/* ---- formatage entier [FOURNI] ---------------------------------------- */
char *telem_fmt_u32(char *p, uint32_t v)
{
    char tmp[11];
    int n = 0;
    do { tmp[n++] = (char)('0' + v % 10u); v /= 10u; } while (v);
    while (n) *p++ = tmp[--n];
    *p = '\0';
    return p;
}

char *telem_fmt_i32(char *p, int32_t v)
{
    if (v < 0) { *p++ = '-'; v = -v; }
    return telem_fmt_u32(p, (uint32_t)v);
}

/* ---- trames ------------------------------------------------------------ */
void telem_entete(void)
{
    telem_put("H,ticks_ms,etat,sens,consigne_pct,pwm_pct,temp_c_x10,vitesse_rpm_x100,nb_evenements,evq_debordements\r\n");
}

/* Ligne T,<ticks_ms>,<etat>,<sens>,<consigne_pct>,<pwm_pct>,<temp_c_x10>,
 * <vitesse_rpm_x100>,<nb_evenements>,<debordements>\r\n (E10), formatée à
 * la main (pas de printf) puis mise en file d'un seul bloc : si la file
 * logicielle n'a pas la place pour la ligne entière, la trame est perdue
 * (comptée) plutôt que tronquée (E12). Longueur max ~ 90 caractères.       */
void telem_trame(const etat_vehicule_t *v, int32_t temp_c_x10,
                 uint32_t nb_evenements, uint32_t debordements)
{
    char ligne[112];
    char *p = ligne;
    uint32_t rpm_x100 = (uint32_t)(((uint64_t)v->vitesse_rpm_q16 * 100u + 32768u) >> 16);

    *p++ = 'T'; *p++ = ',';
    p = telem_fmt_u32(p, ticks_ms);       *p++ = ',';
    p = telem_fmt_u32(p, v->etat);        *p++ = ',';
    p = telem_fmt_u32(p, v->sens);        *p++ = ',';
    p = telem_fmt_u32(p, v->consigne_pct); *p++ = ',';
    p = telem_fmt_u32(p, v->pwm_pct);     *p++ = ',';
    p = telem_fmt_i32(p, temp_c_x10);     *p++ = ',';
    p = telem_fmt_u32(p, rpm_x100);       *p++ = ',';
    p = telem_fmt_u32(p, nb_evenements);  *p++ = ',';
    p = telem_fmt_u32(p, debordements);
    *p++ = '\r'; *p++ = '\n'; *p = '\0';

    if ((uint32_t)(p - ligne) > TX_TAILLE - tx_nombre) {
        pertes++;                         /* pas de trame tronquée            */
        return;
    }
    (void)telem_put(ligne);
}
