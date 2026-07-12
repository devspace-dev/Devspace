import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config();

const supabaseUrl = process.env.SUPABASE_URL || 'https://hybvsgxqstnxamdkijsk.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

const supabase = createClient(supabaseUrl, supabaseKey);

async function testApi() {
  // Let's sign in a user to get an access token
  const { data: users, error: userError } = await supabase
    .from('users')
    .select('id, email')
    .limit(1);

  if (userError || !users.length) {
    console.error('Error getting test user:', userError);
    return;
  }

  const testUser = users[0];
  console.log(`Using test user: ${testUser.email} (${testUser.id})`);

  // Sign in or mock JWT? Or call via supabase.rpc directly?
  // Let's check list_events_with_eligibility RPC directly first
  const { data: rpcData, error: rpcError } = await supabase.rpc('list_events_with_eligibility');
  if (rpcError) {
    console.error('RPC Error:', rpcError);
  } else {
    console.log('RPC first event sample keys:', Object.keys(rpcData[0] || {}));
    console.log('RPC first event sample values:', rpcData[0]);
  }
}

testApi();
