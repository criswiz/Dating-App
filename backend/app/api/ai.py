from fastapi import APIRouter, Query

from app.services.ai_gate import evaluate_ai_readiness, ai_features_enabled

router = APIRouter()


@router.get("/readiness")
def ai_readiness(
    monthly_revenue: int = Query(ge=0, description="Current monthly recurring revenue"),
    training_events: int = Query(ge=0, description="Eligible interaction events collected"),
    conversion_plateaued: bool = Query(default=False),
):
    return evaluate_ai_readiness(
        monthly_revenue=monthly_revenue,
        training_events=training_events,
        conversion_plateaued=conversion_plateaued,
    )


@router.get("/features/status")
def ai_feature_status(
    monthly_revenue: int = Query(ge=0),
    training_events: int = Query(ge=0),
    conversion_plateaued: bool = Query(default=False),
):
    return {
        "enabled": ai_features_enabled(
            monthly_revenue=monthly_revenue,
            training_events=training_events,
            conversion_plateaued=conversion_plateaued,
        )
    }
