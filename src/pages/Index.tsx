import { useState } from "react";
import HeroSection from "@/components/HeroSection";
import CountrySelector from "@/components/CountrySelector";
import HowItWorksSection from "@/components/HowItWorksSection";
import LiveMapDemo from "@/components/LiveMapDemo";
import KeyFeaturesSection from "@/components/KeyFeaturesSection";
import TechStackSection from "@/components/TechStackSection";
import TestimonialsSection from "@/components/TestimonialsSection";
import PricingSection from "@/components/PricingSection";
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

  const handleCountrySelect = (country: string) => {
    // Scroll to the next section after country selection
    setTimeout(() => {
      const element = document.querySelector('[data-section="how-it-works"]');
      if (element) {
        element.scrollIntoView({ behavior: 'smooth' });
      }
    }, 500);
  };

  return (
    <div className="min-h-screen bg-background text-foreground">
      <HeroSection onCtaClick={() => scrollToSection('country-selector')} />
      
      <CountrySelector onCountrySelect={handleCountrySelect} />
      
      <div data-section="how-it-works">
        <HowItWorksSection />
      </div>
      
      <LiveMapDemo />
      
      <KeyFeaturesSection />
      
      <TechStackSection />
      
      <TestimonialsSection />
      
      <PricingSection onGetStarted={() => setIsSignupOpen(true)} />
      
      <FinalCtaSection 
        onGetStarted={() => setIsSignupOpen(true)}
        onRequestDemo={() => setIsSignupOpen(true)}
      />
      
      <Footer />
      
      <SignupModal 
        isOpen={isSignupOpen} 
        onClose={() => setIsSignupOpen(false)} 
      />
    </div>
  );
};

export default Index;
