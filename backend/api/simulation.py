"""
Core simulation engine for Gam3ya Investment Simulator.

Implements the 12-month compound interest simulation as specified in the PRD.
"""

MONTH_NAMES = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
]


def run_simulation(gam3as, settings, overrides=None, extra_inflows=None):
    """
    Run the full 12-month simulation.

    Args:
        gam3as: iterable of Gam3a model instances (active only)
        settings: SimulationSettings instance
        overrides: dict of {month_int: MonthlyOverride} for custom inflows/payments
        extra_inflows: dict of {month_str_or_int: float} for scenario extra inflows

    Returns:
        dict with 'rows' (list of 12 monthly dicts) and 'kpis' dict
    """
    if overrides is None:
        overrides = {}
    if extra_inflows is None:
        extra_inflows = {}

    # Normalise extra_inflows keys to int
    extra_inflows = {int(k): float(v) for k, v in extra_inflows.items()}

    annual_rate = settings.annual_rate / 100.0
    monthly_rate = annual_rate / 12.0
    investment_day = settings.investment_day
    day_ratio = (31 - investment_day) / 31.0

    opening_balance = 0.0
    cumul_invested = 0.0
    cumul_interest = 0.0
    total_payments = 0.0

    rows = []

    for month in range(1, 13):
        override = overrides.get(month)

        # --- Inflow ---
        calculated_inflow = sum(
            g.total_pot
            for g in gam3as
            if g.payout_month == month
        )
        if override and override.custom_inflow is not None:
            inflow = override.custom_inflow
        else:
            inflow = calculated_inflow

        # Add scenario extra inflows
        inflow += extra_inflows.get(month, 0.0)

        # --- Payments out ---
        calculated_payments = sum(
            g.monthly_contribution
            for g in gam3as
            if g.start_month <= month <= g.end_month
        )
        if override and override.custom_payment is not None:
            payments_out = override.custom_payment
        else:
            payments_out = calculated_payments

        # --- Interest ---
        pos_opening = max(0.0, opening_balance)
        available = pos_opening + inflow

        if available <= 0:
            interest = 0.0
        else:
            interest = (pos_opening * monthly_rate) + (inflow * monthly_rate * day_ratio)

        # --- Closing balance ---
        closing_balance = opening_balance + inflow + interest - payments_out

        # --- Cumulative ---
        cumul_invested += inflow
        cumul_interest += interest
        total_payments += payments_out

        # Payout gam3as for this month
        payout_gam3as = [g.name for g in gam3as if g.payout_month == month]

        rows.append({
            'month': month,
            'month_name': MONTH_NAMES[month],
            'opening_balance': round(opening_balance, 2),
            'inflow': round(inflow, 2),
            'interest': round(interest, 2),
            'payments_out': round(payments_out, 2),
            'closing_balance': round(closing_balance, 2),
            'cumul_invested': round(cumul_invested, 2),
            'cumul_interest': round(cumul_interest, 2),
            'is_payout_month': len(payout_gam3as) > 0,
            'payout_gam3as': payout_gam3as,
        })

        opening_balance = closing_balance

    total_interest = round(cumul_interest, 2)
    effective_yield = round((total_interest / cumul_invested * 100), 2) if cumul_invested > 0 else 0.0

    kpis = {
        'total_invested': round(cumul_invested, 2),
        'total_interest': total_interest,
        'total_payments_out': round(total_payments, 2),
        'final_balance': round(opening_balance, 2),
        'effective_yield': effective_yield,
    }

    return {'rows': rows, 'kpis': kpis}
