import test from 'node:test';
import assert from 'node:assert/strict';
import {
  isIndianDevfolioHackathon,
  isIndianUnstopOpportunity,
  isIndianUnstopHackathon,
  isTechBTechInternship,
  unstopLocationText,
} from '../src/services/hackathonSyncService.js';

test('Devfolio: keeps India timezones, drops others', () => {
  assert.equal(isIndianDevfolioHackathon({ timezone: 'Asia/Kolkata' }), true);
  assert.equal(isIndianDevfolioHackathon({ timezone: 'Asia/Calcutta' }), true);
  assert.equal(isIndianDevfolioHackathon({ timezone: 'Europe/London' }), false);
  assert.equal(isIndianDevfolioHackathon({}), false);
});

test('Unstop: keeps online and India in-person, drops other countries', () => {
  assert.equal(isIndianUnstopOpportunity({ region: 'online' }), true);
  assert.equal(isIndianUnstopHackathon({ region: 'online' }), true);
  const india = { region: 'offline', address_with_country_logo: { country: { name: 'India' } } };
  const us = { region: 'offline', address_with_country_logo: { country: { name: 'United States' } } };
  assert.equal(isIndianUnstopOpportunity(india), true);
  assert.equal(isIndianUnstopOpportunity(us), false);
  // Default to true if country is missing on Unstop platform
  assert.equal(isIndianUnstopOpportunity({ region: 'offline' }), true);
});

test('Unstop: shows a real place instead of the raw region', () => {
  assert.equal(unstopLocationText({ region: 'online' }), 'Online');
  assert.equal(
    unstopLocationText({ region: 'offline', address_with_country_logo: { city: 'Pune', state: 'Maharashtra' } }),
    'Pune, Maharashtra',
  );
  assert.equal(unstopLocationText({ region: 'hybrid' }), 'Hybrid');
  assert.equal(unstopLocationText({ region: 'offline' }), 'In-person');
});

test('Internships: keeps B.Tech tech roles and drops non-tech roles', () => {
  // Accepted engineering roles
  assert.equal(isTechBTechInternship({ title: 'Frontend Developer Internship' }), true);
  assert.equal(isTechBTechInternship({ title: 'Software Developer Internship' }), true);
  assert.equal(isTechBTechInternship({ title: 'Python & AI Developer Intern' }), true);
  assert.equal(isTechBTechInternship({ title: 'Android App Developer Internship' }), true);
  assert.equal(isTechBTechInternship({ title: 'Full Stack Web Development Intern' }), true);
  assert.equal(isTechBTechInternship({ title: 'Data Science & Machine Learning Intern' }), true);
  assert.equal(isTechBTechInternship({ title: 'Backend Software Engineer' }), true);

  // Rejected non-tech roles
  assert.equal(isTechBTechInternship({ title: 'Content Marketing Internship' }), false);
  assert.equal(isTechBTechInternship({ title: 'Social Media & Graphic Design Intern' }), false);
  assert.equal(isTechBTechInternship({ title: 'Business Development (Sales) Intern' }), false);
  assert.equal(isTechBTechInternship({ title: 'HR & Talent Acquisition Intern' }), false);
  assert.equal(isTechBTechInternship({ title: 'Campus Ambassador Internship' }), false);
  assert.equal(isTechBTechInternship({ title: 'Finance & Accounting Intern' }), false);

  // Filter checks
  const engOpp = {
    title: 'Software Development Intern',
    filters: [{ name: 'Engineering Students' }, { name: 'Undergraduate' }]
  };
  assert.equal(isTechBTechInternship(engOpp), true);

  const nonEngOpp = {
    title: 'Software Development Intern',
    filters: [{ name: 'MBA Students' }, { name: 'Medical' }]
  };
  assert.equal(isTechBTechInternship(nonEngOpp), false);
});
