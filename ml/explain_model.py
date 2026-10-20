import os
import joblib
import pandas as pd
import shap


# ==========================================
# 1. Paths
# ==========================================

BASE_DIR = os.path.dirname(
    os.path.abspath(__file__)
)

MODEL_PATH = os.path.join(
    BASE_DIR,
    "habitguard_model.pkl"
)

DATASET_PATH = os.path.join(
    BASE_DIR,
    "dataset",
    "habitguard_dataset.csv"
)


# ==========================================
# 2. Load Model
# ==========================================

print("Loading HabitGuard model...")

model = joblib.load(MODEL_PATH)

print("Model loaded successfully!")


# ==========================================
# 3. Load Dataset
# ==========================================

df = pd.read_csv(DATASET_PATH)

X = df.drop(
    "risk_level",
    axis=1
)


# ==========================================
# 4. Select One Sample
# ==========================================

sample = X.iloc[[0]]

print("\n======================================")
print("SAMPLE INPUT")
print("======================================")

print(sample.to_string(index=False))


# ==========================================
# 5. Predict Risk
# ==========================================

prediction = model.predict(sample)[0]

probabilities = model.predict_proba(sample)[0]

classes = model.classes_


print("\n======================================")
print("MODEL PREDICTION")
print("======================================")

print("Predicted Risk:", prediction)

print("\nProbabilities:")

for i in range(len(classes)):
    print(
        f"{classes[i]:<10}: "
        f"{probabilities[i] * 100:.2f}%"
    )


# ==========================================
# 6. Create SHAP Explainer
# ==========================================

print("\n======================================")
print("CREATING SHAP EXPLAINER")
print("======================================")

explainer = shap.TreeExplainer(model)

print("SHAP explainer created successfully!")


# ==========================================
# 7. Calculate SHAP Values
# ==========================================

shap_values = explainer(sample)


# ==========================================
# 8. Display SHAP Values
# ==========================================

print("\n======================================")
print("SHAP FEATURE CONTRIBUTIONS")
print("======================================")


feature_names = X.columns.tolist()


# SHAP 0.52 returns values in the form:
# samples × features × outputs
#
# We select the predicted class.

predicted_class_index = list(
    model.classes_
).index(prediction)


values = shap_values.values[0, :, predicted_class_index]


shap_results = pd.DataFrame({
    "feature": feature_names,
    "value": sample.iloc[0].values,
    "shap_value": values
})


# Sort by absolute contribution

shap_results["absolute_impact"] = (
    shap_results["shap_value"].abs()
)

shap_results = shap_results.sort_values(
    by="absolute_impact",
    ascending=False
)


# ==========================================
# 9. Print Results
# ==========================================

for _, row in shap_results.iterrows():

    direction = (
        "increases risk"
        if row["shap_value"] > 0
        else "decreases risk"
    )

    print(
        f"{row['feature']:<25} "
        f"Value={row['value']:<8} "
        f"SHAP={row['shap_value']:+.4f} "
        f"({direction})"
    )


# ==========================================
# 10. Top 5 Factors
# ==========================================

top_features = shap_results.head(5)


print("\n======================================")
print("TOP 5 INFLUENTIAL FACTORS")
print("======================================")


for _, row in top_features.iterrows():

    direction = (
        "increases risk"
        if row["shap_value"] > 0
        else "decreases risk"
    )

    print(
        f"- {row['feature']}: "
        f"{direction} "
        f"({row['shap_value']:+.4f})"
    )


# ==========================================
# 11. Final Message
# ==========================================

print("\n======================================")
print("SHAP EXPLANATION COMPLETED")
print("======================================")

print(
    "\nSHAP explains how each feature "
    "contributed to this individual prediction."
)