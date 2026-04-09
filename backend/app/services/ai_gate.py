from app.core.config import (
    AI_FEATURES_ENABLED,
    AI_GATE_APPROVED,
    AI_MIN_MONTHLY_REVENUE,
    AI_MIN_TRAINING_EVENTS,
)


def evaluate_ai_readiness(monthly_revenue: int, training_events: int, conversion_plateaued: bool):
    checks = {
        "revenue_threshold": monthly_revenue >= AI_MIN_MONTHLY_REVENUE,
        "training_data_threshold": training_events >= AI_MIN_TRAINING_EVENTS,
        "conversion_plateaued": conversion_plateaued,
        "budget_and_approval": AI_GATE_APPROVED,
    }
    ready = all(checks.values())
    return {"ready": ready, "checks": checks}


def ai_features_enabled(monthly_revenue: int, training_events: int, conversion_plateaued: bool):
    readiness = evaluate_ai_readiness(
        monthly_revenue=monthly_revenue,
        training_events=training_events,
        conversion_plateaued=conversion_plateaued,
    )
    return AI_FEATURES_ENABLED and readiness["ready"]
