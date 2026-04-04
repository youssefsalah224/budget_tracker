from django.urls import path
from .views import (
    Gam3aListCreateView,
    Gam3aDetailView,
    SettingsView,
    SimulateView,
    ScenarioView,
    ChatView,
)

urlpatterns = [
    path('gam3as', Gam3aListCreateView.as_view(), name='gam3a-list-create'),
    path('gam3as/<int:pk>', Gam3aDetailView.as_view(), name='gam3a-detail'),
    path('settings', SettingsView.as_view(), name='settings'),
    path('simulate', SimulateView.as_view(), name='simulate'),
    path('simulate/scenario', ScenarioView.as_view(), name='simulate-scenario'),
    path('chat', ChatView.as_view(), name='chat'),
]
