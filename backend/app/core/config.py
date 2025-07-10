import os
from dotenv import load_dotenv

load_dotenv()

class Settings:
    SENTINELHUB_CLIENT_ID = os.getenv("SENTINELHUB_CLIENT_ID")
    SENTINELHUB_CLIENT_SECRET = os.getenv("SENTINELHUB_CLIENT_SECRET")
    SENTINELHUB_INSTANCE_ID = os.getenv("SENTINELHUB_INSTANCE_ID")
    
    # NDVI Thresholds
    NDVI_CHANGE_THRESHOLD = -0.3  # Significant vegetation loss
    MIN_DEFORESTATION_AREA = 100  # Minimum area in pixels
    CONFIDENCE_THRESHOLD = 0.6    # Minimum confidence for alerts

settings = Settings()
