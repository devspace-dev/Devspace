import test from 'node:test';
import assert from 'node:assert/strict';
import {
  isIndianDevfolioHackathon,
  isIndianUnstopHackathon,
  unstopLocationText,
} from '../src/services/hackathonSyncService.js';

test('Devfolio: keeps India timezones, drops others', () => {
  assert.equal(isIndianDevfolioHackathon({ timezone: 'Asia/Kolkata' }), true);
  assert.equal(isIndianDevfolioHackathon({ timezone: 'Asia/Calcutta' }), true);
  assert.equal(isIndianDevfolioHackathon({ timezone: 'Europe/London' }), false);
  assert.equal(isIndianDevfolioHackathon({}), false);
});

test('Unstop: keeps online and India in-person, drops other countries', () => {
  assert.equal(isIndianUnstopHackathon({ region: 'online' }), true);
  const india = { region: 'offline', address_with_country_logo: { country: { name: 'India' } } };
  const us = { region: 'offline', address_with_country_logo: { country: { name: 'United States' } } };
  assert.equal(isIndianUnstopHackathon(india), true);
  assert.equal(isIndianUnstopHackathon(us), false);
  assert.equal(isIndianUnstopHackathon({ region: 'offline' }), false);
});

test('Unstop: shows a real place instead of the raw region', () => {
  assert.equal(unstopLocationText({ region: 'online' }), 'Online');
  assert.equal(
    unstopLocationText({ region: 'offline', address_with_country_logo: { city: 'Pune', state: 'Maharashtra' } }),
    'Pune, Maharashtra',
  );
  assert.equal(unstopLocationText({ region: 'offline' }), 'In-person');
});
