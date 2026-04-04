"""
Management command to seed the database with initial data from the PRD.

Usage:
    python manage.py seed
    python manage.py seed --reset   (clears existing data first)
"""
from django.core.management.base import BaseCommand
from api.models import Gam3a, SimulationSettings, MonthlyOverride


SEED_GAM3AS = [
    {
        'name': 'Gam3a #1',
        'total_pot': 18000,
        'monthly_contribution': 3000,
        'payout_month': 3,
        'payout_received': True,
        'start_month': 4,
        'end_month': 5,
        'active': True,
    },
    {
        'name': 'Gam3a #2',
        'total_pot': 21000,
        'monthly_contribution': 3500,
        'payout_month': 4,
        'payout_received': True,
        'start_month': 4,
        'end_month': 6,
        'active': True,
    },
    {
        'name': 'Gam3a #3',
        'total_pot': 80000,
        'monthly_contribution': 10000,
        'payout_month': 5,
        'payout_received': False,
        'start_month': 3,
        'end_month': 8,
        'active': True,
    },
    {
        'name': 'Gam3a #4',
        'total_pot': 30000,
        'monthly_contribution': 3000,
        'payout_month': 1,
        'payout_received': True,
        'start_month': 3,
        'end_month': 12,
        'active': True,
    },
]


class Command(BaseCommand):
    help = 'Seed the database with initial Gam3ya Investment Simulator data'

    def add_arguments(self, parser):
        parser.add_argument(
            '--reset',
            action='store_true',
            help='Delete all existing data before seeding',
        )

    def handle(self, *args, **options):
        if options['reset']:
            Gam3a.objects.all().delete()
            SimulationSettings.objects.all().delete()
            MonthlyOverride.objects.all().delete()
            self.stdout.write(self.style.WARNING('Existing data cleared.'))

        # Settings
        sim_settings, created = SimulationSettings.objects.get_or_create(
            pk=1,
            defaults={'annual_rate': 19.0, 'investment_day': 20, 'year': 2026}
        )
        if created:
            self.stdout.write(self.style.SUCCESS('Created SimulationSettings: 19%, day 20, year 2026'))
        else:
            self.stdout.write('SimulationSettings already exists — skipped.')

        # Gam3as
        for data in SEED_GAM3AS:
            obj, created = Gam3a.objects.get_or_create(
                name=data['name'],
                defaults=data,
            )
            if created:
                self.stdout.write(self.style.SUCCESS(
                    f"Created {obj.name}: pot={obj.total_pot:,.0f} EGP, payout month={obj.payout_month}"
                ))
            else:
                self.stdout.write(f'{obj.name} already exists — skipped.')

        # Monthly Override: month 1 → inflow forced to 0
        override, created = MonthlyOverride.objects.get_or_create(
            month=1,
            defaults={
                'custom_inflow': 0.0,
                'custom_payment': None,
                'note': 'G4 payout received in Jan but not deposited into this fund',
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(
                'Created MonthlyOverride: month=1, custom_inflow=0.0'
            ))
        else:
            self.stdout.write('MonthlyOverride month=1 already exists — skipped.')

        self.stdout.write(self.style.SUCCESS('\nSeed complete!'))
