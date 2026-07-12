// Copying parseDevpostDate from event-service.ts
function parseDevpostDate(dateStr) {
  if (!dateStr) return null;
  const parts = dateStr.split("-");
  const targetStr = parts.length > 1 ? parts[1].trim() : dateStr.trim();
  const parsed = Date.parse(targetStr);
  if (!isNaN(parsed)) {
    return new Date(parsed).toISOString();
  }
  const currentYear = new Date().getFullYear();
  const fallbackParsed = Date.parse(`${targetStr}, ${currentYear}`);
  if (!isNaN(fallbackParsed)) {
    return new Date(fallbackParsed).toISOString();
  }
  return null;
}

async function fetchDevpost() {
  try {
    const response = await fetch("https://devpost.com/api/hackathons", {
      headers: {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Accept": "application/json",
      },
    });
    const json = await response.json();
    const items = json.hackathons || [];
    console.log("=== DEVPOST SAMPLES ===");
    for (const hack of items.slice(0, 3)) {
      const dateText = hack.submission_period_dates || "";
      const endDate = dateText ? parseDevpostDate(dateText) : null;
      console.log({
        title: hack.title,
        date: dateText,
        end_date: endDate,
        thumbnail: hack.thumbnail_url
      });
    }
  } catch (e) {
    console.error("Error fetching Devpost:", e);
  }
}

async function fetchDevfolio() {
  try {
    const response = await fetch("https://devfolio.co/hackathons", {
      headers: {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
      },
    });
    const html = await response.text();
    const match = html.match(/<script id="__NEXT_DATA__" type="application\/json">(.*?)<\/script>/);
    const data = JSON.parse(match[1]);
    const queries = data.props?.pageProps?.dehydratedState?.queries || [];
    let openHacks = [];
    let upcomingHacks = [];
    for (const q of queries) {
      const qData = q.state?.data;
      if (qData) {
        if (qData.open_hackathons) openHacks = qData.open_hackathons;
        if (qData.upcoming_hackathons) upcomingHacks = qData.upcoming_hackathons;
      }
    }
    const devfolioHacks = [...openHacks, ...upcomingHacks];
    console.log("=== DEVFOLIO SAMPLES ===");
    for (const hack of devfolioHacks.slice(0, 3)) {
      const startDate = hack.starts_at ? new Date(hack.starts_at) : null;
      const endDateVal = hack.ends_at ? new Date(hack.ends_at) : null;
      let dateText = "";
      if (startDate && endDateVal) {
        dateText = `${startDate.toLocaleDateString("en-US", { month: "short", day: "numeric" })} - ${endDateVal.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })}`;
      } else if (endDateVal) {
        dateText = `Closes ${endDateVal.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })}`;
      }
      let endDate = hack.settings?.reg_ends_at || hack.ends_at || null;
      if (endDate) {
        endDate = new Date(endDate).toISOString();
      }
      console.log({
        title: hack.name,
        date: dateText,
        end_date: endDate,
        cover: hack.settings?.featured_cover_img_v2 || hack.settings?.featured_cover_img
      });
    }
  } catch (e) {
    console.error("Error fetching Devfolio:", e);
  }
}

async function fetchUnstop() {
  try {
    const response = await fetch("https://unstop.com/api/public/opportunity/search-result?opportunity=hackathons&page=1", {
      headers: {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Accept": "application/json",
      },
    });
    const json = await response.json();
    const items = json.data?.data || [];
    console.log("=== UNSTOP SAMPLES ===");
    for (const hack of items.slice(0, 3)) {
      const startDate = hack.regnRequirements?.start_regn_dt ? new Date(hack.regnRequirements.start_regn_dt) : null;
      const endDateVal = hack.end_date ? new Date(hack.end_date) : null;
      let dateText = "";
      if (startDate && endDateVal) {
        dateText = `${startDate.toLocaleDateString("en-US", { month: "short", day: "numeric" })} - ${endDateVal.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })}`;
      } else if (endDateVal) {
        dateText = `Closes ${endDateVal.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })}`;
      }
      let endDate = hack.end_date || null;
      if (endDate) {
        endDate = new Date(endDate).toISOString();
      }
      console.log({
        title: hack.title,
        date: dateText,
        end_date: endDate,
        logo: hack.logoUrl2
      });
    }
  } catch (e) {
    console.error("Error fetching Unstop:", e);
  }
}

async function main() {
  await fetchDevpost();
  await fetchDevfolio();
  await fetchUnstop();
}

main();
