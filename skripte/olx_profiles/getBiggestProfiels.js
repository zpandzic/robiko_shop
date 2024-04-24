const axios = require("axios");
const fs = require("fs");
const path = require("path");

// Function to fetch profiles for a single letter
async function fetchProfilesForLetter(letter) {
  let page = 1;
  let profiles = [];
  let lastPage = 1;

  // Fetch profiles while there are pages to check
  do {
    const response = await axios.get(
      `https://olx.ba/api/shops/letter/${letter}?page=${page}`
    );
    profiles.push(...response.data.data); // Add current page's profiles
    lastPage = response.data.last_page;
    page++;
  } while (page <= lastPage);

  return profiles;
}

// Main function to fetch and sort profiles
async function fetchAndSortProfiles() {
  const letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".split("");
  let allProfiles = [];

  for (const letter of letters) {
    const profilesForLetter = await fetchProfilesForLetter(letter);
    allProfiles.push(...profilesForLetter);
  }

  // Sort profiles by listings in descending order
  let sortedProfiles = allProfiles.sort(
    (a, b) => parseInt(b.listings) - parseInt(a.listings)
  );

  sortedProfiles = sortedProfiles.map((profile, index) => {
    return {
      rank: index + 1,
      id: profile.id,
      username: profile.username,
      listings: profile.listings,
    };
  });

  // Save to a JSON file
  fs.writeFile(
    path.join(__dirname, "sortedProfiles.json"),
    JSON.stringify(sortedProfiles, null, 2),
    (err) => {
      if (err) {
        console.error("Failed to save the profiles to a file:", err);
      } else {
        console.log("Profiles saved to sortedProfiles.json successfully.");
      }
    }
  );
}

fetchAndSortProfiles().then(() =>
  console.log("Profiles fetched and sorted successfully.")
);
