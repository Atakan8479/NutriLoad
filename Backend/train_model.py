import pandas as pd
import numpy as np
from sklearn.linear_model import LinearRegression
import coremltools as ct

print("🚀 Sentetik veri seti oluşturuluyor...")
# 1. Sentetik Veri Üretimi (Feature Engineering)
# Özellikler: Son antrenman tonajı (recentTonnage), Ortalama Zorluk (avgRPE)
# Hedef: Önerilen Tonaj (recommendedTonnage)
np.random.seed(42)
num_samples = 1000

recent_tonnages = np.random.uniform(5000, 20000, num_samples)
avg_rpes = np.random.uniform(5.0, 10.0, num_samples)

# Kural: RPE yüksekse ve önceki tonaj yüksekse, önerilen tonaj düşer (dinlenme/hafif idman)
recommended_tonnages = recent_tonnages * (1.1 - (avg_rpes / 20.0)) 
# Biraz gürültü (noise) ekleyelim ki model gerçekçi olsun
recommended_tonnages += np.random.normal(0, 500, num_samples)

df = pd.DataFrame({
    'recentTonnage': recent_tonnages,
    'avgRPE': avg_rpes,
    'recommendedTonnage': recommended_tonnages
})

print("🧠 Scikit-Learn Modeli Eğitiliyor...")
# 2. Modeli Eğitme
X = df[['recentTonnage', 'avgRPE']]
y = df['recommendedTonnage']

model = LinearRegression()
model.fit(X, y)

print(f"Model Skoru (R^2): {model.score(X, y):.4f}")

print("🍏 Core ML Formatına Çevriliyor...")
# 3. Modeli Core ML (.mlmodel) Formatına Dönüştürme
# coremltools kullanarak scikit-learn modelini Apple'ın formatına çeviriyoruz
coreml_model = ct.converters.sklearn.convert(
    model,
    input_features=["recentTonnage", "avgRPE"],
    output_feature_names="recommendedTonnage"
)

# Model metadatasını ayarlayalım (Xcode'da şık görünmesi için)
coreml_model.author = "NutriLoad ML Engineering"
coreml_model.license = "MIT"
coreml_model.short_description = "Predicts optimal workout tonnage based on recent fatigue and volume."

# Modeli diske kaydet
model_path = "FatigueRegressor.mlmodel"
coreml_model.save(model_path)
print(f"✅ Model başarıyla kaydedildi: {model_path}")