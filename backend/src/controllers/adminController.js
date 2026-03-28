import { supabase } from '../config/supabase.js';

export const createChallenge = async (req, res) => {
  const { title, description, techStack, difficulty, pointsReward, publishDate } = req.body;
  
  const { data, error } = await supabase
    .from('challenges')
    .insert({
      title,
      description,
      tech_stack: techStack,
      difficulty,
      points_reward: pointsReward,
      publish_date: publishDate,
      created_by: req.user.id
    })
    .select();

  if (error) return res.status(400).json(error);
  res.status(201).json(data);
};

export const getAllChallenges = async (req, res) => {
  const { data, error } = await supabase
    .from('challenges')
    .select('*')
    .order('publish_date', { ascending: false });

  if (error) return res.status(400).json(error);
  res.json(data);
};

export const updateChallenge = async (req, res) => {
  const { id } = req.params;
  const { data, error } = await supabase
    .from('challenges')
    .update(req.body)
    .eq('id', id)
    .select();

  if (error) return res.status(400).json(error);
  res.json(data);
};

export const deleteChallenge = async (req, res) => {
  const { id } = req.params;
  const { error } = await supabase.from('challenges').delete().eq('id', id);
  if (error) return res.status(400).json(error);
  res.status(204).send();
};
