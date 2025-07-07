import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Play, Pause } from "lucide-react";

const LiveMapDemo = () => {
  const [isPlaying, setIsPlaying] = useState(false);

  return (
    <section className="py-20 px-6">
      <div className="max-w-6xl mx-auto">
        <div className="text-center mb-12">
          <h2 className="text-4xl md:text-5xl font-bold mb-6">
            Live Deforestation Heatmap
          </h2>
          <p className="text-xl text-muted-foreground">
            Interactive visualization of recent forest loss alerts
          </p>
        </div>
        
        <div className="relative bg-card rounded-2xl p-8 border border-border shadow-card">
          {/* Map Placeholder */}
          <div className="aspect-video bg-gradient-to-br from-secondary/40 to-secondary/60 rounded-xl mb-6 relative overflow-hidden">
            <div className="absolute inset-0 flex items-center justify-center">
              <div className="text-center">
                <div className="w-16 h-16 bg-primary/20 rounded-full flex items-center justify-center mx-auto mb-4">
                  <div className="w-8 h-8 bg-primary rounded-full animate-pulse" />
                </div>
                <p className="text-muted-foreground">
                  Interactive map would render here
                </p>
              </div>
            </div>
            
            {/* Mock Alert Points */}
            <div className="absolute top-1/4 left-1/3 w-3 h-3 bg-destructive rounded-full animate-pulse shadow-glow" />
            <div className="absolute top-2/3 right-1/4 w-2 h-2 bg-destructive rounded-full animate-pulse shadow-glow" />
            <div className="absolute bottom-1/3 left-1/2 w-4 h-4 bg-destructive rounded-full animate-pulse shadow-glow" />
          </div>
          
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-4">
              <Button
                onClick={() => setIsPlaying(!isPlaying)}
                variant="outline"
                size="sm"
                className="flex items-center space-x-2"
              >
                {isPlaying ? <Pause className="w-4 h-4" /> : <Play className="w-4 h-4" />}
                <span>{isPlaying ? "Pause" : "Play"} Time-lapse</span>
              </Button>
              
              <span className="text-muted-foreground text-sm">
                Last 10 days of alerts
              </span>
            </div>
            
            <div className="text-sm text-muted-foreground">
              Hover for detailed information
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default LiveMapDemo;