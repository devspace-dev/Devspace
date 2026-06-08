import { syncHackathonsFromDevpost } from '../services/hackathonSyncService.js';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

const run = async () => {
  try {
    const results = await syncHackathonsFromDevpost();
    console.log('Successfully completed hackathon sync!', results);
    process.exit(0);
  } catch (error) {
    console.error('Failed to run hackathon sync script:', error);
    process.exit(1);
  }
};

run();
