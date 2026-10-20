# HabitGuard Architecture

Phone
 -> Android UsageStatsManager
 -> Flutter MethodChannel
 -> Feature Engineering
 -> Risk Engine
 -> Random Forest (current risk)
 -> LSTM (future trend)
 -> Autoencoder (personal anomaly)
 -> Explainable AI
 -> Adaptive Intervention
 -> GenAI Coach
 -> Firebase/FCM guardian alert

The app is intended to use real device usage data during runtime.
Training data for ML/DL is separate from runtime device data.
