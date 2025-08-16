import { Button } from "@/components/ui/button";
import heroImage from "@/assets/hero-satellite-bg.jpg";

interface HeroSectionProps {
  onCtaClick: () => void;
}

const HeroSection = ({ onCtaClick }: HeroSectionProps) => {
  return (
    <section className="relative min-h-screen flex items-center justify-center overflow-hidden pt-20">
      {/* Background Image with Overlay */}
      <div className="absolute inset-0">
        <img 
          src={heroImage} 
          alt="Satellite view of Earth" 
          className="w-full h-full object-cover"
        />
        <div className="absolute inset-0 bg-gradient-hero" />
      </div>
      
      {/* Content */}
      <div className="relative z-10 text-center max-w-4xl mx-auto px-6">
        <h1 className="text-5xl md:text-7xl font-bold mb-6 text-white animate-fade-in">
          Real-Time Deforestation Alerts, Powered by AI
        </h1>
        
        <p className="text-xl md:text-2xl text-white/80 mb-12 max-w-2xl mx-auto animate-slide-up">
          Pick any country. See forest loss in the last 5–10 days.
        </p>
        
        <Button 
          onClick={() => window.location.href = 'dashboard/index.html'}
          size="lg"
          className="text-lg px-8 py-6 bg-primary text-primary-foreground hover:bg-primary/90 transition-all duration-300 animate-scale-in hover:scale-105"
        >
          Try Carbon Eye
        </Button>
      </div>
      
      {/* White Arrow Indicator */}
      <div className="absolute bottom-8 left-1/2 transform -translate-x-1/2 animate-bounce">
        <div className="w-0 h-0 border-l-4 border-r-4 border-t-8 border-transparent border-t-white" />
      </div>
    </section>
  );
};

export default HeroSection;