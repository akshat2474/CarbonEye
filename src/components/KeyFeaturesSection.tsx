import { Shield, FileText, Bell, BarChart3 } from "lucide-react";

const features = [
  {
    icon: Shield,
    title: "Real Time Tracking",
    description: "Based on super recent satellite image data for the most current forest monitoring available."
  },
  {
    icon: FileText,
    title: "Drill-Down Reports",
    description: "Comprehensive PDF exports with precise geo-tags, timestamps, and impact analysis."
  },
  {
    icon: Bell,
    title: "Alerts & Notifications",
    description: "Real-time email and push notifications for critical deforestation events."
  },
  {
    icon: BarChart3,
    title: "Minimalist Dashboard",
    description: "Clean, zero-fluff interface focused on actionable insights and data clarity."
  }
];

const KeyFeaturesSection = () => {
  return (
    <section className="py-20 px-6 bg-secondary/10">
      <div className="max-w-6xl mx-auto">
        <div className="text-center mb-16 animate-fade-in">
          <h2 className="text-4xl md:text-5xl font-bold mb-6">
            Key Features
          </h2>
          <p className="text-xl text-muted-foreground max-w-3xl mx-auto">
            Professional-grade tools for environmental monitoring and compliance
          </p>
        </div>
        
        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
          {features.map((feature, index) => (
            <div 
              key={index} 
              className="bg-card p-6 rounded-xl border border-border hover:shadow-card transition-all duration-300 animate-scale-in hover:scale-105"
              style={{ animationDelay: `${index * 0.1}s` }}
            >
              <div className="w-12 h-12 bg-gradient-primary rounded-lg flex items-center justify-center mb-4">
                <feature.icon className="w-6 h-6 text-primary-foreground" />
              </div>
              
              <h3 className="text-lg font-semibold mb-3">
                {feature.title}
              </h3>
              
              <p className="text-muted-foreground text-sm leading-relaxed">
                {feature.description}
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};

export default KeyFeaturesSection;