// src/components/TeamSection.tsx

import { useState, useEffect } from "react";
import { Github, Linkedin } from "lucide-react";

interface TeamMember {
  name: string;
  role?: string; // Optional role field
  login: string;
  avatar_url: string;
  githubUrl: string;
  linkedinUrl: string;
}

const TeamSection = () => {
  const [teamMembers, setTeamMembers] = useState<TeamMember[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchTeamMembers = async () => {
      try {
        const res = await fetch("/api/team");
        
        if (!res.ok) {
          throw new Error(`Failed to fetch team data: ${res.status}`);
        }
        
        const data = await res.json();
        setTeamMembers(data);
      } catch (error) {
        console.error("Error fetching team members:", error);
        setError(error instanceof Error ? error.message : "Failed to fetch team data");
      } finally {
        setLoading(false);
      }
    };

    fetchTeamMembers();
  }, []);

  if (error) {
    return (
      <section id="team" className="py-20 px-6 bg-secondary">
        <div className="max-w-6xl mx-auto text-center">
          <h2 className="text-4xl font-bold mb-6 bg-gradient-primary bg-clip-text text-transparent">
            Meet The Team
          </h2>
          <p className="text-red-500">Failed to load team data. Please try again later.</p>
        </div>
      </section>
    );
  }

  return (
    <section id="team" className="py-20 px-6 bg-secondary animate-fade-in">
      <div className="max-w-6xl mx-auto">
        <div className="text-center mb-16">
          <h2 className="text-4xl font-bold mb-6 bg-gradient-primary bg-clip-text text-transparent">
            Meet The Team
          </h2>
          <p className="text-xl text-muted-foreground max-w-3xl mx-auto">
            The innovators behind Carbon Eye&apos;s AI-powered deforestation monitoring technology
          </p>
        </div>

        {loading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
            {[...Array(4)].map((_, index) => (
              <div key={index} className="text-center animate-pulse">
                <div className="w-32 h-32 bg-muted rounded-full mx-auto mb-4"></div>
                <div className="h-6 bg-muted rounded w-24 mx-auto mb-2"></div>
                <div className="h-4 bg-muted rounded w-20 mx-auto mb-4"></div>
                <div className="flex justify-center gap-2">
                  <div className="w-6 h-6 bg-muted rounded"></div>
                  <div className="w-6 h-6 bg-muted rounded"></div>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
            {teamMembers.map((member, index) => (
              <div
                key={member.login}
                className="text-center group hover-scale animate-fade-in"
                style={{ animationDelay: `${index * 0.1}s` }}
              >
                <div className="relative mb-6">
                  <img
                    src={member.avatar_url}
                    alt={member.name}
                    className="w-32 h-32 rounded-full mx-auto object-cover border-4 border-primary/20 group-hover:border-primary/40 transition-all duration-300"
                    onError={(e) => {
                      // Fallback if image fails to load
                      e.currentTarget.src = `https://github.com/${member.login}.png`;
                    }}
                  />
                  <div className="absolute inset-0 rounded-full bg-primary/10 opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
                </div>

                <h3 className="text-xl font-semibold text-foreground mb-2 group-hover:text-primary transition-colors duration-300">
                  {member.name}
                </h3>

                {member.role && (
                  <p className="text-sm text-muted-foreground mb-4">
                    {member.role}
                  </p>
                )}

                <div className="flex justify-center gap-3">
                  <a
                    href={member.githubUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-muted-foreground hover:text-primary transition-all duration-300 hover:scale-110"
                    aria-label={`${member.name}'s GitHub profile`}
                  >
                    <Github className="w-6 h-6" />
                  </a>
                  <a
                    href={member.linkedinUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-muted-foreground hover:text-primary transition-all duration-300 hover:scale-110"
                    aria-label={`${member.name}'s LinkedIn profile`}
                  >
                    <Linkedin className="w-6 h-6" />
                  </a>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </section>
  );
};

export default TeamSection;