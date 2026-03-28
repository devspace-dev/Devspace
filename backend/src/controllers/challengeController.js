import { supabase } from '../config/supabase.js';

export const getTodayChallenge = async (req, res) => {
  try {
    const { data, error } = await supabase.rpc('assign_daily_challenge', {
      p_requested_stack: req.user.stack?.[0] || 'General'
    });

    if (error) throw error;

    const { data: challenge } = await supabase
      .from('challenges')
      .select('*')
      .eq('id', data.challenge_id)
      .single();

    res.json({ ...data, challenge_details: challenge });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

export const submitCompletion = async (req, res) => {
  const { submissionText, submissionLink } = req.body;

  try {
    const { data, error } = await supabase.rpc('complete_daily_challenge', {
      p_submission_text: submissionText,
      p_submission_link: submissionLink
    });

    if (error) return res.status(400).json({ error: error.message });
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
