import { Button } from "@/components/ui/button";

interface FinalCtaSectionProps {
  onGetStarted: () => void;
  onRequestDemo: () => void;
}

const FinalCtaSection = ({ onGetStarted, onRequestDemo }: FinalCtaSectionProps) => {
  return (
    <section className="py-20 px-6 bg-gradient-card">
      <div className="max-w-4xl mx-auto text-center">
        <h2 className="text-4xl md:text-6xl font-bold mb-6">
          Ready to Monitor Global Forests?
        </h2>
        
        <p className="text-xl text-muted-foreground mb-12 max-w-2xl mx-auto">
          Join environmental leaders using Carbon Eye for real-time deforestation monitoring.
        </p>
        
        <div className="flex flex-col sm:flex-row gap-4 justify-center">
          <Button 
            onClick={onGetStarted}
            size="lg"
            className="text-lg px-8 py-6 bg-gradient-primary hover:shadow-glow transition-all duration-300"
          >
            Get Started
          </Button>
          
          <Button 
            onClick={onRequestDemo}
            size="lg"
            variant="outline"
            className="text-lg px-8 py-6 border-primary/30 hover:bg-primary/10"
          >
            Request a Demo
          </Button>
        </div>
      </div>
    </section>
  );
};

export default FinalCtaSection;