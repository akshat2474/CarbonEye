import { Github, Twitter, Linkedin, Mail } from "lucide-react";

const Footer = () => {
  return (
    <footer className="bg-secondary py-16 px-6 animate-fade-in">
      <div className="max-w-6xl mx-auto">
        <div className="grid md:grid-cols-4 gap-8 mb-12">
          {/* Brand */}
          <div className="col-span-1">
            <h3 className="text-2xl font-bold mb-4 bg-gradient-primary bg-clip-text text-transparent">
              Carbon Eye
            </h3>
            <p className="text-muted-foreground text-sm leading-relaxed">
              Real-time deforestation monitoring powered by MRV-grade AI technology.
            </p>
          </div>
          
          {/* Links */}
          <div className="col-span-1">
            <h4 className="font-semibold mb-4">Product</h4>
            <ul className="space-y-2 text-sm">
              <li><a href="#" className="text-muted-foreground hover:text-primary transition-all duration-300 hover:scale-105">About</a></li>
              <li><a href="#" className="text-muted-foreground hover:text-primary transition-all duration-300 hover:scale-105">Features</a></li>
              <li><a href="#" className="text-muted-foreground hover:text-primary transition-all duration-300 hover:scale-105">Pricing</a></li>
              <li><a href="#" className="text-muted-foreground hover:text-primary transition-all duration-300 hover:scale-105">Documentation</a></li>
            </ul>
          </div>
          
          <div className="col-span-1">
            <h4 className="font-semibold mb-4">Resources</h4>
            <ul className="space-y-2 text-sm">
              <li><a href="#" className="text-muted-foreground hover:text-primary transition-all duration-300 hover:scale-105">API Docs</a></li>
              <li><a href="#" className="text-muted-foreground hover:text-primary transition-all duration-300 hover:scale-105">GitHub</a></li>
              <li><a href="#" className="text-muted-foreground hover:text-primary transition-all duration-300 hover:scale-105">Support</a></li>
              <li><a href="#" className="text-muted-foreground hover:text-primary transition-all duration-300 hover:scale-105">Status</a></li>
            </ul>
          </div>
          
          <div className="col-span-1">
            <h4 className="font-semibold mb-4">Legal</h4>
            <ul className="space-y-2 text-sm">
              <li><a href="#" className="text-muted-foreground hover:text-primary transition-all duration-300 hover:scale-105">Privacy Policy</a></li>
              <li><a href="#" className="text-muted-foreground hover:text-primary transition-all duration-300 hover:scale-105">Terms of Service</a></li>
              <li><a href="#" className="text-muted-foreground hover:text-primary transition-all duration-300 hover:scale-105">Contact</a></li>
            </ul>
          </div>
        </div>
        
        {/* Bottom */}
        <div className="border-t border-border pt-8 flex flex-col md:flex-row items-center justify-between">
          <p className="text-muted-foreground text-sm mb-4 md:mb-0">
            © 2024 Carbon Eye (formerly Okari). All rights reserved.
          </p>
          
          <div className="flex items-center space-x-4">
            <a href="#" className="text-muted-foreground hover:text-primary transition-all duration-300 hover:scale-110">
              <Github className="w-5 h-5" />
            </a>
            <a href="#" className="text-muted-foreground hover:text-primary transition-all duration-300 hover:scale-110">
              <Twitter className="w-5 h-5" />
            </a>
            <a href="#" className="text-muted-foreground hover:text-primary transition-all duration-300 hover:scale-110">
              <Linkedin className="w-5 h-5" />
            </a>
            <a href="#" className="text-muted-foreground hover:text-primary transition-all duration-300 hover:scale-110">
              <Mail className="w-5 h-5" />
            </a>
          </div>
        </div>
      </div>
    </footer>
  );
};

export default Footer;