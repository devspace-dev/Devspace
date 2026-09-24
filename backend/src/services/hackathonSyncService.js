import { supabase } from '../config/supabase.js';

// DevSpace only lists hackathons in India.
// - Devpost is a global feed with no country data, so it is not synced.
// - Devfolio and Unstop are India-focused; we still drop the odd non-India
//   event using the country signals each one exposes.
const INDIAN_TIMEZONES = new Set(['Asia/Kolkata', 'Asia/Calcutta']);

export function isIndianDevfolioHackathon(hack) {
  return INDIAN_TIMEZONES.has(hack?.timezone);
}

export function isIndianUnstopHackathon(hack) {
  // Online events on Unstop (an India-only platform) are Indian-organised.
  if (hack?.region === 'online') return true;
  return hack?.address_with_country_logo?.country?.name === 'India';
}

export function unstopLocationText(hack) {
  if (hack?.region === 'online') return 'Online';
  const addr = hack?.address_with_country_logo;
  const place = [addr?.city, addr?.state].filter(Boolean).join(', ');
  return place || 'In-person';
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
        end_date: endDate
      });
    }
  } catch (e) {
    console.error('Error fetching Devfolio hackathons:', e);
  }
  return hackathons;
}

async function fetchUnstop() {
  const hackathons = [];
  try {
    console.log('Fetching from Unstop API...');
    const response = await fetch('https://unstop.com/api/public/opportunity/search-result?opportunity=hackathons&page=1');
    if (!response.ok) {
      throw new Error(`Unstop API returned status ${response.status}`);
    }
    const json = await response.json();
    const items = json.data?.data || [];
    
    for (const hack of items) {
      const title = hack.title || '';
      const publicUrl = hack.public_url || '';
      if (!title || !publicUrl) continue;
      if (!isIndianUnstopHackathon(hack)) continue;

      const link = hack.seo_url || `https://unstop.com/${publicUrl}`;
      const bannerUrl = hack.logoUrl2 || '';
      const organizer = hack.organisation?.name || 'Unstop';
      const locationText = unstopLocationText(hack);
      
      let rawDesc = hack.details ? hack.details.replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ').trim() : '';
      if (rawDesc.length > 250) {
        rawDesc = rawDesc.substring(0, 247) + '...';
      }
      const description = rawDesc || `Join ${title} on Unstop!`;

      const startDate = hack.regnRequirements?.start_regn_dt ? new Date(hack.regnRequirements.start_regn_dt) : null;
      const endDateVal = hack.end_date ? new Date(hack.end_date) : null;
      let dateText = '';
      if (startDate && endDateVal) {
        dateText = `${startDate.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })} - ${endDateVal.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}`;
      } else if (endDateVal) {
        dateText = `Closes ${endDateVal.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}`;
      }

      let endDate = hack.end_date || null;
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
        end_date: endDate
      });
    }
  } catch (e) {
    console.error('Error fetching Unstop hackathons:', e);
  }
  return hackathons;
}

async function upsertEvent(eventData, includeEndDate = true) {
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
        return await upsertEvent(eventData, false);
      }
      console.error(`Error updating event ${existing.id}:`, updateError);
      return false;
    }
    return 'updated';
  } else {
    const insertPayload = {
      ...payload,
      required_aura: 0,
      link: eventData.link,
      type: 'hackathon',
      is_active: true
    };
    delete insertPayload.updated_at;

    const { error: insertError } = await supabase
      .from('events')
      .insert(insertPayload);

    if (insertError) {
      if (includeEndDate && (insertError.code === 'PGRST204' || insertError.message?.includes('end_date'))) {
        console.warn(`Warning: end_date column not found in schema. Retrying insert without end_date...`);
        return await upsertEvent(eventData, false);
      }
      console.error(`Error inserting event "${title}":`, insertError);
      return false;
    }
    return 'inserted';
  }
}

async function cleanExpiredEvents() {
  console.log('Cleaning up expired events...');
  try {
    const { data: expiredEvents, error: expiredError } = await supabase
      .from('events')
      .select('id')
      .eq('type', 'hackathon')
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
      
      console.log(`Successfully deleted ${expiredIds.length} expired hackathons.`);
      return expiredIds.length;
    }
  } catch (e) {
    console.error('Exception cleaning up expired hackathons:', e);
  }
  return 0;
}

async function removeNonIndianEvents() {
  // Devpost hackathons were synced before the India-only rule; remove them.
  try {
    const { data: rows, error } = await supabase
      .from('events')
      .select('id')
      .eq('type', 'hackathon')
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

    console.log(`Removed ${ids.length} non-India (Devpost) hackathons.`);
    return ids.length;
  } catch (e) {
    console.error('Exception removing non-India hackathons:', e);
  }
  return 0;
}

export const syncAllHackathons = async () => {
  console.log('Starting unified hackathon synchronization...');
  
  const [devfolioHacks, unstopHacks] = await Promise.all([
    fetchDevfolio(),
    fetchUnstop()
  ]);

  const allHacks = [...devfolioHacks, ...unstopHacks];
  console.log(`Total active India hackathons fetched: ${allHacks.length} (Devfolio: ${devfolioHacks.length}, Unstop: ${unstopHacks.length})`);

  let newCount = 0;
  let updatedCount = 0;

  for (const hack of allHacks) {
    const result = await upsertEvent(hack);
    if (result === 'inserted') {
      newCount++;
    } else if (result === 'updated') {
      updatedCount++;
    }
  }

  const deletedCount = (await cleanExpiredEvents()) + (await removeNonIndianEvents());

  console.log(`Synchronization summary: ${newCount} inserted, ${updatedCount} updated, ${deletedCount} expired deleted.`);
  return {
    newCount,
    updatedCount,
    deletedCount,
    totalFetched: allHacks.length,
    breakdown: {
      devfolio: devfolioHacks.length,
      unstop: unstopHacks.length
    }
  };
};

export const syncHackathonsFromDevpost = async () => {
  return await syncAllHackathons();
};
