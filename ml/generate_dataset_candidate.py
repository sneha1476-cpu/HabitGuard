import os
import random
import pandas as pd

random.seed(42)
rows = []

for _ in range(2000):
    total = random.randint(30, 600)

    # Categories are mutually exclusive and their sum cannot exceed total.
    remaining = total
    categories = []

    for cap in (250, 200, 120, 180):
        value = random.randint(0, min(cap, remaining))
        categories.append(value)
        remaining -= value

    # Productivity uses some of the remaining time.
    productivity = random.randint(0, min(150, remaining))
    remaining -= productivity

    social, entertainment, communication, gaming = categories

    number_of_apps = random.randint(2, 20)
    number_of_sessions = random.randint(3, 80)
    late_night = random.randint(0, min(180, total))
    most_used_app = random.randint(5, min(240, total))

    score = 0

    if total >= 360:
        score += 3
    elif total >= 240:
        score += 2
    elif total >= 120:
        score += 1

    if social >= 180:
        score += 2
    elif social >= 90:
        score += 1

    if entertainment >= 180:
        score += 2
    elif entertainment >= 90:
        score += 1

    if gaming >= 120:
        score += 2
    elif gaming >= 60:
        score += 1

    if late_night >= 120:
        score += 2
    elif late_night >= 60:
        score += 1

    if number_of_sessions >= 50:
        score += 2
    elif number_of_sessions >= 25:
        score += 1

    if most_used_app >= 180:
        score += 2
    elif most_used_app >= 90:
        score += 1

    if score <= 2:
        risk = "LOW"
    elif score <= 5:
        risk = "MODERATE"
    elif score <= 8:
        risk = "HIGH"
    else:
        risk = "CRITICAL"

    rows.append([
        total, social, entertainment, communication, gaming,
        productivity, number_of_apps, number_of_sessions,
        late_night, most_used_app, risk
    ])

columns = [
    "total_screen_time", "social_media_time", "entertainment_time",
    "communication_time", "gaming_time", "productivity_time",
    "number_of_apps", "number_of_sessions", "late_night_usage",
    "most_used_app_time", "risk_level"
]

df = pd.DataFrame(rows, columns=columns)

os.makedirs("ml/dataset", exist_ok=True)
output_path = "ml/dataset/habitguard_dataset_candidate.csv"
df.to_csv(output_path, index=False)

print(f"Candidate dataset saved: {output_path}")
print(f"Rows: {len(df)}")
print("Risk distribution:")
print(df["risk_level"].value_counts().to_string())
