import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";

interface CountrySelectorProps {
  onCountrySelect: (country: string) => void;
}

const countries = [
  "Brazil", "Indonesia", "Democratic Republic of Congo", "Peru", "Colombia",
  "Bolivia", "Malaysia", "Mexico", "Cameroon", "Papua New Guinea"
];

const CountrySelector = ({ onCountrySelect }: CountrySelectorProps) => {
  const [selectedCountry, setSelectedCountry] = useState<string>("");

  const handleSelect = (country: string) => {
    setSelectedCountry(country);
    onCountrySelect(country);
  };

  return (
    <section id="country-selector" className="py-20 px-6">
      <div className="max-w-4xl mx-auto text-center">
        <h2 className="text-4xl md:text-5xl font-bold mb-8">
          Choose Your Region
        </h2>
        
        <p className="text-xl text-muted-foreground mb-12">
          Select a country to see real-time deforestation data
        </p>
        
        <div className="max-w-md mx-auto">
          <Select onValueChange={handleSelect}>
            <SelectTrigger className="h-14 text-lg bg-card border-border">
              <SelectValue placeholder="Select a country..." />
            </SelectTrigger>
            <SelectContent>
              {countries.map((country) => (
                <SelectItem key={country} value={country} className="text-lg py-3">
                  {country}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          
          {selectedCountry && (
            <div className="mt-8 p-6 bg-card rounded-lg border border-border">
              <p className="text-muted-foreground mb-4">
                Now viewing deforestation data for:
              </p>
              <h3 className="text-2xl font-semibold text-primary">
                {selectedCountry}
              </h3>
            </div>
          )}
        </div>
      </div>
    </section>
  );
};

export default CountrySelector;