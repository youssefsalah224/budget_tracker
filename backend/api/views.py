import json
import types
import anthropic
from django.conf import settings as django_settings
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from .models import Gam3a, SimulationSettings, MonthlyOverride
from .serializers import (
    Gam3aSerializer,
    SimulationSettingsSerializer,
    ScenarioRequestSerializer,
    ChatRequestSerializer,
)
from .simulation import run_simulation


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _get_settings():
    """Return the single SimulationSettings row, creating it if needed."""
    obj, _ = SimulationSettings.objects.get_or_create(
        pk=1,
        defaults={'annual_rate': 19.0, 'investment_day': 20, 'year': 2026}
    )
    return obj


def _get_overrides_map():
    """Return a dict of {month_int: MonthlyOverride}."""
    return {o.month: o for o in MonthlyOverride.objects.all()}


def _active_gam3as():
    return list(Gam3a.objects.filter(active=True))


# ---------------------------------------------------------------------------
# Gam3a CRUD — GET /api/gam3as  POST /api/gam3as
# ---------------------------------------------------------------------------

class Gam3aListCreateView(APIView):

    def get(self, request):
        gam3as = Gam3a.objects.all()
        return Response(Gam3aSerializer(gam3as, many=True).data)

    def post(self, request):
        serializer = Gam3aSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# ---------------------------------------------------------------------------
# Gam3a CRUD — PUT /api/gam3as/{id}  DELETE /api/gam3as/{id}
# ---------------------------------------------------------------------------

class Gam3aDetailView(APIView):

    def _get_object(self, pk):
        try:
            return Gam3a.objects.get(pk=pk)
        except Gam3a.DoesNotExist:
            return None

    def put(self, request, pk):
        obj = self._get_object(pk)
        if obj is None:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
        serializer = Gam3aSerializer(obj, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk):
        obj = self._get_object(pk)
        if obj is None:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
        obj.delete()
        return Response({'ok': True})


# ---------------------------------------------------------------------------
# Settings — GET /api/settings  PUT /api/settings
# ---------------------------------------------------------------------------

class SettingsView(APIView):

    def get(self, request):
        obj = _get_settings()
        return Response(SimulationSettingsSerializer(obj).data)

    def put(self, request):
        obj = _get_settings()
        serializer = SimulationSettingsSerializer(obj, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# ---------------------------------------------------------------------------
# Simulate — GET /api/simulate
# ---------------------------------------------------------------------------

class SimulateView(APIView):

    def get(self, request):
        sim_settings = _get_settings()
        gam3as = _active_gam3as()
        overrides = _get_overrides_map()
        result = run_simulation(gam3as, sim_settings, overrides)
        return Response(result)


# ---------------------------------------------------------------------------
# Scenario — POST /api/simulate/scenario
# ---------------------------------------------------------------------------

class ScenarioView(APIView):

    def post(self, request):
        serializer = ScenarioRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        sim_settings = _get_settings()
        gam3as = _active_gam3as()
        overrides = _get_overrides_map()

        temp_settings = types.SimpleNamespace(
            annual_rate=data.get('annual_rate', sim_settings.annual_rate),
            investment_day=data.get('investment_day', sim_settings.investment_day),
            year=sim_settings.year,
        )

        result = run_simulation(
            gam3as,
            temp_settings,
            overrides,
            extra_inflows=data.get('extra_inflows', {}),
        )
        return Response(result)


# ---------------------------------------------------------------------------
# AI Chat — POST /api/chat
# ---------------------------------------------------------------------------

class ChatView(APIView):

    def post(self, request):
        serializer = ChatRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        user_message = data['message']
        history = data.get('history', [])

        # Build simulation context
        sim_settings = _get_settings()
        gam3as = _active_gam3as()
        overrides = _get_overrides_map()
        simulation = run_simulation(gam3as, sim_settings, overrides)

        gam3as_json = Gam3aSerializer(gam3as, many=True).data
        rows_json = simulation['rows']
        kpis = simulation['kpis']

        system_prompt = (
            "You are a personal finance advisor embedded in an investment tracking app.\n"
            "The user is managing rotating savings clubs (Gam3as) and investing the payouts "
            "into a compounding fund. Here is their current financial data:\n\n"
            f"SETTINGS:\n"
            f"- Annual interest rate: {sim_settings.annual_rate}%\n"
            f"- Investment day: {sim_settings.investment_day}th of each month\n"
            f"- Year: {sim_settings.year}\n\n"
            f"ACTIVE GAM3AS:\n{json.dumps(list(gam3as_json), ensure_ascii=False, indent=2)}\n\n"
            f"12-MONTH SIMULATION:\n{json.dumps(rows_json, ensure_ascii=False, indent=2)}\n\n"
            f"KPIs:\n"
            f"- Total invested: {kpis['total_invested']:,.2f} EGP\n"
            f"- Total interest earned: {kpis['total_interest']:,.2f} EGP\n"
            f"- Total payments out: {kpis['total_payments_out']:,.2f} EGP\n"
            f"- Final balance: {kpis['final_balance']:,.2f} EGP\n"
            f"- Effective yield: {kpis['effective_yield']}%\n\n"
            "Answer concisely and helpfully. Detect the user's language from their message "
            "and respond in the same language (Arabic or English). Format numbers with "
            "commas and EGP suffix. Never make up data — only reference the numbers above."
        )

        # Build messages list from history + new user message
        messages = [
            {'role': m['role'], 'content': m['content']}
            for m in history
        ]
        messages.append({'role': 'user', 'content': user_message})

        api_key = django_settings.ANTHROPIC_API_KEY
        if not api_key:
            return Response(
                {'detail': 'ANTHROPIC_API_KEY is not configured.'},
                status=status.HTTP_503_SERVICE_UNAVAILABLE
            )

        client = anthropic.Anthropic(api_key=api_key)
        response = client.messages.create(
            model='claude-sonnet-4-6',
            max_tokens=1024,
            system=system_prompt,
            messages=messages,
        )

        reply = response.content[0].text
        return Response({'reply': reply})
