import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config();

const supabaseUrl = process.env.SUPABASE_URL || 'https://hybvsgxqstnxamdkijsk.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkEvents() {
  const { data: events, error } = await supabase
    .from('events')
    .select('id, title, type, date, end_date, is_active')
    .order('created_at', { ascending: false });

  if (error) {
    console.error('Error fetching events:', error);
    return;
  }

  console.log(`Total events: ${events.length}`);
  console.log('\n--- All Events in DB ---');
  events.forEach((e, i) => {
    console.log(`${i+1}. [${e.type}] "${e.title}" (Active: ${e.is_active})`);
    console.log(`   date: "${e.date}" | end_date: "${e.end_date}"`);
  });
}

checkEvents();
