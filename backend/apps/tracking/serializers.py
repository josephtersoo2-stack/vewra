from rest_framework import serializers

class ProgressUpdateSerializer(serializers.Serializer):
    session_id = serializers.IntegerField(required=True)
    current_time = serializers.FloatField(required=True, min_value=0.0)
    delta_seconds = serializers.FloatField(required=True, min_value=0.0)

    def validate_delta_seconds(self, value):
        # Cap unreasonable single delta updates (e.g. max 60s per ping) to prevent cheating
        if value > 120.0:
            raise serializers.ValidationError("Delta seconds too large for a single update ping.")
        return value
