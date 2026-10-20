from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
import pandas as pd
import joblib
import os
import shap


# ==================================================
# CREATE FASTAPI APPLICATION
# ==================================================

app = FastAPI(
    title="HabitGuard ML API",
    description="Machine Learning Risk Prediction API with XAI",
    version="1.3"
)


# ==================================================
# LOAD TRAINED RANDOM FOREST MODEL
# ==================================================

MODEL_PATH = os.path.join(
    os.path.dirname(__file__),
    "habitguard_model.pkl"
)

model = joblib.load(MODEL_PATH)


# ==================================================
# CREATE SHAP EXPLAINER
# ==================================================

explainer = shap.TreeExplainer(model)


# ==================================================
# FEATURE NAMES
# ==================================================

FEATURE_NAMES = [
    "total_screen_time",
    "social_media_time",
    "entertainment_time",
    "communication_time",
    "gaming_time",
    "productivity_time",
    "number_of_apps",
    "number_of_sessions",
    "late_night_usage",
    "most_used_app_time"
]


# ==================================================
# INPUT DATA STRUCTURE
# ==================================================

class UsageFeatures(BaseModel):
    total_screen_time: int = Field(ge=0)
    social_media_time: int = Field(ge=0)
    entertainment_time: int = Field(ge=0)
    communication_time: int = Field(ge=0)
    gaming_time: int = Field(ge=0)
    productivity_time: int = Field(ge=0)
    number_of_apps: int = Field(ge=0)
    number_of_sessions: int = Field(ge=0)
    late_night_usage: int = Field(ge=0)
    most_used_app_time: int = Field(ge=0)



# ==================================================
# FEATURE DISPLAY NAMES
# ==================================================

FEATURE_DISPLAY_NAMES = {

    "total_screen_time":
        "Total screen time",

    "social_media_time":
        "Social media usage",

    "entertainment_time":
        "Entertainment usage",

    "communication_time":
        "Communication usage",

    "gaming_time":
        "Gaming usage",

    "productivity_time":
        "Productivity usage",

    "number_of_apps":
        "Number of apps",

    "number_of_sessions":
        "Number of app sessions",

    "late_night_usage":
        "Late-night usage",

    "most_used_app_time":
        "Most-used app time"
}


# ==================================================
# RULE-BASED XAI
# ==================================================

def generate_rule_explanation(features, risk_level):

    reasons = []

    # ----------------------------------------------
    # Total Screen Time
    # ----------------------------------------------

    if features.total_screen_time >= 360:

        reasons.append(
            "Very high total screen time"
        )

    elif features.total_screen_time >= 240:

        reasons.append(
            "High total screen time"
        )

    elif features.total_screen_time <= 120:

        reasons.append(
            "Total screen time is relatively low"
        )


    # ----------------------------------------------
    # Social Media
    # ----------------------------------------------

    if features.social_media_time >= 120:

        reasons.append(
            "High social media usage"
        )

    elif features.social_media_time <= 30:

        reasons.append(
            "Low social media usage"
        )


    # ----------------------------------------------
    # Entertainment
    # ----------------------------------------------

    if features.entertainment_time >= 180:

        reasons.append(
            "High entertainment app usage"
        )

    elif features.entertainment_time <= 60:

        reasons.append(
            "Limited entertainment usage"
        )


    # ----------------------------------------------
    # Gaming
    # ----------------------------------------------

    if features.gaming_time >= 120:

        reasons.append(
            "High gaming usage"
        )

    elif features.gaming_time == 0:

        reasons.append(
            "No significant gaming usage"
        )


    # ----------------------------------------------
    # Productivity
    # ----------------------------------------------

    if features.productivity_time >= 120:

        reasons.append(
            "Good amount of productivity usage"
        )

    elif features.productivity_time == 0:

        reasons.append(
            "No significant productivity app usage"
        )


    # ----------------------------------------------
    # Late Night Usage
    # ----------------------------------------------

    if features.late_night_usage >= 60:

        reasons.append(
            "High late-night usage"
        )

    elif features.late_night_usage <= 15:

        reasons.append(
            "Limited late-night usage"
        )


    # ----------------------------------------------
    # Number of Sessions
    # ----------------------------------------------

    if features.number_of_sessions >= 150:

        reasons.append(
            "Very frequent app sessions"
        )

    elif features.number_of_sessions <= 50:

        reasons.append(
            "Relatively few app sessions"
        )


    # ----------------------------------------------
    # Most Used App
    # ----------------------------------------------

    if features.most_used_app_time >= 180:

        reasons.append(
            "One application accounts for a large amount of usage"
        )


    # ----------------------------------------------
    # Number of Apps
    # ----------------------------------------------

    if features.number_of_apps >= 15:

        reasons.append(
            "High number of frequently used applications"
        )

    elif features.number_of_apps <= 5:

        reasons.append(
            "Limited number of frequently used applications"
        )


    # ----------------------------------------------
    # Risk Summary
    # ----------------------------------------------

    if risk_level == "LOW":

        summary = (
            "Your current usage pattern shows "
            "relatively lower-risk behavior."
        )

    elif risk_level == "MODERATE":

        summary = (
            "Some usage patterns indicate "
            "moderate digital wellbeing risk."
        )

    elif risk_level == "HIGH":

        summary = (
            "Several usage patterns indicate "
            "elevated digital wellbeing risk."
        )

    else:

        summary = (
            "Multiple usage patterns indicate "
            "very high digital wellbeing risk."
        )


    if len(reasons) == 0:

        reasons.append(
            "No major usage factor crossed the current explanation thresholds"
        )


    return {

        "summary":
            summary,

        "reasons":
            reasons[:5]
    }


# ==================================================
# RANDOM FOREST FEATURE IMPORTANCE XAI
# ==================================================

def generate_feature_importance_explanation(data):

    importances = model.feature_importances_

    feature_importance_list = []

    for i in range(len(FEATURE_NAMES)):

        feature_name = FEATURE_NAMES[i]

        importance = float(importances[i])

        actual_value = float(
            data.iloc[0][feature_name]
        )

        feature_importance_list.append({

            "feature":
                feature_name,

            "display_name":
                FEATURE_DISPLAY_NAMES[feature_name],

            "importance":
                round(importance, 4),

            "value":
                actual_value
        })


    # ----------------------------------------------
    # Sort by importance
    # ----------------------------------------------

    feature_importance_list.sort(
        key=lambda x: x["importance"],
        reverse=True
    )


    # ----------------------------------------------
    # Select Top 5 Features
    # ----------------------------------------------

    top_features = feature_importance_list[:5]


    # ----------------------------------------------
    # Create Human-readable explanations
    # ----------------------------------------------

    explanations = []

    for feature in top_features:

        name = feature["display_name"]

        importance = feature["importance"]

        value = feature["value"]


        explanations.append({

            "feature":
                name,

            "importance":
                importance,

            "value":
                value,

            "message":
                f"{name} contributed "
                f"{importance * 100:.1f}% "
                f"of the model's overall feature importance."
        })


    return {

        "top_features":
            top_features,

        "messages":
            explanations
    }


# ==================================================
# SHAP EXPLANATION
# ==================================================

def generate_shap_explanation(data, prediction):

    # ----------------------------------------------
    # Generate SHAP values
    # ----------------------------------------------

    shap_result = explainer(data)

    values = shap_result.values


    # ----------------------------------------------
    # Find predicted class index
    # ----------------------------------------------

    class_index = list(
        model.classes_
    ).index(prediction)


    # ----------------------------------------------
    # Handle SHAP output shape
    # ----------------------------------------------

    if values.ndim == 3:

        # Shape:
        # samples x features x classes

        contributions = values[
            0,
            :,
            class_index
        ]

    elif values.ndim == 2:

        # Shape:
        # samples x features

        contributions = values[0]

    else:

        raise ValueError(
            f"Unexpected SHAP output shape: {values.shape}"
        )


    # ----------------------------------------------
    # Create SHAP result list
    # ----------------------------------------------

    shap_results = []

    for i, feature_name in enumerate(FEATURE_NAMES):

        shap_value = float(
            contributions[i]
        )

        actual_value = float(
            data.iloc[0][feature_name]
        )


        # ------------------------------------------
        # Determine impact
        # ------------------------------------------

        if shap_value > 0:

            impact = "supports predicted class"

        elif shap_value < 0:

            impact = "opposes predicted class"

        else:

            impact = "neutral"


        shap_results.append({

            "feature":
                feature_name,

            "display_name":
                FEATURE_DISPLAY_NAMES[feature_name],

            "value":
                actual_value,

            "shap_value":
                round(shap_value, 4),

            "impact":
                impact
        })


    # ----------------------------------------------
    # Sort by absolute SHAP impact
    # ----------------------------------------------

    shap_results.sort(
        key=lambda x: abs(x["shap_value"]),
        reverse=True
    )


    # ----------------------------------------------
    # Top 5 SHAP features
    # ----------------------------------------------

    top_features = shap_results[:5]


    # ----------------------------------------------
    # Human-readable messages
    # ----------------------------------------------

    messages = []

    for feature in top_features:

        messages.append({

            "feature":
                feature["display_name"],

            "value":
                feature["value"],

            "shap_value":
                feature["shap_value"],

            "impact":
                feature["impact"],

            "message":
                f"{feature['display_name']} "
                f"{feature['impact']} "
                f"for this prediction."
        })


    return {

        "top_features":
            top_features,

        "messages":
            messages
    }


# ==================================================
# ROOT ENDPOINT
# ==================================================

@app.get("/")
def home():

    return {

        "message":
            "HabitGuard ML API is running",

        "model":
            "Random Forest",

        "xai":
            "enabled",

        "xai_type":
            "Rule-based + Random Forest Feature Importance + SHAP",

        "status":
            "ready"
    }


# ==================================================
# PREDICTION ENDPOINT
# ==================================================

@app.post("/predict")
def predict_risk(features: UsageFeatures):
    try:


        # ----------------------------------------------
        # Create DataFrame
        # ----------------------------------------------

        data = pd.DataFrame([

            {

                "total_screen_time":
                    features.total_screen_time,

                "social_media_time":
                    features.social_media_time,

                "entertainment_time":
                    features.entertainment_time,

                "communication_time":
                    features.communication_time,

                "gaming_time":
                    features.gaming_time,

                "productivity_time":
                    features.productivity_time,

                "number_of_apps":
                    features.number_of_apps,

                "number_of_sessions":
                    features.number_of_sessions,

                "late_night_usage":
                    features.late_night_usage,

                "most_used_app_time":
                    features.most_used_app_time,

            }

        ])


        # ----------------------------------------------
        # ML Prediction
        # ----------------------------------------------

        prediction = model.predict(data)[0]


        # ----------------------------------------------
        # Prediction Probabilities
        # ----------------------------------------------

        probabilities = model.predict_proba(data)[0]

        classes = model.classes_


        probability_map = {

            str(classes[i]):
                round(float(probabilities[i]), 4)

            for i in range(len(classes))

        }


        # ----------------------------------------------
        # Rule-based explanation
        # ----------------------------------------------

        rule_explanation = generate_rule_explanation(

            features,

            str(prediction)

        )


        # ----------------------------------------------
        # Random Forest Feature Importance
        # ----------------------------------------------

        feature_importance_explanation = (
            generate_feature_importance_explanation(data)
        )


        # ----------------------------------------------
        # SHAP Explanation
        # ----------------------------------------------

        shap_explanation = generate_shap_explanation(

            data,

            prediction

        )


        # ----------------------------------------------
        # FINAL RESPONSE
        # ----------------------------------------------

        return {

            "risk_level":
                str(prediction),

            "probabilities":
                probability_map,

            "features":
                data.iloc[0].to_dict(),

            "explanation":
                rule_explanation,

            "feature_importance":
                feature_importance_explanation,

            "shap_explanation":
                shap_explanation

        }



    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail="Prediction failed. Please try again later.",
        ) from exc
