from rest_framework import serializers
from .models import Gam3a, SimulationSettings


class Gam3aSerializer(serializers.ModelSerializer):
    class Meta:
        model = Gam3a
        fields = '__all__'
        read_only_fields = ['id', 'created_at']


class SimulationSettingsSerializer(serializers.ModelSerializer):
    class Meta:
        model = SimulationSettings
        fields = '__all__'
        read_only_fields = ['id']


class ScenarioRequestSerializer(serializers.Serializer):
    annual_rate = serializers.FloatField(required=False)
    investment_day = serializers.IntegerField(required=False, min_value=1, max_value=28)
    extra_inflows = serializers.DictField(
        child=serializers.FloatField(),
        required=False,
        default=dict
    )


class ChatMessageSerializer(serializers.Serializer):
    role = serializers.ChoiceField(choices=['user', 'assistant'])
    content = serializers.CharField()


class ChatRequestSerializer(serializers.Serializer):
    message = serializers.CharField()
    history = ChatMessageSerializer(many=True, required=False, default=list)
