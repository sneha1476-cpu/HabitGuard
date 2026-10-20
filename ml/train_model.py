import os
import pandas as pd
import joblib

from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier

from sklearn.metrics import (
    accuracy_score,
    classification_report,
    confusion_matrix,
    precision_score,
    recall_score,
    f1_score
)


# ==========================================
# 1. Load Dataset
# ==========================================

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

dataset_path = os.path.join(
    BASE_DIR,
    "dataset",
    "habitguard_dataset.csv"
)

df = pd.read_csv(dataset_path)

print("======================================")
print("HABITGUARD ML MODEL EVALUATION")
print("======================================")

print("\nDataset loaded successfully!")
print("Total records:", len(df))


# ==========================================
# 2. Separate Features and Target
# ==========================================

X = df.drop("risk_level", axis=1)

y = df["risk_level"]

print("\nFeatures used for training:")
for feature in X.columns:
    print("-", feature)


# ==========================================
# 3. Split Dataset
# ==========================================

X_train, X_test, y_train, y_test = train_test_split(
    X,
    y,
    test_size=0.20,
    random_state=42,
    stratify=y
)

print("\n======================================")
print("DATASET SPLIT")
print("======================================")

print("Training records:", len(X_train))
print("Testing records :", len(X_test))


# ==========================================
# 4. Create Random Forest Model
# ==========================================

model = RandomForestClassifier(
    n_estimators=200,
    random_state=42,
    max_depth=12
)


# ==========================================
# 5. Train Model
# ==========================================

print("\n======================================")
print("MODEL TRAINING")
print("======================================")

print("Training Random Forest model...")

model.fit(X_train, y_train)

print("Model training completed!")


# ==========================================
# 6. Prediction
# ==========================================

y_pred = model.predict(X_test)


# ==========================================
# 7. Accuracy
# ==========================================

accuracy = accuracy_score(
    y_test,
    y_pred
)


# ==========================================
# 8. Precision
# ==========================================

precision = precision_score(
    y_test,
    y_pred,
    average="weighted",
    zero_division=0
)


# ==========================================
# 9. Recall
# ==========================================

recall = recall_score(
    y_test,
    y_pred,
    average="weighted",
    zero_division=0
)


# ==========================================
# 10. F1 Score
# ==========================================

f1 = f1_score(
    y_test,
    y_pred,
    average="weighted",
    zero_division=0
)


# ==========================================
# 11. Model Results
# ==========================================

print("\n======================================")
print("MODEL PERFORMANCE")
print("======================================")

print(f"Accuracy  : {accuracy * 100:.2f}%")
print(f"Precision : {precision * 100:.2f}%")
print(f"Recall    : {recall * 100:.2f}%")
print(f"F1-Score  : {f1 * 100:.2f}%")


# ==========================================
# 12. Classification Report
# ==========================================

print("\n======================================")
print("CLASSIFICATION REPORT")
print("======================================")

print(
    classification_report(
        y_test,
        y_pred,
        zero_division=0
    )
)


# ==========================================
# 13. Confusion Matrix
# ==========================================

labels = [
    "LOW",
    "MODERATE",
    "HIGH",
    "CRITICAL"
]

cm = confusion_matrix(
    y_test,
    y_pred,
    labels=labels
)

confusion_df = pd.DataFrame(
    cm,
    index=labels,
    columns=labels
)

print("\n======================================")
print("CONFUSION MATRIX")
print("======================================")

print("Rows    = Actual")
print("Columns = Predicted\n")

print(confusion_df)


# ==========================================
# 14. Feature Importance
# ==========================================

feature_importance = pd.DataFrame({
    "feature": X.columns,
    "importance": model.feature_importances_
})

feature_importance = feature_importance.sort_values(
    by="importance",
    ascending=False
)

print("\n======================================")
print("FEATURE IMPORTANCE")
print("======================================")

for _, row in feature_importance.iterrows():

    print(
        f"{row['feature']:<25} "
        f"{row['importance'] * 100:.2f}%"
    )


# ==========================================
# 15. Save Trained Model
# ==========================================

model_path = os.path.join(
    BASE_DIR,
    "habitguard_model.pkl"
)

joblib.dump(
    model,
    model_path
)

print("\n======================================")
print("MODEL SAVED SUCCESSFULLY!")
print("======================================")

print("Saved to:")
print(model_path)

print("\n======================================")
print("EVALUATION COMPLETED")
print("======================================")