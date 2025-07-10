import os
from dotenv import load_dotenv
from typing import Optional

load_dotenv()

class Settings:
    SENTINELHUB_CLIENT_ID: Optional[str] = os.getenv("SENTINELHUB_CLIENT_ID")
    SENTINELHUB_CLIENT_SECRET: Optional[str] = os.getenv("SENTINELHUB_CLIENT_SECRET")
    SENTINELHUB_INSTANCE_ID: Optional[str] = os.getenv("SENTINELHUB_INSTANCE_ID")
    
    # NDVI Thresholds
    NDVI_CHANGE_THRESHOLD: float = float(os.getenv("NDVI_CHANGE_THRESHOLD", "-0.3"))
    MIN_DEFORESTATION_AREA: int = int(os.getenv("MIN_DEFORESTATION_AREA", "100"))
    CONFIDENCE_THRESHOLD: float = float(os.getenv("CONFIDENCE_THRESHOLD", "0.6"))
    
    # API Configuration
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "Carbon Eye API"
    VERSION: str = "1.0.0"

settings = Settings()
