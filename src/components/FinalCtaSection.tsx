import { Button } from "@/components/ui/button";

interface FinalCtaSectionProps {
  onGetStarted: () => void;
  onWatchDemo: () => void;
}

const FinalCtaSection = ({
  onGetStarted,
  onWatchDemo,
}: FinalCtaSectionProps) => {
  return (
    <section className="py-20 px-6 bg-gradient-card">
      <div className="max-w-4xl mx-auto text-center animate-fade-in">
        <h2 className="text-4xl md:text-6xl font-bold mb-6 animate-slide-up">
          Ready to Monitor Global Forests?
        </h2>

        <p className="text-xl text-muted-foreground mb-12 max-w-2xl mx-auto animate-fade-in">
          Join environmental leaders using Carbon Eye for real-time
          deforestation monitoring.
        </p>

        <div className="flex flex-col sm:flex-row gap-4 justify-center animate-scale-in">
          <Button
            onClick={onGetStarted}
            size="lg"
            className="text-lg px-8 py-6 bg-gradient-primary hover:shadow-glow transition-all duration-300 hover:scale-105"
          >
            Get Started
          </Button>

          <Button
            onClick={() =>
              window.open(
                "https://www.youtube.com/watch?v=YOUR_VIDEO_ID",
                "_blank"
              )
            }
            size="lg"
            variant="outline"
            className="text-lg px-8 py-6 border-primary/30 hover:bg-primary/10 hover:scale-105 transition-all duration-300"
          >
            Watch a Demo
          </Button>
        </div>
      </div>
    </section>
  );
};

export default FinalCtaSection;
