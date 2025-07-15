### CarbonEye Backend Architecture

```mermaid
graph TD
    %% -- Define Styles --
    classDef user fill:#08427b,stroke:#002a52,stroke-width:2px,color:white
    classDef service fill:#1168bd,stroke:#0b4884,stroke-width:2px,color:white
    classDef core_system fill:#4f46e5,stroke:#3730a3,stroke-width:2px,color:white
    classDef external fill:#6b7280,stroke:#4b5563,stroke-width:2px,color:white

    %% -- Define Actors and Systems --
    User["User via Flutter App"]
    class User user

    subgraph "CarbonEye Backend"
        APIGateway["API Gateway (FastAPI)<br>Handles all incoming requests from the app."]
        AnalysisService["Analysis Service<br>Orchestrates the entire deforestation analysis."]
        ImageProcessor["Image Processing & ML<br>Processes NDVI, runs change detection, and assesses severity."]
        NotificationService["Notification Service<br>Sends alerts to users."]
        class APIGateway,AnalysisService,NotificationService service
        class ImageProcessor core_system
    end

    subgraph "External Services"
        SatelliteProvider["Satellite Imagery Provider<br>e.g., Sentinel Hub"]
        EmailProvider["Email Service<br>e.g., SendGrid"]
        class SatelliteProvider,EmailProvider external
    end

    %% -- Define Relationships --
    User -- "API Request" --> APIGateway
    APIGateway -- "Forward to Analysis" --> AnalysisService
    AnalysisService -- "Request Imagery" --> SatelliteProvider
    SatelliteProvider -- "Return Imagery" --> AnalysisService
    AnalysisService -- "Send for Processing" --> ImageProcessor
    ImageProcessor -- "Return Results" --> AnalysisService
    AnalysisService -- "Send to Gateway" --> APIGateway
    APIGateway -- "Deliver to User" --> User
    AnalysisService -- "Trigger Alert" --> NotificationService
    NotificationService -- "Send Email" --> EmailProvider