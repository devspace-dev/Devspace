import { supabase } from '../config/supabase.js';
import { generateAIChallenge } from '../services/aiGeneratorService.js';

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

export const autoGenerateChallenge = async (req, res) => {
  const { techStack, type, publishDate } = req.body;

  try {
    // 1. Generate content with Gemini AI
    const content = await generateAIChallenge(techStack, type);

    // 2. Insert into Supabase
    const { data, error } = await supabase
      .from('challenges')
      .insert({
        title: content.title,
        description: content.description,
        tech_stack: techStack,
        difficulty: content.difficulty,
        points_reward: content.points_reward,
        publish_date: publishDate || new Date().toISOString().split('T')[0],
        created_by: req.user.id
      })
      .select();

    if (error) throw error;
    res.status(201).json({ message: "AI Challenge Generated", data });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
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
