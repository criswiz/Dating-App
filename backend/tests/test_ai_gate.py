from app.services.ai_gate import evaluate_ai_readiness, ai_features_enabled


def test_ai_readiness_requires_all_checks():
    not_ready = evaluate_ai_readiness(
        monthly_revenue=0,
        training_events=0,
        conversion_plateaued=False,
    )
    assert not_ready["ready"] is False
    assert not_ready["checks"]["revenue_threshold"] is False


def test_ai_feature_status_stays_off_by_default():
    enabled = ai_features_enabled(
        monthly_revenue=1_000_000,
        training_events=1_000_000,
        conversion_plateaued=True,
    )
    # Guardrail: paid AI should remain disabled unless explicitly enabled in config.
    assert enabled is False
