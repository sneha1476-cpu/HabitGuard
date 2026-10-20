import pandas as pd
import random
import os

random.seed(42)

data = []

for _ in range(2000):

    # Total screen time: 30 minutes to 10 hours
    total_screen_time = random.randint(30, 600)

    # Generate category usage independently
    social_media_time = random.randint(
        0, min(250, total_screen_time)
    )

    entertainment_time = random.randint(
        0, min(200, total_screen_time)
    )

    communication_time = random.randint(
        0, min(120, total_screen_time)
    )

    gaming_time = random.randint(
        0, min(180, total_screen_time)
    )

    productivity_time = random.randint(
        0, min(150, total_screen_time)
    )

    number_of_apps = random.randint(2, 20)

    number_of_sessions = random.randint(3, 80)

    late_night_usage = random.randint(0, 180)

    most_used_app_time = random.randint(
        5, min(240, total_screen_time)
    )

    # -----------------------------
    # Calculate Risk Score
    # -----------------------------

    score = 0

    # Total screen time
    if total_screen_time >= 360:
        score += 3
    elif total_screen_time >= 240:
        score += 2
    elif total_screen_time >= 120:
        score += 1

    # Social media
    if social_media_time >= 180:
        score += 2
    elif social_media_time >= 90:
        score += 1

    # Entertainment
    if entertainment_time >= 180:
        score += 2
    elif entertainment_time >= 90:
        score += 1

    # Gaming
    if gaming_time >= 120:
        score += 2
    elif gaming_time >= 60:
        score += 1

    # Late night usage
    if late_night_usage >= 120:
        score += 2
    elif late_night_usage >= 60:
        score += 1

    # Number of sessions
    if number_of_sessions >= 50:
        score += 2
    elif number_of_sessions >= 25:
        score += 1

    # Most used app time
    if most_used_app_time >= 180:
        score += 2
    elif most_used_app_time >= 90:
        score += 1

    # -----------------------------
    # Convert Score to Risk Level
    # -----------------------------

    if score <= 2:
        risk_level = "LOW"

    elif score <= 5:
        risk_level = "MODERATE"

    elif score <= 8:
        risk_level = "HIGH"

    else:
        risk_level = "CRITICAL"

    # Add record
    data.append([
        total_screen_time,
        social_media_time,
        entertainment_time,
        communication_time,
        gaming_time,
        productivity_time,
        number_of_apps,
        number_of_sessions,
        late_night_usage,
        most_used_app_time,
        risk_level
    ])


# -----------------------------
# Create DataFrame
# -----------------------------

columns = [
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
    "risk_level"
]

df = pd.DataFrame(
    data,
    columns=columns
)


# -----------------------------
# Create Dataset Folder
# -----------------------------

os.makedirs("ml/dataset", exist_ok=True)


# -----------------------------
# Save CSV
# -----------------------------

output_path = "ml/dataset/habitguard_dataset.csv"

df.to_csv(
    output_path,
    index=False
)


# -----------------------------
# Print Result
# -----------------------------

print("======================================")
print("HabitGuard Dataset Created!")
print("======================================")

print(f"Total records: {len(df)}")

print("\nRisk distribution:")
print(df["risk_level"].value_counts())

print("\nSaved to:")
print(output_path)