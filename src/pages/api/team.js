// pages/api/team.js (or src/pages/api/team.js depending on your Next.js setup)

export default async function handler(req, res) {
  if (req.method === "GET") {
    try {
      // Debug: Check if GitHub token exists
      if (!process.env.GITHUB_TOKEN) {
        console.error("GITHUB_TOKEN is not set");
        return res.status(500).json({ message: "GitHub token not configured" });
      }
      // Define your team members with GitHub usernames and LinkedIn URLs
      const teamConfig = [
        {
          githubUsername: "GithubAnant",
          linkedinUrl: "https://www.linkedin.com/in/anantsinghal1/"
        },
        {
          githubUsername: "Akshat2474",
          linkedinUrl: "https://www.linkedin.com/in/akshat-singh-48a03b312/"
        },
        {
          githubUsername: "ABHAY-SINGH-CODER",
          linkedinUrl: "https://www.linkedin.com/in/abhaydilipsingh/"
        },
        {
          githubUsername: "Amaan3073",
          linkedinUrl: "https://www.linkedin.com/in/amaan-ali-768b32322/"
        }
      ];

      // Fetch data for each team member from GitHub API
      const teamPromises = teamConfig.map(async (member) => {
        try {
          console.log(`Fetching data for ${member.githubUsername}...`);
          
          const response = await fetch(`https://api.github.com/users/${member.githubUsername}`, {
            headers: {
              'Authorization': `Bearer ${process.env.GITHUB_TOKEN}`,
              'Accept': 'application/vnd.github.v3+json',
              'User-Agent': 'YourApp/1.0'
            },
            timeout: 10000 // 10 second timeout
          });

          if (!response.ok) {
            console.error(`GitHub API error for ${member.githubUsername}:`, {
              status: response.status,
              statusText: response.statusText,
              url: response.url
            });
            
            // Return fallback data instead of null
            return {
              name: member.githubUsername,
              login: member.githubUsername,
              avatar_url: `https://github.com/${member.githubUsername}.png`,
              githubUrl: `https://github.com/${member.githubUsername}`,
              linkedinUrl: member.linkedinUrl
            };
          }

          const userData = await response.json();
          console.log(`Successfully fetched data for ${member.githubUsername}`);
          
          return {
            name: userData.name || userData.login,
            login: userData.login,
            avatar_url: userData.avatar_url,
            githubUrl: userData.html_url,
            linkedinUrl: member.linkedinUrl
          };
        } catch (fetchError) {
          console.error(`Network error fetching ${member.githubUsername}:`, fetchError.message);
          
          // Return fallback data on any error
          return {
            name: member.githubUsername,
            login: member.githubUsername,
            avatar_url: `https://github.com/${member.githubUsername}.png`,
            githubUrl: `https://github.com/${member.githubUsername}`,
            linkedinUrl: member.linkedinUrl
          };
        }
      });

      // Wait for all API calls to complete
      const teamMembers = await Promise.all(teamPromises);
      
      // All members should have data now (either from GitHub or fallback)
      console.log(`Successfully processed ${teamMembers.length} team members`);
      res.status(200).json(teamMembers);
    } catch (error) {
      console.error("Error fetching team data:", error);
      res.status(500).json({ 
        message: "Failed to fetch team data",
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  } else {
    res.setHeader('Allow', ['GET']);
    res.status(405).json({ message: `Method ${req.method} not allowed` });
  }
}