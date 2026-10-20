from fastapi.testclient import TestClient
import ml.api as api
from ml.api import app

client = TestClient(app)

VALID_PAYLOAD = {
    "total_screen_time": 180,
    "social_media_time": 30,
    "entertainment_time": 60,
    "communication_time": 20,
    "gaming_time": 10,
    "productivity_time": 30,
    "number_of_apps": 12,
    "number_of_sessions": 40,
    "late_night_usage": 10,
    "most_used_app_time": 60,
}


def test_home_endpoint_returns_ready_status():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json()["status"] == "ready"


def test_predict_endpoint_returns_expected_fields():
    response = client.post("/predict", json=VALID_PAYLOAD)
    assert response.status_code == 200

    body = response.json()
    assert body["risk_level"] in {"LOW", "MODERATE", "HIGH", "CRITICAL"}
    assert set(body["probabilities"]) == {"LOW", "MODERATE", "HIGH", "CRITICAL"}
    assert abs(sum(body["probabilities"].values()) - 1.0) < 0.02
    assert "features" in body
    assert "explanation" in body
    assert "feature_importance" in body
    assert "shap_explanation" in body


def test_predict_rejects_missing_required_field():
    payload = VALID_PAYLOAD.copy()
    del payload["total_screen_time"]

    response = client.post("/predict", json=payload)
    assert response.status_code == 422


def test_predict_rejects_string_for_integer_field():
    payload = VALID_PAYLOAD.copy()
    payload["total_screen_time"] = "not-a-number"

    response = client.post("/predict", json=payload)
    assert response.status_code == 422


def test_predict_rejects_negative_screen_time():
    payload = VALID_PAYLOAD.copy()
    payload["total_screen_time"] = -10

    response = client.post("/predict", json=payload)
    assert response.status_code == 422
def test_predict_rejects_negative_values_in_all_usage_fields():
    fields = [
        "total_screen_time",
        "social_media_time",
        "entertainment_time",
        "communication_time",
        "gaming_time",
        "productivity_time",
        "number_of_apps",
        "number_of_sessions",
        "late_night_usage",
        "most_used_app_time",
    ]

    for field in fields:
        payload = VALID_PAYLOAD.copy()
        payload[field] = -1
        response = client.post("/predict", json=payload)
        assert response.status_code == 422, (
            f"{field} accepted -1; got HTTP {response.status_code}"
        )


def test_predict_rejects_non_object_json():
    response = client.post("/predict", json=["invalid", "payload"])
    assert response.status_code == 422


def test_predict_returns_controlled_error_when_model_fails(monkeypatch):
    def fail_prediction(data):
        raise RuntimeError("internal model details must not be exposed")

    monkeypatch.setattr(api.model, "predict", fail_prediction)

    response = client.post("/predict", json=VALID_PAYLOAD)

    assert response.status_code == 500
    assert response.json()["detail"] == (
        "Prediction failed. Please try again later."
    )
    assert "internal model details" not in response.text


def test_predict_returns_controlled_error_when_shap_fails(monkeypatch):
    def fail_shap(data, prediction):
        raise ValueError("internal SHAP details must not be exposed")

    monkeypatch.setattr(api, "generate_shap_explanation", fail_shap)

    response = client.post("/predict", json=VALID_PAYLOAD)

    assert response.status_code == 500
    assert response.json()["detail"] == (
        "Prediction failed. Please try again later."
    )
    assert "internal SHAP details" not in response.text
