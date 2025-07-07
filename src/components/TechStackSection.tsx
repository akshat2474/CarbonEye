import { Smartphone, Database, Brain, Github } from "lucide-react";

const techStack = [
  {
    icon: Smartphone,
    title: "Flutter Web",
    description: "Cross-platform frontend with optional mobile support"
  },
  {
    icon: Database,
    title: "Firebase Functions",
    description: "Scalable serverless backend infrastructure"
  },
  {
    icon: Brain,
    title: "In-browser AI",
    description: "Client-side change detection with @xenova/transformers"
  },
  {
    icon: Github,
    title: "Modern Hosting",
    description: "Deployed on GitHub Pages & Vercel for reliability"
  }
];

const TechStackSection = () => {
  return (
    <section className="py-20 px-6">
      <div className="max-w-6xl mx-auto">
        <div className="text-center mb-16">
          <h2 className="text-4xl md:text-5xl font-bold mb-6">
            Tech & Stack
          </h2>
          <p className="text-xl text-muted-foreground">
            Built with modern, scalable technologies
          </p>
        </div>
        
        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
          {techStack.map((tech, index) => (
            <div key={index} className="text-center p-6 bg-gradient-card rounded-xl border border-border/50 hover:border-primary/30 transition-all duration-300">
              <div className="w-16 h-16 mx-auto mb-4 bg-primary/10 rounded-full flex items-center justify-center">
                <tech.icon className="w-8 h-8 text-primary" />
              </div>
              
              <h3 className="font-semibold mb-2">
                {tech.title}
              </h3>
              
              <p className="text-sm text-muted-foreground">
                {tech.description}
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};

export default TechStackSection;