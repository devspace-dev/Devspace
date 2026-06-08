import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config();

const supabaseUrl = process.env.SUPABASE_URL || 'https://hybvsgxqstnxamdkijsk.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

const supabase = createClient(supabaseUrl, supabaseKey);

async function listPolicies() {
  console.log('Querying pg_policies for events and founder_devices...');
  
  // Since we don't have direct SQL execution privileges via the anon key,
  // we can try fetching if there's any public RPC or if we can run a custom query.
  // Wait, does our supabaseKey have permissions? It is the anon key, so we might not be able to read pg_policies directly.
  // Let's try executing a raw SQL if there's a function, or let's inspect the RLS error details.
  
  // Wait, let's check if we can insert a dummy event with different fields to see which field violates RLS.
  // For example, if we set created_by to our user ID:
  const userId = '90dea1d7-cffd-4b31-9bb0-6ca253956a75';
  
  console.log('Testing event insert as anon key...');
  const { data: ins1, error: err1 } = await supabase
    .from('events')
    .insert({
      title: 'Test RLS',
      type: 'hackathon',
      required_aura: 0,
      link: 'https://test-rls-anon.com',
      is_active: true
    });
  console.log('Anon insert without user:', { ins1, err1 });

  // Let's print out what policies we know from the devspace_schema.sql file.
}

listPolicies();
