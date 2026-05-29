from fastapi import FastAPI
from pydantic import BaseModel
from uuid import UUID
from typing import Optional
from datetime import datetime

app = FastAPI(title="NutriLoad Backend API")

# İstemciden (iOS) gelecek veri modelinin şeması
class WorkoutSchema(BaseModel):
    id: UUID
    totalTonnage: float
    date: Optional[datetime] = None

@app.post("/api/v1/sync/workout")
async def sync_workout(workout: WorkoutSchema):
    # Burada asenkron olarak veritabanına (Örn: PostgreSQL) kayıt işlemi yapılır
    print(f"Mobil cihazdan senkronize edilen antrenman:")
    print(f"ID: {workout.id} | Toplam Hacim: {workout.totalTonnage} kg")
    
    # İşlem başarılı olduğunda mobil cihaza syncStatus=1 yapması için onay veriyoruz
    return {"status": "success", "synced_id": workout.id}