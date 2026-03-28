import { supabase } from '../config/supabase.js';

export const protect = async (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'Not authorized' });

  const { data: { user }, error } = await supabase.auth.getUser(token);
  if (error || !user) return res.status(401).json({ error: 'Invalid token' });

  const { data: profile } = await supabase
    .from('users')
    .select('*')
    .eq('id', user.id)
    .single();

  req.user = profile;
  next();
};

export const isAdmin = (req, res, next) => {
  const isFounder = req.user?.email?.toLowerCase() === 'businessrexxon@gmail.com';
  if (!req.user?.is_admin && !isFounder) {
    return res.status(403).json({ error: 'Access denied. Admins only.' });
  }
  next();
};
