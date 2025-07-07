const testimonials = [
  {
    quote: "Carbon Eye cut our false positives by 80% and gave us the audit-ready data we desperately needed.",
    author: "Sarah Chen",
    role: "ESG Director, GreenTech Corp",
    impact: "80% reduction in false positives"
  },
  {
    quote: "Finally, real-time deforestation alerts that actually work. Game-changing for our conservation efforts.",
    author: "Dr. Marcus Rodriguez",
    role: "Senior Analyst, Forest Watch NGO",
    impact: "Real-time accuracy achieved"
  },
  {
    quote: "The MRV-grade data quality gives us confidence in our offset verification process.",
    author: "Lisa Park",
    role: "Carbon Markets Lead, EcoFund",
    impact: "100% audit compliance"
  }
];

const TestimonialsSection = () => {
  return (
    <section className="py-20 px-6 bg-secondary/10">
      <div className="max-w-6xl mx-auto">
        <div className="text-center mb-16">
          <h2 className="text-4xl md:text-5xl font-bold mb-6">
            Trusted by Environmental Leaders
          </h2>
          <p className="text-xl text-muted-foreground">
            See how Carbon Eye transforms forest monitoring workflows
          </p>
        </div>
        
        <div className="grid md:grid-cols-3 gap-8">
          {testimonials.map((testimonial, index) => (
            <div key={index} className="bg-card p-8 rounded-xl border border-border hover:shadow-card transition-all duration-300">
              <div className="mb-6">
                <div className="text-primary text-4xl font-serif">"</div>
                <p className="text-foreground leading-relaxed">
                  {testimonial.quote}
                </p>
              </div>
              
              <div className="border-t border-border pt-4">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="font-semibold text-sm">
                      {testimonial.author}
                    </p>
                    <p className="text-muted-foreground text-sm">
                      {testimonial.role}
                    </p>
                  </div>
                  
                  <div className="text-right">
                    <div className="text-primary font-semibold text-sm">
                      {testimonial.impact}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};

export default TestimonialsSection;