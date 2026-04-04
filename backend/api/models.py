from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator


class Gam3a(models.Model):
    name = models.CharField(max_length=100)
    total_pot = models.FloatField()
    monthly_contribution = models.FloatField()
    payout_month = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(12)]
    )
    payout_received = models.BooleanField(default=False)
    start_month = models.IntegerField(
        default=1,
        validators=[MinValueValidator(1), MaxValueValidator(12)]
    )
    end_month = models.IntegerField(
        default=12,
        validators=[MinValueValidator(1), MaxValueValidator(12)]
    )
    active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['id']

    def __str__(self):
        return self.name


class SimulationSettings(models.Model):
    annual_rate = models.FloatField(default=19.0)
    investment_day = models.IntegerField(
        default=20,
        validators=[MinValueValidator(1), MaxValueValidator(28)]
    )
    year = models.IntegerField(default=2026)

    def __str__(self):
        return f"Settings ({self.year}, {self.annual_rate}%)"


class MonthlyOverride(models.Model):
    month = models.IntegerField(
        unique=True,
        validators=[MinValueValidator(1), MaxValueValidator(12)]
    )
    custom_inflow = models.FloatField(null=True, blank=True)
    custom_payment = models.FloatField(null=True, blank=True)
    note = models.TextField(null=True, blank=True)

    class Meta:
        ordering = ['month']

    def __str__(self):
        return f"Override month {self.month}"
