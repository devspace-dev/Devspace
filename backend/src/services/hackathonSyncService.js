import { supabase } from '../config/supabase.js';

// DevSpace only lists hackathons and tech opportunities in India for B.Tech students.
// - Devpost is a global feed with no country data, so it is not synced.
// - Devfolio is India's premier developer hackathon platform; filtered by IST timezone.
// - Unstop is India's premier campus portal; filtered for engineering students and tech internships.
const INDIAN_TIMEZONES = new Set(['Asia/Kolkata', 'Asia/Calcutta']);

export function isIndianDevfolioHackathon(hack) {
  return INDIAN_TIMEZONES.has(hack?.timezone);
}

export function isIndianUnstopOpportunity(opp) {
  // Online events on Unstop (India-focused platform) are Indian-organized / accessible in IST.
  if (opp?.region === 'online') return true;
  if (!opp?.address_with_country_logo?.country) {
    return true;
  }
  return opp?.address_with_country_logo?.country?.name === 'India';
}

export function isIndianUnstopHackathon(hack) {
  return isIndianUnstopOpportunity(hack);
}

const TECH_TITLE_REGEX = /\b(software|developer|frontend|front-end|backend|back-end|full\s*stack|web|android|flutter|ios|mobile|ai|ml|machine\s*learning|deep\s*learning|data\s*(science|analyst|engineer|analytics)|python|java|javascript|react|node|cloud|devops|security|cyber|qa|sde|engineer|embedded|iot|blockchain|web3|solidity|tech)\b/i;

const NON_TECH_TITLE_REGEX = /\b(sales|business\s*development|bde|marketing|content|writer|copywriting|seo|telecaller|calling|counselor|graphic\s*design|video\s*editor|hr|human\s*resource|talent|recruiter|finance|accounting|lawyer|legal|operations|lead\s*generation|campus\s*ambassador)\b/i;

export function isTechBTechInternship(opp) {
  const title = (opp?.title || '').trim();
  if (!title) return false;
  
  // Must match a tech keyword
  if (!TECH_TITLE_REGEX.test(title)) return false;
  
  // Must not match an explicit non-tech role
  if (NON_TECH_TITLE_REGEX.test(title)) return false;

  // If filters are present, check if engineering/undergraduate or open
  const filters = opp?.filters || [];
  if (filters.length > 0) {
    const filterNames = filters.map(f => (f?.name || '').toLowerCase());
    const isEng = filterNames.some(n => 
      n.includes('engineering') || 
      n.includes('undergraduate') || 
      n.includes('fresher') ||
      n.includes('all')
    );
    if (!isEng) {
      return false;
    }
  }

  return true;
}

export function unstopLocationText(opp) {
  if (opp?.region === 'online') return 'Online';
  const addr = opp?.address_with_country_logo;
  const place = [addr?.city, addr?.state].filter(Boolean).join(', ');
  if (place) return place;
  if (opp?.region === 'hybrid') return 'Hybrid';
  return 'In-person';
}

async function fetchDevfolio() {
  const hackathons = [];
  try {
    console.log('Fetching from Devfolio public page...');
    const response = await fetch('https://devfolio.co/hackathons');
    if (!response.ok) {
      throw new Error(`Devfolio page returned status ${response.status}`);
    }
    const html = await response.text();
    const match = html.match(/<script id="__NEXT_DATA__" type="application\/json">(.*?)<\/script>/);
    if (!match) {
      throw new Error('Failed to find __NEXT_DATA__ on Devfolio page');
    }
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
    
    for (const hack of devfolioHacks) {
      const title = hack.name || '';
      const slug = hack.slug || '';
      if (!title || !slug) continue;
      if (!isIndianDevfolioHackathon(hack)) continue;

      const link = `https://${slug}.devfolio.co`;

      let bannerUrl = hack.settings?.featured_cover_img_v2 || hack.settings?.featured_cover_img || '';
      if (!bannerUrl && slug) {
        try {
          const subRes = await fetch(`https://${slug}.devfolio.co/`, {
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            }
          });
          if (subRes.ok) {
            const subHtml = await subRes.text();
            const subMatch = subHtml.match(/<script id="__NEXT_DATA__" type="application\/json">(.*?)<\/script>/);
            if (subMatch) {
              const subData = JSON.parse(subMatch[1]);
              const hackObj = subData.props?.pageProps?.hackathon;
              if (hackObj?.cover_img) {
                bannerUrl = hackObj.cover_img;
              }
            }
          }
        } catch (err) {
          console.error(`Failed to fetch cover image for Devfolio hackathon ${slug}:`, err);
        }
      }

      if (bannerUrl) {
        if (!bannerUrl.startsWith('http://') && !bannerUrl.startsWith('https://')) {
          if (bannerUrl.startsWith('/')) {
            bannerUrl = `https://assets.devfolio.co${bannerUrl}`;
          } else {
            bannerUrl = `https://assets.devfolio.co/${bannerUrl}`;
          }
        }
      }

      const organizer = 'Devfolio';
      const isOnline = hack.is_online === true;
      const locationText = isOnline ? 'Online' : 'In-person';
      
      const themesList = (hack.themes || []).map(t => t.theme?.name || '').filter(Boolean).join(', ');
      const description = `Themes: ${themesList || 'General Hackathon'}. Mode: ${locationText}. Check out this exciting hackathon from Devfolio!`;

      const startDate = hack.starts_at ? new Date(hack.starts_at) : null;
      const endDateVal = hack.ends_at ? new Date(hack.ends_at) : null;
      let dateText = '';
      if (startDate && endDateVal) {
        dateText = `${startDate.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })} - ${endDateVal.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}`;
      } else if (endDateVal) {
        dateText = `Closes ${endDateVal.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}`;
      }

      let endDate = hack.settings?.reg_ends_at || hack.ends_at || null;
      if (endDate) {
        endDate = new Date(endDate).toISOString();
      }

      hackathons.push({
        title,
        link,
        banner_url: bannerUrl,
        organizer,
        date: dateText,
        location: locationText,
        description,
        end_date: endDate,
        type: 'hackathon'
      });
    }
  } catch (e) {
    console.error('Error fetching Devfolio hackathons:', e);
  }
  return hackathons;
}

async function fetchUnstopHackathons(maxPages = 2, perPage = 50) {
  const hackathons = [];
  const seenLinks = new Set();

  for (let page = 1; page <= maxPages; page++) {
    try {
      console.log(`Fetching Unstop hackathons (Page ${page}/${maxPages}, perPage=${perPage})...`);
      const url = `https://unstop.com/api/public/opportunity/search-result?opportunity=hackathons&eligible=engineering-students&per_page=${perPage}&page=${page}`;
      const response = await fetch(url, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'application/json'
        }
      });
      if (!response.ok) {
        console.warn(`Unstop hackathons API returned status ${response.status} for page ${page}`);
        break;
      }
      const json = await response.json();
      const items = json.data?.data || [];
      if (items.length === 0) break;

      for (const hack of items) {
        const title = hack.title?.trim() || '';
        const publicUrl = hack.public_url || '';
        if (!title || !publicUrl) continue;
        if (!isIndianUnstopOpportunity(hack)) continue;

        const link = hack.seo_url || `https://unstop.com/${publicUrl}`;
        if (seenLinks.has(link)) continue;
        seenLinks.add(link);

        const bannerUrl = hack.logoUrl2 || hack.banner_mobile || '';
        const organizer = hack.organisation?.name || 'Unstop';
        const locationText = unstopLocationText(hack);

        let rawDesc = hack.details ? hack.details.replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ').trim() : '';
        if (rawDesc.length > 250) {
          rawDesc = rawDesc.substring(0, 247) + '...';
        }
        const description = rawDesc || `Join ${title} organized by ${organizer} on Unstop!`;

        const startDate = hack.regnRequirements?.start_regn_dt ? new Date(hack.regnRequirements.start_regn_dt) : null;
        const endDateVal = hack.end_date ? new Date(hack.end_date) : null;
        let dateText = '';
        if (startDate && endDateVal) {
          dateText = `${startDate.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })} - ${endDateVal.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}`;
        } else if (endDateVal) {
          dateText = `Closes ${endDateVal.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}`;
        }

        let endDate = hack.end_date || hack.regnRequirements?.end_regn_dt || null;
        if (endDate) {
          endDate = new Date(endDate).toISOString();
        }

        hackathons.push({
          title,
          link,
          banner_url: bannerUrl,
          organizer,
          date: dateText,
          location: locationText,
          description,
          end_date: endDate,
          type: 'hackathon'
        });
      }
    } catch (e) {
      console.error(`Error fetching Unstop hackathons page ${page}:`, e);
      break;
    }
  }

  return hackathons;
}

async function fetchUnstopInternships() {
  const internships = [];
  const seenLinks = new Set();
  const searchTerms = ['developer', 'software'];

  for (const term of searchTerms) {
    for (let page = 1; page <= 2; page++) {
      try {
        console.log(`Fetching Unstop tech internships (term="${term}", page ${page})...`);
        const url = `https://unstop.com/api/public/opportunity/search-result?opportunity=internships&searchTerm=${encodeURIComponent(term)}&per_page=30&page=${page}`;
        const response = await fetch(url, {
          headers: {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'application/json'
          }
        });
        if (!response.ok) {
          console.warn(`Unstop internships API returned ${response.status} for term="${term}", page=${page}`);
          break;
        }
        const json = await response.json();
        const items = json.data?.data || [];
        if (items.length === 0) break;

        for (const item of items) {
          const title = item.title?.trim() || '';
          const publicUrl = item.public_url || '';
          if (!title || !publicUrl) continue;
          if (!isIndianUnstopOpportunity(item)) continue;
          if (!isTechBTechInternship(item)) continue;

          const link = item.seo_url || `https://unstop.com/${publicUrl}`;
          if (seenLinks.has(link)) continue;
          seenLinks.add(link);

          const bannerUrl = item.logoUrl2 || item.banner_mobile || '';
          const organizer = item.organisation?.name || 'Unstop';
          const locationText = unstopLocationText(item);

          let rawDesc = item.details ? item.details.replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ').trim() : '';
          if (rawDesc.length > 250) {
            rawDesc = rawDesc.substring(0, 247) + '...';
          }
          const description = rawDesc || `Apply for ${title} at ${organizer} on Unstop!`;

          const startDate = item.regnRequirements?.start_regn_dt ? new Date(item.regnRequirements.start_regn_dt) : null;
          const endDateVal = item.end_date ? new Date(item.end_date) : null;
          let dateText = '';
          if (startDate && endDateVal) {
            dateText = `${startDate.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })} - ${endDateVal.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}`;
          } else if (endDateVal) {
            dateText = `Closes ${endDateVal.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}`;
          }

          let endDate = item.end_date || item.regnRequirements?.end_regn_dt || null;
          if (endDate) {
            endDate = new Date(endDate).toISOString();
          }

          internships.push({
            title,
            link,
            banner_url: bannerUrl,
            organizer,
            date: dateText,
            location: locationText,
            description,
            end_date: endDate,
            type: 'internship'
          });
        }
      } catch (e) {
        console.error(`Error fetching Unstop internships term="${term}", page=${page}:`, e);
        break;
      }
    }
  }

  return internships;
}

async function upsertEvent(eventData, includeEndDate = true, fallbackType = false) {
  const { link, title } = eventData;
  if (!link || !title) return false;

  const { data: existing, error: checkError } = await supabase
    .from('events')
    .select('id')
    .eq('link', link)
    .maybeSingle();

  if (checkError) {
    console.error(`Error checking event for link ${link}:`, checkError);
    return false;
  }

  const payload = {
    title: eventData.title,
    description: eventData.description,
    banner_url: eventData.banner_url,
    date: eventData.date,
    location: eventData.location,
    organizer: eventData.organizer,
    updated_at: new Date().toISOString()
  };

  if (includeEndDate && eventData.end_date) {
    payload.end_date = eventData.end_date;
  }

  if (existing) {
    const { error: updateError } = await supabase
      .from('events')
      .update(payload)
      .eq('id', existing.id);

    if (updateError) {
      if (includeEndDate && (updateError.code === 'PGRST204' || updateError.message?.includes('end_date'))) {
        console.warn(`Warning: end_date column not found in schema. Retrying update without end_date...`);
        return await upsertEvent(eventData, false, fallbackType);
      }
      console.error(`Error updating event ${existing.id}:`, updateError);
      return false;
    }
    return 'updated';
  } else {
    // If fallbackType is true, use 'event' instead of 'internship' if DB constraint hasn't been migrated yet
    const typeToUse = fallbackType ? 'event' : (eventData.type || 'hackathon');
    const insertPayload = {
      ...payload,
      required_aura: 0,
      link: eventData.link,
      type: typeToUse,
      is_active: true
    };
    delete insertPayload.updated_at;

    const { error: insertError } = await supabase
      .from('events')
      .insert(insertPayload);

    if (insertError) {
      if (includeEndDate && (insertError.code === 'PGRST204' || insertError.message?.includes('end_date'))) {
        console.warn(`Warning: end_date column not found in schema. Retrying insert without end_date...`);
        return await upsertEvent(eventData, false, fallbackType);
      }
      // If check constraint fails on type 'internship', retry with fallback 'event'
      if (!fallbackType && (insertError.code === '23514' || insertError.message?.includes('events_type_check'))) {
        console.warn(`Warning: events_type_check constraint does not allow "${eventData.type}". Retrying with type="event"...`);
        return await upsertEvent(eventData, includeEndDate, true);
      }
      console.error(`Error inserting event "${title}":`, insertError);
      return false;
    }
    return 'inserted';
  }
}

async function cleanExpiredEvents() {
  console.log('Cleaning up expired events and internships...');
  try {
    const { data: expiredEvents, error: expiredError } = await supabase
      .from('events')
      .select('id')
      .in('type', ['hackathon', 'internship', 'event'])
      .lt('end_date', new Date().toISOString());

    if (expiredError) {
      if (expiredError.code === 'PGRST204' || expiredError.message?.includes('end_date')) {
        console.warn('Skipping cleanup: end_date column does not exist in events table yet.');
        return 0;
      }
      console.error('Error fetching expired events:', expiredError);
      return 0;
    }

    if (expiredEvents && expiredEvents.length > 0) {
      const expiredIds = expiredEvents.map(e => e.id);
      
      const { error: userEventsDeleteError } = await supabase
        .from('user_events')
        .delete()
        .in('event_id', expiredIds);
      
      if (userEventsDeleteError) {
        console.error('Error deleting user_events for expired events:', userEventsDeleteError);
      }

      const { error: eventsDeleteError } = await supabase
        .from('events')
        .delete()
        .in('id', expiredIds);

      if (eventsDeleteError) {
        console.error('Error deleting expired events:', eventsDeleteError);
        return 0;
      }
      
      console.log(`Successfully deleted ${expiredIds.length} expired opportunities.`);
      return expiredIds.length;
    }
  } catch (e) {
    console.error('Exception cleaning up expired opportunities:', e);
  }
  return 0;
}

async function removeNonIndianEvents() {
  // Devpost hackathons were synced before the India-only rule; remove them.
  try {
    const { data: rows, error } = await supabase
      .from('events')
      .select('id')
      .ilike('link', '%devpost.com%');

    if (error) {
      console.error('Error fetching non-India (Devpost) events:', error);
      return 0;
    }
    if (!rows || rows.length === 0) return 0;

    const ids = rows.map(r => r.id);

    const { error: userEventsDeleteError } = await supabase
      .from('user_events')
      .delete()
      .in('event_id', ids);
    if (userEventsDeleteError) {
      console.error('Error deleting user_events for non-India events:', userEventsDeleteError);
    }

    const { error: eventsDeleteError } = await supabase
      .from('events')
      .delete()
      .in('id', ids);
    if (eventsDeleteError) {
      console.error('Error deleting non-India events:', eventsDeleteError);
      return 0;
    }

    console.log(`Removed ${ids.length} non-India (Devpost) events.`);
    return ids.length;
  } catch (e) {
    console.error('Exception removing non-India events:', e);
  }
  return 0;
}

export const syncAllHackathons = async () => {
  console.log('Starting unified India-optimized opportunities synchronization...');
  
  const [devfolioHacks, unstopHacks, unstopInternships] = await Promise.all([
    fetchDevfolio(),
    fetchUnstopHackathons(2, 50),
    fetchUnstopInternships()
  ]);

  const allOpportunities = [...devfolioHacks, ...unstopHacks, ...unstopInternships];
  console.log(`Total active India opportunities fetched: ${allOpportunities.length} (Devfolio: ${devfolioHacks.length}, Unstop Hackathons: ${unstopHacks.length}, Unstop Internships: ${unstopInternships.length})`);

  let newCount = 0;
  let updatedCount = 0;

  for (const item of allOpportunities) {
    const result = await upsertEvent(item);
    if (result === 'inserted') {
      newCount++;
    } else if (result === 'updated') {
      updatedCount++;
    }
  }

  const deletedCount = (await cleanExpiredEvents()) + (await removeNonIndianEvents());

  console.log(`Synchronization summary: ${newCount} inserted, ${updatedCount} updated, ${deletedCount} expired/non-India deleted.`);
  return {
    newCount,
    updatedCount,
    deletedCount,
    totalFetched: allOpportunities.length,
    breakdown: {
      devfolio: devfolioHacks.length,
      unstopHackathons: unstopHacks.length,
      unstopInternships: unstopInternships.length
    }
  };
};

export const syncAllOpportunities = syncAllHackathons;

export const syncHackathonsFromDevpost = syncAllHackathons;
