import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config();

const supabaseUrl = process.env.SUPABASE_URL || 'https://hybvsgxqstnxamdkijsk.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkDatabaseState() {
  console.log('Fetching users, founder devices, and events...');
  
  const { data: users, error: userError } = await supabase
    .from('users')
    .select('id, email, is_admin');

  if (userError) {
    console.error('Error fetching users:', userError);
  } else {
    console.log('\n--- Admin Users ---');
    console.table(users ? users.filter(u => u.is_admin) : []);
  }

  const { data: devices, error: deviceError } = await supabase
    .from('founder_devices')
    .select('*');

  if (deviceError) {
    console.error('Error fetching devices:', deviceError);
  } else {
    console.log('\n--- Founder Devices ---');
    console.table(devices);
  }

  const { count, error: eventsCountError } = await supabase
    .from('events')
    .select('*', { count: 'exact', head: true });

  if (eventsCountError) {
    console.error('Error counting events:', eventsCountError);
  } else {
    console.log(`\nTotal events in database: ${count}`);
  }

  const { data: recentEvents, error: eventsError } = await supabase
    .from('events')
    .select('id, title, type, is_active, date, end_date')
    .limit(10);

  if (eventsError) {
    console.error('Error fetching recent events:', eventsError);
  } else {
    console.log('\n--- Recent 10 Events ---');
    console.table(recentEvents);
  }
}

checkDatabaseState();
