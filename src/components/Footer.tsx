import { Github, Mail, FileText } from "lucide-react";

const Footer = () => {
  return (
    <footer className="bg-secondary py-16 px-6 animate-fade-in">
      <div className="max-w-6xl mx-auto">
        <div className="grid md:grid-cols-2 gap-8 mb-12">
          {/* Brand */}
          <div className="col-span-1">
            <h3 className="text-2xl font-bold mb-4 bg-gradient-primary bg-clip-text text-transparent">
              Carbon Eye
            </h3>
            <p className="text-muted-foreground text-sm leading-relaxed">
              Real-time deforestation monitoring powered by AI
              technology.
            </p>
          </div>

          {/* Resources */}
          <div className="col-span-1">
            <h4 className="font-semibold mb-4">Resources</h4>
            <ul className="space-y-2 text-sm">
              <li>
                <a
                  href="https://github.com/akshat2474/CarbonEye/blob/main/README.md"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-muted-foreground hover:text-primary transition-all duration-300 hover:scale-105"
                >
                  Readme
                </a>
              </li>
              <li>
                <a
                  href="https://github.com/akshat2474/CarbonEye/"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-muted-foreground hover:text-primary transition-all duration-300 hover:scale-105"
                >
                  GitHub
                </a>
              </li>
              <li>
                <a
                  href="mailto:anantsinghal444@gmail.com"
                  className="text-muted-foreground hover:text-primary transition-all duration-300 hover:scale-105"
                >
                  Contact
                </a>
              </li>
            </ul>
          </div>
        </div>

        {/* Bottom */}
        <div className="border-t border-border pt-8 flex flex-col md:flex-row items-center justify-between">
          <p className="text-muted-foreground text-sm mb-4 md:mb-0">
            © 2026 Carbon Eye (formerly Okari). All rights reserved.
          </p>

          <div className="flex items-center space-x-4">
            <a
              href="https://github.com/akshat2474/CarbonEye/"
              className="text-muted-foreground hover:text-primary transition-all duration-300 hover:scale-110"
              target="_blank"
              rel="noopener noreferrer"
            >
              <Github className="w-5 h-5" />
            </a>

            <a
              href="https://github.com/akshat2474/CarbonEye/blob/main/README.md"
              className="text-muted-foreground hover:text-primary transition-all duration-300 hover:scale-110"
              target="_blank"
              rel="noopener noreferrer"
            >
              <FileText className="w-5 h-5" />
            </a>
          </div>
        </div>
      </div>
    </footer>
  );
};

export default Footer;
