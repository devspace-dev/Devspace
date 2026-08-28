import { supabase } from '../config/supabase.js';

export const protect = async (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'Not authorized: No token provided' });

  const { data: { user }, error } = await supabase.auth.getUser(token);
  if (error || !user) return res.status(401).json({ error: 'Invalid or expired token' });

  const { data: profile, error: profileError } = await supabase
    .from('users')
    .select('*')
    .eq('id', user.id)
    .maybeSingle();

  if (profileError || !profile) {
    return res.status(404).json({ error: 'User profile not found. Complete onboarding first.' });
  }

  req.user = profile;
  next();
};

export const isAdmin = (req, res, next) => {
  const founderEmails = (process.env.FOUNDER_EMAILS || '')
    .split(',')
    .map((e) => e.trim().toLowerCase())
    .filter(Boolean);

  const isConfiguredFounder = req.user?.email && founderEmails.includes(req.user.email.toLowerCase());
  const isAdminUser = Boolean(req.user?.is_admin);

  if (!isAdminUser && !isConfiguredFounder) {
    return res.status(403).json({ error: 'Access denied. Admins only.' });
  }
  next();
};

