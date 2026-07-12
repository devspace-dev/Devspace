import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config();

const supabaseUrl = process.env.SUPABASE_URL || 'https://hybvsgxqstnxamdkijsk.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkFunctionSchema() {
  try {
    const { data, error } = await supabase.rpc('list_events_with_eligibility');
    console.log('RPC Call succeeded:', data ? data.length : 0);
  } catch (err) {
    console.log('RPC Call failed with error:', err.message || err);
  }

  const { data: cols, error: colsError } = await supabase
    .from('events')
    .select('*')
    .limit(1);

  if (colsError) {
    console.error('Error fetching events table cols:', colsError);
  } else {
    console.log('Events table columns:', Object.keys(cols[0] || {}));
  }

  // Let's query the pg_catalog to see the exact return type parameters of list_events_with_eligibility
  const query = `
    SELECT 
      proname,
      prosrc,
      proargnames,
      proallargtypes,
      proargmodes
    FROM pg_proc
    WHERE proname = 'list_events_with_eligibility';
  `;

  // We can't do raw sql queries via client unless we run it via an RPC or if we have another way.
  // But we can check if the events columns contains 'end_date'.
}

checkFunctionSchema();
