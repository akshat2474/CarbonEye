import satelliteIcon from "@/assets/satellite-icon.png";
import aiIcon from "@/assets/ai-icon.png";
import alertIcon from "@/assets/alert-icon.png";

const steps = [
  {
    icon: satelliteIcon,
    title: "Fetch Latest Satellite Tiles",
    description: "Continuously monitor global forest coverage using high-resolution satellite imagery updated every 5-10 days."
  },
  {
    icon: aiIcon,
    title: "Analyze via Change-Detection AI",
    description: "Advanced machine learning algorithms detect even subtle changes in forest cover with MRV-grade accuracy."
  },
  {
    icon: alertIcon,
    title: "Flag Unusual Tree-Cover Loss",
    description: "Instant alerts for significant deforestation events with precise geo-location and impact assessment."
  }
];

const HowItWorksSection = () => {
  return (
    <section className="py-20 px-6 bg-secondary/20">
      <div className="max-w-6xl mx-auto">
        <div className="text-center mb-16 animate-fade-in">
          <h2 className="text-4xl md:text-5xl font-bold mb-6">
            How It Works
          </h2>
          <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
            Three simple steps to monitor global deforestation in real-time
          </p>
        </div>
        
        <div className="grid md:grid-cols-3 gap-8">
          {steps.map((step, index) => (
            <div 
              key={index} 
              className="text-center group animate-slide-up"
              style={{ animationDelay: `${index * 0.2}s` }}
            >
              <div className="w-24 h-24 mx-auto mb-6 p-4 bg-gradient-card rounded-2xl group-hover:shadow-glow transition-all duration-300 hover:scale-110">
                <img 
                  src={step.icon} 
                  alt={step.title}
                  className="w-full h-full object-contain"
                />
              </div>
              
              <h3 className="text-xl font-semibold mb-4">
                {step.title}
              </h3>
              
              <p className="text-muted-foreground leading-relaxed">
                {step.description}
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};

export default HowItWorksSection;