import { useState } from "react";
import Navbar from "@/components/Navbar";
import HeroSection from "@/components/HeroSection";
import HowItWorksSection from "@/components/HowItWorksSection";
import KeyFeaturesSection from "@/components/KeyFeaturesSection";
import TeamSection from "@/components/TeamSection";
import FinalCtaSection from "@/components/FinalCtaSection";
import Footer from "@/components/Footer";
import SignupModal from "@/components/SignupModal";

const Index = () => {
  const [isSignupOpen, setIsSignupOpen] = useState(false);

  const scrollToSection = (sectionId: string) => {
    const element = document.getElementById(sectionId);
    if (element) {
      element.scrollIntoView({ behavior: 'smooth' });
    }
  };


  return (
    <div className="min-h-screen bg-background text-foreground">
      <Navbar onNavigate={scrollToSection} />
      
      <HeroSection onCtaClick={() => setIsSignupOpen(true)} />
      
      <div id="how-it-works" data-section="how-it-works">
        <HowItWorksSection />
      </div>
      
      <div id="features">
        <KeyFeaturesSection />
      </div>
      
      <div id="team">
        <TeamSection />
      </div>
      
      <div id="dashboard">
        <FinalCtaSection 
          onGetStarted={() => window.location.href = 'dashboard/index.html'}
          onWatchDemo={() => setIsSignupOpen(true)}
        />
      </div>
      
      <Footer />
      
      <SignupModal 
        isOpen={isSignupOpen} 
        onClose={() => setIsSignupOpen(false)} 
      />
    </div>
  );
};

export default Index;
