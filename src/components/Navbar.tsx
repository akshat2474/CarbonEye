import { TreePine } from "lucide-react";
import { Button } from "@/components/ui/button";

interface NavbarProps {
  onNavigate: (section: string) => void;
}

const Navbar = ({ onNavigate }: NavbarProps) => {
  return (
    <nav className="fixed top-0 left-0 right-0 z-50 bg-background/95 backdrop-blur-sm border-b border-border">
      <div className="max-w-7xl mx-auto px-6 py-4">
        <div className="flex items-center justify-between">
          {/* Logo and Company Name */}
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 bg-primary rounded-full flex items-center justify-center">
              <TreePine className="w-5 h-5 text-primary-foreground" />
            </div>
            <span className="text-xl font-bold text-foreground">Carbon Eye</span>
          </div>
          
          {/* Navigation Links */}
          <div className="flex items-center gap-8">
            <button 
              onClick={() => onNavigate('how-it-works')}
              className="text-foreground hover:text-primary transition-colors"
            >
              How it Works
            </button>
            <button 
              onClick={() => onNavigate('features')}
              className="text-foreground hover:text-primary transition-colors"
            >
              Features
            </button>
            <button 
              onClick={() => onNavigate('team')}
              className="text-foreground hover:text-primary transition-colors"
            >
              The Team
            </button>
            <Button 
              onClick={() => window.location.href = '/dashboard/index.html'}
              variant="default"
              className="bg-primary text-primary-foreground hover:bg-primary/90"
            >
              Dashboard
            </Button>
          </div>
        </div>
      </div>
    </nav>
  );
};

export default Navbar;