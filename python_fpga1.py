# =========================================
# HEART ATTACK RISK PERCEPTRON (8-BIT FPGA)
# =========================================

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

from sklearn.linear_model import Perceptron
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, confusion_matrix, ConfusionMatrixDisplay

# ==========================
# LOAD DATASET
# ==========================
data = pd.read_csv("C:/Users/Dhwanil/Desktop/fpga_2.0/heart_attack_prediction_dataset.csv")

# ==========================
# SPLIT BLOOD PRESSURE
# ==========================
data[['Systolic_BP', 'Diastolic_BP']] = (
    data['Blood Pressure']
    .str.split('/', expand=True)
    .astype(int)
)

# ==========================
# FPGA 8-BIT INTEGER SCALING
# ==========================
def scale_8bit(col):
    return ((col - col.min()) * 255 / (col.max() - col.min())).astype(int)

data['Age_s']   = scale_8bit(data['Age'])
data['Chol_s']  = scale_8bit(data['Cholesterol'])
data['Sys_s']   = scale_8bit(data['Systolic_BP'])
data['Dia_s']   = scale_8bit(data['Diastolic_BP'])
data['HR_s']    = scale_8bit(data['Heart Rate'])
data['BMI_s']   = scale_8bit(data['BMI'])
data['Trig_s']  = scale_8bit(data['Triglycerides'])

# Smoking: binary to 0 / 255
data['Smoke_s'] = data['Smoking'] * 255

# ==========================
# SELECT FPGA FEATURES
# ==========================
X = data[['Age_s', 'Chol_s', 'Sys_s', 'Dia_s',
          'HR_s', 'BMI_s', 'Trig_s', 'Smoke_s']]

y = data['Heart Attack Risk']

# ==========================
# TRAIN TEST SPLIT
# ==========================
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

# ==========================
# TRAIN PERCEPTRON
# ==========================
model = Perceptron(max_iter=1000)
model.fit(X_train, y_train)

# ==========================
# PREDICTION + ACCURACY
# ==========================
y_pred = model.predict(X_test)
accuracy = accuracy_score(y_test, y_pred)

print("\n✅ MODEL ACCURACY =", round(accuracy * 100, 2), "%")

# ==========================
# WEIGHT EXTRACTION
# ==========================
weights = model.coef_[0].astype(int)
bias = int(model.intercept_[0])

print("\n✅ FPGA 8-BIT WEIGHTS")
print("Weights =", weights)
print("Bias =", bias)

# =========================================
# GRAPHICAL REPRESENTATION
# =========================================

# 1) Histograms of all 8 features
X.hist(figsize=(14, 10))
plt.suptitle("8-Bit Feature Distribution for FPGA")
plt.tight_layout()

# 2) Box Plot
plt.figure(figsize=(12, 6))
X.boxplot()
plt.title("Box Plot of Quantized Heart Features")
plt.ylabel("8-bit Values")
plt.xticks(rotation=30)

# 3) Correlation Matrix
plt.figure(figsize=(10, 8))
plt.imshow(X.corr(), cmap='gray', interpolation='nearest')
plt.colorbar()
plt.xticks(range(len(X.columns)), X.columns, rotation=45)
plt.yticks(range(len(X.columns)), X.columns)
plt.title("Feature Correlation Matrix")

# 4) Confusion Matrix
cm = confusion_matrix(y_test, y_pred)
disp = ConfusionMatrixDisplay(confusion_matrix=cm)
disp.plot(cmap="Greys")
plt.title("Confusion Matrix")

plt.show()
